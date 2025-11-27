//
//  UserIntent.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  User intent classification for Zen Coach feature.
//  Defines 8 categories of user intents with Turkish keywords and deep links.
//

import Foundation
import SwiftUI

// MARK: - User Intent

/// Represents the classified intent of a user's message
enum UserIntent: String, Codable, CaseIterable, Identifiable {
    case stress
    case focus
    case sleep
    case breathing
    case motivation
    case meditation
    case progress
    case general

    var id: String { rawValue }

    /// Display name localized
    var displayName: String {
        switch self {
        case .stress:
            return String(localized: "intent_stress", defaultValue: "Stres Yönetimi", comment: "Stress Management")
        case .focus:
            return String(localized: "intent_focus", defaultValue: "Odaklanma", comment: "Focus")
        case .sleep:
            return String(localized: "intent_sleep", defaultValue: "Uyku", comment: "Sleep")
        case .breathing:
            return String(localized: "intent_breathing", defaultValue: "Nefes Egzersizi", comment: "Breathing Exercise")
        case .motivation:
            return String(localized: "intent_motivation", defaultValue: "Motivasyon", comment: "Motivation")
        case .meditation:
            return String(localized: "intent_meditation", defaultValue: "Meditasyon", comment: "Meditation")
        case .progress:
            return String(localized: "intent_progress", defaultValue: "İlerleme", comment: "Progress")
        case .general:
            return String(localized: "intent_general", defaultValue: "Genel", comment: "General")
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .stress:
            return "heart.circle.fill"
        case .focus:
            return "target"
        case .sleep:
            return "moon.stars.fill"
        case .breathing:
            return "wind"
        case .motivation:
            return "bolt.fill"
        case .meditation:
            return "leaf.circle.fill"
        case .progress:
            return "chart.bar.fill"
        case .general:
            return "message.fill"
        }
    }

    /// Turkish keywords for intent matching
    var keywords: [String] {
        switch self {
        case .stress:
            return ["stres", "kaygı", "endişe", "gergin", "huzursuz", "sinirli", "tedirgin", "panik", "korku", "kaygılan", "stresli", "sıkıntı"]
        case .focus:
            return ["odak", "dikkat", "konsantrasyon", "dağınık", "çalış", "verim", "iş", "ders", "pomodoro", "odaklan", "çalışma", "konsantre"]
        case .sleep:
            return ["uyku", "uyu", "dinlen", "yorgun", "bitkin", "uyuya", "gece", "yat", "uyuma", "uyumak", "uykusuz"]
        case .breathing:
            return ["nefes", "soluk", "breathing", "box breathing", "4-7-8", "derin nefes", "nefes al", "soluk al", "nefes egzersiz"]
        case .motivation:
            return ["motivasyon", "başla", "istemi", "üşen", "enerji", "güç", "ilham", "cesaret", "isteksiz", "tembellik", "motivasyon bul"]
        case .meditation:
            return ["meditasyon", "mindfulness", "farkındalık", "meditasyon yap", "nasıl", "öğren", "meditasyon öğren", "başlangıç"]
        case .progress:
            return ["ilerleme", "gelişim", "istatistik", "rozet", "başarı", "seri", "bahçe", "ağaç", "gelişme", "streak", "stats"]
        case .general:
            return []
        }
    }

    /// Deep link URL for navigation with appropriate exercise parameters
    var deepLinkURL: String? {
        switch self {
        case .stress, .breathing:
            // Box Breathing (Kutu Nefesi) - ideal for stress
            return "zenflow://breathing?exercise=box"
        case .focus:
            return "zenflow://focus"
        case .sleep:
            // 4-7-8 Technique - ideal for sleep
            return "zenflow://breathing?exercise=478"
        case .motivation:
            return "zenflow://garden"
        case .meditation:
            // Calming Breath (Sakinleştirici Nefes) - ideal for meditation
            return "zenflow://breathing?exercise=calming"
        case .progress:
            return "zenflow://badges"
        case .general:
            return nil
        }
    }
}
