//
//  DailyZenManager.swift
//  ZenFlow
//
//  Created by Claude AI on 13.07.2026.
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Powers the "Daily Zen Moment" ritual: a deterministic teaching of the
//  day drawn from ZenWisdomLibrary plus a one-line gratitude journal with
//  streak tracking. Entries persist in UserDefaults as JSON.
//

import Foundation
import Combine

// MARK: - Gratitude Entry

/// A single daily gratitude note
struct GratitudeEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let text: String

    init(id: UUID = UUID(), date: Date = Date(), text: String) {
        self.id = id
        self.date = date
        self.text = text
    }
}

// MARK: - Daily Zen Manager

/// Manages the daily zen teaching and the gratitude journal
class DailyZenManager: ObservableObject {
    // MARK: - Singleton

    static let shared = DailyZenManager()

    // MARK: - UserDefaults Keys

    private let entriesKey = "dailyZenGratitudeEntries"
    private let maxStoredEntries = 365

    // MARK: - Published Properties

    @Published private(set) var entries: [GratitudeEntry] = []

    // MARK: - Initialization

    private init() {
        loadEntries()
    }

    // MARK: - Teaching of the Day

    /// Deterministic teaching for today: rotates daily through the wisdom
    /// library so every user sees the same teaching all day long.
    var teachingOfTheDay: ZenTeaching {
        let categories = ZenCategory.allCases
        let daysSinceReference = Int(Calendar.current.startOfDay(for: Date()).timeIntervalSinceReferenceDate / 86400)
        let index = ((daysSinceReference % categories.count) + categories.count) % categories.count
        // ZenWisdomLibrary maps teaching index i to ZenCategory.allCases[i]
        return ZenTeaching(teachingIndex: index, category: categories[index])
    }

    // MARK: - Gratitude Journal

    /// Today's gratitude entry, if one was written
    var todayEntry: GratitudeEntry? {
        entries.first { Calendar.current.isDateInToday($0.date) }
    }

    /// Whether the user has completed today's zen moment
    var hasCheckedInToday: Bool {
        todayEntry != nil
    }

    /// Most recent entries, newest first
    func recentEntries(limit: Int = 7) -> [GratitudeEntry] {
        Array(entries.sorted { $0.date > $1.date }.prefix(limit))
    }

    /// Save (or replace) today's gratitude note
    func saveTodayGratitude(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Replace any existing entry for today
        entries.removeAll { Calendar.current.isDateInToday($0.date) }
        entries.append(GratitudeEntry(text: trimmed))

        persistEntries()
        print("🙏 Gratitude saved. Current streak: \(currentStreak) days")
    }

    // MARK: - Streak

    /// Consecutive days with a gratitude entry, counting back from today
    /// (or from yesterday if today's entry hasn't been written yet)
    var currentStreak: Int {
        let calendar = Calendar.current
        let entryDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        guard !entryDays.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: Date())
        if !entryDays.contains(day) {
            // Today not written yet - streak continues from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while entryDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    // MARK: - Persistence

    private func persistEntries() {
        // Keep storage bounded to about a year of entries
        if entries.count > maxStoredEntries {
            entries = Array(entries.sorted { $0.date > $1.date }.prefix(maxStoredEntries))
        }

        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: entriesKey)
        } catch {
            print("❌ Failed to save gratitude entries: \(error.localizedDescription)")
        }
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: entriesKey) else { return }

        do {
            entries = try JSONDecoder().decode([GratitudeEntry].self, from: data)
        } catch {
            print("❌ Failed to load gratitude entries: \(error.localizedDescription)")
        }
    }
}
