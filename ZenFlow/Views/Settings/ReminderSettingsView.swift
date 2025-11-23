//
//  ReminderSettingsView.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Reminder settings view for meditation notifications
//

import SwiftUI

struct ReminderSettingsView: View {
    // MARK: - State Properties

    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedTime: Date
    @State private var selectedDays: Set<Int>
    @State private var remindersEnabled: Bool
    @State private var streakReminderEnabled: Bool
    @State private var showAuthorizationAlert = false

    // MARK: - Initialization

    init() {
        let manager = NotificationManager.shared
        _selectedTime = State(initialValue: manager.reminderTime)
        _selectedDays = State(initialValue: manager.reminderDays)
        _remindersEnabled = State(initialValue: manager.remindersEnabled)
        _streakReminderEnabled = State(initialValue: manager.streakReminderEnabled)
    }

    // MARK: - Body

    var body: some View {
        List {
            // MARK: - Daily Reminders Section

            Section {
                Toggle("Günlük Hatırlatıcı", isOn: $remindersEnabled)
                    .onChange(of: remindersEnabled) { oldValue, newValue in
                        handleReminderToggle(newValue)
                    }

                if remindersEnabled {
                    DatePicker(
                        "Saat",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: selectedTime) { oldValue, newValue in
                        notificationManager.reminderTime = newValue
                    }
                }
            } header: {
                Text("Meditasyon Hatırlatıcısı")
            } footer: {
                Text("Belirlediğin saatte günlük meditasyon hatırlatıcısı alacaksın.")
            }

            // MARK: - Days Selection Section

            if remindersEnabled {
                Section {
                    ForEach(Weekday.allCases, id: \.self) { weekday in
                        Toggle(weekday.name, isOn: Binding(
                            get: { selectedDays.contains(weekday.rawValue) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDays.insert(weekday.rawValue)
                                } else {
                                    selectedDays.remove(weekday.rawValue)
                                }
                                notificationManager.reminderDays = selectedDays
                            }
                        ))
                    }
                } header: {
                    Text("Hatırlatıcı Günleri")
                } footer: {
                    Text("Hangi günler hatırlatıcı almak istediğini seç.")
                }
            }

            // MARK: - Streak Reminder Section

            Section {
                Toggle("Streak Hatırlatıcısı", isOn: $streakReminderEnabled)
                    .onChange(of: streakReminderEnabled) { oldValue, newValue in
                        handleStreakReminderToggle(newValue)
                    }
            } header: {
                Text("Streak Koruması")
            } footer: {
                Text("Her akşam saat 20:00'de meditasyon yapmadıysan hatırlatıcı alacaksın.")
            }

            // MARK: - Preview Messages Section

            if remindersEnabled || streakReminderEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Örnek Mesajlar:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        ForEach(sampleMessages, id: \.self) { message in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "bell.fill")
                                    .font(.caption)
                                    .foregroundColor(ZenTheme.calmBlue)
                                    .padding(.top, 2)

                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Motivasyon Mesajları")
                }
            }

            // MARK: - Test Section

            if notificationManager.isAuthorized && (remindersEnabled || streakReminderEnabled) {
                Section {
                    Button(action: sendTestNotification) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                            Text("Test Bildirimi Gönder")
                                .foregroundColor(.primary)
                        }
                    }
                } footer: {
                    Text("Bildirim ayarlarını test etmek için bir deneme bildirimi gönder.")
                }
            }
        }
        .navigationTitle("Hatırlatıcılar")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Bildirim İzni Gerekli", isPresented: $showAuthorizationAlert) {
            Button("Ayarlara Git") {
                openAppSettings()
            }
            Button("İptal", role: .cancel) {
                remindersEnabled = false
                streakReminderEnabled = false
            }
        } message: {
            Text("Hatırlatıcı almak için ZenFlow'a bildirim izni vermelisin. Ayarlar'dan izni etkinleştirebilirsin.")
        }
    }

    // MARK: - Helper Methods

    private var sampleMessages: [String] {
        [
            "Bugün kendine 5 dakika ayır 🧘",
            "Nefes almayı unutma, streak'in devam etsin! 🔥",
            "Huzurlu bir gün için kısa bir mola ☮️"
        ]
    }

    private func handleReminderToggle(_ isEnabled: Bool) {
        if isEnabled && !notificationManager.isAuthorized {
            notificationManager.requestAuthorization { granted in
                if granted {
                    notificationManager.remindersEnabled = true
                } else {
                    remindersEnabled = false
                    showAuthorizationAlert = true
                }
            }
        } else {
            notificationManager.remindersEnabled = isEnabled
        }
    }

    private func handleStreakReminderToggle(_ isEnabled: Bool) {
        if isEnabled && !notificationManager.isAuthorized {
            notificationManager.requestAuthorization { granted in
                if granted {
                    notificationManager.streakReminderEnabled = true
                } else {
                    streakReminderEnabled = false
                    showAuthorizationAlert = true
                }
            }
        } else {
            notificationManager.streakReminderEnabled = isEnabled
        }
    }

    private func sendTestNotification() {
        notificationManager.sendImmediateNotification(
            title: "ZenFlow Test 🧘",
            body: "Harika! Bildirimler çalışıyor. Artık meditasyonlarını kaçırmayacaksın."
        )

        HapticManager.shared.playNotification(type: .success)
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Weekday Enum

enum Weekday: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var name: String {
        switch self {
        case .sunday: return "Pazar"
        case .monday: return "Pazartesi"
        case .tuesday: return "Salı"
        case .wednesday: return "Çarşamba"
        case .thursday: return "Perşembe"
        case .friday: return "Cuma"
        case .saturday: return "Cumartesi"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReminderSettingsView()
    }
}
