//
//  GardenDecorationTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the garden decoration unlock rules.
//

import XCTest
@testable import ZenFlow

final class GardenDecorationTests: XCTestCase {

    private func stats(sessions: Int = 0, minutes: Int = 0, streak: Int = 0) -> GardenStats {
        GardenStats(totalSessions: sessions, totalMinutes: minutes, longestStreak: streak)
    }

    func testNewUserHasNothingUnlocked() {
        XCTAssertTrue(GardenDecoration.unlocked(in: stats()).isEmpty)
    }

    func testFirstSessionUnlocksStones() {
        XCTAssertEqual(GardenDecoration.unlocked(in: stats(sessions: 1)), [.stones])
    }

    func testThresholds() {
        XCTAssertFalse(GardenDecoration.bamboo.isUnlocked(in: stats(minutes: 119)))
        XCTAssertTrue(GardenDecoration.bamboo.isUnlocked(in: stats(minutes: 120)))

        XCTAssertFalse(GardenDecoration.lantern.isUnlocked(in: stats(streak: 6)))
        XCTAssertTrue(GardenDecoration.lantern.isUnlocked(in: stats(streak: 7)))

        XCTAssertFalse(GardenDecoration.pond.isUnlocked(in: stats(sessions: 24)))
        XCTAssertTrue(GardenDecoration.pond.isUnlocked(in: stats(sessions: 25)))
    }

    func testLongestStreakKeepsTheLanternAfterTheStreakBreaks() {
        // The rule uses the longest streak, so an unlocked lantern never disappears
        XCTAssertTrue(GardenDecoration.lantern.isUnlocked(in: stats(streak: 12)))
    }

    func testEverythingUnlocksForAnExperiencedUser() {
        XCTAssertEqual(
            GardenDecoration.unlocked(in: stats(sessions: 100, minutes: 1000, streak: 30)),
            Set(GardenDecoration.allCases)
        )
    }

    func testProgressIsCappedAndProportional() {
        XCTAssertEqual(GardenDecoration.pond.progress(in: stats(sessions: 5)), 0.2, accuracy: 0.0001)
        XCTAssertEqual(GardenDecoration.pond.progress(in: stats(sessions: 500)), 1.0)
        XCTAssertEqual(GardenDecoration.stones.progress(in: stats()), 0.0)
    }

    func testEveryDecorationHasPresentationText() {
        for decoration in GardenDecoration.allCases {
            XCTAssertFalse(decoration.name.isEmpty)
            XCTAssertFalse(decoration.emoji.isEmpty)
            XCTAssertNotEqual(decoration.name, "garden_deco_\(decoration.rawValue)")
            XCTAssertFalse(decoration.requirementText.isEmpty)
        }
    }
}
