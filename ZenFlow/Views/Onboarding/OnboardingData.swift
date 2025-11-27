//
//  OnboardingData.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//
//  Data model for onboarding pages, defining the content
//  and structure of each onboarding screen.
//

import SwiftUI

/// Interactive element type for onboarding pages
enum OnboardingInteractiveType {
    case none
    case pulsingCircle
    case breathingDemo
    case treeGrowth
    case timerDemo
}

/// Represents a single onboarding page with content and styling
struct OnboardingPage: Identifiable, Equatable {
    let id: Int
    let iconName: String
    let titleKey: String
    let descriptionKey: String
    let accentColor: Color
    let interactiveType: OnboardingInteractiveType

    // Localized computed properties
    var title: String {
        String(localized: String.LocalizationValue(stringLiteral: titleKey), defaultValue: String.LocalizationValue(stringLiteral: titleKey))
    }

    var description: String {
        String(localized: String.LocalizationValue(stringLiteral: descriptionKey), defaultValue: String.LocalizationValue(stringLiteral: descriptionKey))
    }

    // MARK: - Accessibility

    var accessibilityLabel: String {
        "\(title). \(description)"
    }

    // MARK: - Equatable

    static func == (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool {
        lhs.id == rhs.id
    }
}

/// All onboarding pages for the app
struct OnboardingData {

    /// Static array of all onboarding pages
    static let pages: [OnboardingPage] = [
        // Page 1: Welcome (Value Proposition)
        OnboardingPage(
            id: 0,
            iconName: "hands.sparkles.fill",
            titleKey: "onboarding_page_0_title",
            descriptionKey: "onboarding_page_0_description",
            accentColor: ZenTheme.mysticalViolet,
            interactiveType: .pulsingCircle
        ),

        // Page 2: Breathing Science
        OnboardingPage(
            id: 1,
            iconName: "lungs.fill",
            titleKey: "onboarding_page_1_title",
            descriptionKey: "onboarding_page_1_description",
            accentColor: ZenTheme.calmBlue,
            interactiveType: .breathingDemo
        ),

        // Page 3: Progress Visualization
        OnboardingPage(
            id: 2,
            iconName: "tree.fill",
            titleKey: "onboarding_page_2_title",
            descriptionKey: "onboarding_page_2_description",
            accentColor: ZenTheme.sageGreen,
            interactiveType: .treeGrowth
        ),

        // Page 4: Focus & Productivity
        OnboardingPage(
            id: 3,
            iconName: "timer",
            titleKey: "onboarding_page_3_title",
            descriptionKey: "onboarding_page_3_description",
            accentColor: ZenTheme.softPurple,
            interactiveType: .timerDemo
        ),

        // Page 5: Privacy & Permissions
        OnboardingPage(
            id: 4,
            iconName: "checkmark.shield.fill",
            titleKey: "onboarding_page_4_title",
            descriptionKey: "onboarding_page_4_description",
            accentColor: ZenTheme.serenePurple,
            interactiveType: .none
        )
    ]

    /// Total number of pages
    static var count: Int {
        pages.count
    }

    /// Get page at specific index
    static func page(at index: Int) -> OnboardingPage? {
        guard index >= 0 && index < pages.count else { return nil }
        return pages[index]
    }
}
