//
//  BreathingExerciseTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Sanity checks for the breathing exercise catalog.
//

import XCTest
@testable import ZenFlow

final class BreathingExerciseTests: XCTestCase {

    private var exercises: [BreathingExercise] { BreathingExerciseManager.allExercises }

    func testExerciseTypesAreUnique() {
        let types = exercises.map { $0.exerciseType }
        XCTAssertEqual(types.count, Set(types).count)
    }

    func testBoxBreathingStaysFirstAndFree() {
        XCTAssertEqual(exercises.first?.exerciseType, "box")
        XCTAssertEqual(exercises.first?.isPremium, false)
    }

    func testNewExercisesAreRegistered() {
        let types = Set(exercises.map { $0.exerciseType })
        XCTAssertTrue(types.isSuperset(of: ["coherent", "sigh", "triangle"]))
    }

    func testEveryExerciseHasPhasesAndDescriptiveText() {
        for exercise in exercises {
            XCTAssertGreaterThanOrEqual(exercise.phases.count, 2, exercise.exerciseType)
            XCTAssertTrue(exercise.phases.allSatisfy { $0.duration > 0 }, exercise.exerciseType)
            XCTAssertGreaterThan(exercise.totalCycleDuration, 0, exercise.exerciseType)
            XCTAssertGreaterThan(exercise.recommendedDuration, 0, exercise.exerciseType)

            // Falling through to the raw identifier means a missing switch case
            XCTAssertNotEqual(exercise.name, exercise.exerciseType, "Missing name for \(exercise.exerciseType)")
            XCTAssertNotEqual(exercise.description, exercise.exerciseType, "Missing description for \(exercise.exerciseType)")
            XCTAssertEqual(exercise.benefits.count, 4, exercise.exerciseType)
            XCTAssertTrue(exercise.benefits.allSatisfy { !$0.isEmpty }, "Missing benefit for \(exercise.exerciseType)")
        }
    }

    func testPhysiologicalSighCycleLength() {
        let sigh = exercises.first { $0.exerciseType == "sigh" }
        XCTAssertEqual(sigh?.totalCycleDuration, 9)
        XCTAssertEqual(sigh?.phases.map { $0.phase }, [.inhale, .inhale, .exhale])
    }
}
