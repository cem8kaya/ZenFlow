//
//  ZenTheme.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//  Updated by Claude AI on 16.11.2025.
//
//  Theme system including base colors, premium themes, and styling constants.
//  Supports both free and premium theme options with distinct color palettes
//  and gradients for enhanced user experience.
//

import SwiftUI

// MARK: - Theme Type

/// Available theme types in the application
/// Free theme is available to all users, premium themes require subscription
enum ThemeType: String, CaseIterable, Identifiable {
    case free = "free"
    case premium1 = "premium1"
    case premium2 = "premium2"
    case premium3 = "premium3"

    var id: String { rawValue }

    /// Localized display name for the theme
    var displayName: String {
        switch self {
        case .free:
            return "Klasik Zen"
        case .premium1:
            return "Gece Gökyüzü"
        case .premium2:
            return "Kiraz Çiçeği"
        case .premium3:
            return "Altın Gün Batımı"
        }
    }

    /// Description of the theme
    var description: String {
        switch self {
        case .free:
            return "Derin mor ve mavi tonları ile klasik Zen teması"
        case .premium1:
            return "Yıldızlı gece gökyüzünden ilham alan koyu mavi tonlar"
        case .premium2:
            return "Kiraz çiçeklerinden ilham alan pembe ve mor tonlar"
        case .premium3:
            return "Gün batımı renklerinden ilham alan altın ve turuncu tonlar"
        }
    }

    /// Whether this theme requires premium access
    var isPremium: Bool {
        switch self {
        case .free:
            return false
        case .premium1, .premium2, .premium3:
            return true
        }
    }

    /// Returns the PremiumTheme configuration for this theme type
    var theme: PremiumTheme {
        switch self {
        case .free:
            return PremiumTheme.freeTheme
        case .premium1:
            return PremiumTheme.nightSkyTheme
        case .premium2:
            return PremiumTheme.cherryBlossomTheme
        case .premium3:
            return PremiumTheme.goldenSunsetTheme
        }
    }
}

// MARK: - Premium Theme Model

/// Model representing a complete theme with colors and gradients
/// Used for both free and premium theme configurations
struct PremiumTheme {

    // MARK: - Properties

    let primary: Color
    let secondary: Color
    let accent: Color
    let breathingInner: Color
    let breathingOuter: Color
    let textHighlight: Color
    let background: Color

    // MARK: - Computed Gradients

    var breathingInnerGradient: LinearGradient {
        LinearGradient(
            colors: [breathingInner, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var breathingOuterGradient: LinearGradient {
        LinearGradient(
            colors: [secondary.opacity(0.6), breathingOuter.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.3), secondary.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var progressGradient: LinearGradient {
        LinearGradient(
            colors: [accent, secondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Predefined Themes

    /// Classic Zen theme (Free) - Deep indigo and purple tones
    static let freeTheme = PremiumTheme(
        primary: Color(red: 0.18, green: 0.15, blue: 0.35),      // Deep indigo
        secondary: Color(red: 0.45, green: 0.35, blue: 0.65),    // Soft purple
        accent: Color(red: 0.55, green: 0.40, blue: 0.75),       // Mystical violet
        breathingInner: Color(red: 0.35, green: 0.45, blue: 0.85), // Calm blue
        breathingOuter: Color(red: 0.50, green: 0.35, blue: 0.85), // Serene purple
        textHighlight: Color(red: 0.85, green: 0.80, blue: 0.95),  // Light lavender
        background: Color(red: 0.18, green: 0.15, blue: 0.35)    // Deep indigo
    )

    /// Night Sky theme (Premium 1) - Dark blues inspired by starry night
    static let nightSkyTheme = PremiumTheme(
        primary: Color(red: 0.10, green: 0.12, blue: 0.25),      // Midnight blue
        secondary: Color(red: 0.15, green: 0.25, blue: 0.45),    // Deep sky blue
        accent: Color(red: 0.30, green: 0.50, blue: 0.80),       // Bright blue
        breathingInner: Color(red: 0.20, green: 0.35, blue: 0.70), // Ocean blue
        breathingOuter: Color(red: 0.25, green: 0.40, blue: 0.75), // Azure
        textHighlight: Color(red: 0.80, green: 0.90, blue: 1.00),  // Ice blue
        background: Color(red: 0.05, green: 0.08, blue: 0.20)    // Deep night
    )

    /// Cherry Blossom theme (Premium 2) - Pink and purple tones
    static let cherryBlossomTheme = PremiumTheme(
        primary: Color(red: 0.25, green: 0.15, blue: 0.30),      // Deep plum
        secondary: Color(red: 0.55, green: 0.30, blue: 0.50),    // Mauve
        accent: Color(red: 0.85, green: 0.45, blue: 0.70),       // Pink
        breathingInner: Color(red: 0.70, green: 0.35, blue: 0.65), // Rose
        breathingOuter: Color(red: 0.75, green: 0.40, blue: 0.70), // Cherry pink
        textHighlight: Color(red: 1.00, green: 0.85, blue: 0.95),  // Pale pink
        background: Color(red: 0.20, green: 0.12, blue: 0.25)    // Dark plum
    )

    /// Golden Sunset theme (Premium 3) - Warm golden and orange tones
    static let goldenSunsetTheme = PremiumTheme(
        primary: Color(red: 0.30, green: 0.20, blue: 0.15),      // Deep bronze
        secondary: Color(red: 0.60, green: 0.40, blue: 0.25),    // Copper
        accent: Color(red: 0.95, green: 0.70, blue: 0.30),       // Gold
        breathingInner: Color(red: 0.90, green: 0.55, blue: 0.25), // Amber
        breathingOuter: Color(red: 0.95, green: 0.65, blue: 0.35), // Peach
        textHighlight: Color(red: 1.00, green: 0.95, blue: 0.85),  // Cream
        background: Color(red: 0.25, green: 0.15, blue: 0.10)    // Dark brown
    )
}

struct ZenTheme {
    // MARK: - Colors

    /// Deep indigo blue - primary background
    static let deepIndigo = Color(red: 0.18, green: 0.15, blue: 0.35)

    /// Soft purple - secondary accent
    static let softPurple = Color(red: 0.45, green: 0.35, blue: 0.65)

    /// Mystical violet - primary accent
    static let mysticalViolet = Color(red: 0.55, green: 0.40, blue: 0.75)

    /// Calm blue - breathing circle inner
    static let calmBlue = Color(red: 0.35, green: 0.45, blue: 0.85)

    /// Serene purple - breathing circle outer
    static let serenePurple = Color(red: 0.50, green: 0.35, blue: 0.85)

    /// Light lavender - text highlights
    static let lightLavender = Color(red: 0.85, green: 0.80, blue: 0.95)

    // MARK: - Gradients

    /// Primary breathing gradient (inner circle)
    static let breathingInnerGradient = LinearGradient(
        colors: [calmBlue, mysticalViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Secondary breathing gradient (outer circle)
    static let breathingOuterGradient = LinearGradient(
        colors: [softPurple.opacity(0.6), serenePurple.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Background gradient
    static let backgroundGradient = LinearGradient(
        colors: [deepIndigo, Color.black],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Typography (SF Pro Display)

    static let zenLargeTitle: Font = .system(size: 48, weight: .light, design: .default)
    static let zenTitle: Font = .system(size: 34, weight: .regular, design: .default)
    static let zenHeadline: Font = .system(size: 24, weight: .medium, design: .default)
    static let zenSubheadline: Font = .system(size: 18, weight: .regular, design: .default)
    static let zenBody: Font = .system(size: 17, weight: .regular, design: .default)
}
