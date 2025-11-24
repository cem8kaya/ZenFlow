//
//  OnboardingCompletionView.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//
//  Celebration view shown after completing onboarding with confetti
//  animation and call-to-action for starting first meditation.
//

import SwiftUI

// MARK: - Confetti Particle

struct OnboardingConfetti: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
}

// MARK: - Onboarding Completion View

/// Celebration view shown after completing onboarding
struct OnboardingCompletionView: View {
    @Binding var isPresented: Bool
    let onStartFirstSession: () -> Void

    @State private var confettiParticles: [OnboardingConfetti] = []
    @State private var isAnimating = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Background gradient
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            // Confetti particles
            ForEach(confettiParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .rotationEffect(.degrees(particle.rotation))
            }

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Success icon with animation
                ZStack {
                    // Pulsing background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ZenTheme.sageGreen.opacity(0.4),
                                    ZenTheme.sageGreen.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.8 : 1.0)

                    // Checkmark circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ZenTheme.sageGreen, ZenTheme.calmBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showContent ? 1.0 : 0.3)
                    .rotationEffect(.degrees(showContent ? 0 : -180))
                }
                .opacity(showContent ? 1.0 : 0.0)

                // Title
                VStack(spacing: 12) {
                    Text("Harika!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(ZenTheme.lightLavender)

                    Text("ZenFlow yolculuğuna başlamaya hazırsın")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ZenTheme.softPurple.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                // Call to action buttons
                VStack(spacing: 16) {
                    // Start first session
                    Button(action: {
                        HapticManager.shared.playImpact(style: .medium)
                        isPresented = false
                        // Trigger first breathing tutorial
                        TutorialManager.shared.showTutorial(.firstBreathing)
                        onStartFirstSession()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("İlk Meditasyonuna Başla")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            ZenTheme.calmBlue,
                                            ZenTheme.mysticalViolet
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(
                            color: ZenTheme.calmBlue.opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }

                    // Explore app
                    Button(action: {
                        HapticManager.shared.playImpact(style: .light)
                        isPresented = false
                    }) {
                        Text("Uygulamayı Keşfet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ZenTheme.softPurple)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            createConfetti()
            animateContent()
        }
    }

    // MARK: - Private Methods

    private func createConfetti() {
        let colors = [
            ZenTheme.mysticalViolet,
            ZenTheme.calmBlue,
            ZenTheme.sageGreen,
            ZenTheme.softPurple,
            ZenTheme.serenePurple,
            ZenTheme.lightLavender
        ]

        // Create initial confetti particles
        for _ in 0..<50 {
            let particle = OnboardingConfetti(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: -200...(-50)),
                color: colors.randomElement() ?? ZenTheme.mysticalViolet,
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360)
            )
            confettiParticles.append(particle)
        }

        // Animate confetti falling
        animateConfetti()
    }

    private func animateConfetti() {
        withAnimation(.easeIn(duration: 3.0)) {
            confettiParticles = confettiParticles.map { particle in
                OnboardingConfetti(
                    x: particle.x + CGFloat.random(in: -50...50),
                    y: UIScreen.main.bounds.height + 100,
                    color: particle.color,
                    size: particle.size,
                    rotation: particle.rotation + Double.random(in: 360...720)
                )
            }
        }

        // Clear confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            confettiParticles.removeAll()
        }
    }

    private func animateContent() {
        // Pulsing animation
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
        }

        // Show content with delay
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showContent = true
        }

        // Success haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticManager.shared.playNotification(type: .success)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingCompletionView(
        isPresented: .constant(true),
        onStartFirstSession: {}
    )
}
