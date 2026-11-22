//
//  BackupTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for backup creation, validation and restore. Everything runs against
//  isolated UserDefaults suites, never the user's real data.
//

import XCTest
@testable import ZenFlow

final class BackupTests: XCTestCase {

    private var suites: [String] = []

    override func tearDown() {
        for suite in suites {
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        suites = []
        super.tearDown()
    }

    private func makeManager() -> LocalDataManager {
        let suite = "zenflow.tests.\(UUID().uuidString)"
        suites.append(suite)
        return LocalDataManager(defaults: UserDefaults(suiteName: suite)!)
    }

    private func date(_ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    private func populatedManager() -> LocalDataManager {
        let manager = makeManager()
        manager.isPremiumProvider = { true }
        manager.saveSession(durationMinutes: 10, date: date(3, 2))
        manager.saveSession(durationMinutes: 15, date: date(3, 4)) // freeze covers Mar 3
        manager.saveFocusSession(FocusSessionData(date: date(3, 4), mode: .work, durationMinutes: 25))
        manager.saveMood(.happy, preMood: .sad, exerciseType: "box", durationMinutes: 10, date: date(3, 4))
        manager.weeklyGoalDays = 3
        return manager
    }

    private func backup(from manager: LocalDataManager) -> ZenBackup {
        BackupManager.shared.makeBackup(
            dataManager: manager,
            badges: [],
            gratitudeEntries: [GratitudeEntry(date: date(3, 4), text: "Kahve")],
            customPatterns: [CustomBreathingPattern(name: "Akşam", inhale: 4, hold: 7, exhale: 8, holdAfter: 0)],
            focusSettings: FocusSettings(workMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 30, sessionsBeforeLongBreak: 3),
            now: date(3, 5)
        )
    }

    // MARK: - File format

    func testEncodeDecodeRoundTrip() throws {
        let original = backup(from: populatedManager())
        let decoded = try ZenBackup.decode(from: original.encoded())

        XCTAssertEqual(decoded.version, ZenBackup.currentVersion)
        XCTAssertEqual(decoded.totalMinutes, 25)
        XCTAssertEqual(decoded.totalSessions, 2)
        XCTAssertEqual(decoded.currentStreak, 2)
        XCTAssertEqual(decoded.sessions.count, 2)
        XCTAssertEqual(decoded.frozenDays.count, 1)
        XCTAssertEqual(decoded.focusSessions.count, 1)
        XCTAssertEqual(decoded.moods.first?.preMood, .sad)
        XCTAssertEqual(decoded.moods.first?.exerciseType, "box")
        XCTAssertEqual(decoded.gratitudeEntries.first?.text, "Kahve")
        XCTAssertEqual(decoded.customBreathingPatterns.first?.name, "Akşam")
        XCTAssertEqual(decoded.focusSettings.workMinutes, 50)
        XCTAssertEqual(decoded.weeklyGoalDays, 3)
    }

    func testFileNameUsesTheBackupDate() {
        XCTAssertEqual(backup(from: makeManager()).suggestedFileName(), "MyZenFlow-Backup-2026-03-05.json")
    }

    func testGarbageIsRejected() {
        XCTAssertThrowsError(try ZenBackup.decode(from: Data("not json".utf8))) { error in
            XCTAssertEqual(error as? ZenBackup.BackupError, .invalidFile)
        }
        XCTAssertThrowsError(try ZenBackup.decode(from: Data("{\"hello\":1}".utf8))) { error in
            XCTAssertEqual(error as? ZenBackup.BackupError, .invalidFile)
        }
    }

    func testNewerVersionIsRejected() throws {
        var future = backup(from: makeManager())
        future.version = ZenBackup.currentVersion + 1
        let data = try future.encoded()

        XCTAssertThrowsError(try ZenBackup.decode(from: data)) { error in
            XCTAssertEqual(error as? ZenBackup.BackupError, .newerVersion(ZenBackup.currentVersion + 1))
        }
    }

    func testImpossibleValuesAreRejected() throws {
        var negative = backup(from: makeManager())
        negative.totalMinutes = -5
        XCTAssertThrowsError(try ZenBackup.decode(from: negative.encoded())) { error in
            XCTAssertEqual(error as? ZenBackup.BackupError, .corrupted)
        }

        var badGoal = backup(from: makeManager())
        badGoal.weeklyGoalDays = 12
        XCTAssertThrowsError(try ZenBackup.decode(from: badGoal.encoded())) { error in
            XCTAssertEqual(error as? ZenBackup.BackupError, .corrupted)
        }
    }

    func testSummary() {
        let summary = backup(from: populatedManager()).summary
        XCTAssertEqual(summary.sessionCount, 2)
        XCTAssertEqual(summary.totalMinutes, 25)
        XCTAssertEqual(summary.longestStreak, 2)
    }

    // MARK: - Restore

    func testRestoreRecreatesTheData() throws {
        let source = populatedManager()
        let data = try backup(from: source).encoded()
        let restored = try ZenBackup.decode(from: data)

        let target = makeManager()
        target.saveSession(durationMinutes: 999, date: date(1, 1)) // existing data is replaced
        BackupManager.shared.restoreCoreData(restored, into: target)

        XCTAssertEqual(target.totalMinutes, source.totalMinutes)
        XCTAssertEqual(target.totalSessions, source.totalSessions)
        XCTAssertEqual(target.currentStreak, source.currentStreak)
        XCTAssertEqual(target.longestStreak, source.longestStreak)
        XCTAssertEqual(target.sessionHistory.count, 2)
        XCTAssertEqual(target.frozenDays.count, 1)
        XCTAssertEqual(target.totalFocusSessions, 1)
        XCTAssertEqual(target.focusSessionHistory.count, 1)
        XCTAssertEqual(target.moodHistory.count, 1)
        XCTAssertEqual(target.weeklyGoalDays, 3)
        XCTAssertEqual(
            target.lastSessionDate?.timeIntervalSinceReferenceDate ?? 0,
            source.lastSessionDate?.timeIntervalSinceReferenceDate ?? -1,
            accuracy: 1
        )
    }

    func testRestoreKeepsTheLongestStreakEvenWhenCurrentIsLower() throws {
        var snapshot = backup(from: makeManager())
        snapshot.currentStreak = 2
        snapshot.longestStreak = 30

        let target = makeManager()
        BackupManager.shared.restoreCoreData(snapshot, into: target)

        XCTAssertEqual(target.currentStreak, 2)
        XCTAssertEqual(target.longestStreak, 30)
    }

    func testResetClearsFocusMoodAndFrozenDays() {
        let manager = populatedManager()
        manager.resetAllData()

        XCTAssertEqual(manager.totalMinutes, 0)
        XCTAssertTrue(manager.sessionHistory.isEmpty)
        XCTAssertTrue(manager.frozenDays.isEmpty)
        XCTAssertTrue(manager.focusSessionHistory.isEmpty)
        XCTAssertEqual(manager.totalFocusSessions, 0)
        XCTAssertTrue(manager.moodHistory.isEmpty)
    }
}
