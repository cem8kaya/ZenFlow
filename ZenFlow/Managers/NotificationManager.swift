//
//  NotificationManager.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Manages meditation reminder notifications with customizable schedules
//

import Foundation
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let remindersEnabled = "zenflow_reminders_enabled"
        static let reminderTime = "zenflow_reminder_time"
        static let reminderDays = "zenflow_reminder_days"
        static let streakReminderEnabled = "zenflow_streak_reminder_enabled"
        static let weeklyReportEnabled = "zenflow_weekly_report_enabled"
    }

    // MARK: - Properties

    private let defaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()

    @Published var isAuthorized = false

    // MARK: - Reminder Messages (Turkish)

    private let motivationalMessages = [
        "5 dakika meditasyon, tüm gün huzur. Hazır mısın?",
        "Stresini azalt, odağını artır. Hadi başlayalım! 🌱",
        "Zen Bahçen seni bekliyor. Bugün hangi egzersizi deneyelim?",
        "Bugün kendine 5 dakika ayır 🧘",
        "Nefes almayı unutma, streak'in devam etsin! 🔥",
        "Huzurlu bir gün için kısa bir mola ☮️",
        "Zihninle bağlantı kurma zamanı 🌟",
        "Bugünkü meditasyonun seni bekliyor ✨",
        "İçsel huzur için bir an dur 🌸",
        "Nefesine odaklan, anı yaşa 🌬️",
        "Kendine sevgiyle yaklaş 💚"
    ]

    // MARK: - Computed Properties

    var remindersEnabled: Bool {
        get {
            return defaults.bool(forKey: Keys.remindersEnabled)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.remindersEnabled)

            if newValue {
                scheduleDailyReminders()
            } else {
                cancelAllReminders()
            }

            print("💾 Reminders enabled: \(newValue)")
        }
    }

    var reminderTime: Date {
        get {
            if let timestamp = defaults.object(forKey: Keys.reminderTime) as? Double {
                return Date(timeIntervalSince1970: timestamp)
            }
            // Default: 9:00 AM
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components) ?? Date()
        }
        set {
            objectWillChange.send()
            defaults.set(newValue.timeIntervalSince1970, forKey: Keys.reminderTime)

            if remindersEnabled {
                scheduleDailyReminders()
            }

            print("💾 Reminder time updated: \(newValue)")
        }
    }

    var reminderDays: Set<Int> {
        get {
            if let array = defaults.array(forKey: Keys.reminderDays) as? [Int] {
                return Set(array)
            }
            // Default: All days (1 = Sunday, 7 = Saturday)
            return Set(1...7)
        }
        set {
            objectWillChange.send()
            defaults.set(Array(newValue), forKey: Keys.reminderDays)

            if remindersEnabled {
                scheduleDailyReminders()
            }

            print("💾 Reminder days updated: \(newValue)")
        }
    }

    var streakReminderEnabled: Bool {
        get {
            return defaults.bool(forKey: Keys.streakReminderEnabled)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.streakReminderEnabled)

            if newValue {
                scheduleStreakReminder()
            } else {
                cancelStreakReminder()
            }

            print("💾 Streak reminder enabled: \(newValue)")
        }
    }

    /// Sunday-evening "your week in Zen" notification (opt-in)
    var weeklyReportEnabled: Bool {
        get {
            return defaults.bool(forKey: Keys.weeklyReportEnabled)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.weeklyReportEnabled)

            if newValue {
                scheduleWeeklyReport()
            } else {
                cancelWeeklyReport()
            }

            print("💾 Weekly report enabled: \(newValue)")
        }
    }

    // MARK: - Initialization

    private init() {
        checkAuthorizationStatus()
        registerNotificationCategories()
    }

    // MARK: - Notification Categories

    private func registerNotificationCategories() {
        // Define "Başla" action
        let startAction = UNNotificationAction(
            identifier: "START_ACTION",
            title: "Başla",
            options: [.foreground]
        )

        // Define "Sonra Hatırlat" action
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Sonra Hatırlat",
            options: []
        )

        // Create category with actions
        let meditationCategory = UNNotificationCategory(
            identifier: "MEDITATION_REMINDER",
            actions: [startAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER",
            actions: [startAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Register categories
        notificationCenter.setNotificationCategories([meditationCategory, streakCategory])
        print("✅ Registered notification categories with action buttons")
    }

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted

                if let error = error {
                    print("❌ Notification authorization error: \(error)")
                }

                if granted {
                    print("✅ Notification authorization granted")
                } else {
                    print("⚠️ Notification authorization denied")
                }

                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
                print("📱 Notification authorization status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }

    // MARK: - Daily Reminders

    func scheduleDailyReminders() {
        guard isAuthorized else {
            print("⚠️ Cannot schedule reminders - not authorized")
            return
        }

        // Cancel existing reminders first
        cancelDailyReminders()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)

        guard let hour = components.hour, let minute = components.minute else {
            print("❌ Invalid reminder time")
            return
        }

        // Schedule notification for each selected day
        for day in reminderDays {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = day

            let content = UNMutableNotificationContent()
            content.title = "🧘‍♂️ Günlük MyZenFlow Zamanı"

            // Get current streak
            let currentStreak = LocalDataManager.shared.currentStreak

            // Use streak-aware message if streak > 0
            var message: String
            if currentStreak > 0 {
                message = "Bugün kendine \(currentStreak) gün! Serini korumak için nefes al."
            } else {
                message = motivationalMessages.randomElement() ?? "Meditasyon zamanı! 🧘"
            }

            content.body = message
            content.sound = .default
            content.badge = NSNumber(value: currentStreak > 0 ? currentStreak : 1)
            content.categoryIdentifier = "MEDITATION_REMINDER"

            // Add user info for deep linking
            content.userInfo = [
                "type": "daily_reminder",
                "streak": currentStreak
            ]

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "daily_reminder_\(day)",
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule daily reminder for day \(day): \(error)")
                } else {
                    print("✅ Scheduled daily reminder for weekday \(day) at \(hour):\(String(format: "%02d", minute))")
                }
            }
        }
    }

    func cancelDailyReminders() {
        let identifiers = (1...7).map { "daily_reminder_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled daily reminders")
    }

    // MARK: - Streak Reminder

    func scheduleStreakReminder() {
        guard isAuthorized else {
            print("⚠️ Cannot schedule streak reminder - not authorized")
            return
        }

        cancelStreakReminder()

        // Check if meditation was done today, if not remind at 8 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let currentStreak = LocalDataManager.shared.currentStreak

        let content = UNMutableNotificationContent()
        content.title = "Streak'in Tehlikede! 🔥"

        // Dynamic message based on streak
        if currentStreak > 0 {
            content.body = "Bugün henüz meditasyon yapmadın. \(currentStreak) günlük serini kırma! 💪"
        } else {
            content.body = "Bugün henüz meditasyon yapmadın. Günlük serini başlatmak için meditasyon yap!"
        }

        content.sound = .default
        content.badge = NSNumber(value: currentStreak > 0 ? currentStreak : 1)
        content.categoryIdentifier = "STREAK_REMINDER"

        // Add user info
        content.userInfo = [
            "type": "streak_reminder",
            "streak": currentStreak
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule streak reminder: \(error)")
            } else {
                print("✅ Scheduled streak reminder for 20:00")
            }
        }
    }

    func cancelStreakReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
        print("🗑️ Cancelled streak reminder")
    }

    // MARK: - Weekly Report

    /// Weekday (1 = Sunday) and time of the weekly report notification
    static let weeklyReportWeekday = 1
    static let weeklyReportHour = 19

    func scheduleWeeklyReport() {
        guard isAuthorized else {
            print("⚠️ Cannot schedule weekly report - not authorized")
            return
        }

        cancelWeeklyReport()

        var dateComponents = DateComponents()
        dateComponents.weekday = Self.weeklyReportWeekday
        dateComponents.hour = Self.weeklyReportHour
        dateComponents.minute = 0

        // The text is static (a repeating trigger cannot carry fresh numbers);
        // the report itself is computed live when the user opens it.
        let content = UNMutableNotificationContent()
        content.title = String(localized: "weekly_report_notification_title", defaultValue: "Haftalık Zen Raporun hazır 🌿", comment: "Weekly report notification title")
        content.body = String(localized: "weekly_report_notification_body", defaultValue: "Bu hafta ne kadar nefes aldığına bir göz at.", comment: "Weekly report notification body")
        content.sound = .default
        content.userInfo = [
            "type": "weekly_report",
            "deepLink": "zenflow://report"
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_report", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule weekly report: \(error)")
            } else {
                print("✅ Scheduled weekly report for Sunday 19:00")
            }
        }
    }

    func cancelWeeklyReport() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weekly_report"])
        print("🗑️ Cancelled weekly report")
    }

    // MARK: - Immediate Notification

    func sendImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send immediate notification: \(error)")
            } else {
                print("✅ Sent immediate notification: \(title)")
            }
        }
    }

    // MARK: - Cancel All

    func cancelAllReminders() {
        cancelDailyReminders()
        cancelStreakReminder()
        cancelWeeklyReport()
        print("🗑️ Cancelled all reminders")
    }

    // MARK: - Snooze

    func snoozeNotification(hours: Int) {
        guard isAuthorized else {
            print("⚠️ Cannot snooze notification - not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🧘‍♂️ Günlük MyZenFlow Zamanı"
        content.body = motivationalMessages.randomElement() ?? "Meditasyon zamanı! 🧘"
        content.sound = .default

        let currentStreak = LocalDataManager.shared.currentStreak
        content.badge = NSNumber(value: currentStreak > 0 ? currentStreak : 1)
        content.categoryIdentifier = "MEDITATION_REMINDER"

        // Schedule for specified hours from now
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(hours * 3600),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "snooze_reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule snooze notification: \(error)")
            } else {
                print("✅ Scheduled snooze notification for \(hours) hour(s) from now")
            }
        }
    }

    // MARK: - Utility

    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
                print("📱 Pending notifications: \(requests.count)")
            }
        }
    }

    func clearDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        print("🗑️ Cleared delivered notifications")
    }
}
