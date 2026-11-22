//
//  BadgeTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the badge catalog and the migration that merges saved badge
//  state with newly shipped badges.
//

import XCTest
@testable import ZenFlow

final class BadgeTests: XCTestCase {

    func testCatalogHasNoDuplicateRequirements() {
        let keys = Badge.predefinedBadges.map { "\($0.requirementType.rawValue)-\($0.requiredValue)" }
        XCTAssertEqual(keys.count, Set(keys).count, "Badges are matched by (type, value) so it must be unique")
    }

    func testCatalogGrewBeyondOriginalEight() {
        XCTAssertGreaterThanOrEqual(Badge.predefinedBadges.count, 25)
    }

    func testMergeKeepsUnlockStateAndAddsNewBadges() {
        // Simulate a v1.0 install: only the original 8 badges, one unlocked
        let original = Array(Badge.predefinedBadges.prefix(8))
        var saved = original
        let unlockDate = Date(timeIntervalSince1970: 1_700_000_000)
        saved[2] = Badge(
            id: saved[2].id,
            name: "Eski İsim",
            description: "Eski açıklama",
            requirementType: saved[2].requirementType,
            requiredValue: saved[2].requiredValue,
            iconName: saved[2].iconName,
            isUnlocked: true,
            unlockedDate: unlockDate
        )

        let merged = Badge.merge(saved: saved, with: Badge.predefinedBadges)

        XCTAssertEqual(merged.count, Badge.predefinedBadges.count)

        // Unlock state and identity preserved, text refreshed from the catalog
        XCTAssertTrue(merged[2].isUnlocked)
        XCTAssertEqual(merged[2].unlockedDate, unlockDate)
        XCTAssertEqual(merged[2].id, saved[2].id)
        XCTAssertEqual(merged[2].name, Badge.predefinedBadges[2].name)

        // New badges arrive locked
        XCTAssertTrue(merged.dropFirst(8).allSatisfy { !$0.isUnlocked })
    }

    func testMergeWithEmptySavedReturnsCatalog() {
        let merged = Badge.merge(saved: [], with: Badge.predefinedBadges)
        XCTAssertEqual(merged, Badge.predefinedBadges)
    }

    func testCheckRequirement() {
        let badge = Badge(name: "t", description: "d", requirementType: .sessions, requiredValue: 10, iconName: "star")
        XCTAssertFalse(badge.checkRequirement(value: 9))
        XCTAssertTrue(badge.checkRequirement(value: 10))
    }
}
