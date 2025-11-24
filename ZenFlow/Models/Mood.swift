//
//  Mood.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Mood tracking model for post-session check-ins.
//  Allows users to record their emotional state after completing a session.
//

import Foundation
import SwiftUI

// MARK: - Mood Enum

/// Represents user's emotional state after a session
enum Mood: String, Codable, CaseIterable, Identifiable {
    case verySad
    case sad
    case neutral
    case happy
    case veryHappy

    var id: String { rawValue }

    /// Emoji representation of the mood
    var emoji: String {
        switch self {
        case .verySad:
            return "😢"
        case .sad:
            return "😕"
        case .neutral:
            return "😐"
        case .happy:
            return "😊"
        case .veryHappy:
            return "😄"
        }
    }

    /// Display name for the mood
    var displayName: String {
        switch self {
        case .verySad:
            return "Çok Üzgün"
        case .sad:
            return "Üzgün"
        case .neutral:
            return "Normal"
        case .happy:
            return "Mutlu"
        case .veryHappy:
            return "Çok Mutlu"
        }
    }

    /// Numeric value for analytics (1-5 scale)
    var value: Int {
        switch self {
        case .verySad:
            return 1
        case .sad:
            return 2
        case .neutral:
            return 3
        case .happy:
            return 4
        case .veryHappy:
            return 5
        }
    }
}

// MARK: - Mood Entry Data

/// Represents a saved mood check-in entry
struct MoodEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let mood: Mood

    init(id: UUID = UUID(), date: Date = Date(), mood: Mood) {
        self.id = id
        self.date = date
        self.mood = mood
    }

    /// Formatted date string
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
