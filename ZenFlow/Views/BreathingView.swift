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
            return String(localized: "breathing_phase_inhale", comment: "Inhale")
        case .hold:
            return String(localized: "breathing_phase_hold", comment: "Hold")
        case .exhale:
            return String(localized: "breathing_phase_exhale", comment: "Exhale")
        case .holdAfterExhale:
            return String(localized: "breathing_phase_hold_after_exhale", comment: "Hold after exhale")
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
            return String(localized: "breathing_accessibility_inhale", comment: "Breathe in announcement")
        case .hold:
            return String(localized: "breathing_accessibility_hold", comment: "Hold breath announcement")
        case .exhale:
            return String(localized: "breathing_accessibility_exhale", comment: "Breathe out announcement")
        case .holdAfterExhale:
            return String(localized: "breathing_accessibility_hold_after_exhale", comment: "Hold after exhale announcement")
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

    /// Start countdown timer (updates every 0.5 second for smooth UI with minimal CPU load)
    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            self.phaseTimeRemaining = max(0, self.phaseTimeRemaining - 0.5)
        }
        timer.tolerance = 0.1 // 20% tolerance to reduce CPU wake-ups and audio overload
        RunLoop.current.add(timer, forMode: .common)
        countdownTimer = timer
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
    @State private var countdownTimer: Timer?
    @State private var showSessionComplete = false
    @State private var completedDurationMinutes = 0
    @State private var selectedDurationMinutes: Int = 5
    @State private var sessionTimer: Timer?
    @State private var sessionStartTime: Date?
    @State private var pausedTimeRemaining: TimeInterval = 0
    @State private var showExerciseSelection = false
    @State private var showSoundPicker = false
    @State private var phaseTimeRemaining: TimeInterval = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var volumeBeforePause: Float = 0.0

    // MARK: - Environment Objects (Performance Optimization)
    // Use @EnvironmentObject for singleton managers to avoid re-initialization
    @EnvironmentObject var sessionTracker: SessionTracker
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var featureFlag: FeatureFlag
    @EnvironmentObject var exerciseManager: BreathingExerciseManager
    @EnvironmentObject var soundManager: AmbientSoundManager

    // MARK: - Constants

    private var currentExercise: BreathingExercise {
        exerciseManager.selectedExercise
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        // Exercise selection button (fixed height zone)
                        HStack {
                            Spacer()
                            Button(action: {
                                showExerciseSelection = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: currentExercise.iconName)
                                        .font(.system(size: 14))
                                    Text(currentExercise.name)
                                        .font(.system(size: 14, weight: .semibold))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(ZenTheme.lightLavender)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
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
                            .accessibilityLabel(String(localized: "breathing_select_exercise_accessibility", defaultValue: "Egzersiz seç: \(currentExercise.name)", comment: "Select exercise accessibility"))
                            .accessibilityHint(String(localized: "breathing_select_exercise_hint", defaultValue: "Farklı bir nefes egzersizi seçmek için dokunun", comment: "Tap to select different exercise"))
                            .opacity(isAnimating ? 0 : 1)
                            .allowsHitTesting(!isAnimating)
                            Spacer()
                        }
                        .frame(height: 50)
                        .padding(.top, max(geometry.safeAreaInsets.top, 16))

                // Flexible spacer with minimum height
                Spacer(minLength: 10)

                // Session duration indicator (fixed height zone)
                Text(sessionTracker.getFormattedDuration())
                    .font(ZenTheme.zenHeadline)
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                    .accessibilityLabel(String(localized: "breathing_session_duration_accessibility", defaultValue: "Meditasyon süresi: \(sessionTracker.getFormattedDuration())", comment: "Session duration accessibility"))
                    .opacity((isAnimating || sessionTracker.duration > 0) ? 1 : 0)
                    .frame(height: 40)

                // Flexible spacer with minimum height
                Spacer(minLength: 10)

                // Breathing circles (fixed height zone)
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

                    // Phase countdown and text overlay
                    VStack(spacing: 8) {
                        // Countdown number
                        Text("\(Int(ceil(phaseTimeRemaining)))")
                            .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .opacity(isAnimating && !isPaused ? 1 : 0)

                        // Phase text
                        Text(currentPhase.text)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(isAnimating && !isPaused ? 1 : 0)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "breathing_animation_accessibility", comment: "Breathing animation accessibility"))
                .accessibilityValue(currentPhase.accessibilityAnnouncement)
                .frame(height: geometry.size.height * 0.35)

                // Dynamic breathing text (fixed height zone)
                Text(currentPhase.text)
                    .font(ZenTheme.zenLargeTitle)
                    .foregroundColor(ZenTheme.lightLavender)
                    .id(currentPhase.text)
                    .accessibilityHidden(true)
                    .opacity(isAnimating ? 0 : 1)
                    .frame(height: 50)

                // Flexible spacer with minimum height
                Spacer(minLength: 10)

                // Sound selector (flexible height)
                compactSoundSelector
                    .opacity(isAnimating ? 0 : 1)
                    .allowsHitTesting(!isAnimating)
                    .frame(height: 60)

                // Duration picker (flexible height)
                durationPickerView
                    .opacity(isAnimating ? 0 : 1)
                    .allowsHitTesting(!isAnimating)
                    .frame(height: 70)

                // Flexible spacer with minimum height
                Spacer(minLength: 10)

                // Control buttons (fixed height zone, centered)
                VStack(spacing: 20) {
                    // Main centered Start/Stop button with zen icon
                    Button(action: toggleAnimation) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ZenTheme.lightLavender, ZenTheme.softPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: ZenTheme.lightLavender.opacity(0.5), radius: 20, x: 0, y: 10)

                            Image(systemName: isAnimating ? "stop.fill" : "leaf.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .zenIconButtonStyle()
                    .accessibilityLabel(isAnimating ? String(localized: "breathing_stop_meditation", defaultValue: "Meditasyonu durdur", comment: "Stop meditation") : String(localized: "breathing_start_meditation", defaultValue: "Meditasyonu başlat", comment: "Start meditation"))
                    .accessibilityHint(isAnimating ? String(localized: "breathing_stop_meditation_hint", defaultValue: "Meditasyon seansını sonlandırır ve kaydeder", comment: "Ends and saves session") : String(localized: "breathing_start_meditation_hint", defaultValue: "Nefes egzersizi ile meditasyonu başlatır", comment: "Starts breathing exercise"))

                    // Pause/Resume button (smaller, below main button)
                    if isAnimating {
                        Button(action: togglePause) {
                            HStack(spacing: 8) {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 14))
                                Text(isPaused ? String(localized: "breathing_resume", defaultValue: "Devam Et", comment: "Resume") : String(localized: "breathing_pause", defaultValue: "Duraklat", comment: "Pause"))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(ZenTheme.lightLavender)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
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
                        .accessibilityLabel(isPaused ? String(localized: "breathing_resume_accessibility", defaultValue: "Devam et", comment: "Resume") : String(localized: "breathing_pause_accessibility", defaultValue: "Duraklat", comment: "Pause"))
                        .accessibilityHint(isPaused ? String(localized: "breathing_resume_hint", defaultValue: "Meditasyona devam eder", comment: "Continues meditation") : String(localized: "breathing_pause_hint", defaultValue: "Meditasyonu geçici olarak duraklatır", comment: "Temporarily pauses"))
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .padding(.bottom, 90)
            }

                // Session Complete Overlay
                if showSessionComplete {
                    SessionCompleteView(durationMinutes: completedDurationMinutes) { mood in
                        showSessionComplete = false
                        if let mood = mood {
                            print("✅ User selected mood: \(mood.displayName) (\(mood.emoji))")
                        }
                    }
                }
            }
            .background(
                // Static gradient - optimized for all devices, no edge shifting
                ZenTheme.backgroundGradient
                    .ignoresSafeArea()
            )
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showExerciseSelection) {
                ExerciseSelectionView { selectedExercise in
                    // Handle exercise change
                    handleExerciseChange(to: selectedExercise)
                }
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(24)
            }
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerSheet()
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(24)
            }
            .onReceive(NotificationCenter.default.publisher(for: DeepLinkHandler.switchToTabNotification)) { notification in
                // Handle deep link with exercise parameter
                if let exerciseType = notification.userInfo?["exerciseType"] as? String {
                    handleDeepLinkExercise(exerciseType)
                }
            }
            .onAppear {
                // View appeared - setup if needed
            }
            .onDisappear {
                // PERFORMANCE OPTIMIZATION: Clean up timers when view disappears
                cleanupTimers()

                // Stop animations
                if isAnimating {
                    isAnimating = false
                }

                // Fade out sound if playing
                if !soundManager.activeSounds.isEmpty {
                    soundManager.stopAllSounds(fadeOutDuration: 0.5)
                }
            }
        }
    }

    // MARK: - Duration Picker View

    private var durationPickerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ForEach([5, 10, 15, 30], id: \.self) { duration in
                    Button(action: {
                        selectedDurationMinutes = duration
                        HapticManager.shared.playImpact(style: .light)
                    }) {
                        Text(String(localized: "breathing_duration_minutes", defaultValue: "\(duration) dk", comment: "Duration in minutes"))
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
                    .accessibilityLabel(String(localized: "breathing_duration_accessibility", defaultValue: "\(duration) dakika seans", comment: "Duration accessibility"))
                    .accessibilityHint(selectedDurationMinutes == duration ? String(localized: "breathing_duration_selected", defaultValue: "Seçili", comment: "Selected") : String(localized: "breathing_duration_tap_to_select", defaultValue: "Seçmek için dokunun", comment: "Tap to select"))
                }
            }
        }
    }

    // MARK: - Compact Sound Selector

    private var compactSoundSelector: some View {
        Button(action: {
            showSoundPicker = true
            HapticManager.shared.playImpact(style: .light)
        }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)

                    if soundManager.activeSounds.isEmpty || soundManager.activeSounds.first?.fileName == "" {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ZenTheme.softPurple)
                    } else {
                        Image(systemName: soundManager.activeSounds.first!.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(soundManager.activeSounds.first!.category.color)
                    }
                }

                // Label
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "breathing_sound_label", defaultValue: "Ses", comment: "Sound label"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))

                    if soundManager.activeSounds.isEmpty || soundManager.activeSounds.first?.fileName == "" {
                        Text(String(localized: "breathing_sound_silent", defaultValue: "Sessiz", comment: "Silent"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ZenTheme.lightLavender)
                    } else {
                        Text(soundManager.activeSounds.map { $0.name }.joined(separator: ", "))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ZenTheme.lightLavender)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ZenTheme.softPurple)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .accessibilityLabel(String(localized: "breathing_sound_selection_accessibility", defaultValue: "Ses seçimi", comment: "Sound selection accessibility"))
        .accessibilityHint(String(localized: "breathing_sound_selection_hint", defaultValue: "Arka plan sesi seçmek için dokunun", comment: "Tap to select sound"))
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

        // Play session start haptic
        HapticManager.shared.playSessionStart()

        // Start session duration timer
        let durationInSeconds = TimeInterval(selectedDurationMinutes * 60)
        sessionStartTime = Date()
        pausedTimeRemaining = durationInSeconds
        sessionTimer = Timer.scheduledTimer(withTimeInterval: durationInSeconds, repeats: false) { [self] _ in
            // Session duration completed
            completeSessionAutomatically()
        }

        // Start ambient sounds with fade in
        if soundManager.isEnabled && !soundManager.activeSounds.isEmpty {
            for sound in soundManager.activeSounds where !sound.fileName.isEmpty {
                soundManager.playSound(sound, fadeInDuration: 2.0)
            }
        }

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "accessibility_exercise_started", defaultValue: "\(currentExercise.name) egzersizi başladı. \(selectedDurationMinutes) dakika.", comment: "Exercise started announcement"))

        performBreathingCycle()
    }

    private func stopAnimation() {
        isAnimating = false
        isPaused = false
        cleanupTimers() // Use centralized cleanup
        currentPhaseIndex = 0

        // Stop ambient sounds with fade out
        soundManager.stopAllSounds(fadeOutDuration: 3.0)

        // End meditation session tracking
        sessionTracker.endSession { duration in
            let minutes = Int(duration / Double(AppConstants.TimeFormat.secondsPerMinute))
            print("✅ Meditation session completed: \(minutes) minutes")

            // Only show success animation for sessions >= 1 minute
            if minutes >= 1 {
                // Play session complete haptic
                HapticManager.shared.playSessionComplete()
                completedDurationMinutes = minutes
                showSessionComplete = true
            } else {
                // Play session cancel haptic for short sessions
                HapticManager.shared.playSessionCancel()
            }

            // Accessibility announcement for completion
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Accessibility.announcementDelay) {
                UIAccessibility.post(notification: .announcement, argument: String(localized: "accessibility_meditation_completed", defaultValue: "Meditasyon tamamlandı. \(minutes) dakika.", comment: "Meditation completed announcement"))
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

    // MARK: - Timer Cleanup (Performance Optimization)

    /// Centralized timer cleanup to prevent memory leaks and background CPU usage
    private func cleanupTimers() {
        animationTimer?.invalidate()
        animationTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    private func pauseAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil

        // Pause session timer - calculate remaining time
        sessionTimer?.invalidate()
        sessionTimer = nil
        if let startTime = sessionStartTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            pausedTimeRemaining = max(0, pausedTimeRemaining - elapsedTime)
        }

        // Reduce ambient sound volume to 50% when paused
        volumeBeforePause = soundManager.volume
        withAnimation(.easeInOut(duration: 0.5)) {
            soundManager.volume = volumeBeforePause * 0.5
        }

        // Stop haptic engine when paused
        hapticManager.stopEngine()

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "accessibility_meditation_paused", defaultValue: "Meditasyon duraklatıldı", comment: "Meditation paused announcement"))
    }

    private func resumeAnimation() {
        // Resume session timer with remaining time
        sessionStartTime = Date()
        if pausedTimeRemaining > 0 {
            sessionTimer = Timer.scheduledTimer(withTimeInterval: pausedTimeRemaining, repeats: false) { [self] _ in
                completeSessionAutomatically()
            }
        }

        // Restore ambient sound volume to normal
        withAnimation(.easeInOut(duration: 0.5)) {
            soundManager.volume = volumeBeforePause
        }

        // Restart haptic engine when resumed
        hapticManager.startEngine()

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "accessibility_meditation_resumed", defaultValue: "Meditasyon devam ediyor", comment: "Meditation resumed announcement"))

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

        // Invalidate existing countdown timer to prevent leaks
        countdownTimer?.invalidate()

        // Start phase countdown timer (reduced frequency to lower CPU load and prevent audio overload)
        let newCountdownTimer = Timer(timeInterval: 0.5, repeats: true) { [self] timer in
            guard isAnimating && !isPaused else {
                timer.invalidate()
                return
            }
            phaseTimeRemaining = max(0, phaseTimeRemaining - 0.5)
        }
        newCountdownTimer.tolerance = 0.1 // 20% tolerance to reduce CPU wake-ups
        RunLoop.current.add(newCountdownTimer, forMode: .common)
        countdownTimer = newCountdownTimer

        // Schedule next phase
        animationTimer = Timer.scheduledTimer(withTimeInterval: phaseConfig.duration, repeats: false) { [self] _ in
            countdownTimer?.invalidate()
            countdownTimer = nil
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
            // Gentle pulsing for hold
            HapticManager.shared.playBreathingHold(duration: duration)
        case .exhale:
            // Decreasing intensity haptic
            HapticManager.shared.playBreathingExhale(duration: duration)
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
            argument: String(localized: "accessibility_exercise_changed", defaultValue: "\(exercise.name) egzersizine geçildi", comment: "Exercise changed announcement")
        )
    }

    /// Handle deep link exercise type parameter
    private func handleDeepLinkExercise(_ exerciseType: String) {
        // Select exercise by type
        exerciseManager.selectExerciseByType(exerciseType)

        // Update UI to reflect the new exercise
        if let firstPhase = exerciseManager.selectedExercise.phases.first {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPhase = AnimationPhase(from: firstPhase.phase)
                scale = currentPhase.scale
                phaseTimeRemaining = firstPhase.duration
            }
        }

        // Announce change
        UIAccessibility.post(
            notification: .announcement,
            argument: String(localized: "accessibility_exercise_changed", defaultValue: "\(exerciseManager.selectedExercise.name) egzersizine geçildi", comment: "Exercise changed announcement")
        )
    }
}

#Preview {
    BreathingView()
}
