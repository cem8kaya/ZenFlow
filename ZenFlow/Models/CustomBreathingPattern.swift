//
//  CustomBreathingPattern.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  A user-designed breathing rhythm (inhale / hold / exhale / hold) that is
//  turned into a regular BreathingExercise. Pure and Codable so it is easy to
//  validate, persist and test.
//

import Foundation

struct CustomBreathingPattern: Codable, Identifiable, Equatable {

    // MARK: - Limits (seconds)

    static let inhaleRange = 2...10
    static let holdRange = 0...10
    static let exhaleRange = 2...12
    static let holdAfterRange = 0...10
    static let maxNameLength = 24
    static let maxPatterns = 6

    /// Prefix of the `exerciseType` generated for custom exercises
    static let exerciseTypePrefix = "custom_"

    // MARK: - Data

    var id: UUID
    var name: String
    var inhale: Int
    var hold: Int
    var exhale: Int
    var holdAfter: Int

    init(
        id: UUID = UUID(),
        name: String = "",
        inhale: Int = 4,
        hold: Int = 4,
        exhale: Int = 6,
        holdAfter: Int = 0
    ) {
        self.id = id
        self.name = name
        self.inhale = inhale
        self.hold = hold
        self.exhale = exhale
        self.holdAfter = holdAfter
    }

    // MARK: - Derived

    var exerciseType: String { Self.exerciseTypePrefix + id.uuidString }

    var cycleSeconds: Int { inhale + hold + exhale + holdAfter }

    /// Whole breaths per minute, e.g. 14 s cycle -> 4.3
    var breathsPerMinute: Double {
        guard cycleSeconds > 0 else { return 0 }
        return 60.0 / Double(cycleSeconds)
    }

    /// "4-4-6" style label; skips phases that are not used
    var ratioText: String {
        [inhale, hold, exhale, holdAfter]
            .filter { $0 > 0 }
            .map(String.init)
            .joined(separator: "-")
    }

    /// The name to show: the user's, or a generated one from the ratio
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "\(ratioText)" : trimmed
    }

    // MARK: - Validation

    /// A copy with the name trimmed/limited and every duration clamped to its range
    func sanitized() -> CustomBreathingPattern {
        var copy = self
        copy.name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxNameLength))
        copy.inhale = min(max(inhale, Self.inhaleRange.lowerBound), Self.inhaleRange.upperBound)
        copy.hold = min(max(hold, Self.holdRange.lowerBound), Self.holdRange.upperBound)
        copy.exhale = min(max(exhale, Self.exhaleRange.lowerBound), Self.exhaleRange.upperBound)
        copy.holdAfter = min(max(holdAfter, Self.holdAfterRange.lowerBound), Self.holdAfterRange.upperBound)
        return copy
    }

    // MARK: - Exercise

    /// Phases in order, skipping holds of zero seconds
    func makePhases() -> [BreathingPhaseConfig] {
        var phases: [BreathingPhaseConfig] = [
            BreathingPhaseConfig(phase: .inhale, duration: TimeInterval(inhale), instructionKey: "custom_phase_inhale")
        ]
        if hold > 0 {
            phases.append(BreathingPhaseConfig(phase: .hold, duration: TimeInterval(hold), instructionKey: "custom_phase_hold"))
        }
        phases.append(BreathingPhaseConfig(phase: .exhale, duration: TimeInterval(exhale), instructionKey: "custom_phase_exhale"))
        if holdAfter > 0 {
            phases.append(BreathingPhaseConfig(phase: .holdAfterExhale, duration: TimeInterval(holdAfter), instructionKey: "custom_phase_hold_after"))
        }
        return phases
    }

    /// The playable exercise. The exercise reuses the pattern's id so selection
    /// and favorites stay stable.
    func makeExercise() -> BreathingExercise {
        let pattern = sanitized()
        return BreathingExercise(
            exerciseType: pattern.exerciseType,
            phases: pattern.makePhases(),
            recommendedDuration: 5,
            iconName: "slider.horizontal.3",
            difficulty: .intermediate,
            recommendedTime: .anytime,
            isPremium: true,
            customName: pattern.displayName,
            id: pattern.id
        )
    }
}
