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
/// Renamed to avoid conflicts with other definitions and moved to top level
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
    
    /// Creates ZenUserStats from LocalDataManager
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

/// Singleton class for generating contextual responses with Zen wisdom
class ResponseGenerator {
    
    // MARK: - Singleton
    
    static let shared = ResponseGenerator()
    
    private init() {}
    
    // MARK: - Empathetic Openings (Geliştirilmiş Açılışlar)
    
    /// Kullanıcıyı anladığımızı hissettiren zenginleştirilmiş açılış mesajları
    /// Localized computed property to ensure correct language is fetched at runtime
    private var empatheticOpenings: [String] {
        [
            String(localized: "zen_opening_0", defaultValue: "Seni tüm kalbimle duyuyorum ve anlıyorum.", comment: "Empathetic opening 0"),
            String(localized: "zen_opening_1", defaultValue: "Bunu benimle paylaştığın için teşekkür ederim, yalnız değilsin.", comment: "Empathetic opening 1"),
            String(localized: "zen_opening_2", defaultValue: "Bu duyguyu hissetmen çok insani, çözüm için yanındayım.", comment: "Empathetic opening 2"),
            String(localized: "zen_opening_3", defaultValue: "Derin bir nefes alalım; hissettiklerin geçici, senin özün ise kalıcı.", comment: "Empathetic opening 3"),
            String(localized: "zen_opening_4", defaultValue: "Seni anlıyorum. Bazen zihin gürültülü olabilir, ama sessizlik hep orada.", comment: "Empathetic opening 4"),
            String(localized: "zen_opening_5", defaultValue: "Farkındalığın için seni tebrik ederim, bu ilk ve en önemli adım.", comment: "Empathetic opening 5"),
            String(localized: "zen_opening_6", defaultValue: "Bazen sadece durup hissetmek gerekir. Seni yargısızca dinliyorum.", comment: "Empathetic opening 6"),
            String(localized: "zen_opening_7", defaultValue: "Zihnin söylediklerini bir kenara bırakıp, kalbinin sesine kulak verelim.", comment: "Empathetic opening 7"),
            String(localized: "zen_opening_8", defaultValue: "Şu an hissettiğin her neyse, ona yer aç. Geçip gitmesine izin ver.", comment: "Empathetic opening 8"),
            String(localized: "zen_opening_9", defaultValue: "Yolculuğunda sana eşlik etmekten onur duyuyorum.", comment: "Empathetic opening 9")
        ]
    }
    
    // MARK: - Backup Zen Quotes (Yedek Alıntı Havuzu)
    
    /// Eğer Localizable.xcstrings'ten veri çekilemezse kullanılacak yedek havuz.
    /// Localized computed property
    private var backupZenQuotes: [String] {
        [
            String(localized: "zen_backup_quote_0", defaultValue: "\"Su akıştır, rüzgar esintir, akış ritmini bulmaktır.\"", comment: "Backup Zen quote 0"),
            String(localized: "zen_backup_quote_1", defaultValue: "\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\"", comment: "Backup Zen quote 1"),
            String(localized: "zen_backup_quote_2", defaultValue: "\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\"", comment: "Backup Zen quote 2"),
            String(localized: "zen_backup_quote_3", defaultValue: "\"Her nefes, yeni bir başlangıçtır.\"", comment: "Backup Zen quote 3"),
            String(localized: "zen_backup_quote_4", defaultValue: "\"Sessizlik, tüm cevapları içerir.\"", comment: "Backup Zen quote 4"),
            String(localized: "zen_backup_quote_5", defaultValue: "\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\"", comment: "Backup Zen quote 5"),
            String(localized: "zen_backup_quote_6", defaultValue: "\"Düşünce bulutları gelir ve geçer. Sen gökyüzüsün.\"", comment: "Backup Zen quote 6"),
            String(localized: "zen_backup_quote_7", defaultValue: "\"Tam burada, tam şimdi - sonsuzluk bu anda gizli.\"", comment: "Backup Zen quote 7"),
            String(localized: "zen_backup_quote_8", defaultValue: "\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\"", comment: "Backup Zen quote 8"),
            String(localized: "zen_backup_quote_9", defaultValue: "\"Barış dışarıda aranmaz, içeride keşfedilir.\"", comment: "Backup Zen quote 9"),
            String(localized: "zen_backup_quote_10", defaultValue: "\"Nefes, beden ve zihin arasındaki köprüdür.\"", comment: "Backup Zen quote 10"),
            String(localized: "zen_backup_quote_11", defaultValue: "\"Gel, gör, kabul et. Bu Zen'in yoludur.\"", comment: "Backup Zen quote 11"),
            String(localized: "zen_backup_quote_12", defaultValue: "\"Düşüşte bile zarafet vardır. Kalk ve devam et.\"", comment: "Backup Zen quote 12"),
            String(localized: "zen_backup_quote_13", defaultValue: "\"Sabır, bilgeliğin meyveleridir.\"", comment: "Backup Zen quote 13"),
            String(localized: "zen_backup_quote_14", defaultValue: "\"Her an meditasyon fırsatıdır.\"", comment: "Backup Zen quote 14")
        ]
    }
    
    // MARK: - Response Generation
    
    func generateResponse(
        for intent: UserIntent,
        sentiment: MessageSentiment,
        userStats: ZenUserStats? = nil
    ) -> ZenCoachResponse {
        
        // 1. Ana şablonu al
        var responseText = getResponseTemplate(for: intent, sentiment: sentiment)
        
        // 2. Zen Sözü Ekleme Mantığı
        // Cevap bir fallback (açılış cümlesi) ise MUTLAKA bir söz ekle.
        // Normal bir cevap ise %40 ihtimalle ekle (sürpriz faktörü).
        let isFallbackResponse = empatheticOpenings.contains(responseText)
        let shouldAddQuote = isFallbackResponse || Bool.random()
        
        if shouldAddQuote {
            var attempts = 0
            var randomQuote = ""
            
            // Cevabın içinde zaten geçen bir sözü tekrar eklememek için kontrol
            repeat {
                randomQuote = getRandomZenQuote()
                attempts += 1
            } while responseText.contains(randomQuote) && attempts < 3
            
            if !responseText.contains(randomQuote) {
                responseText += "\n\n\(randomQuote)"
            }
        }
        
        // 3. Kişiselleştirme (Streak, İsim vb.)
        let personalizedText = addPersonalization(to: responseText, with: userStats)
        
        // 4. Aksiyon Butonu
        let (actionText, actionURL) = getActionButton(for: intent)
        
        return ZenCoachResponse(
            text: personalizedText,
            intent: intent,
            sentiment: sentiment,
            actionText: actionText,
            actionURL: actionURL
        )
    }
    
    // MARK: - Zen Quotes Helper
    
    private let zenQuoteCount = 20
    
    private func getRandomZenQuote() -> String {
        let randomIndex = Int.random(in: 0..<zenQuoteCount)
        let key = "zen_quote_\(randomIndex)"
        
        // NSLocalizedString kullanarak çeviriyi al
        let quote = NSLocalizedString(key, comment: "")
        
        // Eğer NSLocalizedString anahtarın kendisini dönerse (çeviri yoksa),
        // yedek havuzdan rastgele bir söz seç.
        if quote == key {
            return backupZenQuotes.randomElement() ?? String(localized: "zen_backup_default", defaultValue: "\"Şimdiki an, sahip olduğun tek andır.\"", comment: "Default backup quote")
        }
        
        return quote
    }
    
    // MARK: - Response Templates
    
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
        
        // Varsayılan fallback mesajı
        let defaultFallback = String(localized: "zen_fallback_understanding", defaultValue: "Seni anlıyorum.", comment: "Default fallback response")
        
        guard count > 0 else {
            return empatheticOpenings.randomElement() ?? defaultFallback
        }
        
        let randomIndex = Int.random(in: 0..<count)
        let key = "response_\(intent.rawValue)_\(sentiment.rawValue)_\(randomIndex)"
        
        // NSLocalizedString ile dinamik anahtarı çek
        let localizedString = NSLocalizedString(key, comment: "")
        
        // Çeviri bulunamazsa (anahtarın kendisi dönerse),
        // zenginleştirilmiş açılış cümlelerinden birini veya fallback'i dön
        if localizedString == key {
            print("⚠️ Missing translation for key: \(key)")
            return empatheticOpenings.randomElement() ?? defaultFallback
        }
        
        return localizedString
    }
    
    // MARK: - Personalization
    
    private func addPersonalization(to response: String, with userStats: ZenUserStats?) -> String {
        guard let stats = userStats else { return response }
        var personalizedResponse = response
        
        // Streak mesajı (sadece anlamlıysa ve %30 ihtimalle, çok sıkmamak için)
        if stats.currentStreak > 2 && Int.random(in: 1...10) > 7 {
            let key = "personalization_streak"
            let template = NSLocalizedString(key, comment: "")
            
            // Çeviri varsa ekle
            if template != key {
                let streakMessage = "\n\n\(String(format: template, stats.currentStreak))"
                // Cevap çok uzun değilse ekle
                if personalizedResponse.count < 250 {
                    personalizedResponse += streakMessage
                }
            }
        }

        // Milestone kutlaması (100, 200, 300. dakikalarda)
        if stats.totalMinutes >= 60 && stats.totalMinutes % 100 < 15 {
             // Sadece milestone'a çok yakınsa göster
            let key = "personalization_milestone"
            let template = NSLocalizedString(key, comment: "")
            
            if template != key {
                let milestoneMessage = "\n\n\(String(format: template, stats.totalMinutes))"
                // Milestone mesajı varsa streak mesajını ezmesin diye sadece bunu ekle
                if !personalizedResponse.contains(milestoneMessage) {
                     personalizedResponse += milestoneMessage
                }
            }
        }
        
        return personalizedResponse
    }
    
    // MARK: - Action Buttons
    
    private func getActionButton(for intent: UserIntent) -> (text: String?, url: String?) {
        // Helper to safely get localized string or fallback
        // Fix: Using NSLocalizedString instead of String(localized:) for dynamic keys to avoid ambiguity
        func loc(_ key: String, defaultVal: String) -> String {
            let value = NSLocalizedString(key, comment: "")
            // If key is returned, it means no translation found, use defaultVal
            return value != key ? value : defaultVal
        }
        
        switch intent {
        case .stress, .breathing:
            return (loc("action_button_breathing", defaultVal: "Nefes Egzersizi Başlat"), intent.deepLinkURL)
        case .focus:
            return (loc("action_button_pomodoro", defaultVal: "Pomodoro Başlat"), intent.deepLinkURL)
        case .sleep:
            return (loc("action_button_478", defaultVal: "4-7-8 Tekniği"), intent.deepLinkURL)
        case .motivation:
            return (loc("action_button_garden", defaultVal: "Zen Bahçeni Gör"), intent.deepLinkURL)
        case .meditation:
            return (loc("action_button_meditation", defaultVal: "Meditasyon Öğren"), intent.deepLinkURL)
        case .progress:
            return (loc("action_button_progress", defaultVal: "İlerlemeni Gör"), intent.deepLinkURL)
        case .general:
            return (nil, nil)
        }
    }
}
