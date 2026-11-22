//
//  SleepTimerPlan.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Pure value types behind Sleep Mode: when the sound starts fading out and
//  the scale of the (optional) 4-7-8 visual breathing guide at a given time.
//  Kept free of UI and audio so they are easy to unit test.
//

import Foundation

/// Timeline of a sleep session: plays, fades out during the last seconds,
/// then finishes.
struct SleepTimerPlan {

    enum Phase: Equatable {
        case playing
        case fadingOut
        case finished
    }

    /// Selectable timer lengths in minutes
    static let durationOptions = [15, 30, 45, 60, 90]

    /// Default length of the final fade-out
    static let defaultFadeSeconds: TimeInterval = 60

    let totalSeconds: TimeInterval
    let fadeSeconds: TimeInterval

    init(totalSeconds: TimeInterval, fadeSeconds: TimeInterval = SleepTimerPlan.defaultFadeSeconds) {
        self.totalSeconds = max(0, totalSeconds)
        self.fadeSeconds = max(0, fadeSeconds)
    }

    init(minutes: Int, fadeSeconds: TimeInterval = SleepTimerPlan.defaultFadeSeconds) {
        self.init(totalSeconds: TimeInterval(minutes * 60), fadeSeconds: fadeSeconds)
    }

    /// The fade never takes more than half of the session so short timers
    /// still get a stretch of full-volume sound.
    var effectiveFadeSeconds: TimeInterval {
        min(fadeSeconds, totalSeconds / 2)
    }

    /// Seconds after the start at which the fade-out begins
    var fadeStartSeconds: TimeInterval {
        totalSeconds - effectiveFadeSeconds
    }

    func phase(elapsed: TimeInterval) -> Phase {
        if elapsed >= totalSeconds { return .finished }
        if elapsed >= fadeStartSeconds { return .fadingOut }
        return .playing
    }

    func remaining(elapsed: TimeInterval) -> TimeInterval {
        max(0, totalSeconds - elapsed)
    }
}

/// Slow 4-7-8 breathing pace shown as a softly pulsing circle (no text,
/// so it stays calm in a dark room).
enum SleepBreathingGuide {
    static let inhaleSeconds: TimeInterval = 4
    static let holdSeconds: TimeInterval = 7
    static let exhaleSeconds: TimeInterval = 8
    static let cycleSeconds: TimeInterval = inhaleSeconds + holdSeconds + exhaleSeconds

    static let minimumScale = 0.55
    static let maximumScale = 1.0

    /// Circle scale (minimumScale...maximumScale) `time` seconds into the session
    static func scale(at time: TimeInterval) -> Double {
        let position = time.truncatingRemainder(dividingBy: cycleSeconds)
        let normalized = position < 0 ? position + cycleSeconds : position

        let progress: Double
        if normalized < inhaleSeconds {
            progress = smoothstep(normalized / inhaleSeconds)
        } else if normalized < inhaleSeconds + holdSeconds {
            progress = 1
        } else {
            let exhaleElapsed = normalized - inhaleSeconds - holdSeconds
            progress = 1 - smoothstep(exhaleElapsed / exhaleSeconds)
        }

        return minimumScale + (maximumScale - minimumScale) * progress
    }

    private static func smoothstep(_ x: Double) -> Double {
        let t = min(max(x, 0), 1)
        return t * t * (3 - 2 * t)
    }
}
