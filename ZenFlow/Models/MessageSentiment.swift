//
//  MessageSentiment.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Sentiment analysis classification for user messages.
//

import Foundation

// MARK: - Message Sentiment

/// Represents the emotional sentiment of a user's message
enum MessageSentiment: String, Codable, CaseIterable {
    case positive
    case neutral
    case negative

    /// Display name localized
    var displayName: String {
        switch self {
        case .positive:
            return String(localized: "sentiment_positive", defaultValue: "Pozitif", comment: "Positive")
        case .neutral:
            return String(localized: "sentiment_neutral", defaultValue: "Nötr", comment: "Neutral")
        case .negative:
            return String(localized: "sentiment_negative", defaultValue: "Negatif", comment: "Negative")
        }
    }

    /// Turkish keywords for sentiment matching
    var keywords: [String] {
        switch self {
        case .positive:
            return ["harika", "güzel", "teşekkür", "mükemmel", "mutlu", "iyi", "süper", "başarı", "sevindim", "hoş", "keyifli", "rahat"]
        case .negative:
            return ["kötü", "üzgün", "stres", "kaygı", "korku", "panik", "yorgun", "bitkin", "berbat", "sinir", "huzursuz", "ağır"]
        case .neutral:
            return []
        }
    }
}
