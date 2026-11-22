//
//  FocusSettingsView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Customize the Pomodoro lengths (Premium). Free users see the classic
//  rhythm and a way to unlock the controls.
//

import SwiftUI

struct FocusSettingsView: View {
    @ObservedObject private var store = FocusSettingsStore.shared
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var showPaywall = false

    private var isPremium: Bool { storeManager.isPremiumUnlocked }

    /// What the steppers show: the user's values for premium, the classic ones otherwise
    private var shown: FocusSettings {
        isPremium ? store.settings : .defaults
    }

    var body: some View {
        List {
            if !isPremium {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(ZenTheme.lightLavender)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "focus_settings_locked_title", defaultValue: "Süreleri özelleştir", comment: "Locked focus settings title"))
                                    .font(.headline)
                                Text(String(localized: "focus_settings_locked_desc", defaultValue: "Klasik 25/5/15 ritmini Premium ile değiştirebilirsin.", comment: "Locked focus settings description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                stepper(
                    String(localized: "focus_settings_work", defaultValue: "Odaklanma", comment: "Work length"),
                    keyPath: \.workMinutes,
                    range: FocusSettings.workRange
                )
                stepper(
                    String(localized: "focus_settings_short_break", defaultValue: "Kısa mola", comment: "Short break length"),
                    keyPath: \.shortBreakMinutes,
                    range: FocusSettings.shortBreakRange
                )
                stepper(
                    String(localized: "focus_settings_long_break", defaultValue: "Uzun mola", comment: "Long break length"),
                    keyPath: \.longBreakMinutes,
                    range: FocusSettings.longBreakRange
                )

                Stepper(
                    value: Binding(
                        get: { shown.sessionsBeforeLongBreak },
                        set: { newValue in
                            var updated = store.settings
                            updated.sessionsBeforeLongBreak = newValue
                            store.update(updated)
                        }
                    ),
                    in: FocusSettings.sessionsBeforeLongBreakRange
                ) {
                    HStack {
                        Text(String(localized: "focus_settings_sessions", defaultValue: "Uzun moladan önce", comment: "Sessions before a long break"))
                        Spacer()
                        Text(String(localized: "focus_settings_sessions_value", defaultValue: "\(shown.sessionsBeforeLongBreak) seans", comment: "Number of sessions"))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!isPremium)
            } header: {
                Text(String(localized: "focus_settings_lengths_header", defaultValue: "Süreler (dakika)", comment: "Lengths section header"))
            } footer: {
                Text(String(localized: "focus_settings_footer", defaultValue: "Değişiklikler bir sonraki zamanlayıcıdan itibaren geçerli olur.", comment: "Focus settings footer"))
            }

            if isPremium {
                Section {
                    Button(role: .destructive) {
                        store.resetToDefaults()
                    } label: {
                        Text(String(localized: "focus_settings_reset", defaultValue: "Klasik 25/5/15'e dön", comment: "Reset focus lengths"))
                    }
                    .disabled(store.settings == .defaults)
                }
            }
        }
        .navigationTitle(String(localized: "settings_focus_lengths", defaultValue: "Odaklanma Süreleri", comment: "Focus lengths settings row"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }

    private func stepper(_ title: String, keyPath: WritableKeyPath<FocusSettings, Int>, range: ClosedRange<Int>) -> some View {
        Stepper(
            value: Binding(
                get: { shown[keyPath: keyPath] },
                set: { newValue in
                    var updated = store.settings
                    updated[keyPath: keyPath] = newValue
                    store.update(updated)
                }
            ),
            in: range
        ) {
            HStack {
                Text(title)
                Spacer()
                Text(String(localized: "sleep_mode_minutes_short", defaultValue: "\(shown[keyPath: keyPath]) dk", comment: "Minutes, short"))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
        .disabled(!isPremium)
    }
}
