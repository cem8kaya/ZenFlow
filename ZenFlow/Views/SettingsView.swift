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
    // MARK: - State Properties

    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = AmbientSoundManager.shared
    @State private var hapticsEnabled = true
    @State private var soundEnabled = true
    @State private var soundVolume: Double = 0.5
    @State private var showResetAlert = false
    @State private var showResetSuccess = false
    @Environment(\.dismiss) private var dismiss

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
                            Text("Hatırlatıcılar")
                        }
                    }
                } header: {
                    Text("Bildirimler")
                }

                // MARK: - Audio Settings Section

                Section {
                    Toggle(isOn: $soundEnabled) {
                        HStack {
                            Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("Ortam Sesleri")
                        }
                    }
                    .onChange(of: soundEnabled) { oldValue, newValue in
                        handleSoundToggle(newValue)
                    }

                    if soundEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(ZenTheme.calmBlue)
                                    .frame(width: 28)
                                Text("Ses Seviyesi")
                                Spacer()
                                Text("\(Int(soundVolume * 100))%")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }

                            Slider(value: $soundVolume, in: 0...1, step: 0.1)
                                .tint(ZenTheme.calmBlue)
                                .onChange(of: soundVolume) { oldValue, newValue in
                                    soundManager.volume = Float(newValue)
                                }
                        }
                    }
                } header: {
                    Text("Ses Ayarları")
                } footer: {
                    Text("Meditasyon sırasında çalacak ortam seslerini yönet.")
                }

                // MARK: - Haptic Settings Section

                Section {
                    Toggle(isOn: $hapticsEnabled) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("Dokunsal Geri Bildirim")
                        }
                    }
                    .onChange(of: hapticsEnabled) { oldValue, newValue in
                        handleHapticsToggle(newValue)
                    }
                    .disabled(!hapticManager.isHapticsAvailable)
                } header: {
                    Text("Dokunsal Ayarlar")
                } footer: {
                    if !hapticManager.isHapticsAvailable {
                        Text("Bu cihaz dokunsal geri bildirimi desteklemiyor.")
                    } else {
                        Text("Uygulama içi titreşim ve dokunsal geri bildirimi kontrol et.")
                    }
                }

                // MARK: - Statistics Section

                Section {
                    NavigationLink(destination: StatisticsView()) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("İstatistikler")
                        }
                    }
                } header: {
                    Text("Veriler")
                }

                // MARK: - Data Management Section

                Section {
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .frame(width: 28)
                            Text("Tüm Verileri Sıfırla")
                        }
                    }
                } header: {
                    Text("Veri Yönetimi")
                } footer: {
                    Text("Bu işlem tüm meditasyon geçmişini, streak'leri ve ayarları siler. Bu işlem geri alınamaz.")
                }

                // MARK: - About Section

                Section {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/cem8kaya/ZenFlow")!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(ZenTheme.calmBlue)
                                .frame(width: 28)
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Hakkında")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .alert("Tüm Verileri Sil", isPresented: $showResetAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Bu işlem tüm meditasyon geçmişini, streak'leri, odaklanma seanslarını ve ayarları kalıcı olarak silecek. Devam etmek istediğinden emin misin?")
            }
            .alert("Veriler Silindi", isPresented: $showResetSuccess) {
                Button("Tamam") {
                    dismiss()
                }
            } message: {
                Text("Tüm veriler başarıyla sıfırlandı.")
            }
        }
    }

    // MARK: - Helper Methods

    private func handleSoundToggle(_ isEnabled: Bool) {
        if !isEnabled {
            soundManager.stopAllSounds()
        }
        HapticManager.shared.playImpact(style: .light)
    }

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
                    title: "Toplam Seans",
                    value: "\(dataManager.totalSessions)"
                )

                StatisticRow(
                    icon: "clock.fill",
                    title: "Toplam Süre",
                    value: formatDuration(dataManager.totalMinutes)
                )

                StatisticRow(
                    icon: "flame.fill",
                    title: "Mevcut Seri",
                    value: "\(dataManager.currentStreak) gün"
                )

                StatisticRow(
                    icon: "trophy.fill",
                    title: "En Uzun Seri",
                    value: "\(dataManager.longestStreak) gün"
                )
            } header: {
                Text("Meditasyon İstatistikleri")
            }

            // Focus Session Statistics
            Section {
                StatisticRow(
                    icon: "brain.head.profile",
                    title: "Toplam Odaklanma Seansı",
                    value: "\(dataManager.totalFocusSessions)"
                )

                StatisticRow(
                    icon: "calendar",
                    title: "Bugünkü Seanslar",
                    value: "\(dataManager.todayFocusSessions)"
                )
            } header: {
                Text("Pomodoro İstatistikleri")
            }

            // Last Session
            if let lastDate = dataManager.lastSessionDate {
                Section {
                    StatisticRow(
                        icon: "calendar.badge.clock",
                        title: "Son Meditasyon",
                        value: formatDate(lastDate)
                    )

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(dataManager.isStreakActive() ? .green : .red)
                            .frame(width: 28)
                        Text("Seri Durumu")
                        Spacer()
                        Text(dataManager.isStreakActive() ? "Aktif" : "Kırıldı")
                            .foregroundColor(dataManager.isStreakActive() ? .green : .red)
                    }
                } header: {
                    Text("Durum")
                }
            }
        }
        .navigationTitle("İstatistikler")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)s \(mins)d"
        } else {
            return "\(mins) dakika"
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
