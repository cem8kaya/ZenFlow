//
//  WidgetSnapshotTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the data the widgets show: staleness rules and snapshot building.
//

import XCTest
@testable import ZenFlow

final class WidgetSnapshotTests: XCTestCase {

    private let calendar = Calendar.current

    private func date(_ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func snapshot(
        streak: Int = 5,
        expiresAt: Date? = nil,
        minutesToday: Int = 12,
        generatedAt: Date,
        teachingTitle: String = "Title"
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            streak: streak,
            streakExpiresAt: expiresAt,
            totalMinutes: 100,
            minutesToday: minutesToday,
            activeDaysThisWeek: 3,
            weeklyGoalDays: 5,
            treeStageName: "Sprout",
            treeProgress: 0.5,
            teachingTitle: teachingTitle,
            teachingQuote: "Quote",
            generatedAt: generatedAt
        )
    }

    // MARK: - Display rules

    func testStreakShownUntilItExpires() {
        let expiry = date(3, 12, hour: 0)
        let snap = snapshot(expiresAt: expiry, generatedAt: date(3, 10))

        XCTAssertEqual(snap.displayedStreak(at: date(3, 11)), 5)
        XCTAssertEqual(snap.displayedStreak(at: date(3, 12, hour: 1)), 0, "A stale snapshot must not keep a dead streak alive")
    }

    func testStreakWithoutExpiryIsAlwaysShown() {
        XCTAssertEqual(snapshot(generatedAt: date(3, 1)).displayedStreak(at: date(9, 1)), 5)
    }

    func testMinutesTodayResetOnANewDay() {
        let snap = snapshot(generatedAt: date(3, 10))
        XCTAssertEqual(snap.displayedMinutesToday(at: date(3, 10, hour: 22)), 12)
        XCTAssertEqual(snap.displayedMinutesToday(at: date(3, 11, hour: 1)), 0)
    }

    func testTeachingOnlyForTheDayItWasWritten() {
        let snap = snapshot(generatedAt: date(3, 10))
        XCTAssertTrue(snap.hasTeachingForToday(at: date(3, 10)))
        XCTAssertFalse(snap.hasTeachingForToday(at: date(3, 11)))
        XCTAssertFalse(snapshot(generatedAt: date(3, 10), teachingTitle: "").hasTeachingForToday(at: date(3, 10)))
    }

    func testWeeklyProgressIsCapped() {
        var snap = snapshot(generatedAt: date(3, 10))
        XCTAssertEqual(snap.weeklyProgress, 0.6, accuracy: 0.0001)
        snap.activeDaysThisWeek = 9
        XCTAssertEqual(snap.weeklyProgress, 1.0)
        snap.weeklyGoalDays = 0
        XCTAssertEqual(snap.weeklyProgress, 0.0)
    }

    func testCodableRoundTrip() throws {
        let original = snapshot(expiresAt: date(3, 12), generatedAt: date(3, 10))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Building from stored data

    func testMakeSnapshotReflectsStoredProgress() {
        let suite = "zenflow.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let manager = LocalDataManager(defaults: defaults)
        let now = Date()
        manager.saveSession(durationMinutes: 20, date: now)
        manager.saveSession(durationMinutes: 10, date: now)

        let snap = WidgetSnapshotWriter.makeSnapshot(
            dataManager: manager,
            teachingTitle: "Today",
            teachingQuote: "A quote",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snap.totalMinutes, 30)
        XCTAssertEqual(snap.minutesToday, 30)
        XCTAssertEqual(snap.streak, 1)
        XCTAssertEqual(snap.activeDaysThisWeek, 1)
        XCTAssertEqual(snap.weeklyGoalDays, 5)
        XCTAssertEqual(snap.teachingTitle, "Today")
        XCTAssertFalse(snap.treeStageName.isEmpty)
        XCTAssertTrue((0...1).contains(snap.treeProgress))

        // Streak stays alive through tomorrow, then expires
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let dayAfterNext = calendar.date(byAdding: .day, value: 2, to: now)!
        XCTAssertEqual(snap.displayedStreak(at: tomorrow), 1)
        XCTAssertEqual(snap.displayedStreak(at: dayAfterNext), 0)
    }

    func testMakeSnapshotForANewUserIsEmpty() {
        let suite = "zenflow.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let snap = WidgetSnapshotWriter.makeSnapshot(
            dataManager: LocalDataManager(defaults: defaults),
            teachingTitle: "",
            teachingQuote: ""
        )

        XCTAssertEqual(snap.streak, 0)
        XCTAssertEqual(snap.totalMinutes, 0)
        XCTAssertNil(snap.streakExpiresAt)
    }

    func testSaveReturnsFalseWithoutAppGroup() {
        // In an unsigned/unentitled test run the container does not exist; the
        // call must fail quietly instead of crashing or writing elsewhere.
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetSnapshot.appGroupIdentifier) == nil {
            XCTAssertFalse(snapshot(generatedAt: Date()).save())
            XCTAssertNil(WidgetSnapshot.load())
        }
    }
}
