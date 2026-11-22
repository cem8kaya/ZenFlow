//
//  OnDeviceCoachAssistant.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Optional: lets Apple's on-device language model (Foundation Models,
//  iOS 26+) put the coach's answer into more natural words. Nothing leaves
//  the device. The rule-based engine always decides WHAT to say (facts,
//  suggested action, safety); the model only rephrases, and any failure,
//  timeout or unavailability falls back to the engine's own text. Self-harm
//  messages never go through the model.
//
//  Compiled only when the ZENFLOW_ONDEVICE_AI Swift flag is set (Build
//  Settings > Active Compilation Conditions), so the project builds the same
//  everywhere until you opt in. Without the flag every member below is an
//  inert stub and the Settings switch stays hidden.
//

import Foundation
#if ZENFLOW_ONDEVICE_AI && canImport(FoundationModels)
import FoundationModels
#endif

class OnDeviceCoachAssistant {

    static let shared = OnDeviceCoachAssistant()

    /// UserDefaults key of the Settings switch
    static let enabledKey = "zenCoachOnDeviceAIEnabled"

    /// Longest model reply we show (the model is asked for far less)
    static let maximumReplyLength = 600
    /// Give up on the model after this long
    static let timeoutSeconds: UInt64 = 8

    private init() {}

    // MARK: - Availability

    /// True only in builds compiled with ZENFLOW_ONDEVICE_AI
    static var isCompiledIn: Bool {
        #if ZENFLOW_ONDEVICE_AI && canImport(FoundationModels)
        return true
        #else
        return false
        #endif
    }

    var isUserEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    /// Whether the device's model can answer right now (iOS 26+, Apple Intelligence on)
    var isModelAvailable: Bool {
        #if ZENFLOW_ONDEVICE_AI && canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
        }
        return false
        #else
        return false
        #endif
    }

    /// Whether replies should be rephrased by the model
    var isActive: Bool {
        Self.isCompiledIn && isUserEnabled && isModelAvailable
    }

    // MARK: - Prompt (pure, testable)

    static let instructions = """
    You are Zen Coach, a warm and calm mindfulness companion inside the MyZenFlow app. \
    Reply in the same language as the user's message (Turkish or English). \
    Keep the reply under 70 words: gentle, practical, no lists. \
    You are not a therapist: never diagnose, never give medical advice, never discuss medication. \
    If the user seems to be in crisis or mentions self-harm, urge them to contact local emergency services and someone they trust. \
    You may mention only these app features: breathing exercises, sleep mode, focus timer, daily Zen moment, weekly report, Zen garden. \
    Do not invent statistics or facts. Use the draft reply's facts and its suggested next step; never contradict them.
    """

    static func makePrompt(userText: String, draft: ZenCoachResponse) -> String {
        var prompt = "User message: \(userText)\n"
        prompt += "Draft reply (facts to keep): \(draft.text.replacingOccurrences(of: "\n\n", with: " "))\n"
        if let action = draft.actionText {
            prompt += "A button under the reply says: \(action)\n"
        }
        prompt += "Write the final reply."
        return prompt
    }

    /// Trim, cap the length at a sentence end and reject empty output
    static func cleaned(_ reply: String) -> String? {
        let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count > maximumReplyLength else { return trimmed }

        let cut = String(trimmed.prefix(maximumReplyLength))
        if let end = cut.lastIndex(where: { ".!?…".contains($0) }) {
            return String(cut[...end])
        }
        return cut
    }

    // MARK: - Rewrite

    /// The model's rephrasing of `draft`, or nil to keep the engine's text
    func rewrite(userText: String, draft: ZenCoachResponse) async -> String? {
        guard isActive, !draft.isCrisis else { return nil }

        let prompt = Self.makePrompt(userText: userText, draft: draft)
        guard let raw = await Self.generate(prompt: prompt) else { return nil }
        return Self.cleaned(raw)
    }

    /// Runs the model with a timeout. Static and `nonisolated` so it only
    /// touches Sendable values.
    private nonisolated static func generate(prompt: String) async -> String? {
        #if ZENFLOW_ONDEVICE_AI && canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return nil }

        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                do {
                    let session = LanguageModelSession(instructions: OnDeviceCoachAssistant.instructions)
                    let response = try await session.respond(to: prompt)
                    return response.content
                } catch {
                    // Unsupported language, guardrails, model busy...
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: OnDeviceCoachAssistant.timeoutSeconds * 1_000_000_000)
                return nil
            }

            // First finisher wins; the other is cancelled
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        #else
        return nil
        #endif
    }
}
