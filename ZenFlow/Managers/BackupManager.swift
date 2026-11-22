//
//  BackupManager.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Creates and restores ZenBackup files. Restoring replaces the current data
//  (the UI asks for confirmation first). The data layer part takes an injected
//  LocalDataManager so it can be tested without touching real user data.
//

import Foundation

class BackupManager {

    static let shared = BackupManager()

    private init() {}

    /// Largest backup file we accept (the real ones are well under 1 MB)
    static let maximumFileSize = 20 * 1024 * 1024

    // MARK: - Create

    /// Collect the user's data into a backup value
    func makeBackup(
        dataManager: LocalDataManager = .shared,
        badges: [Badge] = GamificationManager.shared.badges,
        gratitudeEntries: [GratitudeEntry] = DailyZenManager.shared.entries,
        customPatterns: [CustomBreathingPattern] = BreathingExerciseManager.shared.customPatterns,
        focusSettings: FocusSettings = FocusSettingsStore.shared.settings,
        now: Date = Date()
    ) -> ZenBackup {
        ZenBackup(
            version: ZenBackup.currentVersion,
            createdAt: now,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            totalMinutes: dataManager.totalMinutes,
            totalSessions: dataManager.totalSessions,
            lastSessionDate: dataManager.lastSessionDate,
            currentStreak: dataManager.currentStreak,
            longestStreak: dataManager.longestStreak,
            sessions: dataManager.sessionHistory,
            frozenDays: dataManager.frozenDays,
            weeklyGoalDays: dataManager.weeklyGoalDays,
            focusSessions: dataManager.focusSessionHistory,
            totalFocusSessions: dataManager.totalFocusSessions,
            focusSettings: focusSettings,
            moods: dataManager.moodHistory,
            gratitudeEntries: gratitudeEntries,
            badges: badges,
            customBreathingPatterns: customPatterns
        )
    }

    /// Write a backup to a temporary file the user can share or save
    func writeBackupFile(_ backup: ZenBackup) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(backup.suggestedFileName())
        try backup.encoded().write(to: url, options: .atomic)
        return url
    }

    // MARK: - Restore

    /// Read and validate a backup file (security-scoped URLs from the file picker are handled)
    func readBackup(from url: URL) throws -> ZenBackup {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attributes?[.size] as? Int, size > Self.maximumFileSize {
            throw ZenBackup.BackupError.invalidFile
        }

        let data = try Data(contentsOf: url)
        return try ZenBackup.decode(from: data)
    }

    /// Replace the meditation, focus and mood data. Pure data layer, testable.
    func restoreCoreData(_ backup: ZenBackup, into dataManager: LocalDataManager) {
        dataManager.totalMinutes = backup.totalMinutes
        dataManager.totalSessions = backup.totalSessions
        dataManager.lastSessionDate = backup.lastSessionDate
        dataManager.sessionHistory = backup.sessions
        dataManager.frozenDays = backup.frozenDays
        dataManager.weeklyGoalDays = backup.weeklyGoalDays

        dataManager.focusSessionHistory = backup.focusSessions
        dataManager.totalFocusSessions = backup.totalFocusSessions
        dataManager.moodHistory = backup.moods

        // The currentStreak setter raises longestStreak when needed, so set the
        // current value first and the stored longest value after.
        dataManager.currentStreak = backup.currentStreak
        dataManager.longestStreak = max(backup.longestStreak, backup.currentStreak)
    }

    /// Restore everything, including badges, notes and customizations
    func restoreAll(_ backup: ZenBackup) {
        restoreCoreData(backup, into: LocalDataManager.shared)

        GamificationManager.shared.restoreBadges(backup.badges)
        DailyZenManager.shared.replaceEntries(backup.gratitudeEntries)
        BreathingExerciseManager.shared.replaceCustomPatterns(backup.customBreathingPatterns)
        FocusSettingsStore.shared.update(backup.focusSettings)

        WidgetSnapshotWriter.shared.refresh()
        print("♻️ Backup restored (\(backup.sessions.count) sessions)")
    }
}
