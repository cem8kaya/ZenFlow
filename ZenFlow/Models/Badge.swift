//
//  Badge.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//  Updated by Claude AI on 16.11.2025.
//
//  Badge model representing user achievements in the meditation app.
//  Badges can be unlocked based on streak days or total meditation minutes.
//  Supports persistence through Codable protocol.
//

import Foundation

/// Types of requirements for unlocking badges
enum RequirementType: String, Codable {
    case streak          // Consecutive days of meditation
    case totalMinutes    // Total meditation minutes accumulated
    case focusSessions   // Completed Pomodoro focus sessions
    case focusSessionsDaily // Completed Pomodoro focus sessions in a single day

    /// Localized display name for the requirement type
    var displayName: String {
        switch self {
        case .streak:
            return "Seri"
        case .totalMinutes:
            return "Toplam Dakika"
        case .focusSessions:
            return "Odaklanma Seansı"
        case .focusSessionsDaily:
            return "Günlük Odaklanma Seansı"
        }
    }
}

/// Kullanıcı başarı rozeti
struct Badge: Identifiable, Codable, Equatable {
    // MARK: - Properties

    let id: UUID
    let name: String
    let description: String
    let requirementType: RequirementType
    let requiredValue: Int // Örn: 7 gün, 300 dakika
    let iconName: String   // SF Symbol adı

    var isUnlocked: Bool
    var unlockedDate: Date?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        requirementType: RequirementType,
        requiredValue: Int,
        iconName: String,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.requirementType = requirementType
        self.requiredValue = requiredValue
        self.iconName = iconName
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }

    // MARK: - Unlock Methods

    /// Rozeti aç
    mutating func unlock() {
        isUnlocked = true
        unlockedDate = Date()
    }

    /// Rozeti kilitle (debug amaçlı)
    mutating func lock() {
        isUnlocked = false
        unlockedDate = nil
    }

    /// Gereksinim karşılanıyor mu kontrol et
    /// - Parameter value: Kontrol edilecek değer
    /// - Returns: Gereksinim karşılanıyorsa true
    func checkRequirement(value: Int) -> Bool {
        return value >= requiredValue
    }
}

// MARK: - Predefined Badges

extension Badge {
    /// Önceden tanımlı rozetler listesi
    /// Constants are defined in AppConstants.Badges
    static let predefinedBadges: [Badge] = [
        // Streak Badges
        Badge(
            name: "7 Gün Serisi",
            description: "7 gün üst üste meditasyon yaptın!",
            requirementType: .streak,
            requiredValue: AppConstants.Badges.weekStreakDays,
            iconName: "flame.fill"
        ),
        Badge(
            name: "30 Gün Serisi",
            description: "30 gün üst üste meditasyon yaptın! İnanılmaz bir disiplin!",
            requirementType: .streak,
            requiredValue: AppConstants.Badges.monthStreakDays,
            iconName: "bolt.fill"
        ),

        // Minute Badges
        Badge(
            name: "İlk Saat",
            description: "Toplam 60 dakika meditasyon tamamladın!",
            requirementType: .totalMinutes,
            requiredValue: AppConstants.Badges.firstHourMinutes,
            iconName: "clock.fill"
        ),
        Badge(
            name: "5 Saat Ustalık",
            description: "Toplam 300 dakika meditasyon tamamladın!",
            requirementType: .totalMinutes,
            requiredValue: AppConstants.Badges.masteryMinutes,
            iconName: "star.fill"
        ),
        Badge(
            name: "Zen Ustası",
            description: "Toplam 1000 dakika meditasyon tamamladın! Gerçek bir usta!",
            requirementType: .totalMinutes,
            requiredValue: AppConstants.Badges.zenMasterMinutes,
            iconName: "crown.fill"
        ),

        // Focus Session Badges
        Badge(
            name: "İlk Pomodoro",
            description: "İlk odaklanma seansını tamamladın!",
            requirementType: .focusSessions,
            requiredValue: AppConstants.Pomodoro.firstPomodoroSessions,
            iconName: "timer"
        ),
        Badge(
            name: "Odaklanma Ustası",
            description: "10 odaklanma seansı tamamladın! Harika bir konsantrasyon!",
            requirementType: .focusSessions,
            requiredValue: AppConstants.Pomodoro.focusMasterSessions,
            iconName: "brain.head.profile"
        ),
        Badge(
            name: "Maraton",
            description: "Tek günde 8 odaklanma seansı tamamladın! İnanılmaz bir disiplin!",
            requirementType: .focusSessionsDaily,
            requiredValue: AppConstants.Pomodoro.marathonSessions,
            iconName: "figure.run"
        )
    ]

    /// Tüm rozetleri başlangıç durumunda al (kilili)
    static func getAllBadges() -> [Badge] {
        return predefinedBadges
    }
}
