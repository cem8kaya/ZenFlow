//
//  FocusTimerView.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Pomodoro-style focus timer view with circular progress indicator,
//  session tracking, and breathing exercise suggestions during breaks.
//

import SwiftUI
import Combine
import UserNotifications

struct FocusTimerView: View {
    // MARK: - State Properties

    @State private var currentMode: FocusMode = .work
    @State private var timerState: FocusTimerState = .idle
    @State private var timeRemaining: TimeInterval = FocusMode.work.durationSeconds
    @State private var completedSessions: Int = 0
    @State private var todayCompletedSessions: Int = 0
    @State private var timer: Timer?
    @State private var sessionEndTime: Date?
    @State private var showBreathingExerciseSuggestion = false
    @State private var showCompletionCelebration = false
    @State private var breathingPhase: AnimationPhase = .exhale
    @State private var showSoundPicker = false
    @State private var volumeBeforePause: Float = 0.0
    @StateObject private var soundManager = AmbientSoundManager.shared

    // MARK: - Computed Properties

    private var progress: Double {
        let totalDuration = currentMode.durationSeconds
        return max(0, min(1, (totalDuration - timeRemaining) / totalDuration))
    }

    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            AnimatedGradientView(breathingPhase: $breathingPhase)
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                // Header with session counter
                headerView

                Spacer(minLength: 30)

                // Main timer circle
                timerCircleView

                Spacer(minLength: 30)

                // Mode label
                modeLabel

                Spacer(minLength: 20)

                // Sound selector (visible only when not running)
                if timerState == .idle {
                    compactSoundSelector
                        .transition(.opacity.combined(with: .scale))
                        .padding(.bottom, 12)
                }

                // Control buttons
                controlButtons
                    .padding(.bottom, 30)
            }

            // Celebration overlay
            if showCompletionCelebration {
                celebrationOverlay
            }

            // Breathing exercise suggestion
            if showBreathingExerciseSuggestion {
                breathingExerciseSuggestion
            }
        }
        .onAppear {
            loadTodaysSessions()
            requestNotificationPermission()
        }
        .onDisappear {
            stopTimer()
            soundManager.stopAllSounds(fadeOutDuration: 0)
        }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerSheet()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(24)
                .presentationBackgroundInteraction(.enabled)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pomodoro Zamanlayıcı")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Bugün: \(todayCompletedSessions) oturum")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Total session counter
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: AppConstants.Pomodoro.counterIconSize))
                    .foregroundColor(ZenTheme.calmBlue)

                Text("\(completedSessions)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .padding(.horizontal, 20)
    }

    private var timerCircleView: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color.white.opacity(0.2),
                    lineWidth: AppConstants.Pomodoro.progressStrokeWidth
                )
                .frame(
                    width: AppConstants.Pomodoro.timerCircleSize,
                    height: AppConstants.Pomodoro.timerCircleSize
                )

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    currentMode.color,
                    style: StrokeStyle(
                        lineWidth: AppConstants.Pomodoro.progressStrokeWidth,
                        lineCap: .round
                    )
                )
                .frame(
                    width: AppConstants.Pomodoro.timerCircleSize,
                    height: AppConstants.Pomodoro.timerCircleSize
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Inner content
            VStack(spacing: 16) {
                // Time display
                Text(timeString)
                    .font(.system(size: AppConstants.Pomodoro.timerFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Mode icon
                Image(systemName: currentMode.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(currentMode.color)
            }
        }
    }

    private var modeLabel: some View {
        VStack(spacing: 8) {
            Text(currentMode.displayName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(currentMode.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 32) {
            // Reset button
            Button(action: resetTimer) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(
                        width: AppConstants.Pomodoro.buttonSize,
                        height: AppConstants.Pomodoro.buttonSize
                    )
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )
            }
            .disabled(timerState == .idle)
            .opacity(timerState == .idle ? 0.5 : 1)

            // Play/Pause button
            Button(action: toggleTimer) {
                Image(systemName: timerState.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(
                        width: AppConstants.Pomodoro.buttonSize * 1.2,
                        height: AppConstants.Pomodoro.buttonSize * 1.2
                    )
                    .background(
                        Circle()
                            .fill(currentMode.color)
                            .shadow(color: currentMode.color.opacity(0.5), radius: 20)
                    )
            }

            // Skip button
            Button(action: skipToNextMode) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(
                        width: AppConstants.Pomodoro.buttonSize,
                        height: AppConstants.Pomodoro.buttonSize
                    )
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )
            }
            .disabled(timerState == .idle)
            .opacity(timerState == .idle ? 0.5 : 1)
        }
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(currentMode.color)

                Text("Harika İş!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Bir \(currentMode.displayName) oturumu tamamladın")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Button(action: {
                    withAnimation {
                        showCompletionCelebration = false
                        moveToNextMode()
                    }
                }) {
                    Text("Devam Et")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(currentMode.color)
                        )
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.1))
            )
            .padding(32)
        }
        .transition(.opacity)
    }

    private var breathingExerciseSuggestion: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "wind")
                    .font(.system(size: 60))
                    .foregroundColor(ZenTheme.calmBlue)

                Text("Mola Zamanı")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Nefes egzersizi yapmak ister misin?")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            showBreathingExerciseSuggestion = false
                            moveToNextMode()
                        }
                    }) {
                        Text("Şimdi Değil")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                            )
                    }

                    // Note: In real implementation, this would navigate to BreathingView
                    Button(action: {
                        withAnimation {
                            showBreathingExerciseSuggestion = false
                        }
                        // TODO: Navigate to breathing exercise
                        print("Navigate to breathing exercise")
                    }) {
                        Text("Hadi Başlayalım")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(ZenTheme.calmBlue)
                            )
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.1))
            )
            .padding(32)
        }
        .transition(.opacity)
    }

    // MARK: - Timer Control Methods

    private func toggleTimer() {
        switch timerState {
        case .idle:
            startTimer()
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        case .completed:
            resetTimer()
        }
    }

    private func startTimer() {
        timerState = .running
        HapticManager.shared.playImpact(style: .medium)

        // Start ambient sounds with fade in
        if soundManager.isEnabled && !soundManager.activeSounds.isEmpty {
            for sound in soundManager.activeSounds where !sound.fileName.isEmpty {
                soundManager.playSound(sound, fadeInDuration: 2.0)
            }
        }

        // Set session end time for background-safe timing
        sessionEndTime = Date().addingTimeInterval(timeRemaining)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let endTime = sessionEndTime else { return }
            let remaining = endTime.timeIntervalSince(Date())

            if remaining > 0 {
                timeRemaining = remaining
            } else {
                timeRemaining = 0
                timerCompleted()
            }
        }
    }

    private func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        timer = nil
        sessionEndTime = nil // Clear end time when paused
        HapticManager.shared.playImpact(style: .light)

        // Reduce ambient sound volume to 50% when paused
        volumeBeforePause = soundManager.volume
        withAnimation(.easeInOut(duration: 0.5)) {
            soundManager.volume = volumeBeforePause * 0.5
        }
    }

    private func resumeTimer() {
        // Restore ambient sound volume to normal
        withAnimation(.easeInOut(duration: 0.5)) {
            soundManager.volume = volumeBeforePause
        }

        startTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        timerState = .idle
        timeRemaining = currentMode.durationSeconds
        sessionEndTime = nil
        HapticManager.shared.playImpact(style: .medium)

        // Stop ambient sounds with fade out
        soundManager.stopAllSounds(fadeOutDuration: 2.0)
    }

    private func timerCompleted() {
        stopTimer()
        timerState = .completed

        // Stop ambient sounds with fade out
        soundManager.stopAllSounds(fadeOutDuration: 2.0)

        // Save completed session
        saveSession()

        // Haptic feedback
        HapticManager.shared.playNotification(type: .success)

        // Send notification if app is in background
        sendCompletionNotification()

        // Show appropriate UI
        if currentMode == .work {
            // Increment session counter
            completedSessions += 1
            todayCompletedSessions += 1

            withAnimation {
                showCompletionCelebration = true
            }

            // After celebration, suggest breathing exercise for break
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showCompletionCelebration = false
                    showBreathingExerciseSuggestion = true
                }
            }
        } else {
            // Break completed, show celebration and move to next mode
            withAnimation {
                showCompletionCelebration = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showCompletionCelebration = false
                    moveToNextMode()
                }
            }
        }
    }

    private func skipToNextMode() {
        stopTimer()
        HapticManager.shared.playImpact(style: .medium)

        // Don't count skipped sessions
        moveToNextMode()
    }

    private func moveToNextMode() {
        let nextMode = currentMode.nextMode(completedSessions: completedSessions)
        currentMode = nextMode
        timeRemaining = nextMode.durationSeconds
        sessionEndTime = nil
        timerState = .idle
    }

    // MARK: - Data Persistence

    private func saveSession() {
        let sessionData = FocusSessionData(
            date: Date(),
            mode: currentMode,
            durationMinutes: currentMode.durationMinutes,
            completed: true
        )

        // Save to LocalDataManager
        LocalDataManager.shared.saveFocusSession(sessionData)
    }

    private func loadTodaysSessions() {
        let sessions = LocalDataManager.shared.getTodayFocusSessions()
        todayCompletedSessions = sessions.filter { $0.mode == .work && $0.completed }.count
        completedSessions = LocalDataManager.shared.totalFocusSessions
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()

        switch currentMode {
        case .work:
            content.title = "Odaklanma Tamamlandı! 🎉"
            content.body = "Harika iş! Mola zamanı. \(currentMode.nextMode(completedSessions: completedSessions).durationMinutes) dakika dinlen."
        case .shortBreak, .longBreak:
            content.title = "Mola Bitti! ⏰"
            content.body = "Tekrar odaklanma zamanı. Hazır mısın?"
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate notification
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
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
                    Text("Ses")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))

                    if soundManager.activeSounds.isEmpty || soundManager.activeSounds.first?.fileName == "" {
                        Text("Sessiz")
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
        .padding(.horizontal, 20)
        .accessibilityLabel("Ses seçimi")
        .accessibilityHint("Arka plan sesi seçmek için dokunun")
    }
}

// MARK: - Preview

#Preview {
    FocusTimerView()
}
