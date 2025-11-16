//
//  BreathingView.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import SwiftUI

/// Animation phase enum for breathing cycle
enum AnimationPhase {
    case inhale
    case exhale

    var scale: CGFloat {
        switch self {
        case .inhale:
            return 1.5
        case .exhale:
            return 1.0
        }
    }

    var text: String {
        switch self {
        case .inhale:
            return "Nefes Al"
        case .exhale:
            return "Nefes Ver"
        }
    }
}

struct BreathingView: View {
    @State private var currentPhase: AnimationPhase = .exhale
    @State private var scale: CGFloat = 1.0
    @State private var isAnimating = false
    @State private var isPaused = false
    @State private var animationTimer: Timer?
    @StateObject private var sessionTracker = SessionTracker.shared

    private let animationDuration: Double = 4.0

    var body: some View {
        ZStack {
            // Background gradient
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 80) {
                Spacer()

                // Breathing circles
                ZStack {
                    // Outer circle
                    Circle()
                        .fill(ZenTheme.breathingOuterGradient)
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .blur(radius: 20)

                    // Inner circle
                    Circle()
                        .fill(ZenTheme.breathingInnerGradient)
                        .frame(width: 150, height: 150)
                        .scaleEffect(scale)
                        .blur(radius: 5)
                }

                // Dynamic breathing text
                Text(currentPhase.text)
                    .font(ZenTheme.largeTitle)
                    .foregroundColor(ZenTheme.lightLavender)
                    .transition(.opacity.combined(with: .scale))
                    .id(currentPhase.text) // Force view update on phase change

                Spacer()

                // Control buttons
                HStack(spacing: 40) {
                    // Start/Stop button
                    Button(action: toggleAnimation) {
                        Image(systemName: isAnimating ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(ZenTheme.lightLavender)
                    }

                    // Pause/Resume button
                    if isAnimating {
                        Button(action: togglePause) {
                            Image(systemName: isPaused ? "play.circle" : "pause.circle")
                                .font(.system(size: 50))
                                .foregroundColor(ZenTheme.softPurple)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Animation Control

    private func toggleAnimation() {
        if isAnimating {
            stopAnimation()
        } else {
            startAnimation()
        }
    }

    private func togglePause() {
        isPaused.toggle()
        if isPaused {
            pauseAnimation()
        } else {
            resumeAnimation()
        }
    }

    private func startAnimation() {
        isAnimating = true
        isPaused = false
        scale = 1.0
        currentPhase = .exhale

        // Start meditation session tracking
        sessionTracker.startSession()

        // Start haptic engine
        HapticManager.shared.startEngine()

        performBreathingCycle()
    }

    private func stopAnimation() {
        isAnimating = false
        isPaused = false
        animationTimer?.invalidate()
        animationTimer = nil

        // End meditation session tracking
        sessionTracker.endSession { duration in
            let minutes = Int(duration / 60)
            print("✅ Meditation session completed: \(minutes) minutes")
        }

        // Stop haptic engine
        HapticManager.shared.stopEngine()

        withAnimation(.easeInOut(duration: 1.0)) {
            scale = 1.0
            currentPhase = .exhale
        }
    }

    private func pauseAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil

        // Stop haptic engine when paused
        HapticManager.shared.stopEngine()
    }

    private func resumeAnimation() {
        // Restart haptic engine when resumed
        HapticManager.shared.startEngine()

        performBreathingCycle()
    }

    private func performBreathingCycle() {
        guard isAnimating && !isPaused else { return }

        // Inhale phase - trigger haptic feedback
        currentPhase = .inhale

        // Play haptic pattern at the start of inhale
        HapticManager.shared.playBreathingInhale(duration: animationDuration)

        withAnimation(.easeInOut(duration: animationDuration)) {
            scale = currentPhase.scale
        }

        // Schedule exhale phase
        animationTimer = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: false) { _ in
            guard isAnimating && !isPaused else { return }

            // Exhale phase
            currentPhase = .exhale
            withAnimation(.easeInOut(duration: animationDuration)) {
                scale = currentPhase.scale
            }

            // Schedule next inhale phase
            animationTimer = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: false) { _ in
                performBreathingCycle()
            }
        }
    }
}

#Preview {
    BreathingView()
}
