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
    /// - Parameter urlString: URL string (e.g., "zenflow://breathing")
    func handle(_ urlString: String) {
        guard let url = URL(string: urlString),
              url.scheme == "zenflow",
              let host = url.host else {
            print("⚠️ Invalid deep link URL: \(urlString)")
            return
        }

        // Map host to tab index
        let tabIndex = getTabIndex(for: host)

        // Post notification to switch tabs
        NotificationCenter.default.post(
            name: DeepLinkHandler.switchToTabNotification,
            object: nil,
            userInfo: ["tabIndex": tabIndex]
        )

        print("🔗 Deep link handled: \(host) -> Tab \(tabIndex)")
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
        case "badges", "progress", "stats":
            return 3 // Rozetler tab
        case "settings":
            return 4 // Ayarlar tab
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

    /// Navigates to badges
    func navigateToBadges() {
        handle("zenflow://badges")
    }

    /// Navigates to settings
    func navigateToSettings() {
        handle("zenflow://settings")
    }
}
