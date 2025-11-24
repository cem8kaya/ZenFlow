//
//  DeepLinkHandler.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Handles deep linking from notifications and other sources
//

import Foundation
import UserNotifications
internal import UIKit

class DeepLinkHandler {
    // MARK: - Notification Names

    static let switchToTabNotification = Notification.Name("DeepLinkHandler.switchToTab")
    static let startMeditationNotification = Notification.Name("DeepLinkHandler.startMeditation")

    // MARK: - Tab Indices

    enum Tab: Int {
        case meditation = 0
        case focus = 1
        case garden = 2
        case badges = 3
        case settings = 4
    }

    // MARK: - Singleton

    static let shared = DeepLinkHandler()

    private init() {}

    // MARK: - Public Methods

    /// Switch to a specific tab
    func switchToTab(_ tab: Tab) {
        NotificationCenter.default.post(
            name: DeepLinkHandler.switchToTabNotification,
            object: nil,
            userInfo: ["tabIndex": tab.rawValue]
        )
    }

    /// Handle notification response (when user taps notification)
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        print("🔗 Deep link - Action: \(actionIdentifier), Category: \(categoryIdentifier)")

        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            handleNotificationTap(category: categoryIdentifier)

        case "START_ACTION":
            // User tapped "Başla" action button
            handleStartAction()

        case "SNOOZE_ACTION":
            // User tapped "Sonra Hatırlat" action button
            handleSnoozeAction()

        default:
            break
        }
    }

    // MARK: - Private Methods

    private func handleNotificationTap(category: String) {
        // Switch to meditation tab
        switchToTab(.meditation)

        // Post notification to start meditation
        NotificationCenter.default.post(
            name: DeepLinkHandler.startMeditationNotification,
            object: nil
        )

        // Track analytics
        print("📊 Analytics: notification_opened - category: \(category)")
    }

    private func handleStartAction() {
        // Switch to meditation tab
        switchToTab(.meditation)

        // Post notification to auto-start meditation
        NotificationCenter.default.post(
            name: DeepLinkHandler.startMeditationNotification,
            object: nil,
            userInfo: ["autoStart": true]
        )

        // Play haptic feedback
        HapticManager.shared.playImpact(style: .medium)

        print("📊 Analytics: notification_action_start")
    }

    private func handleSnoozeAction() {
        // Snooze notification for 1 hour
        NotificationManager.shared.snoozeNotification(hours: 1)

        print("📊 Analytics: notification_action_snooze")
    }
}
