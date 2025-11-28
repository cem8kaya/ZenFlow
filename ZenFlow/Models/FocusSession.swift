//
//  FocusSession.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Pomodoro-style focus session model with work, short break, and long break modes.
//  Supports customizable durations and session tracking.
//

import Foundation
import SwiftUI

// MARK: - Focus Mode

/// Focus session modes following the Pomodoro technique
enum FocusMode: String, Codable, CaseIterable {
    case work
    case shortBreak
    case longBreak

    /// Duration in minutes for each mode
    var durationMinutes: Int {
        switch self {
        case .work:
            return 25
        case .shortBreak:
            return 5
        case .longBreak:
            return 15
        }
    }

    /// Duration in seconds for each mode
    var durationSeconds: TimeInterval {
        return TimeInterval(durationMinutes * 60)
    }

    /// Display name for the mode
    var displayName: String {
        switch self {
        case .work:
            return String(localized: "focus_mode_work", defaultValue: "Odaklanma", comment: "Focus mode display name")
        case .shortBreak:
            return String(localized: "focus_mode_short_break", defaultValue: "Kısa Mola", comment: "Short break mode display name")
        case .longBreak:
            return String(localized: "focus_mode_long_break", defaultValue: "Uzun Mola", comment: "Long break mode display name")
        }
    }

    /// Description for the mode
    var description: String {
        switch self {
        case .work:
            return String(localized: "focus_mode_work_desc", defaultValue: "\(durationMinutes) dakika odaklanma zamanı", comment: "Focus mode description")
        case .shortBreak:
            return String(localized: "focus_mode_short_break_desc", defaultValue: "\(durationMinutes) dakika kısa mola", comment: "Short break mode description")
        case .longBreak:
            return String(localized: "focus_mode_long_break_desc", defaultValue: "\(durationMinutes) dakika uzun mola", comment: "Long break mode description")
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .work:
            return "brain.head.profile"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "figure.walk"
        }
    }

    /// Primary color for the mode
    var color: Color {
        switch self {
        case .work:
            return ZenTheme.calmBlue
        case .shortBreak:
            return ZenTheme.serenePurple
        case .longBreak:
            return ZenTheme.mysticalViolet
        }
    }

    /// Next mode in the Pomodoro cycle
    /// - Parameter completedSessions: Number of completed work sessions
    /// - Returns: The next appropriate focus mode
    func nextMode(completedSessions: Int) -> FocusMode {
        switch self {
        case .work:
            // After every 4 work sessions, take a long break
            return (completedSessions % 4 == 0 && completedSessions > 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }
}

// MARK: - Focus Session Data

/// Represents a completed focus session
struct FocusSessionData: Codable, Identifiable {
    let id: UUID
    let date: Date
    let mode: FocusMode
    let durationMinutes: Int
    let completed: Bool // Whether the session was completed or interrupted

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mode: FocusMode,
        durationMinutes: Int,
        completed: Bool = true
    ) {
        self.id = id
        self.date = date
        self.mode = mode
        self.durationMinutes = durationMinutes
        self.completed = completed
    }

    /// Formatted date string
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Focus Timer State

/// Represents the current state of the focus timer
enum FocusTimerState: Equatable {
    case idle
    case running
    case paused
    case completed

    var displayText: String {
        switch self {
        case .idle:
            return String(localized: "timer_state_start", defaultValue: "Başla", comment: "Timer start button")
        case .running:
            return String(localized: "timer_state_pause", defaultValue: "Duraklat", comment: "Timer pause button")
        case .paused:
            return String(localized: "timer_state_resume", defaultValue: "Devam Et", comment: "Timer resume button")
        case .completed:
            return String(localized: "timer_state_completed", defaultValue: "Tamamlandı", comment: "Timer completed status")
        }
    }

    var iconName: String {
        switch self {
        case .idle, .paused:
            return "play.fill"
        case .running:
            return "pause.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}
