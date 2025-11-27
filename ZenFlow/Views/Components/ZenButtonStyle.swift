//
//  ZenButtonStyle.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//
//  Custom button style with micro-interactions:
//  - Press down animation with scale effect
//  - Spring-based release animation
//  - Haptic feedback on tap
//  - Disabled state styling
//

import SwiftUI

/// Professional button style with micro-interactions and haptic feedback
struct ZenButtonStyle: ButtonStyle {
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    var scaleEffect: CGFloat = 0.95
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
                .opacity(isEnabled ? 1.0 : 0.5)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: configuration.isPressed
                )
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed && isEnabled {
                        // Play haptic feedback on press
                        HapticManager.shared.playImpact(style: hapticStyle)
                    }
                }
        } else {
            // Fallback on earlier versions
        };if #available(iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
                .opacity(isEnabled ? 1.0 : 0.5)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: configuration.isPressed
                )
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed && isEnabled {
                        // Play haptic feedback on press
                        HapticManager.shared.playImpact(style: hapticStyle)
                    }
                }
        } else {
            // Fallback on earlier versions
        };if #available(iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
                .opacity(isEnabled ? 1.0 : 0.5)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: configuration.isPressed
                )
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed && isEnabled {
                        // Play haptic feedback on press
                        HapticManager.shared.playImpact(style: hapticStyle)
                    }
                }
        } else {
            // Fallback on earlier versions
        };if #available(iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
                .opacity(isEnabled ? 1.0 : 0.5)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: configuration.isPressed
                )
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed && isEnabled {
                        // Play haptic feedback on press
                        HapticManager.shared.playImpact(style: hapticStyle)
                    }
                }
        } else {
            // Fallback on earlier versions
        }
    }
}

/// Prominent primary button style with larger scale effect
struct ZenPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(isEnabled ? 1.0 : 0.5)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: configuration.isPressed
                )
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed && isEnabled {
                        HapticManager.shared.playImpact(style: .medium)
                    }
                }
        } else {
            // iOS 17 öncesi için fallback
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(isEnabled ? 1.0 : 0.5)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: configuration.isPressed
                )
                .onChange(of: configuration.isPressed) { isPressed in
                    if isPressed && isEnabled {
                        HapticManager.shared.playImpact(style: .medium)
                    }
                }
        }
    }
}

/// Subtle secondary button style with lighter haptic
struct ZenSecondaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .opacity(isEnabled ? 1.0 : 0.6)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: configuration.isPressed
                )
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed && isEnabled {
                        HapticManager.shared.playImpact(style: .light)
                    }
                }
        } else {
            // Fallback on earlier versions
        }
    }
}

/// Icon-only button style with tighter scale
struct ZenIconButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
                .opacity(isEnabled ? 1.0 : 0.5)
                .animation(
                    .spring(response: 0.25, dampingFraction: 0.7),
                    value: configuration.isPressed
                )
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed && isEnabled {
                        HapticManager.shared.playImpact(style: .light)
                    }
                }
        } else {
            // Fallback on earlier versions
        }
    }
}

// MARK: - View Extension for Easy Usage

extension View {
    /// Apply Zen button style with haptic feedback
    func zenButtonStyle(
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        scaleEffect: CGFloat = 0.95,
        isEnabled: Bool = true
    ) -> some View {
        self.buttonStyle(
            ZenButtonStyle(
                hapticStyle: hapticStyle,
                scaleEffect: scaleEffect,
                isEnabled: isEnabled
            )
        )
    }

    /// Apply primary button style
    func zenPrimaryButtonStyle(isEnabled: Bool = true) -> some View {
        self.buttonStyle(ZenPrimaryButtonStyle(isEnabled: isEnabled))
    }

    /// Apply secondary button style
    func zenSecondaryButtonStyle(isEnabled: Bool = true) -> some View {
        self.buttonStyle(ZenSecondaryButtonStyle(isEnabled: isEnabled))
    }

    /// Apply icon button style
    func zenIconButtonStyle(isEnabled: Bool = true) -> some View {
        self.buttonStyle(ZenIconButtonStyle(isEnabled: isEnabled))
    }
}
