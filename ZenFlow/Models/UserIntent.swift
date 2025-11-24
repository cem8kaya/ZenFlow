//
//  UserIntent.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  User intent classification for message analysis.
//

import Foundation

// MARK: - User Intent

/// Represents the intent or purpose behind a user's message
enum UserIntent: String, Codable, CaseIterable {
    case meditation
    case breathing
    case focus
    case mood
    case relaxation
    case sleep
    case stress
    case anxiety
    case exercise
    case general

    /// Display name in Turkish
    var displayName: String {
        switch self {
        case .meditation:
            return "Meditasyon"
        case .breathing:
            return "Nefes Egzersizi"
        case .focus:
            return "Odaklanma"
        case .mood:
            return "Ruh Hali"
        case .relaxation:
            return "Rahatlama"
        case .sleep:
            return "Uyku"
        case .stress:
            return "Stres Yönetimi"
        case .anxiety:
            return "Kaygı Azaltma"
        case .exercise:
            return "Egzersiz"
        case .general:
            return "Genel"
        }
    }

    /// Turkish keywords for intent matching
    var keywords: [String] {
        switch self {
        case .meditation:
            return ["meditasyon", "medit", "huzur", "sakinlik", "dinginlik", "zen"]
        case .breathing:
            return ["nefes", "soluk", "breathing", "nefes al", "nefes ver", "derin nefes"]
        case .focus:
            return ["odak", "konsantrasyon", "dikkat", "çalış", "pomodoro", "çalışma", "verimli"]
        case .mood:
            return ["ruh hal", "duygu", "his", "mood", "nasılsın", "durum"]
        case .relaxation:
            return ["rahatla", "gevşe", "dinlen", "relax", "huzur", "sakin"]
        case .sleep:
            return ["uyku", "uyu", "yat", "uyumak", "uyuyamıyorum", "uyumadan önce", "gece"]
        case .stress:
            return ["stres", "gergin", "baskı", "yük", "stresli", "gerginlik"]
        case .anxiety:
            return ["kaygı", "endişe", "korku", "panik", "tedirgin", "huzursuz", "anxiety"]
        case .exercise:
            return ["egzersiz", "antrenman", "spor", "hareket", "yoga", "jimnastik"]
        case .general:
            return []
        }
    }

    /// Emoji representation
    var emoji: String {
        switch self {
        case .meditation:
            return "🧘"
        case .breathing:
            return "🌬️"
        case .focus:
            return "🎯"
        case .mood:
            return "😊"
        case .relaxation:
            return "😌"
        case .sleep:
            return "😴"
        case .stress:
            return "😓"
        case .anxiety:
            return "😰"
        case .exercise:
            return "💪"
        case .general:
            return "💬"
        }
    }
}
