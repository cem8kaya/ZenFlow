//
//  AmbientSound.swift
//  ZenFlow
//
//  Created by Claude AI on 22.11.2025.
//
//  Defines ambient sound types and categories for meditation sessions.
//  Supports background sounds like rain, forest, and ocean waves.
//

import SwiftUI

// MARK: - Ambient Category

/// Categories for ambient sounds
enum AmbientCategory: String, Codable, CaseIterable {
    case nature = "nature"
    case water = "water"
    case atmosphere = "atmosphere"

    /// Localized display name for the category
    var localizedName: String {
        switch self {
        case .nature:
            return String(localized: "category_nature", defaultValue: "Doğa", comment: "Nature sound category")
        case .water:
            return String(localized: "category_water", defaultValue: "Su", comment: "Water sound category")
        case .atmosphere:
            return String(localized: "category_atmosphere", defaultValue: "Atmosfer", comment: "Atmosphere sound category")
        }
    }
    
    // Backward compatibility for rawValue usage in UI if needed
    // Note: UI should prefer using .localizedName
    var rawValueLocalized: String {
        localizedName
    }

    var icon: String {
        switch self {
        case .nature:
            return "leaf.fill"
        case .water:
            return "drop.fill"
        case .atmosphere:
            return "cloud.fill"
        }
    }

    var color: Color {
        switch self {
        case .nature:
            return ZenTheme.sageGreen
        case .water:
            return ZenTheme.calmBlue
        case .atmosphere:
            return ZenTheme.softPurple
        }
    }
}

// MARK: - Ambient Sound

/// A single ambient sound with metadata
struct AmbientSound: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let iconName: String
    let fileName: String
    let category: AmbientCategory
    let description: String

    init(
        name: String,
        iconName: String,
        fileName: String,
        category: AmbientCategory,
        description: String
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.fileName = fileName
        self.category = category
        self.description = description
    }

    // Equatable conformance
    static func == (lhs: AmbientSound, rhs: AmbientSound) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Predefined Ambient Sounds

extension AmbientSound {
    /// All available ambient sounds
    static let allSounds: [AmbientSound] = [
        // MARK: - Water Sounds (5)
        AmbientSound(
            name: String(localized: "sound_rain", defaultValue: "Yağmur", comment: "Rain sound"),
            iconName: "cloud.rain.fill",
            fileName: "Rain",
            category: .water,
            description: String(localized: "sound_rain_desc", defaultValue: "Sakinleştirici yağmur sesi", comment: "Rain sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_ocean", defaultValue: "Okyanus", comment: "Ocean sound"),
            iconName: "water.waves",
            fileName: "ocean",
            category: .water,
            description: String(localized: "sound_ocean_desc", defaultValue: "Dinlendirici dalga sesleri", comment: "Ocean sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_thunderstorm", defaultValue: "Fırtına", comment: "Thunderstorm sound"),
            iconName: "cloud.bolt.rain.fill",
            fileName: "thunderstorm",
            category: .water,
            description: String(localized: "sound_thunderstorm_desc", defaultValue: "Gök gürültülü yağmur", comment: "Thunderstorm sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_river", defaultValue: "Dere", comment: "River sound"),
            iconName: "drop.triangle.fill",
            fileName: "river",
            category: .water,
            description: String(localized: "sound_river_desc", defaultValue: "Akıp giden dere suyu", comment: "River sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_waterfall", defaultValue: "Şelale", comment: "Waterfall sound"),
            iconName: "drop.halffull",
            fileName: "waterfall",
            category: .water,
            description: String(localized: "sound_waterfall_desc", defaultValue: "Güçlü şelale sesi", comment: "Waterfall sound description")
        ),

        // MARK: - Nature Sounds (5)
        AmbientSound(
            name: String(localized: "sound_forest", defaultValue: "Orman", comment: "Forest sound"),
            iconName: "tree.fill",
            fileName: "forest",
            category: .nature,
            description: String(localized: "sound_forest_desc", defaultValue: "Doğanın huzur verici sesleri", comment: "Forest sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_night", defaultValue: "Gece", comment: "Night sound"),
            iconName: "moon.stars.fill",
            fileName: "night",
            category: .nature,
            description: String(localized: "sound_night_desc", defaultValue: "Cırcır böcekleri ve gece sesleri", comment: "Night sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_wind", defaultValue: "Rüzgar", comment: "Wind sound"),
            iconName: "wind",
            fileName: "wind-trees",
            category: .nature,
            description: String(localized: "sound_wind_desc", defaultValue: "Ağaçlarda esen rüzgar", comment: "Wind sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_mountain", defaultValue: "Dağ", comment: "Mountain sound"),
            iconName: "mountain.2.fill",
            fileName: "mountain",
            category: .nature,
            description: String(localized: "sound_mountain_desc", defaultValue: "Dağ esintisi", comment: "Mountain sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_desert", defaultValue: "Çöl", comment: "Desert sound"),
            iconName: "sun.dust.fill",
            fileName: "desert",
            category: .nature,
            description: String(localized: "sound_desert_desc", defaultValue: "Çöl rüzgarı", comment: "Desert sound description")
        ),

        // MARK: - Fire & Warmth (3)
        AmbientSound(
            name: String(localized: "sound_fireplace", defaultValue: "Şömine", comment: "Fireplace sound"),
            iconName: "fireplace.fill",
            fileName: "fireplace",
            category: .atmosphere,
            description: String(localized: "sound_fireplace_desc", defaultValue: "Çatırdayan şömine", comment: "Fireplace sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_fire", defaultValue: "Ateş", comment: "Fire sound"),
            iconName: "flame.fill",
            fileName: "fire",
            category: .atmosphere,
            description: String(localized: "sound_fire_desc", defaultValue: "Yumuşak ateş sesi", comment: "Fire sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_campfire", defaultValue: "Kamp Ateşi", comment: "Campfire sound"),
            iconName: "tent.fill",
            fileName: "campfire",
            category: .atmosphere,
            description: String(localized: "sound_campfire_desc", defaultValue: "Kamp ateşi çatırtısı", comment: "Campfire sound description")
        ),

        // MARK: - Instrumental (2)
        AmbientSound(
            name: String(localized: "sound_singing_bowl", defaultValue: "Tibet Çanı", comment: "Singing bowl sound"),
            iconName: "bell.fill",
            fileName: "singing-bowl",
            category: .atmosphere,
            description: String(localized: "sound_singing_bowl_desc", defaultValue: "Tibet çanak sesi", comment: "Singing bowl sound description")
        ),
        AmbientSound(
            name: String(localized: "sound_wind_chimes", defaultValue: "Rüzgar Çanı", comment: "Wind chimes sound"),
            iconName: "wind.circle.fill",
            fileName: "wind-chimes",
            category: .atmosphere,
            description: String(localized: "sound_wind_chimes_desc", defaultValue: "Rüzgar çanları", comment: "Wind chimes sound description")
        )
    ]

    /// Get sound by filename
    static func getSound(byFileName fileName: String) -> AmbientSound? {
        return allSounds.first { $0.fileName == fileName }
    }

    /// Get sounds by category
    static func getSounds(byCategory category: AmbientCategory) -> [AmbientSound] {
        return allSounds.filter { $0.category == category }
    }

    /// None option (no sound)
    static let none = AmbientSound(
        name: String(localized: "sound_silent", defaultValue: "Sessiz", comment: "Silent sound option"),
        iconName: "speaker.slash.fill",
        fileName: "",
        category: .atmosphere,
        description: String(localized: "sound_silent_desc", defaultValue: "Arka plan sesi yok", comment: "No background sound")
    )
}
