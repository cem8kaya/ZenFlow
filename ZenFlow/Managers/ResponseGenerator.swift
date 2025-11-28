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

// MARK: - Zen User Stats (Moved to Global Scope)

/// User statistics for personalization
struct ZenUserStats {
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
    
    static func fromLocalData() -> ZenUserStats {
        let manager = LocalDataManager.shared
        return ZenUserStats(
            totalMinutes: manager.totalMinutes,
            totalSessions: manager.totalSessions,
            currentStreak: manager.currentStreak,
            longestStreak: manager.longestStreak
        )
    }
}

// MARK: - Response Generator

class ResponseGenerator {
    
    static let shared = ResponseGenerator()
    
    private init() {}
    
    // MARK: - Empathetic Openings
    private var empatheticOpenings: [String] {
        [
            String(localized: "zen_opening_0", defaultValue: "Seni tüm kalbimle duyuyorum ve anlıyorum."),
            String(localized: "zen_opening_1", defaultValue: "Bunu benimle paylaştığın için teşekkür ederim, yalnız değilsin."),
            String(localized: "zen_opening_2", defaultValue: "Bu duyguyu hissetmen çok insani, çözüm için yanındayım."),
            String(localized: "zen_opening_3", defaultValue: "Derin bir nefes alalım; hissettiklerin geçici, senin özün ise kalıcı."),
            String(localized: "zen_opening_4", defaultValue: "Seni anlıyorum. Bazen zihin gürültülü olabilir, ama sessizlik hep orada."),
            String(localized: "zen_opening_5", defaultValue: "Farkındalığın için seni tebrik ederim, bu ilk ve en önemli adım."),
            String(localized: "zen_opening_6", defaultValue: "Bazen sadece durup hissetmek gerekir. Seni yargısızca dinliyorum."),
            String(localized: "zen_opening_7", defaultValue: "Zihnin söylediklerini bir kenara bırakıp, kalbinin sesine kulak verelim."),
            String(localized: "zen_opening_8", defaultValue: "Şu an hissettiğin her neyse, ona yer aç. Geçip gitmesine izin ver."),
            String(localized: "zen_opening_9", defaultValue: "Yolculuğunda sana eşlik etmekten onur duyuyorum.")
        ]
    }
    
    // MARK: - Backup Zen Quotes
    private var backupZenQuotes: [String] {
        [
            String(localized: "zen_backup_quote_0", defaultValue: "\"Su akıştır, rüzgar esintir, akış ritmini bulmaktır.\""),
            String(localized: "zen_backup_quote_1", defaultValue: "\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\""),
            String(localized: "zen_backup_quote_2", defaultValue: "\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\""),
            String(localized: "zen_backup_quote_3", defaultValue: "\"Her nefes, yeni bir başlangıçtır.\""),
            String(localized: "zen_backup_quote_4", defaultValue: "\"Sessizlik, tüm cevapları içerir.\""),
            String(localized: "zen_backup_quote_5", defaultValue: "\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\""),
            String(localized: "zen_backup_quote_6", defaultValue: "\"Düşünce bulutları gelir ve geçer. Sen gökyüzüsün.\""),
            String(localized: "zen_backup_quote_7", defaultValue: "\"Tam burada, tam şimdi - sonsuzluk bu anda gizli.\""),
            String(localized: "zen_backup_quote_8", defaultValue: "\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\""),
            String(localized: "zen_backup_quote_9", defaultValue: "\"Barış dışarıda aranmaz, içeride keşfedilir.\""),
            String(localized: "zen_backup_quote_10", defaultValue: "\"Nefes, beden ve zihin arasındaki köprüdür.\""),
            String(localized: "zen_backup_quote_11", defaultValue: "\"Gel, gör, kabul et. Bu Zen'in yoludur.\""),
            String(localized: "zen_backup_quote_12", defaultValue: "\"Düşüşte bile zarafet vardır. Kalk ve devam et.\""),
            String(localized: "zen_backup_quote_13", defaultValue: "\"Sabır, bilgeliğin meyveleridir.\""),
            String(localized: "zen_backup_quote_14", defaultValue: "\"Her an meditasyon fırsatıdır.\"")
        ]
    }
    
    // MARK: - Response Generation
    
    func generateResponse(
        for intent: UserIntent,
        sentiment: MessageSentiment,
        userStats: ZenUserStats? = nil
    ) -> ZenCoachResponse {
        
        var responseText = getResponseTemplate(for: intent, sentiment: sentiment)
        
        let isFallbackResponse = empatheticOpenings.contains(responseText)
        let shouldAddQuote = isFallbackResponse || Bool.random()
        
        if shouldAddQuote {
            var attempts = 0
            var randomQuote = ""
            
            repeat {
                randomQuote = getRandomZenQuote()
                attempts += 1
            } while responseText.contains(randomQuote) && attempts < 3
            
            if !responseText.contains(randomQuote) {
                responseText += "\n\n\(randomQuote)"
            }
        }
        
        let personalizedText = addPersonalization(to: responseText, with: userStats)
        let (actionText, actionURL) = getActionButton(for: intent)
        
        return ZenCoachResponse(
            text: personalizedText,
            intent: intent,
            sentiment: sentiment,
            actionText: actionText,
            actionURL: actionURL
        )
    }
    
    private let zenQuoteCount = 20
    
    private func getRandomZenQuote() -> String {
        let randomIndex = Int.random(in: 0..<zenQuoteCount)
        let key = "zen_quote_\(randomIndex)"
        
        let quote = NSLocalizedString(key, comment: "")
        
        if quote == key {
            return backupZenQuotes.randomElement() ?? String(localized: "zen_backup_default", defaultValue: "\"Şimdiki an, sahip olduğun tek andır.\"")
        }
        
        return quote
    }
    
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
    
    private func getResponseTemplate(for intent: UserIntent, sentiment: MessageSentiment) -> String {
        let count = responseTemplateCount[intent]?[sentiment] ?? 0
        let defaultFallback = String(localized: "zen_fallback_understanding", defaultValue: "Seni anlıyorum.")
        
        guard count > 0 else {
            return empatheticOpenings.randomElement() ?? defaultFallback
        }
        
        let randomIndex = Int.random(in: 0..<count)
        let key = "response_\(intent.rawValue)_\(sentiment.rawValue)_\(randomIndex)"
        
        let localizedString = NSLocalizedString(key, comment: "")
        
        if localizedString == key {
            print("⚠️ Missing translation for key: \(key)")
            return empatheticOpenings.randomElement() ?? defaultFallback
        }
        
        return localizedString
    }
    
    private func addPersonalization(to response: String, with userStats: ZenUserStats?) -> String {
        guard let stats = userStats else { return response }
        var personalizedResponse = response
        
        if stats.currentStreak > 2 && Int.random(in: 1...10) > 7 {
            let key = "personalization_streak"
            let template = NSLocalizedString(key, comment: "")
            
            if template != key {
                let streakMessage = "\n\n\(String(format: template, stats.currentStreak))"
                if personalizedResponse.count < 250 {
                    personalizedResponse += streakMessage
                }
            }
        }

        if stats.totalMinutes >= 60 && stats.totalMinutes % 100 < 15 {
            let key = "personalization_milestone"
            let template = NSLocalizedString(key, comment: "")
            
            if template != key {
                let milestoneMessage = "\n\n\(String(format: template, stats.totalMinutes))"
                if !personalizedResponse.contains(milestoneMessage) {
                     personalizedResponse += milestoneMessage
                }
            }
        }
        
        return personalizedResponse
    }
    
    // MARK: - Action Buttons
    
    private func getActionButton(for intent: UserIntent) -> (text: String?, url: String?) {
        switch intent {
        case .stress, .breathing:
            return (String(localized: "action_button_breathing", defaultValue: "Nefes Egzersizi Başlat"), intent.deepLinkURL)
        case .focus:
            return (String(localized: "action_button_pomodoro", defaultValue: "Pomodoro Başlat"), intent.deepLinkURL)
        case .sleep:
            return (String(localized: "action_button_478", defaultValue: "4-7-8 Tekniği"), intent.deepLinkURL)
        case .motivation:
            return (String(localized: "action_button_garden", defaultValue: "Zen Bahçeni Gör"), intent.deepLinkURL)
        case .meditation:
            return (String(localized: "action_button_meditation", defaultValue: "Meditasyon Öğren"), intent.deepLinkURL)
        case .progress:
            return (String(localized: "action_button_progress", defaultValue: "İlerlemeni Gör"), intent.deepLinkURL)
        case .general:
            return (nil, nil)
        }
    }
}
