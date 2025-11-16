//
//  BadgeUnlockAnimationView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//
//  Badge unlock animation sequence:
//  1. Scale pulse (1.0 → 1.3 → 1.0)
//  2. Rotation wiggle (-5° → 5° → 0°)
//  3. Confetti particle burst
//  4. Haptic success feedback
//

import SwiftUI
import Combine
import Lottie

/// Confetti particle for badge unlock celebration
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var scale: CGFloat
    var rotation: Double
    var opacity: Double
    var color: Color
}

/// Badge unlock animation overlay
struct BadgeUnlockAnimationView: View {
    let badge: Badge
    let onComplete: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var opacity: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showText: Bool = false
    @State private var viewSize: CGSize = .zero
    @State private var showLottieConfetti: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .opacity(opacity)

                // Lottie Confetti Animation
                if showLottieConfetti {
                    ConfettiLottieView()
                        .allowsHitTesting(false)
                }

                // Legacy Confetti particles (fallback)
                ForEach(confettiParticles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                }

                // Badge icon with animations
                VStack(spacing: 24) {
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.purple.opacity(glowOpacity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        // Badge circle background
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple.opacity(0.8), .blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 150, height: 150)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 3)
                            )
                            .shadow(color: .purple.opacity(0.6), radius: 20, x: 0, y: 10)

                        // Badge icon
                        Image(systemName: badge.iconName)
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))

                    // Badge unlocked text
                    if showText {
                        VStack(spacing: 12) {
                            Text("Rozet Kazanıldı!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text(badge.name)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text(badge.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .opacity(opacity)
            }
            .onAppear {
                viewSize = geometry.size
                startAnimationSequence()
            }
        }
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Step 1: Fade in
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 1.0
        }

        // Step 2: Scale pulse (1.0 → 1.3 → 1.0, 0.6 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Haptic success feedback
            HapticManager.shared.playNotification(type: .success)

            withAnimation(.easeInOut(duration: 0.3)) {
                scale = 1.3
                glowOpacity = 0.8
            }

            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                scale = 1.0
                glowOpacity = 0.4
            }
        }

        // Step 3: Rotation wiggle (-5° → 5° → 0°, 0.4 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.15)) {
                rotation = -5
            }

            withAnimation(.easeInOut(duration: 0.15).delay(0.15)) {
                rotation = 5
            }

            withAnimation(.easeInOut(duration: 0.1).delay(0.3)) {
                rotation = 0
            }
        }

        // Step 4: Show text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showText = true
            }
        }

        // Step 5: Lottie Confetti burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                showLottieConfetti = true
            }
            // Also generate legacy confetti for extra visual impact
            generateConfetti()
        }

        // Step 6: Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
            }
        }
    }

    // MARK: - Confetti Generation

    private func generateConfetti() {
        let centerX = viewSize.width / 2
        let centerY = viewSize.height / 2
        let colors: [Color] = [.purple, .blue, .pink, .cyan, .yellow, .green]

        // Generate 50 confetti particles
        for _ in 0..<50 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 200...400)
            let velocity = CGVector(
                dx: cos(angle) * speed,
                dy: sin(angle) * speed - 100 // Upward bias
            )

            let particle = ConfettiParticle(
                position: CGPoint(x: centerX, y: centerY),
                velocity: velocity,
                scale: Double.random(in: 0.5...1.5),
                rotation: Double.random(in: 0...360),
                opacity: 1.0,
                color: colors.randomElement() ?? .white
            )

            confettiParticles.append(particle)
        }

        // Animate particles outward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 1.5)) {
                for i in 0..<confettiParticles.count {
                    // Apply velocity to position
                    confettiParticles[i].position.x += confettiParticles[i].velocity.dx * 0.01
                    confettiParticles[i].position.y += confettiParticles[i].velocity.dy * 0.01

                    // Apply gravity
                    confettiParticles[i].position.y += 300

                    // Fade out
                    confettiParticles[i].opacity = 0.0

                    // Rotate
                    confettiParticles[i].rotation += 360
                }
            }
        }

        // Clear particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            confettiParticles.removeAll()
        }
    }
}

// MARK: - Animation Sequence Manager

/// Manages and orchestrates complex animation sequences
class AnimationSequenceManager: ObservableObject {
    @Published var showBadgeUnlockAnimation = false
    @Published var currentBadge: Badge?

    /// Trigger badge unlock animation
    func playBadgeUnlockAnimation(for badge: Badge) {
        currentBadge = badge
        showBadgeUnlockAnimation = true
    }

    /// Dismiss badge unlock animation
    func dismissBadgeUnlockAnimation() {
        showBadgeUnlockAnimation = false
        currentBadge = nil
    }
}
