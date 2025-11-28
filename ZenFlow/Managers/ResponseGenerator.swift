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
    private let empatheticOpenings = [
        "Seni tüm kalbimle duyuyorum ve anlıyorum.",
        "Bunu benimle paylaştığın için teşekkür ederim, yalnız değilsin.",
        "Bu duyguyu hissetmen çok insani, çözüm için yanındayım.",
        "Derin bir nefes alalım; hissettiklerin geçici, senin özün ise kalıcı.",
        "Seni anlıyorum. Bazen zihin gürültülü olabilir, ama sessizlik hep orada.",
        "Farkındalığın için seni tebrik ederim, bu ilk ve en önemli adım.",
        "Bazen sadece durup hissetmek gerekir. Seni yargısızca dinliyorum.",
        "Zihnin söylediklerini bir kenara bırakıp, kalbinin sesine kulak verelim.",
        "Şu an hissettiğin her neyse, ona yer aç. Geçip gitmesine izin ver.",
        "Yolculuğunda sana eşlik etmekten onur duyuyorum."
    ]
    
    // MARK: - Backup Zen Quotes (Yedek Alıntı Havuzu)
    
    /// Eğer Localizable.xcstrings'ten veri çekilemezse kullanılacak yedek havuz.
    /// Bu sayede asla "tek bir cümleye" sıkışıp kalmayız.
    private let backupZenQuotes = [
        "\"Su akıştır, rüzgar esintir, akış ritmini bulmaktır.\"",
        "\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\"",
        "\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\"",
        "\"Her nefes, yeni bir başlangıçtır.\"",
        "\"Sessizlik, tüm cevapları içerir.\"",
        "\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\"",
        "\"Düşünce bulutları gelir ve geçer. Sen gökyüzüsün.\"",
        "\"Tam burada, tam şimdi - sonsuzluk bu anda gizli.\"",
        "\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\"",
        "\"Barış dışarıda aranmaz, içeride keşfedilir.\"",
        "\"Nefes, beden ve zihin arasındaki köprüdür.\"",
        "\"Gel, gör, kabul et. Bu Zen'in yoludur.\"",
        "\"Düşüşte bile zarafet vardır. Kalk ve devam et.\"",
        "\"Sabır, bilgeliğin meyveleridir.\"",
        "\"Her an meditasyon fırsatıdır.\""
    ]
    
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
        
        let quote = NSLocalizedString(key, comment: "")
        
        // Eğer NSLocalizedString anahtarın kendisini dönerse (çeviri yoksa),
        // statik tek bir cümle yerine 'backupZenQuotes' dizisinden rastgele seç.
        if quote == key {
            return backupZenQuotes.randomElement() ?? "\"Şimdiki an, sahip olduğun tek andır.\""
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
        
        guard count > 0 else {
            return empatheticOpenings.randomElement() ?? "Seni anlıyorum."
        }
        
        let randomIndex = Int.random(in: 0..<count)
        let key = "response_\(intent.rawValue)_\(sentiment.rawValue)_\(randomIndex)"
        
        let localizedString = NSLocalizedString(key, comment: "")
        
        // Çeviri bulunamazsa, zenginleştirilmiş açılış cümlelerinden birini dön
        if localizedString == key {
            print("⚠️ Missing translation for key: \(key)")
            return empatheticOpenings.randomElement() ?? "Seni anlıyorum."
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
        func loc(_ key: String, defaultVal: String) -> String {
            let res = NSLocalizedString(key, comment: "")
            return res == key ? defaultVal : res
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
