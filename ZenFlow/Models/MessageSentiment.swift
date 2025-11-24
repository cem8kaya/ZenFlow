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

    /// Display name in Turkish
    var displayName: String {
        switch self {
        case .positive:
            return "Pozitif"
        case .neutral:
            return "Nötr"
        case .negative:
            return "Negatif"
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
