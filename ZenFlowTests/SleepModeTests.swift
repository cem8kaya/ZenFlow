//
//  SleepModeTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the sleep timer timeline and the 4-7-8 breathing light.
//

import XCTest
@testable import ZenFlow

final class SleepTimerPlanTests: XCTestCase {

    func testPhasesOverAThirtyMinuteSession() {
        let plan = SleepTimerPlan(minutes: 30) // 1800s, 60s fade

        XCTAssertEqual(plan.phase(elapsed: 0), .playing)
        XCTAssertEqual(plan.phase(elapsed: 1739), .playing)
        XCTAssertEqual(plan.phase(elapsed: 1740), .fadingOut)
        XCTAssertEqual(plan.phase(elapsed: 1799), .fadingOut)
        XCTAssertEqual(plan.phase(elapsed: 1800), .finished)
        XCTAssertEqual(plan.phase(elapsed: 5000), .finished)
    }

    func testFadeStartAndRemaining() {
        let plan = SleepTimerPlan(minutes: 15)
        XCTAssertEqual(plan.totalSeconds, 900)
        XCTAssertEqual(plan.fadeStartSeconds, 840)
        XCTAssertEqual(plan.remaining(elapsed: 100), 800)
        XCTAssertEqual(plan.remaining(elapsed: 2000), 0, "Remaining time never goes negative")
    }

    func testFadeIsCappedAtHalfOfShortSessions() {
        let plan = SleepTimerPlan(totalSeconds: 60, fadeSeconds: 60)
        XCTAssertEqual(plan.effectiveFadeSeconds, 30)
        XCTAssertEqual(plan.fadeStartSeconds, 30)
        XCTAssertEqual(plan.phase(elapsed: 29), .playing)
        XCTAssertEqual(plan.phase(elapsed: 30), .fadingOut)
    }

    func testNegativeInputsAreClamped() {
        let plan = SleepTimerPlan(totalSeconds: -10, fadeSeconds: -5)
        XCTAssertEqual(plan.totalSeconds, 0)
        XCTAssertEqual(plan.fadeSeconds, 0)
        XCTAssertEqual(plan.phase(elapsed: 0), .finished)
    }

    func testDurationOptionsAreSortedAndPositive() {
        let options = SleepTimerPlan.durationOptions
        XCTAssertEqual(options, options.sorted())
        XCTAssertTrue(options.allSatisfy { $0 > 0 })
        XCTAssertTrue(options.contains(30), "30 minutes is the default and must be selectable")
    }
}

final class SleepBreathingGuideTests: XCTestCase {

    func testCycleLengthIs478() {
        XCTAssertEqual(SleepBreathingGuide.cycleSeconds, 19)
    }

    func testScaleAtKeyMoments() {
        // Start of inhale: smallest; end of inhale and through the hold: largest
        XCTAssertEqual(SleepBreathingGuide.scale(at: 0), SleepBreathingGuide.minimumScale, accuracy: 0.0001)
        XCTAssertEqual(SleepBreathingGuide.scale(at: 4), SleepBreathingGuide.maximumScale, accuracy: 0.0001)
        XCTAssertEqual(SleepBreathingGuide.scale(at: 8), SleepBreathingGuide.maximumScale, accuracy: 0.0001)
        XCTAssertEqual(SleepBreathingGuide.scale(at: 10.99), SleepBreathingGuide.maximumScale, accuracy: 0.0001)
        // End of the exhale: back to the smallest, then the cycle repeats
        XCTAssertEqual(SleepBreathingGuide.scale(at: 19), SleepBreathingGuide.minimumScale, accuracy: 0.0001)
        XCTAssertEqual(SleepBreathingGuide.scale(at: 19 + 4), SleepBreathingGuide.maximumScale, accuracy: 0.0001)
    }

    func testScaleRisesDuringInhaleAndFallsDuringExhale() {
        XCTAssertLessThan(SleepBreathingGuide.scale(at: 1), SleepBreathingGuide.scale(at: 3))
        XCTAssertGreaterThan(SleepBreathingGuide.scale(at: 12), SleepBreathingGuide.scale(at: 17))
    }

    func testScaleStaysWithinBounds() {
        for step in stride(from: 0.0, through: 120.0, by: 0.37) {
            let scale = SleepBreathingGuide.scale(at: step)
            XCTAssertGreaterThanOrEqual(scale, SleepBreathingGuide.minimumScale - 0.0001)
            XCTAssertLessThanOrEqual(scale, SleepBreathingGuide.maximumScale + 0.0001)
        }
    }

    func testNegativeTimeDoesNotCrashAndStaysInBounds() {
        let scale = SleepBreathingGuide.scale(at: -5)
        XCTAssertGreaterThanOrEqual(scale, SleepBreathingGuide.minimumScale - 0.0001)
        XCTAssertLessThanOrEqual(scale, SleepBreathingGuide.maximumScale + 0.0001)
    }
}
