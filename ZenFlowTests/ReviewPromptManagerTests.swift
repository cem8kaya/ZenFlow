//
//  ReviewPromptManagerTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the rule that decides when to ask for an App Store rating.
//

import XCTest
@testable import ZenFlow

final class ReviewPromptManagerTests: XCTestCase {

    private let calendar = Calendar.current
    private let now = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 12))!

    private func shouldPrompt(
        mood: Mood? = .happy,
        sessions: Int = 10,
        streak: Int = 0,
        lastPrompt: Date? = nil,
        lastVersion: String? = nil,
        version: String = "1.1"
    ) -> Bool {
        ReviewPromptManager.shouldPrompt(
            mood: mood,
            totalSessions: sessions,
            currentStreak: streak,
            lastPromptDate: lastPrompt,
            lastPromptVersion: lastVersion,
            currentVersion: version,
            now: now,
            calendar: calendar
        )
    }

    func testPromptsEngagedUserWhoFeelsGood() {
        XCTAssertTrue(shouldPrompt(mood: .happy, sessions: 5))
        XCTAssertTrue(shouldPrompt(mood: .veryHappy, sessions: 5))
    }

    func testNeverPromptsWithoutAGoodMood() {
        XCTAssertFalse(shouldPrompt(mood: nil))
        XCTAssertFalse(shouldPrompt(mood: .neutral))
        XCTAssertFalse(shouldPrompt(mood: .sad))
        XCTAssertFalse(shouldPrompt(mood: .verySad))
    }

    func testNeedsSessionsOrStreak() {
        XCTAssertFalse(shouldPrompt(sessions: 4, streak: 2))
        XCTAssertTrue(shouldPrompt(sessions: 4, streak: 3), "A 3-day streak counts as engagement")
        XCTAssertTrue(shouldPrompt(sessions: 5, streak: 0))
    }

    func testOncePerAppVersion() {
        XCTAssertFalse(shouldPrompt(lastVersion: "1.1", version: "1.1"))
        XCTAssertTrue(shouldPrompt(lastVersion: "1.0", version: "1.1"))
    }

    func testRespectsMinimumDaysBetweenPrompts() {
        let recent = calendar.date(byAdding: .day, value: -(ReviewPromptManager.Policy.minimumDaysBetweenPrompts - 1), to: now)!
        let old = calendar.date(byAdding: .day, value: -ReviewPromptManager.Policy.minimumDaysBetweenPrompts, to: now)!

        XCTAssertFalse(shouldPrompt(lastPrompt: recent, lastVersion: "1.0"))
        XCTAssertTrue(shouldPrompt(lastPrompt: old, lastVersion: "1.0"))
    }
}
