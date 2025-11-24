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
            var coachMessage = response.toChatMessage()

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
            return "Nefes Egzersizi"
        case .focus:
            return "Pomodoro"
        case .sleep:
            return "4-7-8 Tekniği"
        case .motivation:
            return "Zen Bahçem"
        case .meditation:
            return "Meditasyon"
        case .progress:
            return "İlerlemem"
        case .general:
            return ""
        }
    }

    // MARK: - Conversation History

    /// Saves conversation history to UserDefaults
    private func saveConversationHistory() {
        // Keep only last maxHistoryCount messages
        let messagesToSave = Array(messages.suffix(maxHistoryCount))

        if let encoded = try? JSONEncoder().encode(messagesToSave) {
            UserDefaults.standard.set(encoded, forKey: conversationHistoryKey)
            print("💾 Conversation history saved: \(messagesToSave.count) messages")
        }
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

    // MARK: - Suggested Prompts

    /// Returns suggested prompts for quick access
    func getSuggestedPrompts() -> [String] {
        return [
            "Nasıl meditasyon yapabilirim?",
            "Stresli hissediyorum",
            "Odaklanamıyorum, ne yapmalıyım?",
            "Uyuyamıyorum",
            "Motivasyon bulamıyorum"
        ]
    }
}
