//
//  CustomBreathingPatternTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the user-designed breathing patterns (pure logic only, so the
//  user's real saved exercises are never touched).
//

import XCTest
@testable import ZenFlow

final class CustomBreathingPatternTests: XCTestCase {

    func testPhasesSkipZeroHolds() {
        let pattern = CustomBreathingPattern(inhale: 4, hold: 0, exhale: 6, holdAfter: 0)
        XCTAssertEqual(pattern.makePhases().map { $0.phase }, [.inhale, .exhale])
        XCTAssertEqual(pattern.makePhases().map { $0.duration }, [4, 6])
    }

    func testAllFourPhasesInOrder() {
        let pattern = CustomBreathingPattern(inhale: 4, hold: 4, exhale: 4, holdAfter: 4)
        XCTAssertEqual(pattern.makePhases().map { $0.phase }, [.inhale, .hold, .exhale, .holdAfterExhale])
    }

    func testRatioCycleAndRate() {
        let pattern = CustomBreathingPattern(inhale: 4, hold: 4, exhale: 6, holdAfter: 0)
        XCTAssertEqual(pattern.ratioText, "4-4-6")
        XCTAssertEqual(pattern.cycleSeconds, 14)
        XCTAssertEqual(pattern.breathsPerMinute, 60.0 / 14.0, accuracy: 0.0001)
    }

    func testDisplayNameFallsBackToTheRatio() {
        XCTAssertEqual(CustomBreathingPattern(name: "  ", inhale: 5, hold: 0, exhale: 5, holdAfter: 0).displayName, "5-5")
        XCTAssertEqual(CustomBreathingPattern(name: " Sabah ", inhale: 5, hold: 0, exhale: 5, holdAfter: 0).displayName, "Sabah")
    }

    func testSanitizedClampsEverything() {
        let wild = CustomBreathingPattern(
            name: String(repeating: "a", count: 100),
            inhale: 0, hold: 99, exhale: -3, holdAfter: 50
        ).sanitized()

        XCTAssertEqual(wild.name.count, CustomBreathingPattern.maxNameLength)
        XCTAssertEqual(wild.inhale, CustomBreathingPattern.inhaleRange.lowerBound)
        XCTAssertEqual(wild.hold, CustomBreathingPattern.holdRange.upperBound)
        XCTAssertEqual(wild.exhale, CustomBreathingPattern.exhaleRange.lowerBound)
        XCTAssertEqual(wild.holdAfter, CustomBreathingPattern.holdAfterRange.upperBound)
    }

    func testExerciseReusesThePatternIdentity() {
        let pattern = CustomBreathingPattern(name: "Akşam", inhale: 4, hold: 7, exhale: 8, holdAfter: 0)
        let exercise = pattern.makeExercise()

        XCTAssertEqual(exercise.id, pattern.id)
        XCTAssertEqual(exercise.exerciseType, pattern.exerciseType)
        XCTAssertTrue(exercise.exerciseType.hasPrefix(CustomBreathingPattern.exerciseTypePrefix))
        XCTAssertTrue(exercise.isCustom)
        XCTAssertTrue(exercise.isPremium)
        XCTAssertEqual(exercise.name, "Akşam")
        XCTAssertEqual(exercise.totalCycleDuration, 19)
    }

    func testCustomExerciseHasNoEmptyBenefitRows() {
        let exercise = CustomBreathingPattern(inhale: 4, hold: 0, exhale: 6, holdAfter: 0).makeExercise()
        XCTAssertTrue(exercise.benefits.isEmpty)
        XCTAssertFalse(exercise.description.isEmpty)
    }

    func testBuiltInExercisesAreNotCustom() {
        XCTAssertTrue(BreathingExerciseManager.allExercises.allSatisfy { !$0.isCustom })
        XCTAssertTrue(BreathingExerciseManager.allExercises.allSatisfy { $0.benefits.count == 4 })
    }

    func testCodableRoundTrip() throws {
        let original = CustomBreathingPattern(name: "Test", inhale: 3, hold: 2, exhale: 7, holdAfter: 1)
        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([CustomBreathingPattern].self, from: data)
        XCTAssertEqual(decoded, [original])
    }
}
