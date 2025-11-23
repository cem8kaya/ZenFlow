//
//  AmbientSoundManager.swift
//  ZenFlow
//
//  Created by Claude AI on 22.11.2025.
//
//  Manages ambient background sounds for meditation sessions.
//  Features: looping, volume control, fade in/out, and multi-layer mixing (max 2 sounds).
//

import AVFoundation
import Combine
import UIKit

/// Manager for ambient background sounds
class AmbientSoundManager: NSObject, ObservableObject {
    static let shared = AmbientSoundManager()

    // MARK: - UserDefaults Keys

    private let enabledSoundsKey = "ambientSoundsEnabled"
    private let volumeKey = "ambientSoundsVolume"
    private let isEnabledKey = "ambientSoundsIsEnabled"

    // MARK: - Published Properties

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: isEnabledKey)
            if !isEnabled {
                // Immediately stop all sounds without fade when disabled
                stopAllSoundsImmediately()
            }
        }
    }

    @Published var volume: Float {
        didSet {
            UserDefaults.standard.set(volume, forKey: volumeKey)
            updateVolume()
        }
    }

    @Published var activeSounds: [AmbientSound] = [] {
        didSet {
            saveActiveSounds()
        }
    }

    // MARK: - Private Properties

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var fadeTimers: [String: Timer] = [:]
    private let maxSimultaneousSounds = 2

    // MARK: - Initialization

    private override init() {
        // Load saved preferences
        // Default to true if no value is set (better UX - user expects sound when selected)
        let savedIsEnabled = UserDefaults.standard.object(forKey: isEnabledKey) as? Bool
        self.isEnabled = savedIsEnabled ?? true
        self.volume = UserDefaults.standard.object(forKey: volumeKey) as? Float ?? 0.5

        super.init()

        // Configure audio session
        configureAudioSession()

        // Load saved active sounds
        loadActiveSounds()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use .ambient category to allow background sounds to mix with other audio
            // and continue playing when the app goes to background
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Sound Control

    /// Play a sound with optional fade-in
    func playSound(_ sound: AmbientSound, fadeInDuration: TimeInterval = 2.0) {
        guard !sound.fileName.isEmpty else { return }

        // Respect user's sound preference - don't force enable
        // User must explicitly enable sounds in settings
        guard isEnabled else {
            print("⚠️ Sounds are disabled. Enable in settings to play.")
            return
        }

        // Check if we've reached the maximum number of simultaneous sounds
        if !activeSounds.contains(where: { $0.id == sound.id }) {
            if activeSounds.count >= maxSimultaneousSounds {
                // Remove the first sound to make room
                if let firstSound = activeSounds.first {
                    stopSound(firstSound, fadeOutDuration: 1.0)
                }
            }
            activeSounds.append(sound)
        }

        // Stop if already playing
        if audioPlayers[sound.fileName] != nil {
            stopSound(sound, fadeOutDuration: 0)
        }

        // Load audio file from Assets.xcassets using NSDataAsset
        // Assets are stored in Sounds/{fileName}.dataset format
        // NSDataAsset name should match the .dataset folder name without path
        guard let dataAsset = NSDataAsset(name: sound.fileName) else {
            print("❌ Sound file not found in Assets: \(sound.fileName)")
            return
        }

        do {
            // Create AVAudioPlayer from NSDataAsset's data
            let player = try AVAudioPlayer(data: dataAsset.data)
            player.numberOfLoops = -1 // Infinite loop
            player.volume = 0.0 // Start at zero for fade-in
            player.prepareToPlay()
            player.play()

            audioPlayers[sound.fileName] = player

            // Fade in
            fadeIn(sound: sound, duration: fadeInDuration)

            print("✅ Playing ambient sound: \(sound.name)")
        } catch {
            print("❌ Failed to play sound \(sound.fileName): \(error.localizedDescription)")
        }
    }

    /// Stop a specific sound with optional fade-out
    func stopSound(_ sound: AmbientSound, fadeOutDuration: TimeInterval = 2.0) {
        guard let player = audioPlayers[sound.fileName] else { return }

        // Remove from active sounds
        activeSounds.removeAll { $0.id == sound.id }

        if fadeOutDuration > 0 {
            fadeOut(sound: sound, duration: fadeOutDuration) {
                player.stop()
                self.audioPlayers.removeValue(forKey: sound.fileName)
            }
        } else {
            player.stop()
            audioPlayers.removeValue(forKey: sound.fileName)
        }

        print("⏹ Stopped ambient sound: \(sound.name)")
    }

    /// Stop all sounds with optional fade-out
    func stopAllSounds(fadeOutDuration: TimeInterval = 2.0) {
        let soundsToStop = activeSounds
        for sound in soundsToStop {
            stopSound(sound, fadeOutDuration: fadeOutDuration)
        }
    }

    /// Immediately stop all sounds without fade (used when disabling sounds)
    private func stopAllSoundsImmediately() {
        // Cancel all fade timers first
        for timer in fadeTimers.values {
            timer.invalidate()
        }
        fadeTimers.removeAll()

        // Stop all audio players immediately
        for player in audioPlayers.values {
            player.stop()
        }
        audioPlayers.removeAll()

        // Clear active sounds
        activeSounds.removeAll()

        print("⏹ All ambient sounds stopped immediately")
    }

    /// Toggle a sound on/off
    func toggleSound(_ sound: AmbientSound) {
        if activeSounds.contains(where: { $0.id == sound.id }) {
            stopSound(sound)
        } else {
            playSound(sound)
        }
    }

    /// Check if a sound is currently playing
    func isPlaying(_ sound: AmbientSound) -> Bool {
        return activeSounds.contains(where: { $0.id == sound.id })
    }

    // MARK: - Volume Control

    private func updateVolume() {
        for player in audioPlayers.values {
            player.volume = volume
        }
    }

    // MARK: - Fade Effects

    private func fadeIn(sound: AmbientSound, duration: TimeInterval) {
        guard let player = audioPlayers[sound.fileName] else { return }

        // Cancel any existing fade timer
        fadeTimers[sound.fileName]?.invalidate()

        let steps = 50
        let stepDuration = duration / TimeInterval(steps)
        let volumeIncrement = volume / Float(steps)
        var currentStep = 0

        let timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            currentStep += 1
            player.volume = min(volumeIncrement * Float(currentStep), self.volume)

            if currentStep >= steps {
                timer.invalidate()
                self.fadeTimers.removeValue(forKey: sound.fileName)
            }
        }

        fadeTimers[sound.fileName] = timer
    }

    private func fadeOut(sound: AmbientSound, duration: TimeInterval, completion: @escaping () -> Void) {
        guard let player = audioPlayers[sound.fileName] else {
            completion()
            return
        }

        // Cancel any existing fade timer
        fadeTimers[sound.fileName]?.invalidate()

        let steps = 50
        let stepDuration = duration / TimeInterval(steps)
        let startVolume = player.volume
        let volumeDecrement = startVolume / Float(steps)
        var currentStep = 0

        let timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                completion()
                return
            }

            currentStep += 1
            player.volume = max(startVolume - (volumeDecrement * Float(currentStep)), 0.0)

            if currentStep >= steps {
                timer.invalidate()
                self.fadeTimers.removeValue(forKey: sound.fileName)
                completion()
            }
        }

        fadeTimers[sound.fileName] = timer
    }

    // MARK: - Persistence

    private func saveActiveSounds() {
        let soundFileNames = activeSounds.map { $0.fileName }
        UserDefaults.standard.set(soundFileNames, forKey: enabledSoundsKey)
    }

    private func loadActiveSounds() {
        guard let savedFileNames = UserDefaults.standard.array(forKey: enabledSoundsKey) as? [String] else {
            return
        }

        activeSounds = savedFileNames.compactMap { fileName in
            AmbientSound.getSound(byFileName: fileName)
        }

        // Don't auto-play on app launch - let user start meditation/timer first
        // Sounds will play when user explicitly starts a session
    }

    // MARK: - Session Integration

    /// Start ambient sounds for meditation session
    func startSession() {
        guard isEnabled, !activeSounds.isEmpty else { return }

        for sound in activeSounds {
            playSound(sound, fadeInDuration: 3.0)
        }
    }

    /// Stop ambient sounds for meditation session
    func endSession() {
        stopAllSounds(fadeOutDuration: 3.0)
    }

    // MARK: - Cleanup

    deinit {
        stopAllSounds(fadeOutDuration: 0)
        fadeTimers.values.forEach { $0.invalidate() }
    }
}
