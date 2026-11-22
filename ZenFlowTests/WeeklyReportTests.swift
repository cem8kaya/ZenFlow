//
//  WeeklyReportTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the weekly summary and deep-link queueing.
//

import XCTest
@testable import ZenFlow

final class WeeklyReportTests: XCTestCase {

    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()

    /// Wednesday 11 March 2026 noon: week is Mon 9 - Sun 15 March
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 12))!
    }

    private func day(_ dayOfMarch: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: dayOfMarch, hour: hour))!
    }

    private func session(_ dayOfMarch: Int, minutes: Int) -> LocalDataManager.SessionData {
        LocalDataManager.SessionData(date: day(dayOfMarch), durationMinutes: minutes)
    }

    private func report(
        sessions: [LocalDataManager.SessionData] = [],
        focus: [FocusSessionData] = [],
        moods: [MoodEntry] = [],
        goal: Int = 5
    ) -> WeeklyReport {
        WeeklyReport.make(
            weekContaining: now,
            sessions: sessions,
            focusSessions: focus,
            moods: moods,
            goalDays: goal,
            calendar: calendar
        )
    }

    func testEmptyWeek() {
        let report = report()
        XCTAssertTrue(report.isEmpty)
        XCTAssertEqual(report.meditationMinutes, 0)
        XCTAssertEqual(report.activeDays, 0)
        XCTAssertNil(report.bestDay)
        XCTAssertNil(report.averageMood)
        XCTAssertNil(report.minutesChangePercent)
        XCTAssertFalse(report.reachedGoal)
    }

    func testWeekBoundariesAreMondayToSunday() {
        let report = report()
        XCTAssertEqual(calendar.component(.weekday, from: report.weekStart), 2)
        XCTAssertTrue(calendar.isDate(report.weekStart, inSameDayAs: day(9)))
        XCTAssertTrue(calendar.isDate(report.weekEnd, inSameDayAs: day(16)))
    }

    func testOnlySessionsInsideTheWeekCount() {
        let sessions = [
            session(8, minutes: 30),   // Sunday before: previous week
            session(9, minutes: 10),   // Monday: in
            session(11, minutes: 5),   // Wednesday: in
            session(15, minutes: 20),  // Sunday: in
            session(16, minutes: 40)   // next Monday: out
        ]
        let report = report(sessions: sessions)

        XCTAssertEqual(report.meditationMinutes, 35)
        XCTAssertEqual(report.meditationSessions, 3)
        XCTAssertEqual(report.previousWeekMinutes, 30)
        XCTAssertEqual(report.activeDays, 3)
    }

    func testBestDayAndTieBreak() {
        let sessions = [
            session(9, minutes: 10),
            session(9, minutes: 10),   // Monday 20 total
            session(12, minutes: 20)   // Thursday 20 total: tie, earlier day wins
        ]
        let report = report(sessions: sessions)
        XCTAssertEqual(report.bestDayMinutes, 20)
        XCTAssertTrue(calendar.isDate(report.bestDay!, inSameDayAs: day(9)))
    }

    func testFocusSessionsCountOnlyCompletedWorkSessions() {
        let focus = [
            FocusSessionData(date: day(10), mode: .work, durationMinutes: 25),
            FocusSessionData(date: day(10), mode: .work, durationMinutes: 10, completed: false),
            FocusSessionData(date: day(10), mode: .shortBreak, durationMinutes: 5),
            FocusSessionData(date: day(12), mode: .work, durationMinutes: 25)
        ]
        let report = report(focus: focus)

        XCTAssertEqual(report.completedFocusSessions, 2)
        XCTAssertEqual(report.focusMinutes, 50)
        XCTAssertEqual(report.activeDays, 2, "Focus-only days are active days")
        XCTAssertFalse(report.isEmpty)
    }

    func testActiveDaysMergeMeditationAndFocusOnTheSameDay() {
        let report = report(
            sessions: [session(10, minutes: 5)],
            focus: [FocusSessionData(date: day(10, hour: 15), mode: .work, durationMinutes: 25)]
        )
        XCTAssertEqual(report.activeDays, 1)
    }

    func testGoalReached() {
        let sessions = [9, 10, 11].map { session($0, minutes: 5) }
        XCTAssertTrue(report(sessions: sessions, goal: 3).reachedGoal)
        XCTAssertFalse(report(sessions: sessions, goal: 4).reachedGoal)
        XCTAssertEqual(report(sessions: sessions, goal: 0).goalDays, 1, "Goal is clamped to at least one day")
    }

    func testChangePercentAgainstPreviousWeek() {
        let up = report(sessions: [session(2, minutes: 20), session(10, minutes: 30)])
        XCTAssertEqual(up.minutesChangePercent, 50)

        let down = report(sessions: [session(2, minutes: 40), session(10, minutes: 10)])
        XCTAssertEqual(down.minutesChangePercent, -75)
    }

    func testAverageMood() {
        let moods = [
            MoodEntry(date: day(10), mood: .veryHappy),
            MoodEntry(date: day(11), mood: .neutral),
            MoodEntry(date: day(3), mood: .verySad) // previous week: ignored
        ]
        let report = report(sessions: [session(10, minutes: 5)], moods: moods)
        XCTAssertEqual(report.moodCheckIns, 2)
        XCTAssertEqual(report.averageMood ?? -1, 4.0, accuracy: 0.0001)
    }
}

final class DeepLinkQueueTests: XCTestCase {

    func testEnqueuedLinkIsHandledAndCleared() {
        // The app root may consume a queued link as soon as it is enqueued
        // (when the UI is ready), so assert on the outcome, not on the timing.
        let expectation = expectation(forNotification: DeepLinkHandler.switchToTabNotification, object: nil) { notification in
            notification.userInfo?["openWeeklyReport"] as? Bool == true
        }

        let handler = DeepLinkHandler.shared
        handler.enqueue("zenflow://report")
        handler.consumePending()
        wait(for: [expectation], timeout: 1)

        XCTAssertNil(handler.pendingURLString)
    }

    func testConsumeWithoutPendingDoesNothing() {
        let handler = DeepLinkHandler.shared
        handler.consumePending() // clear anything left over
        XCTAssertNil(handler.pendingURLString)
        handler.consumePending()
        XCTAssertNil(handler.pendingURLString)
    }

    func testReportLinkDoesNotSwitchTabs() {
        let expectation = expectation(forNotification: DeepLinkHandler.switchToTabNotification, object: nil) { notification in
            notification.userInfo?["tabIndex"] == nil && notification.userInfo?["openWeeklyReport"] as? Bool == true
        }
        DeepLinkHandler.shared.handle("zenflow://report")
        wait(for: [expectation], timeout: 1)
    }

    func testSleepLinkTargetsCoachTabAndFlagsSleepMode() {
        let expectation = expectation(forNotification: DeepLinkHandler.switchToTabNotification, object: nil) { notification in
            notification.userInfo?["tabIndex"] as? Int == 0 && notification.userInfo?["openSleepMode"] as? Bool == true
        }
        DeepLinkHandler.shared.handle("zenflow://sleep")
        wait(for: [expectation], timeout: 1)
    }
}
