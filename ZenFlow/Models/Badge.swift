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
            return String(localized: "requirement_type_streak", defaultValue: "Seri", comment: "Streak requirement")
        case .totalMinutes:
            return String(localized: "requirement_type_total_minutes", defaultValue: "Toplam Dakika", comment: "Total minutes requirement")
        case .focusSessions:
            return String(localized: "requirement_type_focus_sessions", defaultValue: "Odaklanma Seansı", comment: "Focus sessions requirement")
        case .focusSessionsDaily:
            return String(localized: "requirement_type_focus_sessions_daily", defaultValue: "Günlük Odaklanma Seansı", comment: "Daily focus sessions requirement")
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
            name: String(localized: "badge_7_day_streak_title", defaultValue: "7 Gün Serisi", comment: "7 Day Streak Badge Title"),
            description: String(localized: "badge_7_day_streak_desc", defaultValue: "7 gün üst üste meditasyon yaptın!", comment: "7 Day Streak Badge Description"),
            requirementType: .streak,
            requiredValue: AppConstants.Badges.weekStreakDays,
            iconName: "flame.fill"
        ),
        Badge(
            name: String(localized: "badge_30_day_streak_title", defaultValue: "30 Gün Serisi", comment: "30 Day Streak Badge Title"),
            description: String(localized: "badge_30_day_streak_desc", defaultValue: "30 gün üst üste meditasyon yaptın! İnanılmaz bir disiplin!", comment: "30 Day Streak Badge Description"),
            requirementType: .streak,
            requiredValue: AppConstants.Badges.monthStreakDays,
            iconName: "bolt.fill"
        ),

        // Minute Badges
        Badge(
            name: String(localized: "badge_first_hour_title", defaultValue: "İlk Saat", comment: "First Hour Badge Title"),
            description: String(localized: "badge_first_hour_desc", defaultValue: "Toplam 60 dakika meditasyon tamamladın!", comment: "First Hour Badge Description"),
            requirementType: .totalMinutes,
            requiredValue: AppConstants.Badges.firstHourMinutes,
            iconName: "clock.fill"
        ),
        Badge(
            name: String(localized: "badge_5_hour_mastery_title", defaultValue: "5 Saat Ustalık", comment: "5 Hour Mastery Badge Title"),
            description: String(localized: "badge_5_hour_mastery_desc", defaultValue: "Toplam 300 dakika meditasyon tamamladın!", comment: "5 Hour Mastery Badge Description"),
            requirementType: .totalMinutes,
            requiredValue: AppConstants.Badges.masteryMinutes,
            iconName: "star.fill"
        ),
        Badge(
            name: String(localized: "badge_zen_master_title", defaultValue: "Zen Ustası", comment: "Zen Master Badge Title"),
            description: String(localized: "badge_zen_master_desc", defaultValue: "Toplam 1000 dakika meditasyon tamamladın! Gerçek bir usta!", comment: "Zen Master Badge Description"),
            requirementType: .totalMinutes,
            requiredValue: AppConstants.Badges.zenMasterMinutes,
            iconName: "crown.fill"
        ),

        // Focus Session Badges
        Badge(
            name: String(localized: "badge_first_pomodoro_title", defaultValue: "İlk Pomodoro", comment: "First Pomodoro Badge Title"),
            description: String(localized: "badge_first_pomodoro_desc", defaultValue: "İlk odaklanma seansını tamamladın!", comment: "First Pomodoro Badge Description"),
            requirementType: .focusSessions,
            requiredValue: AppConstants.Pomodoro.firstPomodoroSessions,
            iconName: "timer"
        ),
        Badge(
            name: String(localized: "badge_focus_master_title", defaultValue: "Odaklanma Ustası", comment: "Focus Master Badge Title"),
            description: String(localized: "badge_focus_master_desc", defaultValue: "10 odaklanma seansı tamamladın! Harika bir konsantrasyon!", comment: "Focus Master Badge Description"),
            requirementType: .focusSessions,
            requiredValue: AppConstants.Pomodoro.focusMasterSessions,
            iconName: "brain.head.profile"
        ),
        Badge(
            name: String(localized: "badge_marathon_title", defaultValue: "Maraton", comment: "Marathon Badge Title"),
            description: String(localized: "badge_marathon_desc", defaultValue: "Tek günde 8 odaklanma seansı tamamladın! İnanılmaz bir disiplin!", comment: "Marathon Badge Description"),
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
