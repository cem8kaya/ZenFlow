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
    // MARK: - Environment Objects (Performance Optimization)
    @EnvironmentObject var notificationManager: NotificationManager

    // MARK: - State Properties
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
                if #available(iOS 17.0, *) {
                    Toggle(isOn: $remindersEnabled) {
                        Text(String(localized: "reminder_daily_toggle", defaultValue: "Günlük Hatırlatıcı", comment: "Daily reminder toggle"))
                    }
                    .onChange(of: remindersEnabled) { oldValue, newValue in
                        handleReminderToggle(newValue)
                    }
                } else {
                    // Fallback on earlier versions
                }

                if remindersEnabled {
                    if #available(iOS 17.0, *) {
                        DatePicker(
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        ) {
                            Text(String(localized: "reminder_time_picker", defaultValue: "Saat", comment: "Time picker label"))
                        }
                        .onChange(of: selectedTime) { oldValue, newValue in
                            notificationManager.reminderTime = newValue
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                }
            } header: {
                Text(String(localized: "reminder_meditation_header", defaultValue: "Meditasyon Hatırlatıcısı", comment: "Meditation reminder section header"))
            } footer: {
                Text(String(localized: "reminder_meditation_footer", defaultValue: "Belirlediğin saatte günlük meditasyon hatırlatıcısı alacaksın.", comment: "Meditation reminder footer"))
            }

            // MARK: - Days Selection Section

            if remindersEnabled {
                Section {
                    ForEach(Weekday.allCases, id: \.self) { weekday in
                        Toggle(isOn: Binding(
                            get: { selectedDays.contains(weekday.rawValue) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDays.insert(weekday.rawValue)
                                } else {
                                    selectedDays.remove(weekday.rawValue)
                                }
                                notificationManager.reminderDays = selectedDays
                            }
                        )) {
                            Text(weekday.localizedName)
                        }
                    }
                } header: {
                    Text(String(localized: "reminder_days_header", defaultValue: "Hatırlatıcı Günleri", comment: "Reminder days section header"))
                } footer: {
                    Text(String(localized: "reminder_days_footer", defaultValue: "Hangi günler hatırlatıcı almak istediğini seç.", comment: "Reminder days footer"))
                }
            }

            // MARK: - Streak Reminder Section

            Section {
                if #available(iOS 17.0, *) {
                    Toggle(isOn: $streakReminderEnabled) {
                        Text(String(localized: "reminder_streak_toggle", defaultValue: "Streak Hatırlatıcısı", comment: "Streak reminder toggle"))
                    }
                    .onChange(of: streakReminderEnabled) { oldValue, newValue in
                        handleStreakReminderToggle(newValue)
                    }
                } else {
                    // Fallback on earlier versions
                }
            } header: {
                Text(String(localized: "reminder_streak_header", defaultValue: "Streak Koruması", comment: "Streak protection section header"))
            } footer: {
                Text(String(localized: "reminder_streak_footer", defaultValue: "Her akşam saat 20:00'de meditasyon yapmadıysan hatırlatıcı alacaksın.", comment: "Streak reminder footer"))
            }

            // MARK: - Preview Messages Section

            if remindersEnabled || streakReminderEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "reminder_sample_messages", defaultValue: "Örnek Mesajlar:", comment: "Sample messages label"))
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
                    Text(String(localized: "reminder_motivation_header", defaultValue: "Motivasyon Mesajları", comment: "Motivation messages section header"))
                }
            }

            // MARK: - Test Section

            if notificationManager.isAuthorized && (remindersEnabled || streakReminderEnabled) {
                Section {
                    Button(action: sendTestNotification) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(ZenTheme.calmBlue)
                            Text(String(localized: "reminder_test_notification", defaultValue: "Test Bildirimi Gönder", comment: "Send test notification button"))
                                .foregroundColor(.primary)
                        }
                    }
                } footer: {
                    Text(String(localized: "reminder_test_footer", defaultValue: "Bildirim ayarlarını test etmek için bir deneme bildirimi gönder.", comment: "Test notification footer"))
                }
            }
        }
        .navigationTitle(Text(String(localized: "settings_reminders", defaultValue: "Hatırlatıcılar", comment: "Reminders page title")))
        .navigationBarTitleDisplayMode(.inline)
        .alert(Text(String(localized: "reminder_permission_title", defaultValue: "Bildirim İzni Gerekli", comment: "Notification permission required alert title")), isPresented: $showAuthorizationAlert) {
            Button {
                openAppSettings()
            } label: {
                Text(String(localized: "reminder_go_to_settings", defaultValue: "Ayarlara Git", comment: "Go to settings button"))
            }
            Button(role: .cancel) {
                remindersEnabled = false
                streakReminderEnabled = false
            } label: {
                Text(String(localized: "reminder_cancel", defaultValue: "İptal", comment: "Cancel button"))
            }
        } message: {
            Text(String(localized: "reminder_permission_message", defaultValue: "Hatırlatıcı almak için ZenFlow'a bildirim izni vermelisin. Ayarlar'dan izni etkinleştirebilirsin.", comment: "Notification permission message"))
        }
    }

    // MARK: - Helper Methods

    private var sampleMessages: [String] {
        [
            String(localized: "Bugün kendine 5 dakika ayır 🧘", comment: "Sample reminder message 1"),
            String(localized: "Nefes almayı unutma, streak'in devam etsin! 🔥", comment: "Sample reminder message 2"),
            String(localized: "Huzurlu bir gün için kısa bir mola ☮️", comment: "Sample reminder message 3")
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

    var localizedName: String {
        switch self {
        case .sunday:
            return String(localized: "weekday_sunday", comment: "Sunday")
        case .monday:
            return String(localized: "weekday_monday", comment: "Monday")
        case .tuesday:
            return String(localized: "weekday_tuesday", comment: "Tuesday")
        case .wednesday:
            return String(localized: "weekday_wednesday", comment: "Wednesday")
        case .thursday:
            return String(localized: "weekday_thursday", comment: "Thursday")
        case .friday:
            return String(localized: "weekday_friday", comment: "Friday")
        case .saturday:
            return String(localized: "weekday_saturday", comment: "Saturday")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReminderSettingsView()
    }
}
