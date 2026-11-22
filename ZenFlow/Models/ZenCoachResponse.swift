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

// MARK: - Reply Kind

/// What sort of reply the coach produced (used for safety handling and tests)
enum CoachReplyKind: Equatable {
    /// Safety response to a message about self-harm
    case crisis
    case greeting
    case thanks
    /// Answer to a "yes" / "no" after a suggestion
    case followUp
    /// Data-driven answer about the user's progress
    case progress
    case standard
}

// MARK: - Zen Coach Response

/// Represents a response from Zen Coach with optional action
struct ZenCoachResponse {
    let text: String
    let intent: UserIntent
    let sentiment: MessageSentiment
    let actionText: String?
    let actionURL: String?
    let kind: CoachReplyKind

    init(
        text: String,
        intent: UserIntent,
        sentiment: MessageSentiment,
        actionText: String? = nil,
        actionURL: String? = nil,
        kind: CoachReplyKind = .standard
    ) {
        self.text = text
        self.intent = intent
        self.sentiment = sentiment
        self.actionText = actionText
        self.actionURL = actionURL
        self.kind = kind
    }

    var isCrisis: Bool { kind == .crisis }

    /// The same response with different text (used when the text is rewritten)
    func replacingText(_ newText: String) -> ZenCoachResponse {
        ZenCoachResponse(
            text: newText,
            intent: intent,
            sentiment: sentiment,
            actionText: actionText,
            actionURL: actionURL,
            kind: kind
        )
    }

    /// Convert response to a chat message (the action travels with it, so
    /// older messages keep their button)
    func toChatMessage() -> ZenCoachMessage {
        return ZenCoachMessage(
            text: text,
            isUser: false,
            intent: intent,
            sentiment: sentiment,
            actionText: actionText,
            actionURL: actionURL
        )
    }
}
