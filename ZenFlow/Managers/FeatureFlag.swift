//
//  FeatureFlag.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Feature flag management system for controlling premium features
//  and app configuration. Currently uses UserDefaults for persistence,
//  with future integration planned for StoreKit subscriptions.
//

import Foundation
import Combine

/// Manages feature flags and premium status for the application
/// Singleton pattern ensures consistent state across the app
final class FeatureFlag: ObservableObject {

    // MARK: - Singleton

    static let shared = FeatureFlag()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let isPremium = "zenflow_is_premium"
        static let selectedThemeType = "zenflow_selected_theme_type"
    }

    // MARK: - Published Properties

    /// Indicates whether the user has premium access
    /// Currently persisted in UserDefaults, will be managed by StoreKit in future
    @Published var isPremium: Bool {
        didSet {
            UserDefaults.standard.set(isPremium, forKey: Keys.isPremium)
            objectWillChange.send()
        }
    }

    /// The currently selected theme type
    @Published var selectedThemeType: ThemeType {
        didSet {
            UserDefaults.standard.set(selectedThemeType.rawValue, forKey: Keys.selectedThemeType)
            objectWillChange.send()
        }
    }

    // MARK: - Initialization

    private init() {
        // Load premium status from UserDefaults
        self.isPremium = UserDefaults.standard.bool(forKey: Keys.isPremium)

        // Load selected theme, defaulting to free theme
        let savedThemeRaw = UserDefaults.standard.string(forKey: Keys.selectedThemeType) ?? ThemeType.free.rawValue
        self.selectedThemeType = ThemeType(rawValue: savedThemeRaw) ?? .free

        // If user is not premium but has a premium theme selected, reset to free
        if !isPremium && selectedThemeType.isPremium {
            self.selectedThemeType = .free
        }
    }

    // MARK: - Public Methods

    /// Updates premium status and validates theme selection
    /// - Parameter isPremium: New premium status
    func setPremiumStatus(_ isPremium: Bool) {
        self.isPremium = isPremium

        // If downgrading from premium, reset to free theme
        if !isPremium && selectedThemeType.isPremium {
            selectedThemeType = .free
        }
    }

    /// Attempts to select a theme, checking premium requirements
    /// - Parameter themeType: The theme to select
    /// - Returns: True if theme was successfully selected, false if premium required
    @discardableResult
    func selectTheme(_ themeType: ThemeType) -> Bool {
        // Check if theme requires premium and user doesn't have it
        if themeType.isPremium && !isPremium {
            return false
        }

        selectedThemeType = themeType
        return true
    }

    /// Resets all feature flags to default values (for testing/debugging)
    func reset() {
        isPremium = false
        selectedThemeType = .free
    }

    // MARK: - Future StoreKit Integration

    /// Placeholder for future StoreKit subscription validation
    /// This will be implemented when integrating with Apple's StoreKit 2
    func validateSubscription() async throws {
        // TODO: Implement StoreKit subscription validation
        // - Check for active subscription
        // - Verify receipt with Apple servers
        // - Update isPremium based on subscription status
    }

    /// Placeholder for initiating premium purchase flow
    /// This will be implemented when integrating with Apple's StoreKit 2
    func purchasePremium() async throws {
        // TODO: Implement StoreKit purchase flow
        // - Present available subscription options
        // - Handle purchase transaction
        // - Validate receipt
        // - Update isPremium status
    }

    /// Placeholder for restoring previous purchases
    /// This will be implemented when integrating with Apple's StoreKit 2
    func restorePurchases() async throws {
        // TODO: Implement StoreKit restore purchases
        // - Request purchase restoration
        // - Validate restored transactions
        // - Update isPremium status
    }
}
