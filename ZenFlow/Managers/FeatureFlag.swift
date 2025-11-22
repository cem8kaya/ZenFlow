//
//  FeatureFlag.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Feature flag management system for controlling app configuration
//  and visual effects settings. Uses UserDefaults for persistence.
//

import Foundation
import Combine

/// Manages feature flags for the application
/// Singleton pattern ensures consistent state across the app
final class FeatureFlag: ObservableObject {

    // MARK: - Singleton

    static let shared = FeatureFlag()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let particleEffectsEnabled = "zenflow_particle_effects_enabled"
        static let particleIntensity = "zenflow_particle_intensity"
        static let particleColorTheme = "zenflow_particle_color_theme"
        static let breathingGradientEnabled = "zenflow_breathing_gradient_enabled"
        static let breathingGradientPalette = "zenflow_breathing_gradient_palette"
        static let breathingGradientOpacity = "zenflow_breathing_gradient_opacity"
    }

    // MARK: - Published Properties

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
    }

    // MARK: - Public Methods

    /// Resets all feature flags to default values (for testing/debugging)
    func reset() {
        particleEffectsEnabled = true
        particleIntensity = .medium
        particleColorTheme = .zen
        breathingGradientEnabled = true
        breathingGradientPalette = .serene
        breathingGradientOpacity = 0.5
    }
}
