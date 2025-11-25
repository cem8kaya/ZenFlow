//
//  ZenCoachResponse.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Response model for Zen Coach with action buttons.
//

import Foundation

// MARK: - Zen Coach Response

/// Represents a response from Zen Coach with optional action
struct ZenCoachResponse {
    let text: String
    let intent: UserIntent
    let sentiment: MessageSentiment
    let actionText: String?
    let actionURL: String?

    init(
        text: String,
        intent: UserIntent,
        sentiment: MessageSentiment,
        actionText: String? = nil,
        actionURL: String? = nil
    ) {
        self.text = text
        self.intent = intent
        self.sentiment = sentiment
        self.actionText = actionText
        self.actionURL = actionURL
    }

    /// Convert response to a chat message
    func toChatMessage() -> ZenCoachMessage {
        return ZenCoachMessage(
            text: text,
            isUser: false,
            intent: intent,
            sentiment: sentiment
        )
    }
}
