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
    case sessions        // Completed meditation sessions
    case moodCheckIns    // Logged mood check-ins

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
        case .sessions:
            return String(localized: "requirement_type_sessions", defaultValue: "Seans", comment: "Sessions requirement")
        case .moodCheckIns:
            return String(localized: "requirement_type_mood_checkins", defaultValue: "Ruh Hali Kaydı", comment: "Mood check-ins requirement")
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
        ),

        // MARK: Added in 1.1
        Badge(
            name: String(localized: "badge_3_day_streak_title", defaultValue: "3 Gün Serisi", comment: "3-Day Streak Badge Title"),
            description: String(localized: "badge_3_day_streak_desc", defaultValue: "3 gün üst üste meditasyon yaptın. Alışkanlık filizleniyor!", comment: "3-Day Streak Badge Description"),
            requirementType: .streak,
            requiredValue: 3,
            iconName: "flame"
        ),
        Badge(
            name: String(localized: "badge_14_day_streak_title", defaultValue: "İki Hafta", comment: "Two Weeks Badge Title"),
            description: String(localized: "badge_14_day_streak_desc", defaultValue: "14 gün üst üste meditasyon yaptın!", comment: "Two Weeks Badge Description"),
            requirementType: .streak,
            requiredValue: 14,
            iconName: "sun.max.fill"
        ),
        Badge(
            name: String(localized: "badge_60_day_streak_title", defaultValue: "60 Gün Serisi", comment: "60-Day Streak Badge Title"),
            description: String(localized: "badge_60_day_streak_desc", defaultValue: "60 gün üst üste meditasyon yaptın! Bu artık bir yaşam tarzı.", comment: "60-Day Streak Badge Description"),
            requirementType: .streak,
            requiredValue: 60,
            iconName: "moon.stars.fill"
        ),
        Badge(
            name: String(localized: "badge_100_day_streak_title", defaultValue: "100 Gün Serisi", comment: "100-Day Streak Badge Title"),
            description: String(localized: "badge_100_day_streak_desc", defaultValue: "100 gün üst üste meditasyon yaptın! Efsanevi bir bağlılık.", comment: "100-Day Streak Badge Description"),
            requirementType: .streak,
            requiredValue: 100,
            iconName: "trophy.fill"
        ),
        Badge(
            name: String(localized: "badge_first_steps_title", defaultValue: "İlk Adımlar", comment: "First Steps Badge Title"),
            description: String(localized: "badge_first_steps_desc", defaultValue: "Toplam 15 dakika meditasyon tamamladın.", comment: "First Steps Badge Description"),
            requirementType: .totalMinutes,
            requiredValue: 15,
            iconName: "shoeprints.fill"
        ),
        Badge(
            name: String(localized: "badge_two_hours_title", defaultValue: "İki Saat", comment: "Two Hours Badge Title"),
            description: String(localized: "badge_two_hours_desc", defaultValue: "Toplam 120 dakika meditasyon tamamladın!", comment: "Two Hours Badge Description"),
            requirementType: .totalMinutes,
            requiredValue: 120,
            iconName: "hourglass"
        ),
        Badge(
            name: String(localized: "badge_ten_hours_title", defaultValue: "10 Saat Sükûnet", comment: "10 Hours of Calm Badge Title"),
            description: String(localized: "badge_ten_hours_desc", defaultValue: "Toplam 600 dakika meditasyon tamamladın!", comment: "10 Hours of Calm Badge Description"),
            requirementType: .totalMinutes,
            requiredValue: 600,
            iconName: "mountain.2.fill"
        ),
        Badge(
            name: String(localized: "badge_zen_sage_title", defaultValue: "Zen Bilgesi", comment: "Zen Sage Badge Title"),
            description: String(localized: "badge_zen_sage_desc", defaultValue: "Toplam 2000 dakika meditasyon tamamladın. Gerçek bir bilge!", comment: "Zen Sage Badge Description"),
            requirementType: .totalMinutes,
            requiredValue: 2000,
            iconName: "sparkles"
        ),
        Badge(
            name: String(localized: "badge_first_session_title", defaultValue: "İlk Seans", comment: "First Session Badge Title"),
            description: String(localized: "badge_first_session_desc", defaultValue: "İlk meditasyon seansını tamamladın.", comment: "First Session Badge Description"),
            requirementType: .sessions,
            requiredValue: 1,
            iconName: "play.circle.fill"
        ),
        Badge(
            name: String(localized: "badge_ten_sessions_title", defaultValue: "On Seans", comment: "Ten Sessions Badge Title"),
            description: String(localized: "badge_ten_sessions_desc", defaultValue: "10 meditasyon seansı tamamladın!", comment: "Ten Sessions Badge Description"),
            requirementType: .sessions,
            requiredValue: 10,
            iconName: "repeat.circle.fill"
        ),
        Badge(
            name: String(localized: "badge_fifty_sessions_title", defaultValue: "50 Seans", comment: "50 Sessions Badge Title"),
            description: String(localized: "badge_fifty_sessions_desc", defaultValue: "50 meditasyon seansı tamamladın!", comment: "50 Sessions Badge Description"),
            requirementType: .sessions,
            requiredValue: 50,
            iconName: "infinity.circle.fill"
        ),
        Badge(
            name: String(localized: "badge_hundred_sessions_title", defaultValue: "100 Seans", comment: "100 Sessions Badge Title"),
            description: String(localized: "badge_hundred_sessions_desc", defaultValue: "100 meditasyon seansı tamamladın! Sebat kazanır.", comment: "100 Sessions Badge Description"),
            requirementType: .sessions,
            requiredValue: 100,
            iconName: "seal.fill"
        ),
        Badge(
            name: String(localized: "badge_focus_beginner_title", defaultValue: "Odak Başlangıcı", comment: "Focus Beginner Badge Title"),
            description: String(localized: "badge_focus_beginner_desc", defaultValue: "5 odaklanma seansı tamamladın!", comment: "Focus Beginner Badge Description"),
            requirementType: .focusSessions,
            requiredValue: 5,
            iconName: "target"
        ),
        Badge(
            name: String(localized: "badge_deep_focus_title", defaultValue: "Derin Odak", comment: "Deep Focus Badge Title"),
            description: String(localized: "badge_deep_focus_desc", defaultValue: "25 odaklanma seansı tamamladın!", comment: "Deep Focus Badge Description"),
            requirementType: .focusSessions,
            requiredValue: 25,
            iconName: "scope"
        ),
        Badge(
            name: String(localized: "badge_focus_sage_title", defaultValue: "Odak Efendisi", comment: "Focus Sage Badge Title"),
            description: String(localized: "badge_focus_sage_desc", defaultValue: "50 odaklanma seansı tamamladın! Muhteşem bir konsantrasyon.", comment: "Focus Sage Badge Description"),
            requirementType: .focusSessions,
            requiredValue: 50,
            iconName: "bolt.circle.fill"
        ),
        Badge(
            name: String(localized: "badge_productive_day_title", defaultValue: "Verimli Gün", comment: "Productive Day Badge Title"),
            description: String(localized: "badge_productive_day_desc", defaultValue: "Tek günde 4 odaklanma seansı tamamladın!", comment: "Productive Day Badge Description"),
            requirementType: .focusSessionsDaily,
            requiredValue: 4,
            iconName: "calendar.badge.checkmark"
        ),
        Badge(
            name: String(localized: "badge_check_in_title", defaultValue: "Kendini Dinle", comment: "Check In Badge Title"),
            description: String(localized: "badge_check_in_desc", defaultValue: "7 kez ruh halini kaydettin.", comment: "Check In Badge Description"),
            requirementType: .moodCheckIns,
            requiredValue: 7,
            iconName: "heart.fill"
        ),
        Badge(
            name: String(localized: "badge_mood_observer_title", defaultValue: "Duygu Gözlemcisi", comment: "Mood Observer Badge Title"),
            description: String(localized: "badge_mood_observer_desc", defaultValue: "30 kez ruh halini kaydettin. Kendini tanıyorsun!", comment: "Mood Observer Badge Description"),
            requirementType: .moodCheckIns,
            requiredValue: 30,
            iconName: "face.smiling.fill"
        )
    ]

    /// Merges previously saved badges (unlock state) with the current
    /// predefined list. Badges are matched by requirement (type + value), which
    /// is stable across launches and languages, so new badges shipped in an
    /// update appear for existing users while their unlocked badges are kept.
    /// Name, description and icon are always refreshed from the predefined
    /// list so they follow the current app language.
    static func merge(saved: [Badge], with predefined: [Badge]) -> [Badge] {
        predefined.map { fresh in
            guard let old = saved.first(where: {
                $0.requirementType == fresh.requirementType && $0.requiredValue == fresh.requiredValue
            }) else {
                return fresh
            }
            return Badge(
                id: old.id,
                name: fresh.name,
                description: fresh.description,
                requirementType: fresh.requirementType,
                requiredValue: fresh.requiredValue,
                iconName: fresh.iconName,
                isUnlocked: old.isUnlocked,
                unlockedDate: old.unlockedDate
            )
        }
    }

    /// Tüm rozetleri başlangıç durumunda al (kilili)
    static func getAllBadges() -> [Badge] {
        return predefinedBadges
    }
}
