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

    /// Display name for the mood (localized)
    var displayName: String {
        switch self {
        case .verySad:
            return String(localized: "mood_very_sad", defaultValue: "Çok Üzgün", comment: "Mood: very sad")
        case .sad:
            return String(localized: "mood_sad", defaultValue: "Üzgün", comment: "Mood: sad")
        case .neutral:
            return String(localized: "mood_neutral", defaultValue: "Normal", comment: "Mood: neutral")
        case .happy:
            return String(localized: "mood_happy", defaultValue: "Mutlu", comment: "Mood: happy")
        case .veryHappy:
            return String(localized: "mood_very_happy", defaultValue: "Çok Mutlu", comment: "Mood: very happy")
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

extension Mood {
    /// The mood closest to a 1...5 average (used to label chart axes and averages)
    static func nearest(toValue value: Double) -> Mood {
        let clamped = min(max(Int(value.rounded()), 1), 5)
        return Mood.allCases.first { $0.value == clamped } ?? .neutral
    }
}

// MARK: - Mood Entry Data

/// Represents a saved mood check-in entry
struct MoodEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    /// Mood after the session
    let mood: Mood
    /// Optional mood before the session (enables before/after insights)
    let preMood: Mood?
    /// `exerciseType` of the breathing exercise that was practiced, if any
    let exerciseType: String?
    /// Session length in minutes, if known
    let durationMinutes: Int?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Mood,
        preMood: Mood? = nil,
        exerciseType: String? = nil,
        durationMinutes: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.preMood = preMood
        self.exerciseType = exerciseType
        self.durationMinutes = durationMinutes
    }

    /// Mood change over the session (after minus before), if a before-mood exists
    var change: Int? {
        guard let preMood else { return nil }
        return mood.value - preMood.value
    }

    /// Formatted date string
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
