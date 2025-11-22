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
enum ThemeType: String, CaseIterable, Identifiable {
    case free = "free"

    var id: String { rawValue }

    /// Localized display name for the theme
    var displayName: String {
        return "Klasik Zen"
    }

    /// Description of the theme
    var description: String {
        return "Derin mor ve mavi tonları ile klasik Zen teması"
    }

    /// Returns the PremiumTheme configuration for this theme type
    var theme: PremiumTheme {
        return PremiumTheme.freeTheme
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

    /// Classic Zen theme - Deep indigo and purple tones
    static let freeTheme = PremiumTheme(
        primary: Color(red: 0.18, green: 0.15, blue: 0.35),      // Deep indigo
        secondary: Color(red: 0.45, green: 0.35, blue: 0.65),    // Soft purple
        accent: Color(red: 0.55, green: 0.40, blue: 0.75),       // Mystical violet
        breathingInner: Color(red: 0.35, green: 0.45, blue: 0.85), // Calm blue
        breathingOuter: Color(red: 0.50, green: 0.35, blue: 0.85), // Serene purple
        textHighlight: Color(red: 0.85, green: 0.80, blue: 0.95),  // Light lavender
        background: Color(red: 0.18, green: 0.15, blue: 0.35)    // Deep indigo
    )
}

struct ZenTheme {
    // MARK: - Nature Colors (Earth Tones)

    /// Sage green - calming natural green
    static let sageGreen = Color(red: 0.42, green: 0.56, blue: 0.14) // #6B8E23

    /// Earth brown - warm grounding brown
    static let earthBrown = Color(red: 0.55, green: 0.45, blue: 0.33) // #8B7355

    /// Sky blue - very soft, greyish blue
    static let skyBlue = Color(red: 0.53, green: 0.60, blue: 0.65) // #87999A

    /// Soft cream - warm beige
    static let softCream = Color(red: 0.96, green: 0.96, blue: 0.86) // #F5F5DC

    /// Sand tan - zen sand color
    static let sandTan = Color(red: 0.82, green: 0.71, blue: 0.55) // #D2B48C

    /// Deep sage - darker green for contrast
    static let deepSage = Color(red: 0.13, green: 0.55, blue: 0.13) // #228B22

    // MARK: - Legacy Colors (kept for compatibility)

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