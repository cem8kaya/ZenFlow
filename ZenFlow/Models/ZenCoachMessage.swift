//
//  ZenCoachMessage.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Chat message model for Zen Coach conversations.
//

import Foundation

// MARK: - Zen Coach Message

/// Represents a single message in the Zen Coach chat
struct ZenCoachMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    let intent: UserIntent?
    let sentiment: MessageSentiment?
    /// Action button of a coach reply (nil for user messages and older history)
    let actionText: String?
    let actionURL: String?

    init(
        id: UUID = UUID(),
        text: String,
        isUser: Bool,
        timestamp: Date = Date(),
        intent: UserIntent? = nil,
        sentiment: MessageSentiment? = nil,
        actionText: String? = nil,
        actionURL: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.intent = intent
        self.sentiment = sentiment
        self.actionText = actionText
        self.actionURL = actionURL
    }

    /// Formatted timestamp string
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
