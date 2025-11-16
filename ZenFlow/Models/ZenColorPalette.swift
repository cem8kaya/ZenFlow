//
//  ZenColorPalette.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Color palette system for animated gradients with breathing synchronization.
//  Provides smooth color interpolation and multiple themed color schemes.
//

import SwiftUI

// MARK: - Color Extension for Interpolation

extension Color {
    /// Linear interpolation (lerp) between two colors
    /// - Parameters:
    ///   - to: Target color to interpolate to
    ///   - progress: Interpolation progress (0.0 to 1.0)
    /// - Returns: Interpolated color
    func lerp(to: Color, progress: CGFloat) -> Color {
        // Clamp progress to 0...1 range
        let t = max(0, min(1, progress))

        // Get color components
        guard let fromComponents = UIColor(self).cgColor.components,
              let toComponents = UIColor(to).cgColor.components else {
            return self
        }

        // Ensure we have at least RGB components
        guard fromComponents.count >= 3, toComponents.count >= 3 else {
            return self
        }

        // Interpolate each component
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * t
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * t
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * t

        // Handle alpha channel
        let fromAlpha = fromComponents.count >= 4 ? fromComponents[3] : 1.0
        let toAlpha = toComponents.count >= 4 ? toComponents[3] : 1.0
        let a = fromAlpha + (toAlpha - fromAlpha) * t

        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }

    /// Adjust color saturation
    /// - Parameter amount: Saturation multiplier (1.0 = no change)
    /// - Returns: Color with adjusted saturation
    func adjustSaturation(_ amount: CGFloat) -> Color {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return self
        }

        let r = components[0]
        let g = components[1]
        let b = components[2]

        // Convert to HSB
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min

        guard delta > 0.001 else { return self } // Grayscale, no saturation to adjust

        let brightness = max
        let saturation = delta / max

        var hue: CGFloat = 0
        if r == max {
            hue = (g - b) / delta
        } else if g == max {
            hue = 2 + (b - r) / delta
        } else {
            hue = 4 + (r - g) / delta
        }
        hue *= 60
        if hue < 0 { hue += 360 }
        hue /= 360

        // Adjust saturation
        let newSaturation = Swift.min(1.0, saturation * amount)

        return Color(hue: Double(hue), saturation: Double(newSaturation), brightness: Double(brightness))
    }
}

// MARK: - Zen Color Palette

/// Color palettes for animated breathing backgrounds
/// Each palette contains 3-4 colors for smooth gradient transitions
enum ZenColorPalette: String, CaseIterable, Identifiable {
    case serene
    case forest
    case sunset
    case midnight

    var id: String { rawValue }

    /// Localized display name
    var displayName: String {
        switch self {
        case .serene:
            return "Sakin (Mavi-Mor)"
        case .forest:
            return "Orman (Yeşil-Mavi)"
        case .sunset:
            return "Gün Batımı (Turuncu-Pembe)"
        case .midnight:
            return "Gece Yarısı (Koyu Mavi-Siyah)"
        }
    }

    /// Description of the palette
    var description: String {
        switch self {
        case .serene:
            return "Huzurlu mavi ve mor tonları"
        case .forest:
            return "Dinlendirici yeşil ve mavi tonları"
        case .sunset:
            return "Sıcak turuncu ve pembe tonları"
        case .midnight:
            return "Derin koyu mavi ve siyah tonları"
        }
    }

    /// Color array for gradient (3-4 colors)
    var colors: [Color] {
        switch self {
        case .serene:
            return [
                Color(red: 0.20, green: 0.35, blue: 0.70),  // Deep blue
                Color(red: 0.35, green: 0.45, blue: 0.85),  // Calm blue
                Color(red: 0.50, green: 0.35, blue: 0.85),  // Serene purple
                Color(red: 0.40, green: 0.25, blue: 0.70)   // Deep purple
            ]

        case .forest:
            return [
                Color(red: 0.15, green: 0.45, blue: 0.35),  // Forest green
                Color(red: 0.20, green: 0.55, blue: 0.50),  // Teal
                Color(red: 0.25, green: 0.50, blue: 0.70),  // Ocean blue
                Color(red: 0.18, green: 0.40, blue: 0.55)   // Deep teal
            ]

        case .sunset:
            return [
                Color(red: 0.90, green: 0.50, blue: 0.25),  // Warm orange
                Color(red: 0.95, green: 0.65, blue: 0.35),  // Peach
                Color(red: 0.85, green: 0.45, blue: 0.60),  // Pink
                Color(red: 0.75, green: 0.35, blue: 0.55)   // Deep rose
            ]

        case .midnight:
            return [
                Color(red: 0.05, green: 0.08, blue: 0.20),  // Deep night
                Color(red: 0.10, green: 0.15, blue: 0.30),  // Midnight blue
                Color(red: 0.08, green: 0.12, blue: 0.25),  // Dark blue
                Color(red: 0.02, green: 0.05, blue: 0.15)   // Near black
            ]
        }
    }

    /// Get color at specific index (wraps around)
    func color(at index: Int) -> Color {
        let colors = self.colors
        return colors[index % colors.count]
    }

    /// Get interpolated color between two palette indices
    /// - Parameters:
    ///   - from: Starting color index
    ///   - to: Target color index
    ///   - progress: Interpolation progress (0.0 to 1.0)
    /// - Returns: Interpolated color
    func interpolatedColor(from: Int, to: Int, progress: CGFloat) -> Color {
        let fromColor = color(at: from)
        let toColor = color(at: to)
        return fromColor.lerp(to: toColor, progress: progress)
    }
}
