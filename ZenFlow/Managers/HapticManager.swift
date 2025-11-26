//
//  HapticManager.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import CoreHaptics
internal import UIKit
import Combine
import SwiftUI

class HapticManager: ObservableObject {
    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Properties

    @AppStorage("hapticsEnabled") var isEnabled: Bool = true

    private var engine: CHHapticEngine?
    private(set) var isHapticsAvailable = false

    // Reusable haptic generators (cached for performance)
    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private var notificationGenerator: UINotificationFeedbackGenerator?

    // Cached haptic patterns to avoid repeated creation
    private var cachedBreathingPatterns: [Double: CHHapticPattern] = [:]

    // MARK: - Initialization

    private init() {
        prepareHaptics()
    }

    // MARK: - Lifecycle Management

    /// Prepare and configure the haptic engine
    private func prepareHaptics() {
        // Check if device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Device does not support haptics")
            isHapticsAvailable = false
            return
        }

        do {
            // Create and configure the engine
            engine = try CHHapticEngine()
            isHapticsAvailable = true

            // Set up engine stopped handler
            engine?.stoppedHandler = { [weak self] reason in
                print("⚠️ Haptic engine stopped: \(reason.rawValue)")
                self?.handleEngineStoppedError(reason: reason)
            }

            // Set up engine reset handler
            engine?.resetHandler = { [weak self] in
                print("🔄 Haptic engine reset")
                self?.handleEngineResetError()
            }

            print("✅ Haptic engine initialized successfully")
        } catch {
            print("❌ Failed to create haptic engine: \(error.localizedDescription)")
            isHapticsAvailable = false
        }
    }

    /// Start the haptic engine
    func startEngine() {
        guard isHapticsAvailable, let engine = engine else {
            print("⚠️ Cannot start engine - haptics not available")
            return
        }

        do {
            try engine.start()
            print("▶️ Haptic engine started")
        } catch {
            print("❌ Failed to start haptic engine: \(error.localizedDescription)")
        }
    }

    /// Stop the haptic engine
    func stopEngine() {
        guard let engine = engine else { return }

        engine.stop(completionHandler: { error in
            if let error = error {
                print("❌ Failed to stop haptic engine: \(error.localizedDescription)")
            } else {
                print("⏹️ Haptic engine stopped")
            }
        })
    }

    // MARK: - Error Handling

    private func handleEngineStoppedError(reason: CHHapticEngine.StoppedReason) {
        switch reason {
        case .audioSessionInterrupt:
            print("Audio session interrupt - attempting to restart")
            restartEngine()
        case .applicationSuspended:
            print("Application suspended - engine stopped")
        case .idleTimeout:
            print("Engine idle timeout")
        case .systemError:
            print("System error - attempting to restart")
            restartEngine()
        case .notifyWhenFinished:
            print("Engine finished playing pattern")
        case .engineDestroyed:
            print("Engine destroyed")
        case .gameControllerDisconnect:
            print("Game controller disconnected")
        @unknown default:
            print("Unknown stop reason: \(reason.rawValue)")
        }
    }

    private func handleEngineResetError() {
        // Engine has been reset, attempt to restart it
        do {
            try engine?.start()
            print("✅ Haptic engine restarted after reset")
        } catch {
            print("❌ Failed to restart haptic engine after reset: \(error.localizedDescription)")
        }
    }

    private func restartEngine() {
        stopEngine()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startEngine()
        }
    }

    // MARK: - Haptic Pattern Generation

    /// Create a dynamic haptic pattern for the breathing inhale phase
    /// - Parameter duration: Duration of the pattern in seconds (default: 4.0)
    /// - Returns: CHHapticPattern or nil if creation fails
    func createBreathingInhalePattern(duration: Double = 4.0) -> CHHapticPattern? {
        guard isHapticsAvailable else {
            print("⚠️ Haptics not available - cannot create pattern")
            return nil
        }

        // Return cached pattern if available
        if let cachedPattern = cachedBreathingPatterns[duration] {
            return cachedPattern
        }

        do {
            // Create parameter curve for intensity (0.0 → 1.0 over duration)
            let intensityParameter = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.0),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.25, value: 0.4),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.5, value: 0.7),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.75, value: 0.9),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 1.0)
                ],
                relativeTime: 0
            )

            // Create parameter curve for sharpness (constant 0.3 for gentle vibration)
            let sharpnessParameter = CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.3),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.3)
                ],
                relativeTime: 0
            )

            // Create a continuous haptic event
            let continuousEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0,
                duration: duration
            )

            // Create and return the pattern
            let pattern = try CHHapticPattern(
                events: [continuousEvent],
                parameterCurves: [intensityParameter, sharpnessParameter]
            )

            // Cache the pattern for future use
            cachedBreathingPatterns[duration] = pattern

            print("✅ Created breathing inhale haptic pattern (duration: \(duration)s)")
            return pattern

        } catch {
            print("❌ Failed to create haptic pattern: \(error.localizedDescription)")
            return nil
        }
    }

    /// Play a haptic pattern
    /// - Parameter pattern: The CHHapticPattern to play
    func playPattern(_ pattern: CHHapticPattern) {
        guard isHapticsAvailable, let engine = engine else {
            print("⚠️ Cannot play pattern - haptics not available")
            return
        }

        do {
            // Create a player for the pattern
            let player = try engine.makePlayer(with: pattern)

            // Start the player
            try player.start(atTime: CHHapticTimeImmediate)

            print("▶️ Playing haptic pattern")
        } catch {
            print("❌ Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }

    /// Play the breathing inhale haptic pattern
    /// - Parameter duration: Duration of the pattern in seconds (default: 4.0)
    func playBreathingInhale(duration: Double = 4.0) {
        guard isEnabled && isHapticsAvailable else { return }

        guard let pattern = createBreathingInhalePattern(duration: duration) else {
            print("⚠️ Could not create breathing pattern")
            return
        }

        playPattern(pattern)
    }

    // MARK: - Simple Haptic Feedback

    /// Play impact haptic feedback
    /// - Parameter style: The impact style (light, medium, heavy, soft, rigid)
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }

        // Reuse existing generator or create new one
        let generator: UIImpactFeedbackGenerator
        if let existingGenerator = impactGenerators[style] {
            generator = existingGenerator
        } else {
            generator = UIImpactFeedbackGenerator(style: style)
            impactGenerators[style] = generator
        }

        generator.prepare()
        generator.impactOccurred()
        print("▶️ Playing impact haptic: \(style)")
    }

    /// Play notification haptic feedback
    /// - Parameter type: The notification type (success, warning, error)
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }

        // Reuse existing generator or create new one
        if notificationGenerator == nil {
            notificationGenerator = UINotificationFeedbackGenerator()
        }

        notificationGenerator?.prepare()
        notificationGenerator?.notificationOccurred(type)
        print("▶️ Playing notification haptic: \(type)")
    }

    // MARK: - Exhale and Hold Patterns

    /// Create exhale haptic pattern with decreasing intensity
    /// - Parameter duration: Duration of exhale (default: 4.0)
    private func createBreathingExhalePattern(duration: Double = 4.0) -> CHHapticPattern? {
        guard isHapticsAvailable else { return nil }

        // Return cached pattern if available (use negative key for exhale)
        if let cachedPattern = cachedBreathingPatterns[-duration] {
            return cachedPattern
        }

        do {
            // Intensity curve: 1.0 → 0.0 (reverse of inhale)
            let intensityParameter = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1.0),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.25, value: 0.7),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.5, value: 0.4),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.75, value: 0.2),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.0)
                ],
                relativeTime: 0
            )

            let sharpnessParameter = CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.3),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.3)
                ],
                relativeTime: 0
            )

            let continuousEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0,
                duration: duration
            )

            let pattern = try CHHapticPattern(
                events: [continuousEvent],
                parameterCurves: [intensityParameter, sharpnessParameter]
            )

            cachedBreathingPatterns[-duration] = pattern
            print("✅ Created breathing exhale haptic pattern (duration: \(duration)s)")
            return pattern

        } catch {
            print("❌ Failed to create exhale pattern: \(error.localizedDescription)")
            return nil
        }
    }

    /// Play exhale haptic pattern
    func playBreathingExhale(duration: Double = 4.0) {
        guard isEnabled && isHapticsAvailable else { return }

        guard let pattern = createBreathingExhalePattern(duration: duration) else {
            print("⚠️ Could not create exhale pattern")
            return
        }
        playPattern(pattern)
    }

    /// Create hold haptic pattern with gentle pulsing
    /// - Parameter duration: Duration of hold phase
    private func createBreathingHoldPattern(duration: Double) -> CHHapticPattern? {
        guard isHapticsAvailable else { return nil }

        do {
            var events: [CHHapticEvent] = []
            let pulseInterval = 0.8 // Pulse every 0.8 seconds
            let pulseCount = Int(duration / pulseInterval)

            for i in 0..<pulseCount {
                let pulseTime = Double(i) * pulseInterval

                // Each pulse: gentle tap
                let pulseEvent = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: pulseTime
                )
                events.append(pulseEvent)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            print("✅ Created breathing hold haptic pattern (duration: \(duration)s, pulses: \(pulseCount))")
            return pattern

        } catch {
            print("❌ Failed to create hold pattern: \(error.localizedDescription)")
            return nil
        }
    }

    /// Play hold haptic pattern
    func playBreathingHold(duration: Double) {
        guard isEnabled && isHapticsAvailable else { return }

        guard let pattern = createBreathingHoldPattern(duration: duration) else {
            print("⚠️ Could not create hold pattern")
            return
        }
        playPattern(pattern)
    }

    // MARK: - Session Lifecycle Patterns

    /// Play session start haptic (encouraging start)
    func playSessionStart() {
        guard isEnabled else { return }
        playImpact(style: .medium)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.playImpact(style: .light)
        }
    }

    /// Play session complete haptic (celebratory)
    func playSessionComplete() {
        guard isEnabled else { return }

        // Three-stage success pattern
        playImpact(style: .light)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.playImpact(style: .medium)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.playNotification(type: .success)
        }
    }

    /// Play session cancel/interrupt haptic (subtle warning)
    func playSessionCancel() {
        guard isEnabled else { return }
        playNotification(type: .warning)
    }

    /// Play interval milestone haptic (e.g., 5 min, 10 min completed)
    func playIntervalMilestone() {
        guard isEnabled else { return }
        playImpact(style: .medium)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.playImpact(style: .light)
        }
    }
}
