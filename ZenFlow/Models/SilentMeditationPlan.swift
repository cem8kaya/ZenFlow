//
//  SilentMeditationPlan.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Timeline of a silent (unguided) meditation: an optional short preparation
//  countdown, then the sit itself. Pure value type so it is easy to test.
//

import Foundation

struct SilentMeditationPlan {

    enum Phase: Equatable {
        case preparing
        case meditating
        case finished
    }

    /// Quick-pick durations in minutes
    static let presetMinutes = [5, 10, 15, 20, 30, 45, 60]

    /// Allowed custom durations in minutes
    static let minuteRange = 1...120

    /// Default preparation countdown before the opening gong
    static let defaultPrepSeconds: TimeInterval = 10

    let prepSeconds: TimeInterval
    let durationSeconds: TimeInterval

    init(prepSeconds: TimeInterval, minutes: Int) {
        self.prepSeconds = max(0, prepSeconds)
        let clamped = min(max(minutes, Self.minuteRange.lowerBound), Self.minuteRange.upperBound)
        self.durationSeconds = TimeInterval(clamped * 60)
    }

    var totalSeconds: TimeInterval { prepSeconds + durationSeconds }

    /// Phase `elapsed` seconds after the plan started
    func phase(elapsed: TimeInterval) -> Phase {
        if elapsed >= totalSeconds { return .finished }
        if elapsed >= prepSeconds { return .meditating }
        return .preparing
    }

    /// Seconds left in the preparation countdown
    func remainingPrep(elapsed: TimeInterval) -> TimeInterval {
        max(0, prepSeconds - elapsed)
    }

    /// Seconds left of the sit itself (the full duration while still preparing)
    func remainingMeditation(elapsed: TimeInterval) -> TimeInterval {
        let sitElapsed = max(0, elapsed - prepSeconds)
        return max(0, durationSeconds - sitElapsed)
    }

    /// "mm:ss", or "h:mm:ss" from one hour up
    static func formatted(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
