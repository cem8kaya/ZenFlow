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

    private let intentClassifier = IntentClassifier.shared
    private let responseGenerator = ResponseGenerator.shared

    // MARK: - Initialization

    private init() {
        loadConversationHistory()
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

        // Simulate processing delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            // Classify intent and sentiment
            let intent = self.intentClassifier.classifyIntent(from: trimmedText)
            let sentiment = self.intentClassifier.analyzeSentiment(from: trimmedText)

            // Generate response
            let userStats = UserStats.fromLocalData()
            let response = self.responseGenerator.generateResponse(
                for: intent,
                sentiment: sentiment,
                userStats: userStats
            )

            // Create coach message
            let coachMessage = response.toChatMessage()

            // Add action URL to message if available (stored in a custom way)
            // We'll pass this through the UI via the response
            self.messages.append(coachMessage)

            // Store the last response for action button handling
            self.lastResponse = response

            // Hide processing indicator
            self.isProcessing = false

            // Save conversation history
            self.saveConversationHistory()

            print("💬 Message processed: \(intent.displayName) - \(sentiment.displayName)")
        }
    }

    // MARK: - Last Response

    /// Stores the last response for action button handling
    private(set) var lastResponse: ZenCoachResponse?

    /// Gets action for a specific message ID
    func getAction(for messageId: UUID) -> (text: String, url: String)? {
        // Find the message
        guard let message = messages.first(where: { $0.id == messageId }),
              !message.isUser else {
            return nil
        }

        // Check if this is the last coach message
        if message.id == messages.filter({ !$0.isUser }).last?.id,
           let response = lastResponse,
           let actionText = response.actionText,
           let actionURL = response.actionURL {
            return (actionText, actionURL)
        }

        // For older messages, regenerate action based on intent
        if let intent = message.intent,
           let url = intent.deepLinkURL {
            let actionText = getActionText(for: intent)
            return (actionText, url)
        }

        return nil
    }

    /// Gets action text for intent
    private func getActionText(for intent: UserIntent) -> String {
        switch intent {
        case .stress, .breathing:
            return String(localized: "action_breathing", comment: "Breathing Exercise")
        case .focus:
            return String(localized: "action_pomodoro", comment: "Pomodoro")
        case .sleep:
            return String(localized: "action_478", comment: "4-7-8 Technique")
        case .motivation:
            return String(localized: "action_garden", comment: "Zen Garden")
        case .meditation:
            return String(localized: "action_meditation", comment: "Meditation")
        case .progress:
            return String(localized: "action_progress", comment: "My Progress")
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
        UserDefaults.standard.removeObject(forKey: conversationHistoryKey)
        print("🗑️ Conversation history cleared")
    }

    // MARK: - Suggested Prompts (Enhanced)

    /// Returns suggested prompts for quick access - limited to 5 for better UX
    func getSuggestedPrompts() -> [String] {
        return [
            String(localized: "suggested_prompt_0", comment: "How to start meditation"),
            String(localized: "suggested_prompt_1", comment: "Mentally tired, need help"),
            String(localized: "suggested_prompt_2", comment: "How to improve focus"),
            String(localized: "suggested_prompt_3", comment: "Can't sleep well at night"),
            String(localized: "suggested_prompt_4", comment: "Need motivation today")
        ]
    }

    /// Returns category-specific suggested prompts
    func getCategorySuggestedPrompts(for category: String) -> [String] {
        switch category.lowercased() {
        case "stres", "stress":
            return [
                String(localized: "category_prompt_stress_0", comment: "Feeling very stressed"),
                String(localized: "category_prompt_stress_1", comment: "How to control anxiety"),
                String(localized: "category_prompt_stress_2", comment: "Need immediate relief"),
                String(localized: "category_prompt_stress_3", comment: "Overwhelmed by stress")
            ]
        case "odaklanma", "focus":
            return [
                String(localized: "category_prompt_focus_0", comment: "Can't concentrate"),
                String(localized: "category_prompt_focus_1", comment: "What is Pomodoro technique"),
                String(localized: "category_prompt_focus_2", comment: "Tips for productive work"),
                String(localized: "category_prompt_focus_3", comment: "Very distracted")
            ]
        case "uyku", "sleep":
            return [
                String(localized: "category_prompt_sleep_0", comment: "Having trouble sleeping"),
                String(localized: "category_prompt_sleep_1", comment: "Show 4-7-8 technique"),
                String(localized: "category_prompt_sleep_2", comment: "How to improve sleep quality"),
                String(localized: "category_prompt_sleep_3", comment: "Mind won't stop at night")
            ]
        case "meditasyon", "meditation":
            return [
                String(localized: "category_prompt_meditation_0", comment: "Want to learn meditation"),
                String(localized: "category_prompt_meditation_1", comment: "How many minutes per day"),
                String(localized: "category_prompt_meditation_2", comment: "What to think during meditation"),
                String(localized: "category_prompt_meditation_3", comment: "Show beginner exercises")
            ]
        default:
            return getSuggestedPrompts()
        }
    }
}
