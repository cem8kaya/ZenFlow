//
//  StreakFreezeTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Unit tests for streak-freeze handling and the weekly goal in
//  LocalDataManager. Each test uses an isolated UserDefaults suite and
//  fixed calendar dates so results never depend on today's date.
//

import XCTest
@testable import ZenFlow

final class StreakFreezeTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var manager: LocalDataManager!
    private let calendar = Calendar.current

    override func setUp() {
        super.setUp()
        suiteName = "zenflow.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        manager = LocalDataManager(defaults: defaults)
        manager.isPremiumProvider = { false }
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        manager = nil
        defaults = nil
        super.tearDown()
    }

    /// Noon on the given 2026 date (mid-day avoids DST edges)
    private func date(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    // MARK: - Streak updates

    func testConsecutiveDaysIncreaseStreakWithoutFreeze() {
        manager.saveSession(durationMinutes: 5, date: date(3, 2))
        manager.saveSession(durationMinutes: 5, date: date(3, 3))
        XCTAssertEqual(manager.currentStreak, 2)
        XCTAssertTrue(manager.frozenDays.isEmpty)
    }

    func testSameDaySessionsDoNotChangeStreak() {
        manager.saveSession(durationMinutes: 5, date: date(3, 2))
        manager.saveSession(durationMinutes: 5, date: date(3, 2))
        XCTAssertEqual(manager.currentStreak, 1)
    }

    func testSingleMissedDayIsCoveredByFreeze() {
        manager.saveSession(durationMinutes: 5, date: date(3, 2))
        manager.saveSession(durationMinutes: 5, date: date(3, 4)) // Mar 3 missed

        XCTAssertEqual(manager.currentStreak, 2)
        XCTAssertEqual(manager.frozenDays.count, 1)
        XCTAssertTrue(calendar.isDate(manager.frozenDays[0], inSameDayAs: date(3, 3)))
    }

    func testFreeUserCannotCoverASecondGapInTheSameMonth() {
        manager.saveSession(durationMinutes: 5, date: date(3, 2))
        manager.saveSession(durationMinutes: 5, date: date(3, 4)) // uses the single free freeze
        manager.saveSession(durationMinutes: 5, date: date(3, 6)) // Mar 5 missed, no freeze left

        XCTAssertEqual(manager.currentStreak, 1)
        XCTAssertEqual(manager.frozenDays.count, 1)
    }

    func testMultiDayGapNeedsOneFreezePerDay() {
        manager.saveSession(durationMinutes: 5, date: date(3, 2))
        manager.saveSession(durationMinutes: 5, date: date(3, 5)) // Mar 3 and 4 missed, only 1 freeze

        XCTAssertEqual(manager.currentStreak, 1)
        XCTAssertTrue(manager.frozenDays.isEmpty, "Partial coverage must not consume any freeze")
    }

    func testPremiumGetsThreeFreezesPerMonth() {
        manager.isPremiumProvider = { true }
        manager.saveSession(durationMinutes: 5, date: date(3, 2))
        manager.saveSession(durationMinutes: 5, date: date(3, 4))
        manager.saveSession(durationMinutes: 5, date: date(3, 6))
        manager.saveSession(durationMinutes: 5, date: date(3, 8))
        XCTAssertEqual(manager.currentStreak, 4)
        XCTAssertEqual(manager.frozenDays.count, 3)

        // Fourth gap in the same month is not covered
        manager.saveSession(durationMinutes: 5, date: date(3, 10))
        XCTAssertEqual(manager.currentStreak, 1)
    }

    func testFreezeAllowanceResetsEachMonth() {
        manager.saveSession(durationMinutes: 5, date: date(3, 29))
        manager.saveSession(durationMinutes: 5, date: date(3, 31)) // March freeze used (Mar 30)
        manager.saveSession(durationMinutes: 5, date: date(4, 2))  // April freeze (Apr 1)

        XCTAssertEqual(manager.currentStreak, 3)
        XCTAssertEqual(manager.frozenDays.count, 2)
    }

    func testLongGapBreaksStreak() {
        manager.saveSession(durationMinutes: 5, date: date(3, 2))
        manager.saveSession(durationMinutes: 5, date: date(3, 20))
        XCTAssertEqual(manager.currentStreak, 1)
    }

    // MARK: - Streak recomputation

    func testComputeStreakBridgesFrozenDay() {
        let d0 = calendar.startOfDay(for: date(3, 2))
        let d1 = calendar.startOfDay(for: date(3, 3))
        let d2 = calendar.startOfDay(for: date(3, 4))
        let d3 = calendar.startOfDay(for: date(3, 5))

        let streak = LocalDataManager.computeStreak(
            sessionDays: [d0, d2, d3],
            frozenDays: [d1],
            endingAt: d3,
            calendar: calendar
        )
        // d3 + d2 are consecutive, d1 is frozen, d0 counts again
        XCTAssertEqual(streak, 3)
    }

    func testComputeStreakStopsAtUnfrozenGap() {
        let d0 = calendar.startOfDay(for: date(3, 2))
        let d2 = calendar.startOfDay(for: date(3, 4))
        let d3 = calendar.startOfDay(for: date(3, 5))

        let streak = LocalDataManager.computeStreak(
            sessionDays: [d0, d2, d3],
            frozenDays: [],
            endingAt: d3,
            calendar: calendar
        )
        XCTAssertEqual(streak, 2)
    }

    func testComputeStreakWithoutSessionOnEndDateIsZero() {
        let d0 = calendar.startOfDay(for: date(3, 2))
        let other = calendar.startOfDay(for: date(3, 9))
        XCTAssertEqual(
            LocalDataManager.computeStreak(sessionDays: [d0], frozenDays: [], endingAt: other, calendar: calendar),
            0
        )
    }

    func testMissedDaysBetweenDates() {
        let missed = LocalDataManager.missedDays(
            between: calendar.startOfDay(for: date(3, 2)),
            and: calendar.startOfDay(for: date(3, 5)),
            calendar: calendar
        )
        XCTAssertEqual(missed.count, 2)
        XCTAssertTrue(calendar.isDate(missed[0], inSameDayAs: date(3, 3)))
        XCTAssertTrue(calendar.isDate(missed[1], inSameDayAs: date(3, 4)))

        XCTAssertTrue(LocalDataManager.missedDays(between: date(3, 2), and: date(3, 3), calendar: calendar).isEmpty)
        XCTAssertTrue(LocalDataManager.missedDays(between: date(3, 3), and: date(3, 2), calendar: calendar).isEmpty)
    }

    // MARK: - Weekly goal

    func testWeeklyGoalDefaultsToFiveAndClamps() {
        XCTAssertEqual(manager.weeklyGoalDays, 5)

        manager.weeklyGoalDays = 3
        XCTAssertEqual(manager.weeklyGoalDays, 3)

        manager.weeklyGoalDays = 99
        XCTAssertEqual(manager.weeklyGoalDays, 7)

        manager.weeklyGoalDays = -4
        XCTAssertEqual(manager.weeklyGoalDays, 1)
    }

    func testActiveDaysThisWeekCountsMeditationAndFocusOncePerDay() {
        let today = Date()
        manager.saveSession(durationMinutes: 5, date: today)
        manager.saveSession(durationMinutes: 5, date: today) // same day, counted once
        manager.saveFocusSession(FocusSessionData(date: today, mode: .work, durationMinutes: 25))
        // Interrupted and break sessions never count
        manager.saveFocusSession(FocusSessionData(date: today, mode: .shortBreak, durationMinutes: 5))

        XCTAssertEqual(manager.activeDaysThisWeek, 1)
        XCTAssertEqual(manager.weeklyGoalProgress, 1.0 / Double(manager.weeklyGoalDays), accuracy: 0.0001)
    }
}
