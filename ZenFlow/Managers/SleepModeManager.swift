//
//  SleepModeManager.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Drives Sleep Mode: plays a chosen ambient sound for a chosen time, fades
//  it out gently at the end, keeps the screen awake while the dimmed sleep
//  screen is showing and lets audio continue if the user locks the phone.
//

import AVFoundation
import Combine
import UIKit

class SleepModeManager: ObservableObject {

    // MARK: - Singleton

    static let shared = SleepModeManager()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let durationMinutes = "sleepModeDurationMinutes"
        static let soundFileName = "sleepModeSoundFileName"
        static let breathingGuide = "sleepModeBreathingGuide"
    }

    // MARK: - Published State

    /// Whether a sleep session is running
    @Published private(set) var isRunning = false
    /// Seconds left in the running session
    @Published private(set) var remainingSeconds: TimeInterval = 0
    /// Set when a session ran to its end (the view says good night)
    @Published private(set) var didFinishNaturally = false
    /// Start of the running session (drives the breathing guide)
    @Published private(set) var startDate: Date?

    // MARK: - Preferences

    @Published var durationMinutes: Int {
        didSet { UserDefaults.standard.set(durationMinutes, forKey: Keys.durationMinutes) }
    }

    /// `fileName` of the chosen ambient sound; empty means silence
    @Published var soundFileName: String {
        didSet { UserDefaults.standard.set(soundFileName, forKey: Keys.soundFileName) }
    }

    @Published var breathingGuideEnabled: Bool {
        didSet { UserDefaults.standard.set(breathingGuideEnabled, forKey: Keys.breathingGuide) }
    }

    // MARK: - Private

    private let soundManager = AmbientSoundManager.shared
    private var plan = SleepTimerPlan(minutes: 30)
    private var timer: Timer?
    private var fadeStarted = false
    /// Meditation sound selection to restore once the sleep session ends
    private var soundsBeforeSleep: [AmbientSound] = []

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        let savedMinutes = defaults.integer(forKey: Keys.durationMinutes)
        self.durationMinutes = SleepTimerPlan.durationOptions.contains(savedMinutes) ? savedMinutes : 30
        self.soundFileName = defaults.string(forKey: Keys.soundFileName) ?? "Rain"
        self.breathingGuideEnabled = defaults.object(forKey: Keys.breathingGuide) as? Bool ?? true
    }

    // MARK: - Selected Sound

    /// The chosen sound, or nil for silence / an unknown file
    var selectedSound: AmbientSound? {
        soundFileName.isEmpty ? nil : AmbientSound.getSound(byFileName: soundFileName)
    }

    // MARK: - Control

    /// Start a sleep session with the current preferences
    func start() {
        guard !isRunning else { return }

        plan = SleepTimerPlan(minutes: durationMinutes)
        fadeStarted = false
        didFinishNaturally = false
        startDate = Date()
        remainingSeconds = plan.totalSeconds
        isRunning = true

        // Keep the dimmed screen on and let sound continue if the phone is locked
        UIApplication.shared.isIdleTimerDisabled = true
        configurePlaybackSession()

        // Sleep sound replaces whatever else was playing; remember the user's
        // meditation sound selection so it is not overwritten
        soundsBeforeSleep = soundManager.activeSounds
        soundManager.stopAllSounds(fadeOutDuration: 0)
        if let sound = selectedSound, soundManager.isEnabled {
            soundManager.playSound(sound, fadeInDuration: 5.0)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }

        print("😴 Sleep mode started: \(durationMinutes) min, sound: \(soundFileName.isEmpty ? "none" : soundFileName)")
    }

    /// End the session early (user tapped stop) with a short fade
    func stop() {
        guard isRunning else { return }
        finish(naturally: false, fadeSeconds: 3.0)
    }

    // MARK: - Timer

    private func tick() {
        guard isRunning, let startDate else { return }

        let elapsed = Date().timeIntervalSince(startDate)
        remainingSeconds = plan.remaining(elapsed: elapsed)

        switch plan.phase(elapsed: elapsed) {
        case .playing:
            break
        case .fadingOut:
            if !fadeStarted {
                fadeStarted = true
                soundManager.stopAllSounds(fadeOutDuration: max(1, remainingSeconds - 1))
            }
        case .finished:
            finish(naturally: true, fadeSeconds: 0)
        }
    }

    private func finish(naturally: Bool, fadeSeconds: TimeInterval) {
        timer?.invalidate()
        timer = nil

        if !fadeStarted {
            soundManager.stopAllSounds(fadeOutDuration: fadeSeconds)
        }
        fadeStarted = false

        // Players are fading out on their own; put the user's selection back
        soundManager.activeSounds = soundsBeforeSleep
        soundsBeforeSleep = []

        UIApplication.shared.isIdleTimerDisabled = false
        restoreAmbientSession()

        isRunning = false
        startDate = nil
        remainingSeconds = 0
        didFinishNaturally = naturally

        print("😴 Sleep mode ended (natural: \(naturally))")
    }

    // MARK: - Audio Session

    /// `.playback` keeps audio going when the screen locks (requires the
    /// "audio" background mode in Info.plist).
    private func configurePlaybackSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("❌ Sleep mode: failed to configure playback session: \(error.localizedDescription)")
        }
    }

    /// Back to the app's normal mixing behaviour
    private func restoreAmbientSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ Sleep mode: failed to restore ambient session: \(error.localizedDescription)")
        }
    }
}
