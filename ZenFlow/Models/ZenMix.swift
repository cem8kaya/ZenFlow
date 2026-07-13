//
//  ZenMix.swift
//  ZenFlow
//
//  Created by Claude AI on 13.07.2026.
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Curated ambient soundscape presets ("Zen Mixes") that combine
//  two complementary ambient sounds into a one-tap atmosphere.
//  Builds on the existing AmbientSound library and the
//  AmbientSoundManager's two-layer mixing capability.
//

import SwiftUI

// MARK: - Zen Mix

/// A curated combination of ambient sounds that can be applied with a single tap
struct ZenMix: Identifiable, Equatable {
    let id: String // Stable identifier (e.g., "rainy_fireside")
    let name: String
    let iconName: String
    let description: String
    /// File names of the ambient sounds included in this mix (max 2)
    let soundFileNames: [String]
    let accentColor: Color
    let isPremium: Bool

    /// Resolved ambient sounds for this mix
    var sounds: [AmbientSound] {
        soundFileNames.compactMap { AmbientSound.getSound(byFileName: $0) }
    }

    static func == (lhs: ZenMix, rhs: ZenMix) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Predefined Zen Mixes

extension ZenMix {
    /// All curated soundscape presets
    static let allMixes: [ZenMix] = [
        ZenMix(
            id: "rainy_fireside",
            name: String(localized: "mix_rainy_fireside_name", defaultValue: "Yağmurlu Şömine", comment: "Rainy Fireside mix name"),
            iconName: "fireplace.fill",
            description: String(localized: "mix_rainy_fireside_desc", defaultValue: "Yağmur ve çıtırdayan şömine", comment: "Rainy Fireside mix description"),
            soundFileNames: ["Rain", "campfire"],
            accentColor: ZenTheme.sandTan,
            isPremium: false // FREE (Rain is free; campfire layer as free taster)
        ),
        ZenMix(
            id: "forest_stream",
            name: String(localized: "mix_forest_stream_name", defaultValue: "Orman Deresi", comment: "Forest Stream mix name"),
            iconName: "tree.fill",
            description: String(localized: "mix_forest_stream_desc", defaultValue: "Orman sesleri ve akan dere", comment: "Forest Stream mix description"),
            soundFileNames: ["forest", "river"],
            accentColor: ZenTheme.sageGreen,
            isPremium: true
        ),
        ZenMix(
            id: "ocean_breeze",
            name: String(localized: "mix_ocean_breeze_name", defaultValue: "Okyanus Esintisi", comment: "Ocean Breeze mix name"),
            iconName: "water.waves",
            description: String(localized: "mix_ocean_breeze_desc", defaultValue: "Dalgalar ve hafif rüzgar", comment: "Ocean Breeze mix description"),
            soundFileNames: ["ocean", "wind-trees"],
            accentColor: ZenTheme.calmBlue,
            isPremium: true
        ),
        ZenMix(
            id: "starry_night",
            name: String(localized: "mix_starry_night_name", defaultValue: "Yıldızlı Gece", comment: "Starry Night mix name"),
            iconName: "moon.stars.fill",
            description: String(localized: "mix_starry_night_desc", defaultValue: "Gece sesleri ve kamp ateşi", comment: "Starry Night mix description"),
            soundFileNames: ["night", "campfire"],
            accentColor: ZenTheme.softPurple,
            isPremium: true
        ),
        ZenMix(
            id: "mountain_temple",
            name: String(localized: "mix_mountain_temple_name", defaultValue: "Dağ Tapınağı", comment: "Mountain Temple mix name"),
            iconName: "mountain.2.fill",
            description: String(localized: "mix_mountain_temple_desc", defaultValue: "Dağ esintisi ve rüzgar çanları", comment: "Mountain Temple mix description"),
            soundFileNames: ["mountain", "wind-chimes"],
            accentColor: ZenTheme.skyBlue,
            isPremium: true
        ),
        ZenMix(
            id: "storm_shelter",
            name: String(localized: "mix_storm_shelter_name", defaultValue: "Fırtına Sığınağı", comment: "Storm Shelter mix name"),
            iconName: "cloud.bolt.rain.fill",
            description: String(localized: "mix_storm_shelter_desc", defaultValue: "Gök gürültüsü ve sıcak şömine", comment: "Storm Shelter mix description"),
            // Note: uses "campfire" because the "fireplace" catalog entry has no
            // audio asset in Assets.xcassets/Sounds
            soundFileNames: ["thunderstorm", "campfire"],
            accentColor: ZenTheme.mysticalViolet,
            isPremium: true
        )
    ]
}

// MARK: - AmbientSoundManager Integration

extension AmbientSoundManager {
    /// Whether all sounds of the given mix are currently active
    func isMixActive(_ mix: ZenMix) -> Bool {
        let activeFileNames = Set(activeSounds.map { $0.fileName })
        let mixFileNames = Set(mix.soundFileNames)
        return !mixFileNames.isEmpty && mixFileNames == activeFileNames
    }

    /// Apply a curated mix: stops current sounds and plays the mix's sounds
    func playMix(_ mix: ZenMix, fadeInDuration: TimeInterval = 2.0) {
        guard isEnabled else {
            print("⚠️ Sounds are disabled. Enable in settings to play a mix.")
            return
        }

        // Stop currently playing sounds quickly to make room for the mix
        stopAllSounds(fadeOutDuration: 0.5)

        for sound in mix.sounds {
            playSound(sound, fadeInDuration: fadeInDuration)
        }

        print("✅ Playing zen mix: \(mix.name)")
    }

    /// Stop a mix (stops all of its sounds)
    func stopMix(_ mix: ZenMix, fadeOutDuration: TimeInterval = 1.0) {
        for sound in mix.sounds {
            stopSound(sound, fadeOutDuration: fadeOutDuration)
        }
    }
}
