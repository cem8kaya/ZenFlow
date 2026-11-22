//
//  IntentsTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Shortcuts must not become a way around the paywall, and every exercise
//  offered to Siri must exist in the app.
//

import XCTest
@testable import ZenFlow

final class IntentsTests: XCTestCase {

    func testFreeUserGetsBoxBreathingForPremiumExercises() {
        XCTAssertEqual(StartBreathingIntent.allowedExerciseType("478", isPremium: false), "box")
        XCTAssertEqual(StartBreathingIntent.allowedExerciseType("sigh", isPremium: false), "box")
    }

    func testFreeExerciseIsAlwaysAllowed() {
        XCTAssertEqual(StartBreathingIntent.allowedExerciseType("box", isPremium: false), "box")
    }

    func testPremiumUserGetsTheRequestedExercise() {
        XCTAssertEqual(StartBreathingIntent.allowedExerciseType("478", isPremium: true), "478")
        XCTAssertEqual(StartBreathingIntent.allowedExerciseType("coherent", isPremium: true), "coherent")
    }

    func testUnknownExerciseFallsBackToBox() {
        XCTAssertEqual(StartBreathingIntent.allowedExerciseType("nope", isPremium: true), "box")
    }

    func testEveryExerciseOptionMapsToARealExercise() {
        let types = Set(BreathingExerciseManager.allExercises.map { $0.exerciseType })
        for option in [BreathingExerciseOption.box, .calming, .energy, .deep, .fourSevenEight, .coherent, .sigh, .triangle] {
            XCTAssertTrue(types.contains(option.rawValue), "Missing exercise for \(option.rawValue)")
        }
    }
}
