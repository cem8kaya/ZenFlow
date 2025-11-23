//
//  OnboardingManager.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//
//  Manages the onboarding state using UserDefaults to ensure
//  the onboarding flow is shown only once on first launch.
//

import Foundation
import Combine

/// Manager for tracking onboarding completion state
class OnboardingManager: ObservableObject {

    // MARK: - Singleton

    static let shared = OnboardingManager()

    // MARK: - Published Properties

    /// Whether the user has completed the onboarding
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    // MARK: - Constants

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    // MARK: - Initialization

    private init() {
        // Load onboarding state from UserDefaults
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
    }

    // MARK: - Public Methods

    /// Mark onboarding as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    /// Reset onboarding state (useful for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    /// Check if onboarding should be shown
    var shouldShowOnboarding: Bool {
        return !hasCompletedOnboarding
    }
}
