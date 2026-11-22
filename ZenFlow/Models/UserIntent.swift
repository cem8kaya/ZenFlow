//
//  UserIntent.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  User intent classification for Zen Coach feature.
//  Defines 8 categories of user intents with Turkish and English keywords.
//

import Foundation
import SwiftUI

// MARK: - User Intent

/// Represents the classified intent of a user's message
enum UserIntent: String, Codable, CaseIterable, Identifiable {
    case stress
    case anger
    case focus
    case sleep
    case breathing
    case motivation
    case meditation
    case progress
    case gratitude
    case general

    var id: String { rawValue }

    /// Display name localized
    var displayName: String {
        switch self {
        case .stress:
            return String(localized: "intent_stress", defaultValue: "Stres Yönetimi", comment: "Stress Management")
        case .anger:
            return String(localized: "intent_anger", defaultValue: "Öfke", comment: "Anger")
        case .gratitude:
            return String(localized: "intent_gratitude", defaultValue: "Şükran", comment: "Gratitude")
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
        case .anger:
            return "flame.fill"
        case .gratitude:
            return "heart.text.square.fill"
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

    /// Turkish and English keywords for intent matching
    /// Updated to ensure correct routing for bilingual support
    var keywords: [String] {
        switch self {
        case .stress:
            return [
                // Türkçe
                "stres", "kaygı", "endişe", "gergin", "huzursuz", "tedirgin", "zihinsel", "zihnim", "panik", "korku", "kaygılan", "stresli", "sıkıntı", "bunalım", "daraldım",
                // English
                "stress", "anxiety", "worry", "nervous", "restless", "panic", "mental", "mentally", "fear", "scared", "overwhelmed", "tension", "upset", "help"
            ]
        case .anger:
            return [
                // Türkçe
                "öfke", "kızgın", "kızdım", "sinir", "sinirli", "bağır", "çıldır", "nefret", "tepem attı", "deliriyorum", "hırs",
                // English
                "anger", "angry", "furious", "rage", "irritated", "mad at", "annoyed", "frustrated", "frustration"
            ]
        case .gratitude:
            return [
                // Türkçe
                "şükran", "şükret", "minnettar", "minnet", "müteşekkir", "şükür",
                // English
                "gratitude", "grateful", "thankful", "appreciate", "blessed"
            ]
        case .focus:
            return [
                // Türkçe
                "odak", "dikkat", "konsantrasyon", "dağınık", "çalış", "verim", "ders", "pomodoro", "odaklan", "çalışma", "konsantre", "zihin dağınıklığı",
                // English
                "focus", "attention", "concentrate", "concentration", "distracted", "distraction", "work", "study", "productive", "pomodoro", "efficiency"
            ]
        case .sleep:
            return [
                // Türkçe
                "uyku", "uyu", "dinlen", "yorgun", "bitkin", "uyuya", "gece", "yat", "uyuma", "uyumak", "uykusuz", "kabûs",
                // English
                "sleep", "insomnia", "tired", "exhausted", "rest", "night", "awake", "dream", "nap", "sleepy"
            ]
        case .breathing:
            return [
                // Türkçe
                "nefes", "soluk", "breathing", "box breathing", "4-7-8", "derin nefes", "nefes al", "soluk al", "nefes egzersiz", "egzersiz", "teknik",
                // English
                "breath", "breathing", "inhale", "exhale", "box breathing", "4-7-8", "deep breath", "lung", "exercise", "technique"
            ]
        case .motivation:
            return [
                // Türkçe
                "motivasyon", "başla", "istemi", "üşen", "enerji", "güç", "ilham", "cesaret", "isteksiz", "tembellik", "motivasyon bul", "bahçe", "zen bahçesi", "ağaç", "büyüme", "çiçek", "bitki",
                // English
                "motivation", "inspire", "inspiration", "energy", "power", "courage", "lazy", "procrastination", "start", "garden", "zen garden", "tree", "grow", "plant"
            ]
        case .meditation:
            return [
                // Türkçe
                "meditasyon", "mindfulness", "farkındalık", "meditasyon yap", "nasıl", "öğren", "meditasyon öğren", "başlangıç", "sakinleş", "huzur",
                // English
                "meditation", "mindfulness", "awareness", "meditate", "meditat", "how to", "learn", "beginner", "start", "calm", "peace"
            ]
        case .progress:
            return [
                // Türkçe
                "ilerleme", "gelişim", "istatistik", "rozet", "başarı", "seri", "gelişme", "streak", "stats", "durum", "skor", "puan", "hafta", "haftalık", "rapor", "nasıl gidiyorum", "kaç dakika",
                // English
                "progress", "improvement", "stats", "statistics", "badge", "achievement", "streak", "score", "status", "week", "weekly", "report", "how am i doing", "how many minutes"
            ]
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
        case .anger:
            // Calming Breath: a long exhale (premium falls back to Box Breathing)
            return "zenflow://breathing?exercise=calming"
        case .sleep:
            // Sleep Mode: soft sound, timer and a dimmed screen (free)
            return "zenflow://sleep"
        case .gratitude:
            return "zenflow://dailyzen"
        case .motivation:
            // Motivasyon intent'i Zen Bahçesi'ne yönlendiriyor
            return "zenflow://garden"
        case .meditation:
            // Calming Breath (Sakinleştirici Nefes) - ideal for meditation
            return "zenflow://breathing?exercise=calming"
        case .progress:
            return "zenflow://report"
        case .general:
            return nil
        }
    }
}
