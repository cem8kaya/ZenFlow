//
//  ZenTheme.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import SwiftUI

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

    static let largeTitle: Font = .system(size: 48, weight: .light, design: .default)
    static let title: Font = .system(size: 34, weight: .regular, design: .default)
    static let headline: Font = .system(size: 24, weight: .medium, design: .default)
    static let body: Font = .system(size: 17, weight: .regular, design: .default)
}
