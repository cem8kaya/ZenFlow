//
//  BreathingView.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//  Updated by Claude AI on 16.11.2025.
//
//  Main meditation view featuring a guided breathing exercise with
//  animated visual feedback, haptic patterns, and session tracking.
//  Integrates with HealthKit and local data persistence.
//

import SwiftUI

/// Animation phase for the breathing cycle
enum AnimationPhase {
    case inhale
    case exhale

    /// Scale factor for the breathing circles
    var scale: CGFloat {
        switch self {
        case .inhale:
            return AppConstants.Breathing.inhaleScale
        case .exhale:
            return AppConstants.Breathing.exhaleScale
        }
    }

    /// Display text for current breathing phase
    var text: String {
        switch self {
        case .inhale:
            return "Nefes Al"
        case .exhale:
            return "Nefes Ver"
        }
    }

    /// Accessibility announcement for VoiceOver
    var accessibilityAnnouncement: String {
        switch self {
        case .inhale:
            return "Nefes alın"
        case .exhale:
            return "Nefes verin"
        }
    }
}

/// Main breathing meditation view with animated guidance
struct BreathingView: View {

    // MARK: - State

    @State private var currentPhase: AnimationPhase = .exhale
    @State private var scale: CGFloat = AppConstants.Breathing.exhaleScale
    @State private var isAnimating = false
    @State private var isPaused = false
    @State private var animationTimer: Timer?
    @StateObject private var sessionTracker = SessionTracker.shared
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var featureFlag = FeatureFlag.shared

    // MARK: - Constants

    private let animationDuration: Double = AppConstants.Animation.breathingCycleDuration

    var body: some View {
        ZStack {
            // Background gradient
            if featureFlag.breathingGradientEnabled {
                // Animated breathing-synchronized gradient
                AnimatedGradientView(
                    breathingPhase: $currentPhase,
                    palette: featureFlag.breathingGradientPalette,
                    opacity: featureFlag.breathingGradientOpacity
                )
            } else {
                // Static gradient
                ZenTheme.backgroundGradient
                    .ignoresSafeArea()
            }

            // Particle effects layer (if enabled)
            if featureFlag.particleEffectsEnabled {
                ParticleCanvasView(
                    isAnimating: isAnimating && !isPaused,
                    currentPhase: currentPhase == .inhale ? .inhale : .exhale,
                    intensity: featureFlag.particleIntensity,
                    colorTheme: featureFlag.particleColorTheme
                )
            }

            VStack(spacing: 80) {
                Spacer()

                // Session duration indicator
                if isAnimating || sessionTracker.duration > 0 {
                    Text(sessionTracker.getFormattedDuration())
                        .font(ZenTheme.headline)
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                        .accessibilityLabel("Meditasyon süresi: \(sessionTracker.getFormattedDuration())")
                }

                // Breathing circles
                ZStack {
                    // Outer circle
                    Circle()
                        .fill(ZenTheme.breathingOuterGradient)
                        .frame(width: AppConstants.Breathing.outerCircleSize, height: AppConstants.Breathing.outerCircleSize)
                        .scaleEffect(scale)
                        .blur(radius: AppConstants.Breathing.circleBlurRadius)

                    // Inner circle
                    Circle()
                        .fill(ZenTheme.breathingInnerGradient)
                        .frame(width: AppConstants.Breathing.innerCircleSize, height: AppConstants.Breathing.innerCircleSize)
                        .scaleEffect(scale)
                        .blur(radius: 5)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Nefes alma animasyonu")
                .accessibilityValue(currentPhase.accessibilityAnnouncement)

                // Dynamic breathing text
                Text(currentPhase.text)
                    .font(ZenTheme.largeTitle)
                    .foregroundColor(ZenTheme.lightLavender)
                    .transition(.opacity.combined(with: .scale))
                    .id(currentPhase.text)
                    .accessibilityHidden(true) // Announced via circle accessibilityValue

                Spacer()

                // Control buttons
                HStack(spacing: 40) {
                    // Start/Stop button
                    Button(action: toggleAnimation) {
                        Image(systemName: isAnimating ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(ZenTheme.lightLavender)
                    }
                    .accessibilityLabel(isAnimating ? "Meditasyonu durdur" : "Meditasyonu başlat")
                    .accessibilityHint(isAnimating ? "Meditasyon seansını sonlandırır ve kaydeder" : "Nefes egzersizi ile meditasyonu başlatır")

                    // Pause/Resume button
                    if isAnimating {
                        Button(action: togglePause) {
                            Image(systemName: isPaused ? "play.circle" : "pause.circle")
                                .font(.system(size: 50))
                                .foregroundColor(ZenTheme.softPurple)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel(isPaused ? "Devam et" : "Duraklat")
                        .accessibilityHint(isPaused ? "Meditasyona devam eder" : "Meditasyonu geçici olarak duraklatır")
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Animation Control

    private func toggleAnimation() {
        // Haptic feedback for button press
        hapticManager.playImpact(style: .medium)

        if isAnimating {
            stopAnimation()
        } else {
            startAnimation()
        }
    }

    private func togglePause() {
        // Haptic feedback for button press
        hapticManager.playImpact(style: .light)

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
        scale = AppConstants.Breathing.exhaleScale
        currentPhase = .exhale

        // Start meditation session tracking
        sessionTracker.startSession()

        // Start haptic engine
        hapticManager.startEngine()

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: "Meditasyon başladı")

        performBreathingCycle()
    }

    private func stopAnimation() {
        isAnimating = false
        isPaused = false
        animationTimer?.invalidate()
        animationTimer = nil

        // End meditation session tracking
        sessionTracker.endSession { duration in
            let minutes = Int(duration / AppConstants.TimeFormat.secondsPerMinute)
            print("✅ Meditation session completed: \(minutes) minutes")

            // Accessibility announcement for completion
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Accessibility.announcementDelay) {
                UIAccessibility.post(notification: .announcement, argument: "Meditasyon tamamlandı. \(minutes) dakika.")
            }
        }

        // Stop haptic engine
        hapticManager.stopEngine()

        // Success haptic feedback
        hapticManager.playNotification(type: .success)

        withAnimation(.easeInOut(duration: AppConstants.Animation.transitionDuration)) {
            scale = AppConstants.Breathing.exhaleScale
            currentPhase = .exhale
        }
    }

    private func pauseAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil

        // Stop haptic engine when paused
        hapticManager.stopEngine()

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: "Meditasyon duraklatıldı")
    }

    private func resumeAnimation() {
        // Restart haptic engine when resumed
        hapticManager.startEngine()

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: "Meditasyon devam ediyor")

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
