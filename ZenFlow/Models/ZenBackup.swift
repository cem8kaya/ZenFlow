//
//  ZenBackup.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Everything a user would hate to lose when changing phones: sessions,
//  streak, focus history, moods, badges, gratitude notes and customizations,
//  as one versioned JSON document. Purchases are not included (the App Store
//  restores them).
//

import Foundation

struct ZenBackup: Codable {

    /// Bumped when the format changes incompatibly
    static let currentVersion = 1

    var version: Int
    var createdAt: Date
    var appVersion: String

    // Meditation
    var totalMinutes: Int
    var totalSessions: Int
    var lastSessionDate: Date?
    var currentStreak: Int
    var longestStreak: Int
    var sessions: [LocalDataManager.SessionData]
    var frozenDays: [Date]
    var weeklyGoalDays: Int

    // Focus
    var focusSessions: [FocusSessionData]
    var totalFocusSessions: Int
    var focusSettings: FocusSettings

    // Mood, gratitude, badges
    var moods: [MoodEntry]
    var gratitudeEntries: [GratitudeEntry]
    var badges: [Badge]

    // Customizations
    var customBreathingPatterns: [CustomBreathingPattern]

    // MARK: - Summary

    /// What the restore confirmation shows
    struct Summary: Equatable {
        let createdAt: Date
        let sessionCount: Int
        let totalMinutes: Int
        let longestStreak: Int
    }

    var summary: Summary {
        Summary(
            createdAt: createdAt,
            sessionCount: totalSessions,
            totalMinutes: totalMinutes,
            longestStreak: longestStreak
        )
    }

    // MARK: - Coding

    enum BackupError: Error, Equatable {
        /// The file is not a MyZenFlow backup
        case invalidFile
        /// The backup was made by a newer version of the app
        case newerVersion(Int)
        /// The backup contains impossible values
        case corrupted
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func encoded() throws -> Data {
        try Self.makeEncoder().encode(self)
    }

    /// Decode and validate a backup file's contents
    static func decode(from data: Data) throws -> ZenBackup {
        let backup: ZenBackup
        do {
            backup = try makeDecoder().decode(ZenBackup.self, from: data)
        } catch {
            throw BackupError.invalidFile
        }

        guard backup.version <= currentVersion else {
            throw BackupError.newerVersion(backup.version)
        }

        // Reject impossible numbers rather than writing them into the app
        let counters = [
            backup.totalMinutes, backup.totalSessions, backup.currentStreak,
            backup.longestStreak, backup.totalFocusSessions
        ]
        guard counters.allSatisfy({ $0 >= 0 }),
              backup.sessions.allSatisfy({ $0.durationMinutes >= 0 }),
              (1...7).contains(backup.weeklyGoalDays) else {
            throw BackupError.corrupted
        }

        return backup
    }

    /// File name like "MyZenFlow-Backup-2026-03-11.json"
    func suggestedFileName(calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: createdAt)
        return String(
            format: "MyZenFlow-Backup-%04d-%02d-%02d.json",
            parts.year ?? 0, parts.month ?? 0, parts.day ?? 0
        )
    }
}
