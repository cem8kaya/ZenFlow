//
//  MindfulnessBellManager.swift
//  ZenFlow
//
//  Created by Claude AI on 13.07.2026.
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Plays a gentle singing-bowl chime at a configurable interval during
//  meditation and focus sessions — a traditional mindfulness anchor that
//  softly returns wandering attention to the present moment.
//  Uses the existing "singing-bowl" audio asset and pairs each chime
//  with a subtle haptic pulse.
//

import AVFoundation
import Combine
internal import UIKit

/// Available chime intervals for the mindfulness bell
enum BellInterval: Int, CaseIterable, Identifiable {
    case threeMinutes = 3
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15

    var id: Int { rawValue }

    var displayName: String {
        String(localized: "bell_interval_minutes", defaultValue: "\(rawValue) dk", comment: "Bell interval in minutes")
    }
}

/// Manages the periodic mindfulness bell chime during sessions
class MindfulnessBellManager: ObservableObject {
    // MARK: - Singleton

    static let shared = MindfulnessBellManager()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let isEnabled = "mindfulnessBellEnabled"
        static let intervalMinutes = "mindfulnessBellIntervalMinutes"
    }

    // MARK: - Published Properties

    /// Whether the mindfulness bell is enabled
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
            if !isEnabled {
                stopBell()
            }
        }
    }

    /// Minutes between chimes
    @Published var interval: BellInterval {
        didSet {
            UserDefaults.standard.set(interval.rawValue, forKey: Keys.intervalMinutes)
            // Reschedule with the new interval if a session is running
            if bellTimer != nil {
                scheduleTimer()
            }
        }
    }

    /// Whether the bell is currently scheduled (session running)
    @Published private(set) var isRunning: Bool = false

    // MARK: - Private Properties

    private var bellTimer: Timer?
    private var chimePlayer: AVAudioPlayer?
    private var cachedChimeData: Data?
    private let chimeAssetName = "singing-bowl"
    private let chimeVolume: Float = 0.6

    // MARK: - Initialization

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: Keys.isEnabled) as? Bool ?? false

        let savedInterval = UserDefaults.standard.integer(forKey: Keys.intervalMinutes)
        self.interval = BellInterval(rawValue: savedInterval) ?? .fiveMinutes
    }

    // MARK: - Session Lifecycle

    /// Start the bell for a session (called when a meditation/focus session starts)
    func startBell() {
        guard isEnabled else { return }
        scheduleTimer()
        isRunning = true
        print("🔔 Mindfulness bell started (every \(interval.rawValue) min)")
    }

    /// Pause the bell (called when a session is paused)
    func pauseBell() {
        invalidateTimer()
        print("🔔 Mindfulness bell paused")
    }

    /// Resume the bell after a pause (restarts the full interval)
    func resumeBell() {
        guard isEnabled, isRunning else { return }
        scheduleTimer()
        print("🔔 Mindfulness bell resumed")
    }

    /// Stop the bell (called when a session ends or is cancelled)
    func stopBell() {
        invalidateTimer()
        isRunning = false
    }

    // MARK: - Timer Management

    private func scheduleTimer() {
        invalidateTimer()

        let timer = Timer(timeInterval: TimeInterval(interval.rawValue * 60), repeats: true) { [weak self] _ in
            self?.chime()
        }
        // Generous tolerance: the bell is an ambient cue, not a precise alarm
        timer.tolerance = 5.0
        RunLoop.main.add(timer, forMode: .common)
        bellTimer = timer
    }

    private func invalidateTimer() {
        bellTimer?.invalidate()
        bellTimer = nil
    }

    // MARK: - Chime Playback

    /// Play a single soft chime with a subtle haptic pulse
    func chime() {
        playChimeSound()
        HapticManager.shared.playIntervalMilestone()
    }

    private func playChimeSound() {
        // Load and cache the singing bowl audio data
        let audioData: Data
        if let cached = cachedChimeData {
            audioData = cached
        } else {
            guard let dataAsset = NSDataAsset(name: chimeAssetName) else {
                print("❌ Chime asset not found: \(chimeAssetName)")
                return
            }
            audioData = dataAsset.data
            cachedChimeData = audioData
        }

        do {
            let player = try AVAudioPlayer(data: audioData)
            player.numberOfLoops = 0 // Single chime
            player.volume = chimeVolume
            player.prepareToPlay()
            player.play()
            chimePlayer = player // Retain until playback finishes
        } catch {
            print("❌ Failed to play chime: \(error.localizedDescription)")
        }
    }

    // MARK: - Cleanup

    deinit {
        invalidateTimer()
        chimePlayer?.stop()
    }
}
