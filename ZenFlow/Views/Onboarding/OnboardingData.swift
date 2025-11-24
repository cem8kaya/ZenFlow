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
    let title: String
    let description: String
    let accentColor: Color
    let interactiveType: OnboardingInteractiveType

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
            title: "Hoş Geldin ZenFlow'a",
            description: "Günde sadece 5 dakika ile stres azaltma, daha iyi uyku ve artmış odaklanma. Bilimsel olarak kanıtlanmış teknikler, her zaman yanında.",
            accentColor: ZenTheme.mysticalViolet,
            interactiveType: .pulsingCircle
        ),

        // Page 2: Breathing Science
        OnboardingPage(
            id: 1,
            iconName: "lungs.fill",
            title: "Nefes Alın, Rahatlayın",
            description: "Box Breathing, 4-7-8 tekniği ve daha fazlası. NASA astronotları ve Navy SEALs tarafından kullanılan tekniklerle stresini yönet.",
            accentColor: ZenTheme.calmBlue,
            interactiveType: .breathingDemo
        ),

        // Page 3: Progress Visualization
        OnboardingPage(
            id: 2,
            iconName: "tree.fill",
            title: "İlerlemenizi Görün",
            description: "Her meditasyon seansı Zen Bahçenizi büyütür. Rozetler kazanın, serilerinizi koruyun, gelişiminizi kutlayın.",
            accentColor: ZenTheme.sageGreen,
            interactiveType: .treeGrowth
        ),

        // Page 4: Focus & Productivity
        OnboardingPage(
            id: 3,
            iconName: "timer",
            title: "Odaklanın, Üretin",
            description: "Pomodoro tekniği ile 25 dakika derin odaklanma, 5 dakika dinlenme. Verimliliğinizi %40 artırın.",
            accentColor: ZenTheme.softPurple,
            interactiveType: .timerDemo
        ),

        // Page 5: Privacy & Permissions
        OnboardingPage(
            id: 4,
            iconName: "checkmark.shield.fill",
            title: "Gizliliğiniz Bizim İçin Önemli",
            description: "Verileriniz sadece cihazınızda. Sunucuya hiçbir veri gönderilmez. HealthKit ve bildirimler tamamen opsiyonel.",
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
