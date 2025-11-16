//
//  ZenCardModifier.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//
//  Custom card modifier with micro-interactions:
//  - Tap scale animation with shadow expansion
//  - Long press gesture support
//  - Haptic feedback
//  - Interactive dismissal gestures (optional)
//

import SwiftUI

/// Card interaction modifier with tap and long press effects
struct ZenCardModifier: ViewModifier {
    @State private var isPressed = false
    @State private var dragOffset: CGSize = .zero

    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?
    var enableSwipeToDismiss: Bool = false
    var dismissThreshold: CGFloat = 100

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: .black.opacity(isPressed ? 0.3 : 0.2),
                radius: isPressed ? 15 : 10,
                x: 0,
                y: isPressed ? 8 : 5
            )
            .offset(enableSwipeToDismiss ? dragOffset : .zero)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6),
                value: isPressed
            )
            .animation(
                .spring(response: 0.4, dampingFraction: 0.7),
                value: dragOffset
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if value.translation == .zero {
                            // Just pressed, not dragging yet
                            isPressed = true
                        } else if enableSwipeToDismiss {
                            // Swiping
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        isPressed = false

                        if enableSwipeToDismiss {
                            // Check if swipe exceeds threshold
                            let horizontalSwipe = abs(value.translation.width)
                            if horizontalSwipe > dismissThreshold {
                                // Swipe to dismiss
                                HapticManager.shared.playImpact(style: .medium)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = CGSize(
                                        width: value.translation.width > 0 ? 500 : -500,
                                        height: value.translation.height
                                    )
                                }
                                // Reset after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dragOffset = .zero
                                }
                            } else {
                                // Return to original position
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = .zero
                                }

                                // If it was a tap (minimal movement)
                                if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                                    HapticManager.shared.playImpact(style: .light)
                                    onTap?()
                                }
                            }
                        } else {
                            // Not swipe-enabled, just handle tap
                            if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                                HapticManager.shared.playImpact(style: .light)
                                onTap?()
                            }
                        }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        HapticManager.shared.playImpact(style: .heavy)
                        onLongPress?()
                    }
            )
    }
}

/// Enhanced card modifier with more pronounced effects
struct ZenCardPressModifier: ViewModifier {
    @State private var isPressed = false

    var onTap: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .shadow(
                color: .purple.opacity(isPressed ? 0.4 : 0.2),
                radius: isPressed ? 20 : 12,
                x: 0,
                y: isPressed ? 10 : 6
            )
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6),
                value: isPressed
            )
            .onTapGesture {
                // Play haptic feedback
                HapticManager.shared.playImpact(style: .medium)
                // Trigger press animation
                isPressed = true
                // Reset press state after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPressed = false
                }
                // Execute tap action
                onTap?()
            }
    }
}

// MARK: - View Extension

extension View {
    /// Apply Zen card interaction modifier
    func zenCardInteraction(
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        enableSwipeToDismiss: Bool = false,
        dismissThreshold: CGFloat = 100
    ) -> some View {
        self.modifier(
            ZenCardModifier(
                onTap: onTap,
                onLongPress: onLongPress,
                enableSwipeToDismiss: enableSwipeToDismiss,
                dismissThreshold: dismissThreshold
            )
        )
    }

    /// Apply enhanced card press effect
    func zenCardPress(onTap: (() -> Void)? = nil) -> some View {
        self.modifier(ZenCardPressModifier(onTap: onTap))
    }
}
