//
//  WidgetSnapshot.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Small, Codable summary of the user's progress that the app writes for the
//  home/lock screen widgets to read. It travels through an App Group
//  container, so the app's own storage (UserDefaults.standard) stays untouched.
//
//  SHARED FILE: add it to BOTH the app target and the widget extension target
//  (File inspector > Target Membership). See ZenFlowWidget/README.md.
//

import Foundation

struct WidgetSnapshot: Codable, Equatable {

    /// App Group that both the app and the widget extension must have enabled.
    /// Change it here if your team uses a different identifier.
    static let appGroupIdentifier = "group.com.oqza.MyZenFlowApp"

    private static let storageKey = "zenflow_widget_snapshot"

    // MARK: - Data

    var streak: Int
    /// Until when the streak is still alive; afterwards widgets show 0
    var streakExpiresAt: Date?
    var totalMinutes: Int
    var minutesToday: Int
    var activeDaysThisWeek: Int
    var weeklyGoalDays: Int
    var treeStageName: String
    /// Progress to the next tree stage, 0...1
    var treeProgress: Double
    var teachingTitle: String
    var teachingQuote: String
    var generatedAt: Date

    // MARK: - Derived (evaluated by the widget at display time)

    /// The streak as it should be shown at `date`
    func displayedStreak(at date: Date = Date()) -> Int {
        guard let expiry = streakExpiresAt else { return streak }
        return date < expiry ? streak : 0
    }

    /// Minutes today, only if the snapshot was taken today
    func displayedMinutesToday(at date: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.isDate(generatedAt, inSameDayAs: date) ? minutesToday : 0
    }

    /// Whether the stored teaching is today's
    func hasTeachingForToday(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        calendar.isDate(generatedAt, inSameDayAs: date) && !teachingTitle.isEmpty
    }

    var weeklyProgress: Double {
        guard weeklyGoalDays > 0 else { return 0 }
        return min(1, Double(activeDaysThisWeek) / Double(weeklyGoalDays))
    }

    /// Sample content for widget galleries and previews
    static let placeholder = WidgetSnapshot(
        streak: 5,
        streakExpiresAt: nil,
        totalMinutes: 180,
        minutesToday: 10,
        activeDaysThisWeek: 3,
        weeklyGoalDays: 5,
        treeStageName: "Sapling",
        treeProgress: 0.4,
        teachingTitle: "",
        teachingQuote: "",
        generatedAt: Date()
    )

    // MARK: - Storage

    /// Shared defaults, or nil when the App Group is not set up for this build
    /// (checked via the container so an unentitled build never touches it)
    private static var sharedDefaults: UserDefaults? {
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) != nil else {
            return nil
        }
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    /// Write the snapshot; false when the App Group is unavailable
    @discardableResult
    func save() -> Bool {
        guard let defaults = Self.sharedDefaults, let data = try? JSONEncoder().encode(self) else {
            return false
        }
        defaults.set(data, forKey: Self.storageKey)
        return true
    }

    /// Read the last saved snapshot
    static func load() -> WidgetSnapshot? {
        guard let data = sharedDefaults?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
