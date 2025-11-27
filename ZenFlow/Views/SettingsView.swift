//
//  SettingsView.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Main settings view for ZenFlow app
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Environment Objects (Performance Optimization)
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var soundManager: AmbientSoundManager

    // MARK: - State Properties
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("hapticIntensity") private var hapticIntensity = 0.7
    @State private var showResetAlert = false
    @State private var showResetSuccess = false

    // MARK: - Computed Properties

    private var intensityLabel: String {
        let percentage = Int(hapticIntensity * 100)
        if hapticIntensity <= 0.5 {
            return String(localized: "settings.haptic.intensity.light", defaultValue: "Hafif (\(percentage)%)", comment: "Light intensity label")
        } else if hapticIntensity <= 0.8 {
            return String(localized: "settings.haptic.intensity.medium", defaultValue: "Orta (\(percentage)%)", comment: "Medium intensity label")
        } else {
            return String(localized: "settings.haptic.intensity.strong", defaultValue: "Güçlü (\(percentage)%)", comment: "Strong intensity label")
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Notifications Section

                Section {
                    NavigationLink(destination: ReminderSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text(String(localized: "settings_reminders", defaultValue: "Hatırlatıcılar", comment: "Reminders setting"))
                        }
                    }
                } header: {
                    Text(String(localized: "settings_notifications_section", defaultValue: "Bildirimler", comment: "Notifications section header"))
                }

                // MARK: - Audio Settings Section

                Section {
                    Toggle(isOn: $soundManager.isEnabled) {
                        HStack {
                            Image(systemName: soundManager.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text(String(localized: "settings_ambient_sounds", defaultValue: "Ortam Sesleri", comment: "Ambient sounds setting"))
                        }
                    }
                    .onChange(of: soundManager.isEnabled) { oldValue, newValue in
                        HapticManager.shared.playImpact(style: .light)
                    }

                    if soundManager.isEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(ZenTheme.calmBlue)
                                    .frame(width: 28)
                                Text(String(localized: "settings_volume", defaultValue: "Ses Seviyesi", comment: "Volume label"))
                                Spacer()
                                Text("\(Int(soundManager.volume * 100))%")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }

                            Slider(value: Binding(
                                get: { Double(soundManager.volume) },
                                set: { soundManager.volume = Float($0) }
                            ), in: 0...1, step: 0.1)
                                .tint(ZenTheme.calmBlue)
                        }
                    }
                } header: {
                    Text(String(localized: "settings_audio_section", defaultValue: "Ses Ayarları", comment: "Audio settings section header"))
                } footer: {
                    Text(String(localized: "settings_audio_footer", defaultValue: "Meditasyon sırasında çalacak ortam seslerini yönet.", comment: "Audio settings footer"))
                }

                // MARK: - Haptic Settings Section

                Section {
                    Toggle(isOn: $hapticsEnabled) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text(String(localized: "settings_haptic_feedback", defaultValue: "Dokunsal Geri Bildirim", comment: "Haptic feedback setting"))
                        }
                    }
                    .onChange(of: hapticsEnabled) { oldValue, newValue in
                        handleHapticsToggle(newValue)
                    }
                    .disabled(!hapticManager.isHapticsAvailable)

                    if hapticsEnabled && hapticManager.isHapticsAvailable {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(ZenTheme.calmBlue)
                                    .frame(width: 28)
                                Text(String(localized: "settings.haptic.intensity", defaultValue: "Titreşim Şiddeti", comment: "Haptic intensity label"))
                                Spacer()
                                Text(intensityLabel)
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }

                            Slider(value: $hapticIntensity, in: 0.3...1.0, step: 0.1)
                                .tint(ZenTheme.calmBlue)
                                .onChange(of: hapticIntensity) { oldValue, newValue in
                                    // Play demo haptic at new intensity level
                                    hapticManager.playIntensityDemo()
                                }
                        }
                    }
                } header: {
                    Text(String(localized: "settings_haptic_section", defaultValue: "Dokunsal Ayarlar", comment: "Haptic settings section header"))
                } footer: {
                    if !hapticManager.isHapticsAvailable {
                        Text(String(localized: "settings_haptic_not_supported", defaultValue: "Bu cihaz dokunsal geri bildirimi desteklemiyor.", comment: "Haptic not supported message"))
                    } else if hapticsEnabled {
                        Text(String(localized: "settings.haptic.enabled.description", defaultValue: "Nefes egzersizleri sırasında animasyonlarla senkronize titreşim geri bildirimi. Şiddet ayarı tüm titreşimleri etkiler.", comment: "Haptic enabled description"))
                    } else {
                        Text(String(localized: "settings.haptic.disabled.description", defaultValue: "Nefes egzersizleri sırasında titreşim geri bildirimi kapalı.", comment: "Haptic disabled description"))
                    }
                }

                // MARK: - Achievements Section

                Section {
                    NavigationLink(destination: BadgesView()) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text(String(localized: "settings_badges", defaultValue: "Rozetler", comment: "Badges section"))
                        }
                    }

                    NavigationLink(destination: StatsView()) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text(String(localized: "settings_statistics", defaultValue: "İstatistikler", comment: "Statistics section"))
                        }
                    }
                } header: {
                    Text(String(localized: "settings_achievements_section", defaultValue: "Başarılar & İstatistikler", comment: "Achievements and statistics section header"))
                }

                // MARK: - Data Management Section

                Section {
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .frame(width: 28)
                            Text(String(localized: "settings_reset_all_data", defaultValue: "Tüm Verileri Sıfırla", comment: "Reset all data button"))
                        }
                    }
                } header: {
                    Text(String(localized: "settings_data_management_section", defaultValue: "Veri Yönetimi", comment: "Data management section header"))
                } footer: {
                    Text(String(localized: "settings_reset_data_footer", defaultValue: "Bu işlem tüm meditasyon geçmişini, streak'leri ve ayarları siler. Bu işlem geri alınamaz.", comment: "Reset data footer warning"))
                }

                // MARK: - About Section

                Section {
                    HStack {
                        Text(String(localized: "settings_version", defaultValue: "Versiyon", comment: "Version label"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ContactView()) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text(String(localized: "settings_contact_feedback", defaultValue: "İletişim & Geri Bildirim", comment: "Contact and feedback menu item"))
                        }
                    }

                    Link(destination: URL(string: "https://zenflow.app")!) {
                        HStack {
                            Image(systemName: "safari.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text(String(localized: "settings_website", defaultValue: "Website", comment: "Website link label"))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(String(localized: "settings_about_section", defaultValue: "Hakkında", comment: "About section header"))
                }
            }
            .navigationTitle(Text(String(localized: "settings_title", defaultValue: "Ayarlar", comment: "Settings tab bar item")))
            .navigationBarTitleDisplayMode(.large)
            .alert(Text(String(localized: "settings_delete_all_data_title", defaultValue: "Tüm Verileri Sil", comment: "Delete all data alert title")), isPresented: $showResetAlert) {
                Button(role: .cancel) { } label: {
                    Text(String(localized: "settings_cancel", defaultValue: "İptal", comment: "Cancel button"))
                }
                Button(role: .destructive) {
                    resetAllData()
                } label: {
                    Text(String(localized: "settings_delete", defaultValue: "Sil", comment: "Delete button"))
                }
            } message: {
                Text(String(localized: "settings_delete_confirmation", defaultValue: "Bu işlem tüm meditasyon geçmişini, streak'leri, odaklanma seanslarını ve ayarları kalıcı olarak silecek. Devam etmek istediğinden emin misin?", comment: "Delete all data confirmation message"))
            }
            .alert(Text(String(localized: "settings_data_deleted_title", defaultValue: "Veriler Silindi", comment: "Data deleted alert title")), isPresented: $showResetSuccess) {
                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "settings_ok", defaultValue: "Tamam", comment: "OK button"))
                }
            } message: {
                Text(String(localized: "settings_data_reset_success", defaultValue: "Tüm veriler başarıyla sıfırlandı.", comment: "Data reset success message"))
            }
        }
    }

    // MARK: - Helper Methods

    private func handleHapticsToggle(_ isEnabled: Bool) {
        if isEnabled {
            hapticManager.startEngine()
            // Demo haptic pattern when enabled: medium followed by light
            HapticManager.shared.playImpact(style: .medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                HapticManager.shared.playImpact(style: .light)
            }
        } else {
            // Final gentle tap when disabling
            HapticManager.shared.playImpact(style: .light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hapticManager.stopEngine()
            }
        }
    }

    private func resetAllData() {
        // Reset LocalDataManager
        LocalDataManager.shared.resetAllData()

        // Reset NotificationManager settings
        NotificationManager.shared.remindersEnabled = false
        NotificationManager.shared.streakReminderEnabled = false

        // Stop all sounds
        soundManager.stopAllSounds()

        // Show success alert
        showResetSuccess = true

        // Haptic feedback
        HapticManager.shared.playNotification(type: .warning)
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    // MARK: - Environment Objects (Performance Optimization)
    @EnvironmentObject var dataManager: LocalDataManager

    var body: some View {
        List {
            // Meditation Statistics
            Section {
                StatisticRow(
                    icon: "figure.mind.and.body",
                    title: String(localized: "Toplam Seans", comment: "Total sessions label"),
                    value: "\(dataManager.totalSessions)"
                )

                StatisticRow(
                    icon: "clock.fill",
                    title: String(localized: "Toplam Süre", comment: "Total duration label"),
                    value: formatDuration(dataManager.totalMinutes)
                )

                StatisticRow(
                    icon: "flame.fill",
                    title: String(localized: "Mevcut Seri", comment: "Current streak label"),
                    value: String(localized: "\(dataManager.currentStreak) gün", comment: "Days count")
                )

                StatisticRow(
                    icon: "trophy.fill",
                    title: String(localized: "En Uzun Seri", comment: "Longest streak label"),
                    value: String(localized: "\(dataManager.longestStreak) gün", comment: "Days count")
                )
            } header: {
                Text(String(localized: "settings_meditation_statistics_section", defaultValue: "Meditasyon İstatistikleri", comment: "Meditation statistics section header"))
            }

            // Focus Session Statistics
            Section {
                StatisticRow(
                    icon: "brain.head.profile",
                    title: String(localized: "Toplam Odaklanma Seansı", comment: "Total focus sessions label"),
                    value: "\(dataManager.totalFocusSessions)"
                )

                StatisticRow(
                    icon: "calendar",
                    title: String(localized: "Bugünkü Seanslar", comment: "Today's sessions label"),
                    value: "\(dataManager.todayFocusSessions)"
                )
            } header: {
                Text(String(localized: "settings_pomodoro_statistics_section", defaultValue: "Pomodoro İstatistikleri", comment: "Pomodoro statistics section header"))
            }

            // Last Session
            if let lastDate = dataManager.lastSessionDate {
                Section {
                    StatisticRow(
                        icon: "calendar.badge.clock",
                        title: String(localized: "Son Meditasyon", comment: "Last meditation label"),
                        value: formatDate(lastDate)
                    )

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(dataManager.isStreakActive() ? .green : .red)
                            .frame(width: 28)
                        Text(String(localized: "settings_streak_status", defaultValue: "Seri Durumu", comment: "Streak status label"))
                        Spacer()
                        Group {
                            if dataManager.isStreakActive() {
                                Text(String(localized: "settings_active_status", defaultValue: "Aktif", comment: "Active status"))
                            } else {
                                Text(String(localized: "settings_broken_status", defaultValue: "Kırıldı", comment: "Broken status"))
                            }
                        }
                        .foregroundColor(dataManager.isStreakActive() ? .green : .red)
                    }
                } header: {
                    Text(String(localized: "settings_status_section", defaultValue: "Durum", comment: "Status section header"))
                }
            }
        }
        .navigationTitle(Text(String(localized: "settings_statistics_title", defaultValue: "İstatistikler", comment: "Statistics page title")))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return String(localized: "\(hours)s \(mins)d", comment: "Hours and minutes format (short)")
        } else {
            return String(localized: "\(mins) dakika", comment: "Minutes only format")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Contact View

struct ContactView: View {
    @State private var feedbackText = ""
    @State private var showSubmitAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: "settings_your_feedback_title", defaultValue: "Geri Bildiriminiz", comment: "Your feedback section title"))
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(String(localized: "settings_feedback_description", defaultValue: "ZenFlow'u daha iyi hale getirmemize yardımcı olun. Önerileriniz, hata raporlarınız veya genel geri bildirimlerinizi bizimle paylaşın.", comment: "Feedback description text"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    Button(action: {
                        submitFeedback()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "paperplane.fill")
                            Text(String(localized: "settings_send", defaultValue: "Gönder", comment: "Send feedback button"))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(feedbackText.isEmpty ? Color.gray.opacity(0.3) : ZenTheme.calmBlue)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(feedbackText.isEmpty)
                }
                .padding(.vertical, 8)
            } header: {
                Text(String(localized: "settings_feedback_section", defaultValue: "Geri Bildirim", comment: "Feedback section header"))
            } footer: {
                Text(String(localized: "settings_feedback_footer", defaultValue: "Geri bildiriminiz doğrudan geliştirme ekibine iletilecektir.", comment: "Feedback footer text"))
            }

            Section {
                Link(destination: URL(string: "mailto:contact@zenflow.app")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(ZenTheme.calmBlue)
                            .frame(width: 28)
                        Text(String(localized: "settings_email", defaultValue: "E-posta", comment: "Email contact option"))
                        Spacer()
                        Text("contact@zenflow.app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: URL(string: "https://twitter.com/zenflowapp")!) {
                    HStack {
                        Image(systemName: "at")
                            .foregroundColor(ZenTheme.calmBlue)
                            .frame(width: 28)
                        Text(String(localized: "settings_twitter", defaultValue: "Twitter", comment: "Twitter contact option"))
                        Spacer()
                        Text("@zenflowapp")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "settings_contact_channels_section", defaultValue: "İletişim Kanalları", comment: "Contact channels section header"))
            }
        }
        .navigationTitle(Text(String(localized: "settings_contact_title", defaultValue: "İletişim", comment: "Contact page title")))
        .navigationBarTitleDisplayMode(.inline)
        .alert(Text(String(localized: "settings_thank_you_title", defaultValue: "Teşekkürler!", comment: "Thank you alert title")), isPresented: $showSubmitAlert) {
            Button {
                feedbackText = ""
                dismiss()
            } label: {
                Text(String(localized: "settings_ok", defaultValue: "Tamam", comment: "OK button"))
            }
        } message: {
            Text(String(localized: "settings_feedback_success_message", defaultValue: "Geri bildiriminiz başarıyla gönderildi. Katkınız için teşekkür ederiz!", comment: "Feedback success message"))
        }
    }

    private func submitFeedback() {
        // In a real implementation, this would send the feedback to a backend
        // For now, we'll just show a success message
        HapticManager.shared.playNotification(type: .success)
        showSubmitAlert = true
    }
}

// MARK: - Statistic Row Component

struct StatisticRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ZenTheme.calmBlue)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
}

#Preview("Statistics") {
    NavigationStack {
        StatisticsView()
    }
}
