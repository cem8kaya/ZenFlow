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
    case nature = "Doğa"
    case water = "Su"
    case atmosphere = "Atmosfer"

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
            name: "Yağmur",
            iconName: "cloud.rain.fill",
            fileName: "Rain",
            category: .water,
            description: "Sakinleştirici yağmur sesi"
        ),
        AmbientSound(
            name: "Okyanus",
            iconName: "water.waves",
            fileName: "ocean",
            category: .water,
            description: "Dinlendirici dalga sesleri"
        ),
        AmbientSound(
            name: "Fırtına",
            iconName: "cloud.bolt.rain.fill",
            fileName: "thunderstorm",
            category: .water,
            description: "Gök gürültülü yağmur"
        ),
        AmbientSound(
            name: "Dere",
            iconName: "drop.triangle.fill",
            fileName: "river",
            category: .water,
            description: "Akıp giden dere suyu"
        ),
        AmbientSound(
            name: "Şelale",
            iconName: "drop.halffull",
            fileName: "waterfall",
            category: .water,
            description: "Güçlü şelale sesi"
        ),

        // MARK: - Nature Sounds (5)
        AmbientSound(
            name: "Orman",
            iconName: "tree.fill",
            fileName: "forest",
            category: .nature,
            description: "Doğanın huzur verici sesleri"
        ),
        AmbientSound(
            name: "Gece",
            iconName: "moon.stars.fill",
            fileName: "night",
            category: .nature,
            description: "Cırcır böcekleri ve gece sesleri"
        ),
        AmbientSound(
            name: "Rüzgar",
            iconName: "wind",
            fileName: "wind-trees",
            category: .nature,
            description: "Ağaçlarda esen rüzgar"
        ),
        AmbientSound(
            name: "Dağ",
            iconName: "mountain.2.fill",
            fileName: "mountain",
            category: .nature,
            description: "Dağ esintisi"
        ),
        AmbientSound(
            name: "Çöl",
            iconName: "sun.dust.fill",
            fileName: "desert",
            category: .nature,
            description: "Çöl rüzgarı"
        ),

        // MARK: - Fire & Warmth (3)
        AmbientSound(
            name: "Şömine",
            iconName: "fireplace.fill",
            fileName: "fireplace",
            category: .atmosphere,
            description: "Çatırdayan şömine"
        ),
        AmbientSound(
            name: "Ateş",
            iconName: "flame.fill",
            fileName: "fire",
            category: .atmosphere,
            description: "Yumuşak ateş sesi"
        ),
        AmbientSound(
            name: "Kamp Ateşi",
            iconName: "tent.fill",
            fileName: "campfire",
            category: .atmosphere,
            description: "Kamp ateşi çatırtısı"
        ),

        // MARK: - Instrumental (2)
        AmbientSound(
            name: "Tibet Çanı",
            iconName: "bell.fill",
            fileName: "singing-bowl",
            category: .atmosphere,
            description: "Tibet çanak sesi"
        ),
        AmbientSound(
            name: "Rüzgar Çanı",
            iconName: "wind.circle.fill",
            fileName: "wind-chimes",
            category: .atmosphere,
            description: "Rüzgar çanları"
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
        name: "Sessiz",
        iconName: "speaker.slash.fill",
        fileName: "",
        category: .atmosphere,
        description: "Arka plan sesi yok"
    )
}
