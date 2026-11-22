//
//  SilentMeditationTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the silent meditation timeline and time formatting.
//

import XCTest
@testable import ZenFlow

final class SilentMeditationTests: XCTestCase {

    func testPhasesWithPreparation() {
        let plan = SilentMeditationPlan(prepSeconds: 10, minutes: 5) // 10s + 300s

        XCTAssertEqual(plan.totalSeconds, 310)
        XCTAssertEqual(plan.phase(elapsed: 0), .preparing)
        XCTAssertEqual(plan.phase(elapsed: 9.9), .preparing)
        XCTAssertEqual(plan.phase(elapsed: 10), .meditating)
        XCTAssertEqual(plan.phase(elapsed: 309), .meditating)
        XCTAssertEqual(plan.phase(elapsed: 310), .finished)
    }

    func testNoPreparationStartsMeditatingImmediately() {
        let plan = SilentMeditationPlan(prepSeconds: 0, minutes: 1)
        XCTAssertEqual(plan.phase(elapsed: 0), .meditating)
        XCTAssertEqual(plan.phase(elapsed: 60), .finished)
    }

    func testRemainingTimes() {
        let plan = SilentMeditationPlan(prepSeconds: 10, minutes: 10)

        XCTAssertEqual(plan.remainingPrep(elapsed: 3), 7)
        XCTAssertEqual(plan.remainingPrep(elapsed: 50), 0)

        // Still preparing: the full sit is ahead
        XCTAssertEqual(plan.remainingMeditation(elapsed: 3), 600)
        XCTAssertEqual(plan.remainingMeditation(elapsed: 10), 600)
        XCTAssertEqual(plan.remainingMeditation(elapsed: 70), 540)
        XCTAssertEqual(plan.remainingMeditation(elapsed: 9999), 0)
    }

    func testDurationIsClampedToAllowedRange() {
        XCTAssertEqual(SilentMeditationPlan(prepSeconds: 0, minutes: 0).durationSeconds, 60)
        XCTAssertEqual(SilentMeditationPlan(prepSeconds: 0, minutes: -5).durationSeconds, 60)
        XCTAssertEqual(SilentMeditationPlan(prepSeconds: 0, minutes: 500).durationSeconds, 7200)
        XCTAssertEqual(SilentMeditationPlan(prepSeconds: -3, minutes: 5).prepSeconds, 0)
    }

    func testPresetsAreInsideTheAllowedRange() {
        XCTAssertTrue(SilentMeditationPlan.presetMinutes.allSatisfy { SilentMeditationPlan.minuteRange.contains($0) })
        XCTAssertEqual(SilentMeditationPlan.presetMinutes, SilentMeditationPlan.presetMinutes.sorted())
    }

    func testFormatting() {
        XCTAssertEqual(SilentMeditationPlan.formatted(0), "00:00")
        XCTAssertEqual(SilentMeditationPlan.formatted(5), "00:05")
        XCTAssertEqual(SilentMeditationPlan.formatted(65), "01:05")
        XCTAssertEqual(SilentMeditationPlan.formatted(599.2), "10:00", "Partial seconds round up so the clock never shows 00:00 early")
        XCTAssertEqual(SilentMeditationPlan.formatted(3600), "1:00:00")
        XCTAssertEqual(SilentMeditationPlan.formatted(3725), "1:02:05")
        XCTAssertEqual(SilentMeditationPlan.formatted(-4), "00:00")
    }

    func testSilentMeditationTypeIsNotARealExercise() {
        // It shares the mood-entry field with breathing exercises but must not collide
        XCTAssertFalse(BreathingExerciseManager.allExercises.contains { $0.exerciseType == MoodEntry.silentMeditationType })
    }
}
