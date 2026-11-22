//
//  SilentMeditationView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Silent meditation: no breathing guidance, just a timer with an opening and
//  closing gong, an optional preparation countdown and the user's ambient
//  sound and interval bell. Sessions count towards minutes, streak, garden
//  and HealthKit like any other meditation.
//

import SwiftUI
import UIKit

struct SilentMeditationView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var soundManager = AmbientSoundManager.shared
    private let sessionTracker = SessionTracker.shared
    private let bell = MindfulnessBellManager.shared

    @AppStorage("silentMeditationMinutes") private var minutes: Int = 10
    @AppStorage("silentMeditationPrep") private var prepEnabled: Bool = true
    @AppStorage("silentMeditationGongs") private var gongsEnabled: Bool = true

    private enum Stage {
        case setup, preparing, meditating, complete
    }

    @State private var stage: Stage = .setup
    @State private var startedAt: Date?
    @State private var remaining: TimeInterval = 0
    @State private var completedMinutes = 0
    @State private var soundsBefore: [AmbientSound] = []

    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var plan: SilentMeditationPlan {
        SilentMeditationPlan(prepSeconds: prepEnabled ? SilentMeditationPlan.defaultPrepSeconds : 0, minutes: minutes)
    }

    var body: some View {
        ZStack {
            switch stage {
            case .setup:
                setupView
            case .preparing, .meditating:
                runningView
            case .complete:
                Color.black.ignoresSafeArea()
            }

            if stage == .complete {
                SessionCompleteView(
                    durationMinutes: completedMinutes,
                    exerciseType: MoodEntry.silentMeditationType
                ) { _ in
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(ticker) { _ in tick() }
        .onDisappear {
            // Never leave the screen locked awake or a session dangling
            if stage == .preparing || stage == .meditating {
                finish(natural: false)
            }
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        ZStack {
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(String(localized: "silent_title", defaultValue: "Sessiz Meditasyon", comment: "Silent meditation title"), systemImage: "figure.mind.and.body")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(ZenTheme.lightLavender)

                            Text(String(localized: "silent_subtitle", defaultValue: "Rehbersiz oturuş: yalnızca zaman, bir çan ve sen.", comment: "Silent meditation subtitle"))
                                .font(.system(size: 15))
                                .foregroundColor(ZenTheme.softPurple)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ZenTheme.lightLavender)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        .accessibilityLabel(String(localized: "sleep_mode_close", defaultValue: "Kapat", comment: "Close sleep mode"))
                    }

                    durationSection

                    toggles

                    Button {
                        HapticManager.shared.playImpact(style: .medium)
                        start()
                    } label: {
                        HStack {
                            Image(systemName: "leaf.fill")
                            Text(String(localized: "silent_start", defaultValue: "Başla", comment: "Start silent meditation"))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [ZenTheme.mysticalViolet, ZenTheme.calmBlue], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "sleep_mode_timer", defaultValue: "Süre", comment: "Sleep mode timer section"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ZenTheme.softPurple)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SilentMeditationPlan.presetMinutes, id: \.self) { preset in
                        Button {
                            HapticManager.shared.playImpact(style: .light)
                            minutes = preset
                        } label: {
                            Text(String(localized: "sleep_mode_minutes_short", defaultValue: "\(preset) dk", comment: "Minutes, short"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(minutes == preset ? .white : ZenTheme.softPurple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(minutes == preset ? ZenTheme.mysticalViolet.opacity(0.7) : Color.white.opacity(0.08))
                                )
                        }
                    }
                }
            }

            Picker("", selection: $minutes) {
                ForEach(Array(SilentMeditationPlan.minuteRange), id: \.self) { value in
                    Text(String(localized: "sleep_mode_minutes_short", defaultValue: "\(value) dk", comment: "Minutes, short")).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .accessibilityLabel(String(localized: "silent_duration_picker", defaultValue: "Meditasyon süresi", comment: "Silent meditation duration picker"))
        }
    }

    private var toggles: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $prepEnabled) {
                Text(String(localized: "silent_prep", defaultValue: "10 saniyelik hazırlık", comment: "Preparation countdown toggle"))
                    .foregroundColor(ZenTheme.lightLavender)
            }
            .padding(14)

            Divider().background(Color.white.opacity(0.1))

            Toggle(isOn: $gongsEnabled) {
                Text(String(localized: "silent_gongs", defaultValue: "Başlangıç ve bitiş çanı", comment: "Opening and closing gong toggle"))
                    .foregroundColor(ZenTheme.lightLavender)
            }
            .padding(14)

            if bell.isEnabled {
                Divider().background(Color.white.opacity(0.1))
                Text(String(localized: "silent_bell_note", defaultValue: "Farkındalık çanın her \(bell.interval.rawValue) dakikada bir çalacak.", comment: "Interval bell note"))
                    .font(.footnote)
                    .foregroundColor(ZenTheme.softPurple)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
        }
        .tint(ZenTheme.mysticalViolet)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
    }

    // MARK: - Running

    private var runningView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if stage == .preparing {
                    Text(String(localized: "silent_get_ready", defaultValue: "Yerleş ve gözlerini kapat", comment: "Get comfortable message"))
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.6))
                }

                Text(SilentMeditationPlan.formatted(remaining))
                    .font(.system(size: 64, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(ZenTheme.lightLavender.opacity(stage == .preparing ? 0.4 : 0.55))
                    .accessibilityLabel(String(localized: "silent_remaining_accessibility", defaultValue: "Kalan süre \(SilentMeditationPlan.formatted(remaining))", comment: "Remaining time accessibility"))

                Spacer()

                Button {
                    finish(natural: false)
                } label: {
                    Label(String(localized: "sleep_mode_stop", defaultValue: "Bitir", comment: "End sleep mode"), systemImage: "stop.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                .padding(.bottom, 48)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Flow

    private func start() {
        startedAt = Date()
        stage = .preparing
        remaining = plan.remainingPrep(elapsed: 0)
        UIApplication.shared.isIdleTimerDisabled = true
        tick()
    }

    private func tick() {
        guard stage == .preparing || stage == .meditating, let startedAt else { return }

        let elapsed = Date().timeIntervalSince(startedAt)
        let currentPlan = plan

        switch currentPlan.phase(elapsed: elapsed) {
        case .preparing:
            remaining = currentPlan.remainingPrep(elapsed: elapsed)
        case .meditating:
            if stage == .preparing {
                beginMeditation()
            }
            remaining = currentPlan.remainingMeditation(elapsed: elapsed)
        case .finished:
            finish(natural: true)
        }
    }

    private func beginMeditation() {
        stage = .meditating
        sessionTracker.startSession()
        HapticManager.shared.playSessionStart()

        if gongsEnabled {
            bell.chime()
        }
        bell.startBell()

        // The user's ambient selection plays, and is restored afterwards
        soundsBefore = soundManager.activeSounds
        if soundManager.isEnabled {
            for sound in soundsBefore where !sound.fileName.isEmpty {
                soundManager.playSound(sound, fadeInDuration: 2.0)
            }
        }
    }

    private func finish(natural: Bool) {
        let wasMeditating = stage == .meditating

        bell.stopBell()
        UIApplication.shared.isIdleTimerDisabled = false
        startedAt = nil

        if wasMeditating {
            soundManager.stopAllSounds(fadeOutDuration: 3.0)
            soundManager.activeSounds = soundsBefore
            soundsBefore = []

            if natural && gongsEnabled {
                bell.chime()
            }

            sessionTracker.endSession { duration in
                let finishedMinutes = Int(duration / 60)
                if finishedMinutes >= 1 {
                    HapticManager.shared.playSessionComplete()
                    completedMinutes = finishedMinutes
                    stage = .complete
                } else {
                    HapticManager.shared.playSessionCancel()
                    stage = .setup
                }
            }
        } else {
            stage = .setup
        }
    }
}

#Preview {
    SilentMeditationView()
}
