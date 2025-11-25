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

    // MARK: - State Properties

    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = AmbientSoundManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var hapticsEnabled = true
    @State private var showResetAlert = false
    @State private var showResetSuccess = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // MARK: - General Section

                Section {
                    Picker(selection: $languageManager.currentLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("Dil", comment: "Language setting label")
                        }
                    }
                    .onChange(of: languageManager.currentLanguage) { _, _ in
                        HapticManager.shared.playImpact(style: .light)
                    }
                } header: {
                    Text("Genel", comment: "General settings section header")
                }

                // MARK: - Notifications Section

                Section {
                    NavigationLink(destination: ReminderSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("Hatırlatıcılar", comment: "Reminders setting")
                        }
                    }
                } header: {
                    Text("Bildirimler", comment: "Notifications section header")
                }

                // MARK: - Audio Settings Section

                Section {
                    Toggle(isOn: $soundManager.isEnabled) {
                        HStack {
                            Image(systemName: soundManager.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("Ortam Sesleri", comment: "Ambient sounds setting")
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
                                Text("Ses Seviyesi", comment: "Volume label")
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
                    Text("Ses Ayarları", comment: "Audio settings section header")
                } footer: {
                    Text("Meditasyon sırasında çalacak ortam seslerini yönet.", comment: "Audio settings footer")
                }

                // MARK: - Haptic Settings Section

                Section {
                    Toggle(isOn: $hapticsEnabled) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("Dokunsal Geri Bildirim", comment: "Haptic feedback setting")
                        }
                    }
                    .onChange(of: hapticsEnabled) { oldValue, newValue in
                        handleHapticsToggle(newValue)
                    }
                    .disabled(!hapticManager.isHapticsAvailable)
                } header: {
                    Text("Dokunsal Ayarlar", comment: "Haptic settings section header")
                } footer: {
                    if !hapticManager.isHapticsAvailable {
                        Text("Bu cihaz dokunsal geri bildirimi desteklemiyor.", comment: "Haptic not supported message")
                    } else {
                        Text("Uygulama içi titreşim ve dokunsal geri bildirimi kontrol et.", comment: "Haptic settings footer")
                    }
                }

                // MARK: - Achievements Section

                Section {
                    NavigationLink(destination: BadgesView()) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("Rozetler", comment: "Badges section")
                        }
                    }

                    NavigationLink(destination: StatsView()) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("İstatistikler", comment: "Statistics section")
                        }
                    }
                } header: {
                    Text("Başarılar & İstatistikler", comment: "Achievements and statistics section header")
                }

                // MARK: - Data Management Section

                Section {
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .frame(width: 28)
                            Text("Tüm Verileri Sıfırla", comment: "Reset all data button")
                        }
                    }
                } header: {
                    Text("Veri Yönetimi", comment: "Data management section header")
                } footer: {
                    Text("Bu işlem tüm meditasyon geçmişini, streak'leri ve ayarları siler. Bu işlem geri alınamaz.", comment: "Reset data footer warning")
                }

                // MARK: - About Section

                Section {
                    HStack {
                        Text("Versiyon", comment: "Version label")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ContactView()) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("İletişim & Geri Bildirim", comment: "Contact and feedback menu item")
                        }
                    }

                    Link(destination: URL(string: "https://zenflow.app")!) {
                        HStack {
                            Image(systemName: "safari.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("Website", comment: "Website link label")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Hakkında", comment: "About section header")
                }
            }
            .navigationTitle(Text("Ayarlar", comment: "Settings tab bar item"))
            .navigationBarTitleDisplayMode(.large)
            .alert(Text("Tüm Verileri Sil", comment: "Delete all data alert title"), isPresented: $showResetAlert) {
                Button(role: .cancel) { } label: {
                    Text("İptal", comment: "Cancel button")
                }
                Button(role: .destructive) {
                    resetAllData()
                } label: {
                    Text("Sil", comment: "Delete button")
                }
            } message: {
                Text("Bu işlem tüm meditasyon geçmişini, streak'leri, odaklanma seanslarını ve ayarları kalıcı olarak silecek. Devam etmek istediğinden emin misin?", comment: "Delete all data confirmation message")
            }
            .alert(Text("Veriler Silindi", comment: "Data deleted alert title"), isPresented: $showResetSuccess) {
                Button {
                    dismiss()
                } label: {
                    Text("Tamam", comment: "OK button")
                }
            } message: {
                Text("Tüm veriler başarıyla sıfırlandı.", comment: "Data reset success message")
            }
        }
    }

    // MARK: - Helper Methods

    private func handleHapticsToggle(_ isEnabled: Bool) {
        if isEnabled {
            hapticManager.startEngine()
            HapticManager.shared.playImpact(style: .medium)
        } else {
            hapticManager.stopEngine()
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
    @StateObject private var dataManager = LocalDataManager.shared

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
                Text("Meditasyon İstatistikleri", comment: "Meditation statistics section header")
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
                Text("Pomodoro İstatistikleri", comment: "Pomodoro statistics section header")
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
                        Text("Seri Durumu", comment: "Streak status label")
                        Spacer()
                        Group {
                            if dataManager.isStreakActive() {
                                Text("Aktif", comment: "Active status")
                            } else {
                                Text("Kırıldı", comment: "Broken status")
                            }
                        }
                        .foregroundColor(dataManager.isStreakActive() ? .green : .red)
                    }
                } header: {
                    Text("Durum", comment: "Status section header")
                }
            }
        }
        .navigationTitle(Text("İstatistikler", comment: "Statistics page title"))
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
                    Text("Geri Bildiriminiz", comment: "Your feedback section title")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("ZenFlow'u daha iyi hale getirmemize yardımcı olun. Önerileriniz, hata raporlarınız veya genel geri bildirimlerinizi bizimle paylaşın.", comment: "Feedback description text")
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
                            Text("Gönder", comment: "Send feedback button")
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
                Text("Geri Bildirim", comment: "Feedback section header")
            } footer: {
                Text("Geri bildiriminiz doğrudan geliştirme ekibine iletilecektir.", comment: "Feedback footer text")
            }

            Section {
                Link(destination: URL(string: "mailto:contact@zenflow.app")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(ZenTheme.calmBlue)
                            .frame(width: 28)
                        Text("E-posta", comment: "Email contact option")
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
                        Text("Twitter", comment: "Twitter contact option")
                        Spacer()
                        Text("@zenflowapp")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("İletişim Kanalları", comment: "Contact channels section header")
            }
        }
        .navigationTitle(Text("İletişim", comment: "Contact page title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(Text("Teşekkürler!", comment: "Thank you alert title"), isPresented: $showSubmitAlert) {
            Button {
                feedbackText = ""
                dismiss()
            } label: {
                Text("Tamam", comment: "OK button")
            }
        } message: {
            Text("Geri bildiriminiz başarıyla gönderildi. Katkınız için teşekkür ederiz!", comment: "Feedback success message")
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
