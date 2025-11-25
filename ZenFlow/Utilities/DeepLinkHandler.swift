//
//  DeepLinkHandler.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Deep link handler for navigating to app features from Zen Coach.
//  Supports custom URL scheme: zenflow://
//

import Foundation
import UserNotifications

// MARK: - Deep Link Handler

/// Singleton class for handling deep links within the app
class DeepLinkHandler {

    // MARK: - Singleton

    static let shared = DeepLinkHandler()

    // MARK: - Notification Name

    static let switchToTabNotification = Notification.Name("SwitchToTab")

    private init() {}

    // MARK: - Deep Link Handling

    /// Handles a deep link URL string
    /// - Parameter urlString: URL string (e.g., "zenflow://breathing?exercise=box")
    func handle(_ urlString: String) {
        guard let url = URL(string: urlString),
              url.scheme == "zenflow",
              let host = url.host else {
            print("⚠️ Invalid deep link URL: \(urlString)")
            return
        }

        // Parse query parameters
        var queryParams: [String: String] = [:]
        if let components = URLComponents(string: urlString),
           let queryItems = components.queryItems {
            for item in queryItems {
                if let value = item.value {
                    queryParams[item.name] = value
                }
            }
        }

        // Map host to tab index
        let tabIndex = getTabIndex(for: host)

        // Prepare userInfo with tab index and query params
        var userInfo: [String: Any] = ["tabIndex": tabIndex]

        // Handle breathing exercise parameter
        if host.lowercased() == "breathing" || host.lowercased() == "meditation",
           let exercise = queryParams["exercise"] {
            userInfo["exerciseType"] = exercise
        }

        // Post notification to switch tabs
        NotificationCenter.default.post(
            name: DeepLinkHandler.switchToTabNotification,
            object: nil,
            userInfo: userInfo
        )

        print("🔗 Deep link handled: \(host) -> Tab \(tabIndex), params: \(queryParams)")
    }

    /// Maps URL host to tab index
    /// - Parameter host: URL host (e.g., "breathing")
    /// - Returns: Tab index
    private func getTabIndex(for host: String) -> Int {
        switch host.lowercased() {
        case "breathing", "meditation":
            return 0 // Meditasyon tab
        case "focus", "pomodoro":
            return 1 // Odaklan tab
        case "garden":
            return 2 // Zen Bahçem tab
        case "coach", "zencoach":
            return 3 // Zen Coach tab
        case "badges", "progress", "stats":
            return 4 // Rozetler tab
        case "settings":
            return 5 // Ayarlar tab
        default:
            print("⚠️ Unknown deep link host: \(host), defaulting to tab 0")
            return 0
        }
    }

    // MARK: - Convenience Methods

    /// Navigates to breathing exercises
    func navigateToBreathing() {
        handle("zenflow://breathing")
    }

    /// Navigates to focus timer
    func navigateToFocus() {
        handle("zenflow://focus")
    }

    /// Navigates to zen garden
    func navigateToGarden() {
        handle("zenflow://garden")
    }

    /// Navigates to zen coach
    func navigateToCoach() {
        handle("zenflow://coach")
    }

    /// Navigates to badges
    func navigateToBadges() {
        handle("zenflow://badges")
    }

    /// Navigates to settings
    func navigateToSettings() {
        handle("zenflow://settings")
    }

    // MARK: - Notification Response Handling

    /// Handles notification response (when user taps on a notification)
    /// - Parameter response: The notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        // Check for deep link in userInfo
        if let deepLink = userInfo["deepLink"] as? String {
            handle(deepLink)
        } else {
            // Default behavior: navigate to meditation tab
            navigateToBreathing()
        }
    }
}
