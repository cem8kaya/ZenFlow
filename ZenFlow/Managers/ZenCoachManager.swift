//
//  ZenCoachManager.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Main manager for Zen Coach feature.
//  Coordinates intent classification, response generation, and conversation history.
//

import Foundation
import Combine

// MARK: - Zen Coach Manager

/// Main manager for Zen Coach feature
class ZenCoachManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ZenCoachManager()

    // MARK: - Published Properties

    @Published var messages: [ZenCoachMessage] = []
    @Published var isProcessing: Bool = false

    // MARK: - Constants

    private let maxHistoryCount = 50
    private let conversationHistoryKey = "zenCoachConversationHistory"
    private var saveWorkItem: DispatchWorkItem?

    // MARK: - Dependencies

    private var engine = ZenCoachEngine()
    private var engineState = CoachConversationState()
    private let assistant = OnDeviceCoachAssistant.shared

    // MARK: - Initialization

    private init() {
        loadConversationHistory()

        // After a restart "yes" should still mean the last suggestion
        if let last = messages.last(where: { !$0.isUser }) {
            engineState.lastActionText = last.actionText
            engineState.lastActionURL = last.actionURL
        }
    }

    // MARK: - Message Handling

    /// Sends a user message and generates a response
    /// - Parameter text: User's message text
    func sendMessage(_ text: String) {
        // Trim whitespace
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Add user message
        let userMessage = ZenCoachMessage(
            text: trimmedText,
            isUser: true
        )
        messages.append(userMessage)

        // Show processing indicator
        isProcessing = true

        // Short pause so the reply does not feel instant
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            let context = CoachContext.current()
            let response = self.engine.reply(to: trimmedText, context: context, state: &self.engineState)

            // Optionally let the on-device model rephrase (never for safety replies)
            if self.assistant.isActive, !response.isCrisis {
                Task { @MainActor in
                    let rewritten = await self.assistant.rewrite(userText: trimmedText, draft: response)
                    self.deliver(rewritten.map { response.replacingText($0) } ?? response)
                }
            } else {
                self.deliver(response)
            }
        }
    }

    /// Adds the coach's reply to the conversation
    private func deliver(_ response: ZenCoachResponse) {
        messages.append(response.toChatMessage())
        lastResponse = response
        isProcessing = false
        saveConversationHistory()

        print("💬 Message processed: \(response.intent.displayName) - \(response.sentiment.displayName) (\(response.kind))")
    }

    // MARK: - Last Response

    /// Stores the last response
    private(set) var lastResponse: ZenCoachResponse?

    /// The action button of a coach message
    func getAction(for messageId: UUID) -> (text: String, url: String)? {
        guard let message = messages.first(where: { $0.id == messageId }),
              !message.isUser else {
            return nil
        }

        // Replies carry their own action
        if let text = message.actionText, let url = message.actionURL {
            return (text, url)
        }

        // History saved before replies carried actions: derive one from the intent
        if let intent = message.intent,
           let url = intent.deepLinkURL {
            let actionText = getActionText(for: intent)
            return actionText.isEmpty ? nil : (actionText, url)
        }

        return nil
    }

    /// Button text for messages saved by older versions
    private func getActionText(for intent: UserIntent) -> String {
        switch intent {
        case .stress, .anger, .breathing:
            return String(localized: "action_breathing", defaultValue: "Nefes Egzersizi", comment: "Breathing Exercise")
        case .focus:
            return String(localized: "action_pomodoro", defaultValue: "Pomodoro", comment: "Pomodoro")
        case .sleep:
            return CoachStrings.text("coach_action_sleep")
        case .motivation:
            return String(localized: "action_garden", defaultValue: "Zen Bahçesi", comment: "Zen Garden")
        case .meditation:
            return String(localized: "action_meditation", defaultValue: "Meditasyon", comment: "Meditation")
        case .progress:
            return CoachStrings.text("coach_action_report")
        case .gratitude:
            return CoachStrings.text("coach_action_gratitude")
        case .general:
            return ""
        }
    }

    // MARK: - Conversation History

    /// Saves conversation history to UserDefaults with debouncing
    private func saveConversationHistory() {
        // Cancel previous save work item to debounce
        saveWorkItem?.cancel()

        // Create new work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // Trim messages to maxHistoryCount in memory
            if self.messages.count > self.maxHistoryCount {
                let excessCount = self.messages.count - self.maxHistoryCount
                DispatchQueue.main.async {
                    self.messages.removeFirst(excessCount)
                }
            }

            // Keep only last maxHistoryCount messages
            let messagesToSave = Array(self.messages.suffix(self.maxHistoryCount))

            // Encode on background thread
            if let encoded = try? JSONEncoder().encode(messagesToSave) {
                UserDefaults.standard.set(encoded, forKey: self.conversationHistoryKey)
                print("💾 Conversation history saved: \(messagesToSave.count) messages")
            }
        }

        saveWorkItem = workItem

        // Execute after 1 second delay to debounce rapid saves
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    /// Loads conversation history from UserDefaults
    private func loadConversationHistory() {
        if let data = UserDefaults.standard.data(forKey: conversationHistoryKey),
           let decoded = try? JSONDecoder().decode([ZenCoachMessage].self, from: data) {
            messages = decoded
            print("📂 Conversation history loaded: \(decoded.count) messages")
        }
    }

    /// Clears conversation history
    func clearHistory() {
        messages.removeAll()
        lastResponse = nil
        engineState = CoachConversationState()
        UserDefaults.standard.removeObject(forKey: conversationHistoryKey)
        print("🗑️ Conversation history cleared")
    }

    // MARK: - Suggested Prompts

    /// Quick prompts that fit the moment (time of day, streak, new or returning user)
    func getSuggestedPrompts() -> [String] {
        ZenCoachEngine.suggestedPrompts(for: CoachContext.current()).map { $0.text }
    }

    /// A tapped prompt without its leading emoji, ready to be sent as a message
    static func cleanPrompt(_ prompt: String) -> String {
        String(prompt.drop(while: { !$0.isLetter && !$0.isNumber }))
            .trimmingCharacters(in: .whitespaces)
    }

    /// Returns category-specific suggested prompts
    func getCategorySuggestedPrompts(for category: String) -> [String] {
        switch category.lowercased() {
        case "stres", "stress":
            return [
                String(localized: "category_prompt_stress_0", defaultValue: "Çok stresli hissediyorum", comment: "Feeling very stressed"),
                String(localized: "category_prompt_stress_1", defaultValue: "Kaygılarımı nasıl kontrol ederim?", comment: "How to control anxiety"),
                String(localized: "category_prompt_stress_2", defaultValue: "Hemen rahatlamam lazım", comment: "Need immediate relief"),
                String(localized: "category_prompt_stress_3", defaultValue: "Stresten bunaldım", comment: "Overwhelmed by stress")
            ]
        case "odaklanma", "focus":
            return [
                String(localized: "category_prompt_focus_0", defaultValue: "Konsantre olamıyorum", comment: "Can't concentrate"),
                String(localized: "category_prompt_focus_1", defaultValue: "Pomodoro tekniği nedir?", comment: "What is Pomodoro technique"),
                String(localized: "category_prompt_focus_2", defaultValue: "Verimli çalışma için ipuçları ver", comment: "Tips for productive work"),
                String(localized: "category_prompt_focus_3", defaultValue: "Dikkatim çok dağınık", comment: "Very distracted")
            ]
        case "uyku", "sleep":
            return [
                String(localized: "category_prompt_sleep_0", defaultValue: "Uyumakta zorlanıyorum", comment: "Having trouble sleeping"),
                String(localized: "category_prompt_sleep_1", defaultValue: "4-7-8 nefes tekniği göster", comment: "Show 4-7-8 technique"),
                String(localized: "category_prompt_sleep_2", defaultValue: "Uyku kalitemi nasıl artırırım?", comment: "How to improve sleep quality"),
                String(localized: "category_prompt_sleep_3", defaultValue: "Zihinim durmuyor gece", comment: "Mind won't stop at night")
            ]
        case "meditasyon", "meditation":
            return [
                String(localized: "category_prompt_meditation_0", defaultValue: "Meditasyon yapmayı öğrenmek istiyorum", comment: "Want to learn meditation"),
                String(localized: "category_prompt_meditation_1", defaultValue: "Günde kaç dakika meditasyon yapmalıyım?", comment: "How many minutes per day"),
                String(localized: "category_prompt_meditation_2", defaultValue: "Meditasyon sırasında ne düşünmeliyim?", comment: "What to think during meditation"),
                String(localized: "category_prompt_meditation_3", defaultValue: "Başlangıç egzersizleri göster", comment: "Show beginner exercises")
            ]
        default:
            return getSuggestedPrompts()
        }
    }
}
