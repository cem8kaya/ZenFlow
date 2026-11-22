//
//  SleepModeView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Sleep Mode: pick a calming sound and a timer, then the screen dims to
//  near-black with an optional, text-free 4-7-8 breathing glow. The sound
//  fades out by itself, so the user can fall asleep without touching the phone.
//

import SwiftUI

struct SleepModeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var sleep = SleepModeManager.shared
    @ObservedObject private var soundManager = AmbientSoundManager.shared
    @ObservedObject private var storeManager = StoreManager.shared

    @State private var showPaywall = false
    @State private var showControls = false
    @State private var showGoodNight = false
    @State private var hideControlsTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if sleep.isRunning {
                runningView
                    .transition(.opacity)
            } else if showGoodNight {
                goodNightView
                    .transition(.opacity)
            } else {
                setupView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: sleep.isRunning)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
        .onChange(of: sleep.didFinishNaturally) { _, finished in
            if finished {
                showGoodNight = true
            }
        }
        .onAppear {
            // Never leave a premium-only sound selected for a free user
            if let sound = sleep.selectedSound, sound.isPremium, !storeManager.isPremiumUnlocked {
                sleep.soundFileName = "Rain"
            }
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        ZStack {
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    setupHeader

                    soundSection

                    timerSection

                    guideToggle

                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }

    private var setupHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Label(String(localized: "sleep_mode_title", defaultValue: "Uyku Modu", comment: "Sleep mode title"), systemImage: "moon.stars.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ZenTheme.lightLavender)

                Text(String(localized: "sleep_mode_subtitle", defaultValue: "Bir ses ve süre seç. Ekran kararır, ses yavaşça kısılarak kapanır.", comment: "Sleep mode subtitle"))
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
    }

    // MARK: Sound

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(String(localized: "sleep_mode_sound", defaultValue: "Ses", comment: "Sleep mode sound section"))

            if !soundManager.isEnabled {
                Toggle(isOn: $soundManager.isEnabled) {
                    Text(String(localized: "sleep_mode_sounds_off", defaultValue: "Ortam sesleri kapalı. Açmak için dokun.", comment: "Ambient sounds are turned off"))
                        .font(.footnote)
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.8))
                }
                .tint(ZenTheme.mysticalViolet)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    soundChip(
                        title: String(localized: "sleep_mode_silence", defaultValue: "Sessiz", comment: "No sound option"),
                        icon: "speaker.slash.fill",
                        isSelected: sleep.soundFileName.isEmpty,
                        isLocked: false
                    ) {
                        sleep.soundFileName = ""
                    }

                    ForEach(AmbientSound.allSounds) { sound in
                        let locked = sound.isPremium && !storeManager.isPremiumUnlocked
                        soundChip(
                            title: sound.name,
                            icon: sound.iconName,
                            isSelected: sleep.soundFileName == sound.fileName,
                            isLocked: locked
                        ) {
                            if locked {
                                showPaywall = true
                            } else {
                                sleep.soundFileName = sound.fileName
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func soundChip(
        title: String,
        icon: String,
        isSelected: Bool,
        isLocked: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.shared.playImpact(style: .light)
            action()
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .frame(width: 52, height: 52)
                        .background(
                            Circle().fill(isSelected ? ZenTheme.mysticalViolet.opacity(0.6) : Color.white.opacity(0.08))
                        )
                        .overlay(
                            Circle().stroke(isSelected ? ZenTheme.lightLavender : Color.clear, lineWidth: 1.5)
                        )

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? ZenTheme.lightLavender : ZenTheme.lightLavender.opacity(0.7))
            .frame(width: 72)
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Timer

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(String(localized: "sleep_mode_timer", defaultValue: "Süre", comment: "Sleep mode timer section"))

            HStack(spacing: 8) {
                ForEach(SleepTimerPlan.durationOptions, id: \.self) { minutes in
                    Button {
                        HapticManager.shared.playImpact(style: .light)
                        sleep.durationMinutes = minutes
                    } label: {
                        Text(String(localized: "sleep_mode_minutes_short", defaultValue: "\(minutes) dk", comment: "Minutes, short"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(sleep.durationMinutes == minutes ? .white : ZenTheme.softPurple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(sleep.durationMinutes == minutes ? ZenTheme.mysticalViolet.opacity(0.7) : Color.white.opacity(0.08))
                            )
                    }
                    .accessibilityAddTraits(sleep.durationMinutes == minutes ? .isSelected : [])
                }
            }
        }
    }

    // MARK: Guide toggle

    private var guideToggle: some View {
        Toggle(isOn: $sleep.breathingGuideEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "sleep_mode_guide", defaultValue: "4-7-8 nefes ışığı", comment: "Sleep mode breathing guide toggle"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ZenTheme.lightLavender)
                Text(String(localized: "sleep_mode_guide_desc", defaultValue: "Karanlıkta yumuşakça büyüyüp küçülen bir ışık, nefesini yavaşlatmana yardım eder.", comment: "Sleep mode breathing guide description"))
                    .font(.system(size: 13))
                    .foregroundColor(ZenTheme.softPurple)
            }
        }
        .tint(ZenTheme.mysticalViolet)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
    }

    private var startButton: some View {
        Button {
            HapticManager.shared.playImpact(style: .medium)
            showGoodNight = false
            showControls = false
            sleep.start()
        } label: {
            HStack {
                Image(systemName: "moon.fill")
                Text(String(localized: "sleep_mode_start", defaultValue: "Uykuya Dal", comment: "Start sleep mode"))
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [ZenTheme.mysticalViolet, ZenTheme.calmBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .padding(.top, 4)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(ZenTheme.softPurple)
            .textCase(.uppercase)
    }

    // MARK: - Running

    private var runningView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if sleep.breathingGuideEnabled, let start = sleep.startDate {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
                    let scale = SleepBreathingGuide.scale(at: context.date.timeIntervalSince(start))
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ZenTheme.mysticalViolet.opacity(0.35),
                                    ZenTheme.deepIndigo.opacity(0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(scale)
                        .accessibilityHidden(true)
                }
            }

            VStack {
                Spacer()

                Text(remainingText)
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.white.opacity(0.22))
                    .padding(.bottom, showControls ? 16 : 56)

                if showControls {
                    Button {
                        sleep.stop()
                    } label: {
                        Label(String(localized: "sleep_mode_stop", defaultValue: "Bitir", comment: "End sleep mode"), systemImage: "stop.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .padding(.bottom, 48)
                    .transition(.opacity)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            revealControls()
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "sleep_mode_running_accessibility", defaultValue: "Uyku modu çalışıyor. \(remainingText)", comment: "Sleep mode running accessibility"))
    }

    private var remainingText: String {
        let minutes = Int(ceil(sleep.remainingSeconds / 60))
        return String(localized: "sleep_mode_remaining", defaultValue: "\(minutes) dk kaldı", comment: "Minutes remaining in sleep mode")
    }

    private func revealControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = true
        }
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showControls = false
                }
            }
        }
    }

    // MARK: - Good night

    private var goodNightView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 44))
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.6))

                Text(String(localized: "sleep_mode_good_night", defaultValue: "İyi geceler", comment: "Good night message"))
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.7))

                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "daily_zen_done", defaultValue: "Tamam", comment: "Done button"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    SleepModeView()
}
