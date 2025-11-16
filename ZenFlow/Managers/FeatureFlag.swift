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
        static let particleEffectsEnabled = "zenflow_particle_effects_enabled"
        static let particleIntensity = "zenflow_particle_intensity"
        static let particleColorTheme = "zenflow_particle_color_theme"
        static let breathingGradientEnabled = "zenflow_breathing_gradient_enabled"
        static let breathingGradientPalette = "zenflow_breathing_gradient_palette"
        static let breathingGradientOpacity = "zenflow_breathing_gradient_opacity"
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

    /// Indicates whether particle effects are enabled
    @Published var particleEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(particleEffectsEnabled, forKey: Keys.particleEffectsEnabled)
            objectWillChange.send()
        }
    }

    /// Particle effect intensity level
    @Published var particleIntensity: ParticleIntensity {
        didSet {
            UserDefaults.standard.set(particleIntensity.rawValue, forKey: Keys.particleIntensity)
            objectWillChange.send()
        }
    }

    /// Particle color theme
    @Published var particleColorTheme: ParticleColorTheme {
        didSet {
            UserDefaults.standard.set(particleColorTheme.rawValue, forKey: Keys.particleColorTheme)
            objectWillChange.send()
        }
    }

    /// Indicates whether breathing gradient background is enabled
    @Published var breathingGradientEnabled: Bool {
        didSet {
            UserDefaults.standard.set(breathingGradientEnabled, forKey: Keys.breathingGradientEnabled)
            objectWillChange.send()
        }
    }

    /// Selected breathing gradient color palette
    @Published var breathingGradientPalette: ZenColorPalette {
        didSet {
            UserDefaults.standard.set(breathingGradientPalette.rawValue, forKey: Keys.breathingGradientPalette)
            objectWillChange.send()
        }
    }

    /// Breathing gradient background opacity (0.0 to 1.0)
    @Published var breathingGradientOpacity: Double {
        didSet {
            UserDefaults.standard.set(breathingGradientOpacity, forKey: Keys.breathingGradientOpacity)
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

        // Load particle effects settings
        // Default to true if not previously set
        if UserDefaults.standard.object(forKey: Keys.particleEffectsEnabled) == nil {
            self.particleEffectsEnabled = true
        } else {
            self.particleEffectsEnabled = UserDefaults.standard.bool(forKey: Keys.particleEffectsEnabled)
        }

        // Load particle intensity, defaulting to medium
        let savedIntensityRaw = UserDefaults.standard.string(forKey: Keys.particleIntensity) ?? ParticleIntensity.medium.rawValue
        self.particleIntensity = ParticleIntensity(rawValue: savedIntensityRaw) ?? .medium

        // Load particle color theme, defaulting to zen
        let savedColorThemeRaw = UserDefaults.standard.string(forKey: Keys.particleColorTheme) ?? ParticleColorTheme.zen.rawValue
        self.particleColorTheme = ParticleColorTheme(rawValue: savedColorThemeRaw) ?? .zen

        // Load breathing gradient settings
        // Default to enabled if not previously set
        if UserDefaults.standard.object(forKey: Keys.breathingGradientEnabled) == nil {
            self.breathingGradientEnabled = true
        } else {
            self.breathingGradientEnabled = UserDefaults.standard.bool(forKey: Keys.breathingGradientEnabled)
        }

        // Load breathing gradient palette, defaulting to serene
        let savedPaletteRaw = UserDefaults.standard.string(forKey: Keys.breathingGradientPalette) ?? ZenColorPalette.serene.rawValue
        self.breathingGradientPalette = ZenColorPalette(rawValue: savedPaletteRaw) ?? .serene

        // Load breathing gradient opacity, defaulting to 0.5
        if UserDefaults.standard.object(forKey: Keys.breathingGradientOpacity) == nil {
            self.breathingGradientOpacity = 0.5
        } else {
            self.breathingGradientOpacity = UserDefaults.standard.double(forKey: Keys.breathingGradientOpacity)
        }

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
        particleEffectsEnabled = true
        particleIntensity = .medium
        particleColorTheme = .zen
        breathingGradientEnabled = true
        breathingGradientPalette = .serene
        breathingGradientOpacity = 0.5
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
