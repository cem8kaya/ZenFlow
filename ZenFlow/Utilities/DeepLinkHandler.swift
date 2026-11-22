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

    /// Posted when a link was queued (e.g. by a Siri Shortcut) and should be handled
    static let pendingLinkNotification = Notification.Name("PendingDeepLink")

    // MARK: - Pending link (Shortcuts / cold launch)

    /// A link waiting until the app UI is ready (splash and onboarding done)
    private(set) var pendingURLString: String?

    /// Queue a link; the app root handles it as soon as the UI is ready
    func enqueue(_ urlString: String) {
        pendingURLString = urlString
        NotificationCenter.default.post(name: Self.pendingLinkNotification, object: nil)
    }

    /// Handle and clear the queued link, if any
    func consumePending() {
        guard let link = pendingURLString else { return }
        pendingURLString = nil
        handle(link)
    }

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

        // zenflow://report opens the weekly report (presented by the app root)
        if host.lowercased() == "report" {
            userInfo.removeValue(forKey: "tabIndex")
            userInfo["openWeeklyReport"] = true
        }

        // zenflow://sleep opens Sleep Mode (hosted by the coach tab)
        if host.lowercased() == "sleep" {
            userInfo["openSleepMode"] = true
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
        case "coach", "zencoach", "sleep":
            return 0 // Zen Coach tab (also hosts Sleep Mode)
        case "breathing", "meditation":
            return 1 // Meditasyon tab
        case "focus", "pomodoro":
            return 2 // Odaklan tab
        case "garden":
            return 3 // Zen Bahçem tab
        case "settings":
            return 4 // Ayarlar tab
        case "badges", "progress", "stats":
            // Navigate to settings and let the user go to badges from there
            return 4
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

    /// Opens the weekly report
    func navigateToWeeklyReport() {
        handle("zenflow://report")
    }

    /// Opens Sleep Mode
    func navigateToSleepMode() {
        handle("zenflow://sleep")
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
