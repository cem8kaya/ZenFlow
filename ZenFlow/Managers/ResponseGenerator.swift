//
//  ResponseGenerator.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Context-aware response generation for Zen Coach.
//  Provides empathetic, actionable responses with Zen wisdom.
//

import Foundation

// MARK: - Response Generator

/// Singleton class for generating contextual responses with Zen wisdom
class ResponseGenerator {
    
    // MARK: - Singleton
    
    static let shared = ResponseGenerator()
    
    private init() {}
    
    // MARK: - Response Generation
    
    /// Generates a contextual response based on intent and sentiment
    /// - Parameters:
    ///   - intent: Classified user intent
    ///   - sentiment: Analyzed sentiment
    ///   - userStats: User's meditation statistics (optional)
    /// - Returns: Generated response with action
    func generateResponse(
        for intent: UserIntent,
        sentiment: MessageSentiment,
        userStats: UserStats? = nil
    ) -> ZenCoachResponse {
        // Get base response template with possible Zen quote
        let responseText = getResponseTemplate(for: intent, sentiment: sentiment)
        
        // Add personalization if user stats available
        let personalizedText = addPersonalization(to: responseText, with: userStats)
        
        // Get action text and URL
        let (actionText, actionURL) = getActionButton(for: intent)
        
        return ZenCoachResponse(
            text: personalizedText,
            intent: intent,
            sentiment: sentiment,
            actionText: actionText,
            actionURL: actionURL
        )
    }
    
    // MARK: - Zen Quotes
    
    /// Total number of available Zen quotes
    private let zenQuoteCount = 20
    
    /// Gets a random Zen quote (localized)
    private func getRandomZenQuote() -> String {
        let randomIndex = Int.random(in: 0..<zenQuoteCount)
        // DÜZELTME 1: Foundation ile uyumlu NSLocalizedString kullanıldı
        return NSLocalizedString("zen_quote_\(randomIndex)", comment: "Zen quote")
    }
    
    // MARK: - Response Templates
    
    /// Number of response templates per intent-sentiment combination
    private let responseTemplateCount: [UserIntent: [MessageSentiment: Int]] = [
        .stress: [.negative: 3, .neutral: 3, .positive: 3],
        .focus: [.negative: 3, .neutral: 3, .positive: 3],
        .sleep: [.negative: 3, .neutral: 3, .positive: 3],
        .breathing: [.negative: 3, .neutral: 3, .positive: 3],
        .motivation: [.negative: 3, .neutral: 3, .positive: 3],
        .meditation: [.negative: 3, .neutral: 3, .positive: 3],
        .progress: [.negative: 3, .neutral: 3, .positive: 3],
        .general: [.negative: 3, .neutral: 3, .positive: 3]
    ]
    
    /// Gets response template based on intent and sentiment (localized)
    private func getResponseTemplate(for intent: UserIntent, sentiment: MessageSentiment) -> String {
        // Get count of templates for this combination
        let count = responseTemplateCount[intent]?[sentiment] ?? 0
        
        guard count > 0 else {
            let fallback = String(localized: "response_fallback", defaultValue: "Anlıyorum. Sana nasıl yardımcı olabilirim? 🧘", comment: "Fallback response")
            return "\(fallback)\n\n\(getRandomZenQuote())"
        }
        
        // Randomly select a template index
        let randomIndex = Int.random(in: 0..<count)
        let key = "response_\(intent.rawValue)_\(sentiment.rawValue)_\(randomIndex)"
        // DÜZELTME 2: Foundation ile uyumlu NSLocalizedString kullanıldı
        return NSLocalizedString(key, comment: "Response template")
    }
    
    
    // MARK: - Personalization
    
    /// Adds personalization to response based on user statistics
    private func addPersonalization(to response: String, with userStats: UserStats?) -> String {
        guard let stats = userStats else {
            return response
        }
        
        var personalizedResponse = response
        
        // Add streak information
        if stats.currentStreak > 0 {
            let streakTemplate = String(localized: "personalization_streak", defaultValue: "🔥 Bu arada, %d günlük serin devam ediyor! Harika bir disiplin.", comment: "Streak message")
            let streakMessage = "\n\n\(String(format: streakTemplate, stats.currentStreak))"
            personalizedResponse += streakMessage
        }

        // Add milestone celebration
        if stats.totalMinutes >= 300 && stats.totalMinutes % 100 < 10 {
            let milestoneTemplate = String(localized: "personalization_milestone", defaultValue: "🎉 %d dakikayı geçtin! Bu muazzam bir başarı!", comment: "Milestone message")
            let milestoneMessage = "\n\n\(String(format: milestoneTemplate, stats.totalMinutes))"
            personalizedResponse += milestoneMessage
        }
        
        return personalizedResponse
    }
    
    // MARK: - Action Buttons
    
    /// Gets action button text and URL for intent
    private func getActionButton(for intent: UserIntent) -> (text: String?, url: String?) {
        switch intent {
        case .stress, .breathing:
            return (String(localized: "action_button_breathing", defaultValue: "Nefes Egzersizi Başlat", comment: "Start breathing exercise"), intent.deepLinkURL)
        case .focus:
            return (String(localized: "action_button_pomodoro", defaultValue: "Pomodoro Başlat", comment: "Start Pomodoro"), intent.deepLinkURL)
        case .sleep:
            return (String(localized: "action_button_478", defaultValue: "4-7-8 Tekniği", comment: "4-7-8 Technique"), intent.deepLinkURL)
        case .motivation:
            return (String(localized: "action_button_garden", defaultValue: "Zen Bahçeni Gör", comment: "View Zen Garden"), intent.deepLinkURL)
        case .meditation:
            return (String(localized: "action_button_meditation", defaultValue: "Meditasyon Öğren", comment: "Learn meditation"), intent.deepLinkURL)
        case .progress:
            return (String(localized: "action_button_progress", defaultValue: "İlerlemeni Gör", comment: "View progress"), intent.deepLinkURL)
        case .general:
            return (nil, nil)
        }
    }
}

// MARK: - User Stats

/// User statistics for personalization
struct UserStats {
    let totalMinutes: Int
    let totalSessions: Int
    let currentStreak: Int
    let longestStreak: Int
    
    init(totalMinutes: Int, totalSessions: Int, currentStreak: Int, longestStreak: Int) {
        self.totalMinutes = totalMinutes
        self.totalSessions = totalSessions
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
    }
    
    /// Creates UserStats from LocalDataManager
    static func fromLocalData() -> UserStats {
        let manager = LocalDataManager.shared
        return UserStats(
            totalMinutes: manager.totalMinutes,
            totalSessions: manager.totalSessions,
            currentStreak: manager.currentStreak,
            longestStreak: manager.longestStreak
        )
    }
}
