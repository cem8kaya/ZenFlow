//
//  HapticManager.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import CoreHaptics
import UIKit
import Combine

class HapticManager: ObservableObject {
    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Properties

    private var engine: CHHapticEngine?
    private(set) var isHapticsAvailable = false

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
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        print("▶️ Playing impact haptic: \(style)")
    }

    /// Play notification haptic feedback
    /// - Parameter type: The notification type (success, warning, error)
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        print("▶️ Playing notification haptic: \(type)")
    }
}
