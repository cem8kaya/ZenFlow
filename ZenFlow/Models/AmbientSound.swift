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
        AmbientSound(
            name: "Yağmur",
            iconName: "cloud.rain.fill",
            fileName: "Rain",
            category: .water,
            description: "Sakinleştirici yağmur sesi"
        ),
        AmbientSound(
            name: "Orman",
            iconName: "tree.fill",
            fileName: "forest",
            category: .nature,
            description: "Doğanın huzur verici sesleri"
        ),
        AmbientSound(
            name: "Okyanus",
            iconName: "water.waves",
            fileName: "ocean",
            category: .water,
            description: "Dinlendirici dalga sesleri"
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
