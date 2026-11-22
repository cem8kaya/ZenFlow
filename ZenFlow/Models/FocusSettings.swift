//
//  FocusSettings.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Customizable Pomodoro lengths. Everyone gets the classic 25/5/15 rhythm;
//  changing it is a Premium feature. The settings are a pure, validated value
//  type; FocusSettingsStore persists them and applies the premium rule.
//

import Combine
import Foundation

struct FocusSettings: Codable, Equatable {

    // MARK: - Limits

    static let workRange = 10...90
    static let shortBreakRange = 3...20
    static let longBreakRange = 10...45
    static let sessionsBeforeLongBreakRange = 2...8

    /// The classic Pomodoro rhythm every user gets
    static let defaults = FocusSettings(
        workMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        sessionsBeforeLongBreak: 4
    )

    // MARK: - Data

    var workMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var sessionsBeforeLongBreak: Int

    // MARK: - Helpers

    func minutes(for mode: FocusMode) -> Int {
        switch mode {
        case .work: return workMinutes
        case .shortBreak: return shortBreakMinutes
        case .longBreak: return longBreakMinutes
        }
    }

    /// A copy with every value clamped to its allowed range
    func sanitized() -> FocusSettings {
        func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int {
            min(max(value, range.lowerBound), range.upperBound)
        }
        return FocusSettings(
            workMinutes: clamp(workMinutes, Self.workRange),
            shortBreakMinutes: clamp(shortBreakMinutes, Self.shortBreakRange),
            longBreakMinutes: clamp(longBreakMinutes, Self.longBreakRange),
            sessionsBeforeLongBreak: clamp(sessionsBeforeLongBreak, Self.sessionsBeforeLongBreakRange)
        )
    }

    /// Which mode follows `mode` after `completedSessions` finished work sessions
    func nextMode(after mode: FocusMode, completedSessions: Int) -> FocusMode {
        switch mode {
        case .work:
            let isLongBreakDue = completedSessions > 0 && completedSessions % sessionsBeforeLongBreak == 0
            return isLongBreakDue ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }
}

/// Persists the user's settings and decides which ones are in effect
class FocusSettingsStore: ObservableObject {

    static let shared = FocusSettingsStore()

    private let defaults: UserDefaults
    private let storageKey = "focusSettings"

    /// Whether the user has premium. Overridable for tests.
    var isPremiumProvider: () -> Bool = { StoreManager.cachedPremiumStatus }

    /// What the user configured (kept even if premium is not active)
    @Published private(set) var settings: FocusSettings

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(FocusSettings.self, from: data) {
            self.settings = saved.sanitized()
        } else {
            self.settings = .defaults
        }
    }

    /// The settings the timer actually uses: custom ones for premium users,
    /// the classic rhythm for everyone else
    var effectiveSettings: FocusSettings {
        isPremiumProvider() ? settings : .defaults
    }

    func update(_ newSettings: FocusSettings) {
        settings = newSettings.sanitized()
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: storageKey)
        }
    }

    func resetToDefaults() {
        update(.defaults)
    }
}
