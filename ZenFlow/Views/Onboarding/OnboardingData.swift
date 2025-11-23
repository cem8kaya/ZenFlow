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

/// Represents a single onboarding page with content and styling
struct OnboardingPage: Identifiable, Equatable {
    let id: Int
    let iconName: String
    let title: String
    let description: String
    let accentColor: Color

    // MARK: - Accessibility

    var accessibilityLabel: String {
        "\(title). \(description)"
    }
}

/// All onboarding pages for the app
struct OnboardingData {

    /// Static array of all onboarding pages
    static let pages: [OnboardingPage] = [
        // Page 1: Welcome
        OnboardingPage(
            id: 0,
            iconName: "hands.sparkles.fill",
            title: "Hoş Geldin",
            description: "ZenFlow ile huzurlu bir zihin yolculuğuna başla. Nefes egzersizleri, meditasyon ve odaklanma teknikleriyle günlük yaşamında denge bul.",
            accentColor: ZenTheme.mysticalViolet
        ),

        // Page 2: Breathing Exercises
        OnboardingPage(
            id: 1,
            iconName: "lungs.fill",
            title: "Nefes Egzersizleri",
            description: "5 farklı nefes tekniği ile stresini azalt. Box Breathing, 4-7-8 tekniği, derin nefes alma ve daha fazlası seni bekliyor.",
            accentColor: ZenTheme.calmBlue
        ),

        // Page 3: Zen Garden
        OnboardingPage(
            id: 2,
            iconName: "tree.fill",
            title: "Zen Bahçen",
            description: "Her meditasyon seansı ile bahçeni büyüt. Rozetler kazan, ilerlemeni takip et ve kişisel gelişimini görselleştir.",
            accentColor: ZenTheme.sageGreen
        ),

        // Page 4: Focus Timer
        OnboardingPage(
            id: 3,
            iconName: "timer",
            title: "Odaklanma Zamanlayıcı",
            description: "Pomodoro tekniği ile produktiviteni artır. İşlerine odaklan, düzenli molalar ver ve verimini maksimize et.",
            accentColor: ZenTheme.softPurple
        ),

        // Page 5: Permissions
        OnboardingPage(
            id: 4,
            iconName: "checkmark.shield.fill",
            title: "Hazırsın!",
            description: "HealthKit entegrasyonu ile meditasyon verilerini kaydet. Bildirimler ile günlük hatırlatmalar al. Hemen başla!",
            accentColor: ZenTheme.serenePurple
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
