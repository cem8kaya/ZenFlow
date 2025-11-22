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
import Combine

/// Animation phase for the breathing cycle (backward compatible)
enum AnimationPhase {
    case inhale
    case hold
    case exhale
    case holdAfterExhale

    /// Scale factor for the breathing circles
    var scale: CGFloat {
        switch self {
        case .inhale:
            return AppConstants.Breathing.inhaleScale
        case .hold:
            return AppConstants.Breathing.inhaleScale
        case .exhale:
            return AppConstants.Breathing.exhaleScale
        case .holdAfterExhale:
            return AppConstants.Breathing.exhaleScale
        }
    }

    /// Display text for current breathing phase
    var text: String {
        switch self {
        case .inhale:
            return "Nefes Al"
        case .hold:
            return "Tut"
        case .exhale:
            return "Nefes Ver"
        case .holdAfterExhale:
            return "Tut"
        }
    }

    /// Primary color for the phase (affects circle color)
    var color: Color {
        switch self {
        case .inhale:
            return ZenTheme.calmBlue
        case .hold:
            return ZenTheme.mysticalViolet
        case .exhale:
            return ZenTheme.serenePurple
        case .holdAfterExhale:
            return ZenTheme.softPurple
        }
    }

    /// Whether this phase should have pulsing animation
    var shouldPulse: Bool {
        switch self {
        case .inhale, .exhale:
            return false // Moving phases don't pulse
        case .hold, .holdAfterExhale:
            return true // Hold phases pulse gently
        }
    }

    /// Accessibility announcement for VoiceOver
    var accessibilityAnnouncement: String {
        switch self {
        case .inhale:
            return "Nefes alın"
        case .hold:
            return "Nefesinizi tutun"
        case .exhale:
            return "Nefes verin"
        case .holdAfterExhale:
            return "Nefesinizi tutun"
        }
    }

    /// Convert from BreathingPhaseType
    init(from phaseType: BreathingPhaseType) {
        switch phaseType {
        case .inhale:
            self = .inhale
        case .hold:
            self = .hold
        case .exhale:
            self = .exhale
        case .holdAfterExhale:
            self = .holdAfterExhale
        }
    }
}

/// Controller for breathing animation phases with countdown timer
class BreathingAnimationController: ObservableObject {
    @Published var currentPhase: AnimationPhase = .exhale
    @Published var currentPhaseIndex: Int = 0
    @Published var phaseTimeRemaining: TimeInterval = 0
    @Published var isActive: Bool = false

    private var currentExercise: BreathingExercise
    private var phaseTimer: Timer?
    private var countdownTimer: Timer?
    private var onPhaseChange: ((AnimationPhase, TimeInterval) -> Void)?

    init(exercise: BreathingExercise, onPhaseChange: ((AnimationPhase, TimeInterval) -> Void)? = nil) {
        self.currentExercise = exercise
        self.onPhaseChange = onPhaseChange

        // Set initial phase
        if let firstPhase = exercise.phases.first {
            self.currentPhase = AnimationPhase(from: firstPhase.phase)
            self.phaseTimeRemaining = firstPhase.duration
        }
    }

    /// Start the breathing cycle
    func start() {
        guard !currentExercise.phases.isEmpty else { return }
        isActive = true
        currentPhaseIndex = 0
        advanceToPhase(at: currentPhaseIndex)
    }

    /// Stop the breathing cycle
    func stop() {
        isActive = false
        phaseTimer?.invalidate()
        countdownTimer?.invalidate()
        phaseTimer = nil
        countdownTimer = nil
    }

    /// Pause the breathing cycle
    func pause() {
        phaseTimer?.invalidate()
        countdownTimer?.invalidate()
        phaseTimer = nil
        countdownTimer = nil
    }

    /// Resume the breathing cycle with remaining time
    func resume() {
        guard isActive, phaseTimeRemaining > 0 else { return }
        startCountdownTimer()
        scheduleNextPhase(after: phaseTimeRemaining)
    }

    /// Update the exercise (called when user selects a different exercise)
    func updateExercise(_ exercise: BreathingExercise) {
        let wasActive = isActive
        stop()
        currentExercise = exercise
        currentPhaseIndex = 0

        if let firstPhase = exercise.phases.first {
            currentPhase = AnimationPhase(from: firstPhase.phase)
            phaseTimeRemaining = firstPhase.duration
        }

        if wasActive {
            start()
        }
    }

    /// Advance to a specific phase
    private func advanceToPhase(at index: Int) {
        guard index < currentExercise.phases.count else { return }

        let phaseConfig = currentExercise.phases[index]
        currentPhase = AnimationPhase(from: phaseConfig.phase)
        phaseTimeRemaining = phaseConfig.duration

        // Notify delegate
        onPhaseChange?(currentPhase, phaseConfig.duration)

        // Start countdown
        startCountdownTimer()

        // Schedule next phase
        scheduleNextPhase(after: phaseConfig.duration)
    }

    /// Start countdown timer (updates every 0.1 second for smooth UI)
    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            self.phaseTimeRemaining = max(0, self.phaseTimeRemaining - 0.1)
        }
    }

    /// Schedule next phase transition
    private func scheduleNextPhase(after duration: TimeInterval) {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self, self.isActive else { return }

            // Move to next phase
            self.currentPhaseIndex = (self.currentPhaseIndex + 1) % self.currentExercise.phases.count
            self.advanceToPhase(at: self.currentPhaseIndex)
        }
    }

    deinit {
        stop()
    }
}

/// Main breathing meditation view with animated guidance
struct BreathingView: View {

    // MARK: - State

    @State private var currentPhase: AnimationPhase = .exhale
    @State private var currentPhaseIndex: Int = 0
    @State private var scale: CGFloat = AppConstants.Breathing.exhaleScale
    @State private var isAnimating = false
    @State private var isPaused = false
    @State private var animationTimer: Timer?
    @State private var showSessionComplete = false
    @State private var completedDurationMinutes = 0
    @State private var selectedDurationMinutes: Int = 5
    @State private var sessionTimer: Timer?
    @State private var sessionStartTime: Date?
    @State private var pausedTimeRemaining: TimeInterval = 0
    @State private var showExerciseSelection = false
    @State private var phaseTimeRemaining: TimeInterval = 0
    @State private var pulseScale: CGFloat = 1.0
    @StateObject private var sessionTracker = SessionTracker.shared
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var featureFlag = FeatureFlag.shared
    @StateObject private var exerciseManager = BreathingExerciseManager.shared

    // MARK: - Constants

    private var currentExercise: BreathingExercise {
        exerciseManager.selectedExercise
    }

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
            } else {
                // Static gradient
                ZenTheme.backgroundGradient
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all)
            }

            // Particle effects layer (if enabled)
            if featureFlag.particleEffectsEnabled {
                ParticleCanvasView(
                    isAnimating: isAnimating && !isPaused,
                    currentPhase: currentPhase,
                    intensity: featureFlag.particleIntensity,
                    colorTheme: featureFlag.particleColorTheme
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(spacing: 80) {
                // Exercise selection button (only when not animating)
                if !isAnimating {
                    HStack {
                        Spacer()
                        Button(action: {
                            showExerciseSelection = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: currentExercise.iconName)
                                    .font(.system(size: 16))
                                Text(currentExercise.name)
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(ZenTheme.lightLavender)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .zenSecondaryButtonStyle()
                        .accessibilityLabel("Egzersiz seç: \(currentExercise.name)")
                        .accessibilityHint("Farklı bir nefes egzersizi seçmek için dokunun")
                        Spacer()
                    }
                    .padding(.top, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                // Session duration indicator
                if isAnimating || sessionTracker.duration > 0 {
                    Text(sessionTracker.getFormattedDuration())
                        .font(ZenTheme.zenHeadline)
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                        .accessibilityLabel("Meditasyon süresi: \(sessionTracker.getFormattedDuration())")
                }

                // Breathing circles
                ZStack {
                    // Outer circle
                    Circle()
                        .fill(ZenTheme.breathingOuterGradient)
                        .frame(width: AppConstants.Breathing.outerCircleSize, height: AppConstants.Breathing.outerCircleSize)
                        .scaleEffect(scale * pulseScale)
                        .blur(radius: AppConstants.Breathing.circleBlurRadius)

                    // Inner circle with phase-based color
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [currentPhase.color, currentPhase.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: AppConstants.Breathing.innerCircleSize, height: AppConstants.Breathing.innerCircleSize)
                        .scaleEffect(scale * pulseScale)
                        .blur(radius: 5)

                    // Phase countdown (only when animating)
                    if isAnimating && !isPaused {
                        VStack(spacing: 8) {
                            // Countdown number
                            Text("\(Int(ceil(phaseTimeRemaining)))")
                                .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            // Phase text
                            Text(currentPhase.text)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .transition(.opacity)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Nefes alma animasyonu")
                .accessibilityValue(currentPhase.accessibilityAnnouncement)

                // Dynamic breathing text (when not animating)
                if !isAnimating {
                    Text(currentPhase.text)
                        .font(ZenTheme.zenLargeTitle)
                        .foregroundColor(ZenTheme.lightLavender)
                        .transition(.opacity.combined(with: .scale))
                        .id(currentPhase.text)
                        .accessibilityHidden(true)
                }

                Spacer()

                // Duration picker (visible only when not animating)
                if !isAnimating {
                    durationPickerView
                        .transition(.opacity.combined(with: .scale))
                        .padding(.bottom, 20)
                }

                // Control buttons
                HStack(spacing: 40) {
                    // Start/Stop button
                    Button(action: toggleAnimation) {
                        Image(systemName: isAnimating ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(ZenTheme.lightLavender)
                    }
                    .zenIconButtonStyle()
                    .accessibilityLabel(isAnimating ? "Meditasyonu durdur" : "Meditasyonu başlat")
                    .accessibilityHint(isAnimating ? "Meditasyon seansını sonlandırır ve kaydeder" : "Nefes egzersizi ile meditasyonu başlatır")

                    // Pause/Resume button
                    if isAnimating {
                        Button(action: togglePause) {
                            Image(systemName: isPaused ? "play.circle" : "pause.circle")
                                .font(.system(size: 50))
                                .foregroundColor(ZenTheme.softPurple)
                        }
                        .zenSecondaryButtonStyle()
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel(isPaused ? "Devam et" : "Duraklat")
                        .accessibilityHint(isPaused ? "Meditasyona devam eder" : "Meditasyonu geçici olarak duraklatır")
                    }
                }
                .padding(.bottom, 120)
            }

            // Session Complete Overlay
            if showSessionComplete {
                SessionCompleteView(durationMinutes: completedDurationMinutes) {
                    showSessionComplete = false
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showExerciseSelection) {
            ExerciseSelectionView { selectedExercise in
                // Handle exercise change
                handleExerciseChange(to: selectedExercise)
            }
        }
    }

    // MARK: - Duration Picker View

    private var durationPickerView: some View {
        VStack(spacing: 12) {
            Text("Seans Süresi")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ZenTheme.softPurple)

            HStack(spacing: 16) {
                ForEach([5, 10, 15, 30], id: \.self) { duration in
                    Button(action: {
                        selectedDurationMinutes = duration
                        HapticManager.shared.playImpact(style: .light)
                    }) {
                        Text("\(duration) dk")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedDurationMinutes == duration ? .white : ZenTheme.softPurple)
                            .frame(width: 70, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedDurationMinutes == duration ?
                                          ZenTheme.lightLavender.opacity(0.3) :
                                          Color.white.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedDurationMinutes == duration ?
                                            ZenTheme.lightLavender :
                                            Color.clear, lineWidth: 2)
                            )
                    }
                    .accessibilityLabel("\(duration) dakika seans")
                    .accessibilityHint(selectedDurationMinutes == duration ? "Seçili" : "Seçmek için dokunun")
                }
            }
        }
    }

    // MARK: - Animation Control

    private func toggleAnimation() {
        // Button style handles haptic feedback automatically
        if isAnimating {
            stopAnimation()
        } else {
            startAnimation()
        }
    }

    private func togglePause() {
        // Button style handles haptic feedback automatically
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
        currentPhaseIndex = 0

        // Set initial state based on first phase of the exercise
        if let firstPhase = currentExercise.phases.first {
            currentPhase = AnimationPhase(from: firstPhase.phase)
            scale = currentPhase.scale
        } else {
            scale = AppConstants.Breathing.exhaleScale
            currentPhase = .exhale
        }

        // Start meditation session tracking
        sessionTracker.startSession()

        // Start haptic engine
        hapticManager.startEngine()

        // Start session duration timer
        let durationInSeconds = TimeInterval(selectedDurationMinutes * 60)
        sessionStartTime = Date()
        pausedTimeRemaining = durationInSeconds
        sessionTimer = Timer.scheduledTimer(withTimeInterval: durationInSeconds, repeats: false) { [self] _ in
            // Session duration completed
            completeSessionAutomatically()
        }

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: "\(currentExercise.name) egzersizi başladı. \(selectedDurationMinutes) dakika.")

        performBreathingCycle()
    }

    private func stopAnimation() {
        isAnimating = false
        isPaused = false
        animationTimer?.invalidate()
        animationTimer = nil
        sessionTimer?.invalidate()
        sessionTimer = nil
        currentPhaseIndex = 0

        // End meditation session tracking
        sessionTracker.endSession { duration in
            let minutes = Int(duration / Double(AppConstants.TimeFormat.secondsPerMinute))
            print("✅ Meditation session completed: \(minutes) minutes")

            // Only show success animation for sessions >= 1 minute
            if minutes >= 1 {
                completedDurationMinutes = minutes
                showSessionComplete = true
            }

            // Accessibility announcement for completion
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Accessibility.announcementDelay) {
                UIAccessibility.post(notification: .announcement, argument: "Meditasyon tamamlandı. \(minutes) dakika.")
            }
        }

        // Stop haptic engine
        hapticManager.stopEngine()

        // Reset to first phase of the exercise
        if let firstPhase = currentExercise.phases.first {
            withAnimation(.easeInOut(duration: AppConstants.Animation.transitionDuration)) {
                currentPhase = AnimationPhase(from: firstPhase.phase)
                scale = currentPhase.scale
            }
        } else {
            withAnimation(.easeInOut(duration: AppConstants.Animation.transitionDuration)) {
                scale = AppConstants.Breathing.exhaleScale
                currentPhase = .exhale
            }
        }
    }

    private func completeSessionAutomatically() {
        // Called when the session timer completes
        stopAnimation()
    }

    private func pauseAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil

        // Pause session timer - calculate remaining time
        sessionTimer?.invalidate()
        sessionTimer = nil
        if let startTime = sessionStartTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            pausedTimeRemaining = max(0, pausedTimeRemaining - elapsedTime)
        }

        // Stop haptic engine when paused
        hapticManager.stopEngine()

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: "Meditasyon duraklatıldı")
    }

    private func resumeAnimation() {
        // Resume session timer with remaining time
        sessionStartTime = Date()
        if pausedTimeRemaining > 0 {
            sessionTimer = Timer.scheduledTimer(withTimeInterval: pausedTimeRemaining, repeats: false) { [self] _ in
                completeSessionAutomatically()
            }
        }

        // Restart haptic engine when resumed
        hapticManager.startEngine()

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: "Meditasyon devam ediyor")

        performBreathingCycle()
    }

    private func performBreathingCycle() {
        guard isAnimating && !isPaused else { return }
        guard !currentExercise.phases.isEmpty else { return }

        // Get current phase configuration
        let phaseConfig = currentExercise.phases[currentPhaseIndex]
        currentPhase = AnimationPhase(from: phaseConfig.phase)
        phaseTimeRemaining = phaseConfig.duration

        // Play phase-based haptic pattern
        playHapticForPhase(currentPhase, duration: phaseConfig.duration)

        // Announce phase change for VoiceOver
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(currentPhase.accessibilityAnnouncement). \(Int(phaseConfig.duration)) saniye"
            )
        }

        // Animate to the current phase
        withAnimation(.easeInOut(duration: phaseConfig.duration)) {
            scale = currentPhase.scale
        }

        // Start pulsing effect for hold phases
        if currentPhase.shouldPulse {
            startPulsingEffect(duration: phaseConfig.duration)
        } else {
            pulseScale = 1.0
        }

        // Start phase countdown timer
        let countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] timer in
            guard isAnimating && !isPaused else {
                timer.invalidate()
                return
            }
            phaseTimeRemaining = max(0, phaseTimeRemaining - 0.1)
        }

        // Schedule next phase
        animationTimer = Timer.scheduledTimer(withTimeInterval: phaseConfig.duration, repeats: false) { [self] _ in
            countdownTimer.invalidate()
            guard isAnimating && !isPaused else { return }

            // Move to next phase
            currentPhaseIndex = (currentPhaseIndex + 1) % currentExercise.phases.count

            // Continue the cycle
            performBreathingCycle()
        }
    }

    /// Start pulsing effect for hold phases
    private func startPulsingEffect(duration: TimeInterval) {
        let pulseCount = Int(duration / 0.6) // Pulse every 0.6 seconds

        for i in 0..<pulseCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) { [self] in
                guard isAnimating && !isPaused && currentPhase.shouldPulse else { return }

                withAnimation(.easeInOut(duration: 0.3)) {
                    pulseScale = 1.03
                }
                withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                    pulseScale = 1.0
                }
            }
        }
    }

    /// Play haptic feedback pattern based on phase
    private func playHapticForPhase(_ phase: AnimationPhase, duration: TimeInterval) {
        switch phase {
        case .inhale:
            // Rising intensity haptic
            HapticManager.shared.playBreathingInhale(duration: duration)
        case .hold, .holdAfterExhale:
            // Gentle tap for hold
            HapticManager.shared.playImpact(style: .light)
        case .exhale:
            // Subtle notification for exhale
            HapticManager.shared.playImpact(style: .soft)
        }
    }

    /// Handle exercise change from selection view
    private func handleExerciseChange(to exercise: BreathingExercise) {
        // Stop current animation if running
        if isAnimating {
            stopAnimation()
        }

        // Update to new exercise
        exerciseManager.selectExercise(exercise)

        // Reset to first phase of new exercise
        if let firstPhase = exercise.phases.first {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPhase = AnimationPhase(from: firstPhase.phase)
                scale = currentPhase.scale
                phaseTimeRemaining = firstPhase.duration
            }
        }

        // Announce change
        UIAccessibility.post(
            notification: .announcement,
            argument: "\(exercise.name) egzersizine geçildi"
        )
    }
}

#Preview {
    BreathingView()
}
