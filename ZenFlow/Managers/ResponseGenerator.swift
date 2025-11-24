//
//  ResponseGenerator.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Context-aware response generation for Zen Coach.
//  Provides empathetic, actionable responses based on intent and sentiment.
//

import Foundation

// MARK: - Response Generator

/// Singleton class for generating contextual responses
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
        // Get base response template
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

    // MARK: - Response Templates

    /// Gets response template based on intent and sentiment
    private func getResponseTemplate(for intent: UserIntent, sentiment: MessageSentiment) -> String {
        let templates = responseTemplates[intent] ?? [:]
        let sentimentTemplates = templates[sentiment] ?? []

        guard !sentimentTemplates.isEmpty else {
            return "Anlıyorum. Sana nasıl yardımcı olabilirim? 🧘"
        }

        // Randomly select a template for variety
        return sentimentTemplates.randomElement() ?? sentimentTemplates[0]
    }

    /// Response templates for all intents and sentiments
    private let responseTemplates: [UserIntent: [MessageSentiment: [String]]] = [
        .stress: [
            .negative: [
                "Stresli hissetmek tamamen normal. Şimdi birkaç dakika kendine ayır. Box Breathing egzersizi ile başlamak ister misin? 🫁",
                "Anlıyorum, zor bir gün geçiriyorsun. Derin nefes almak stresi azaltmanın en hızlı yolu. Beraber başlayalım mı? 🌊",
                "Stres zamanla zihinsel yorgunluk yaratabilir. 5 dakikalık nefes egzersizi ile rahatlamaya ne dersin? 💙"
            ],
            .neutral: [
                "Stres yönetimi için en etkili yöntem düzenli nefes egzersizleri. Hangi tekniği denemek istersin? 🧘",
                "Stresle baş etmenin birçok yolu var. Nefes egzersizleri, meditasyon veya odaklanma teknikleri. Seninle uygun olanı bulalım. ✨",
                "Günlük nefes egzersizleri stresi %40 oranında azaltıyor. Başlamak için hazır mısın? 🌟"
            ],
            .positive: [
                "Harika! Stresinle baş etmeye hazırsın. Nefes egzersizlerimizi görmek ister misin? ✨",
                "Proaktif yaklaşım mükemmel! Box Breathing veya 4-7-8 tekniğinden hangisini denemek istersin? 🌈",
                "Süper! Stres yönetiminde ilk adım farkındalık. Şimdi pratik yapalım! 🚀"
            ]
        ],
        .focus: [
            .negative: [
                "Odaklanmakta zorlanmak çok yaygın. Önce zihnini sakinleştir, sonra Pomodoro ile başla. Deneyelim mi? 🎯",
                "Dağınık hissetmek normal. 2 dakika nefes egzersizi + 25 dakika odaklanma = Harika sonuçlar! 💡",
                "Dikkat dağınıklığı günümüzün en büyük sorunu. Ama çözümü var: Pomodoro tekniği! Gösterayim mi? ⏰"
            ],
            .neutral: [
                "Odaklanma için Pomodoro tekniği harika çalışır: 25 dakika derin konsantrasyon + 5 dakika mola. Deneyelim mi? ⏰",
                "Verimli çalışmanın sırrı: Kısa aralıklarla yoğun odaklanma. Pomodoro ile başlamaya hazır mısın? 🎯",
                "Konsantrasyon kas gibidir, egzersiz gerektirir. Pomodoro tekniği ile günlük antrenman yapalım! 💪"
            ],
            .positive: [
                "Harika enerji! Şimdi bu enerjiyi Pomodoro ile odaklanmaya kanalize et! 🚀",
                "Motivasyonun yüksek! Bu tam Pomodoro başlatma zamanı. Hadi gidelim! ⚡",
                "Süper! İyi odaklanma + düzenli molalar = Maksimum verim. Başlıyoruz! 🎯"
            ]
        ],
        .sleep: [
            .negative: [
                "Uyku için en etkili teknik: 4-7-8 nefes egzersizi. Dr. Andrew Weil'in önerisi ile 5 dakikada uyuyabilirsin. 🌙",
                "Uykusuzluk zor bir durum. 4-7-8 tekniği sinir sistemini sakinleştirir. Denemeye hazır mısın? 💤",
                "Zihnini yatıştırmak için derin nefes alma egzersizi yapalım. Vücudun dinlenmeye hazır hale gelecek. 🌃"
            ],
            .neutral: [
                "Kaliteli uyku için zihinsel gevşeme şart. 4-7-8 nefes tekniği bunun için tasarlandı. Göstereyim mi? 🛌",
                "Uyku öncesi rutini çok önemli. 5-10 dakika nefes egzersizi ile uyku kalitenizi artırabilirsiniz. 🌙",
                "Derin uyku için parasempatik sinir sistemini aktive etmeliyiz. Box Breathing tam bunun için! 💫"
            ],
            .positive: [
                "İyi bir uyku rutini oluşturmak istemen harika! 4-7-8 tekniği ile başlayalım. 🌟",
                "Uyku hijyeni için proaktif adım atmak mükemmel! Nefes egzersizlerine bakalım. 🌙",
                "Süper! Düzenli uyku rutini = Daha enerjik günler. Hadi başlayalım! ✨"
            ]
        ],
        .breathing: [
            .negative: [
                "Nefes almakta zorlanıyorsan, önce rahat bir pozisyon bul. Box Breathing ile başlamak ister misin? 🫁",
                "Derin nefes alma zihin ve bedeni sakinleştirir. Beraber yavaşça başlayalım. 🌊",
                "Nefes egzersizleri çok etkili. 3-4 dakika bile fark yaratıyor. Denemek ister misin? 💙"
            ],
            .neutral: [
                "Nefes egzersizlerimizde 3 teknik var: Box Breathing, 4-7-8, ve Derin Nefes. Hangisini görmek istersin? 🫁",
                "Nefes kontrolü meditasyonun temelidir. Hangi teknikle başlamak istersin? 🧘",
                "Farklı nefes teknikleri farklı amaçlara hizmet eder. Sana uygun olanı bulalım! 🌬️"
            ],
            .positive: [
                "Harika seçim! Nefes egzersizleri zihin-beden bağlantısını güçlendirir. Hadi başlayalım! ✨",
                "Süper! Düzenli nefes pratiği hayat kalitesini artırır. Hangi tekniği deneyelim? 🌟",
                "Mükemmel! Nefes farkındalığı mindfulness'ın kalbidir. İlk adımı atalım! 🚀"
            ]
        ],
        .motivation: [
            .negative: [
                "Motivasyon eksikliği yaşamak insani. Küçük adımlar atmak çok etkili. 2 dakikalık bir egzersiz ile başlamaya ne dersin? 💪",
                "İlham bulmak zor olabilir. Ama bazen sadece başlamak yeterli. Beraber küçük bir adım atalım mı? 🌱",
                "Tembellik hissi normaldir. Zen bahçene bakmak veya kısa bir meditasyon seni motive edebilir. Hangisi? 🌸"
            ],
            .neutral: [
                "Motivasyon dalgalıdır, önemli olan süreklilik. Küçük kazanımlar büyük değişim yaratır. Başlayalım mı? 🎯",
                "En zor kısım başlamaktır. Bir kez başladığında momentum gelir. 5 dakikalık bir egzersiz ile deneyelim mi? ⚡",
                "Zen bahçen ve rozetlerin sana ilham verebilir. İlerlemenize bakmak ister misin? 🌟"
            ],
            .positive: [
                "İşte bu enerji! Şimdi bu motivasyonu bir egzersize kanalize edelim! 🚀",
                "Harika! Motivasyonlu anları değerlendirmek çok önemli. Hadi başlayalım! ⚡",
                "Süper enerji! Bu momentum ile neler başarabileceğini görelim! 💫"
            ]
        ],
        .meditation: [
            .negative: [
                "Meditasyon öğrenmek göz korkutucu gelebilir, ama aslında çok basit. 2 dakikalık bir deneme ile başlamak ister misin? 🧘",
                "Herkes meditasyon yapabilir, pratik gerektirir. Basit nefes odaklı bir egzersiz ile başlayalım mı? 🌸",
                "Meditasyonun 'yanlış' yapılma şekli yoktur. Rahat ol ve deneyelim. Başlamaya hazır mısın? 💙"
            ],
            .neutral: [
                "Meditasyon nefes farkındalığı ile başlar. Adım adım öğreneceğiz. İlk egzersizi görmek ister misin? 🧘",
                "Mindfulness pratiği hayatı değiştirir. Başlangıç seviyesi egzersizlerimiz tam sana göre. Bakalım mı? ✨",
                "Meditasyon öğrenmek yolculuktur. Her gün biraz pratik = Büyük gelişim. Başlayalım mı? 🌟"
            ],
            .positive: [
                "Harika karar! Meditasyon öğrenmek en güzel hediyelerden biri. Hadi ilk adımı atalım! 🌈",
                "Mükemmel! Meditasyon pratiği zihinsel netlik getirir. İlk egzersizimizi görelim! ✨",
                "Süper! Meditasyon öğrenmeye istekli olmak başarının yarısı. Başlıyoruz! 🚀"
            ]
        ],
        .progress: [
            .negative: [
                "İlerleme görmek zaman alır, ama sen harika gidiyorsun! İstatistiklerini görmek ister misin? 📊",
                "Her küçük adım önemli. Zen bahçen ve rozetlerin gelişimini gösteriyor. Bakalım mı? 🌱",
                "Kendini karşılaştırma, kendi yolculuğuna odaklan. İlerlemeniz muhtemelen düşündüğünden iyi! 📈"
            ],
            .neutral: [
                "İstatistiklerini görmek motivasyon artırıcı. Toplam süren, serin ve rozetlerin burada! 📊",
                "Gelişimini takip etmek önemli. Zen bahçene ve rozetlerine bakmaya ne dersin? 🏆",
                "İlerleme raporunu görmek ister misin? Toplam seans, dakika ve başarıların burada! 📈"
            ],
            .positive: [
                "Harika! İlerleme takibi seni daha da motive edecek. Rozetlerine ve Zen bahçene bakalım! 🏆",
                "Süper! Başarılarını görmek çok keyifli. İstatistiklerin ve rozetlerin burada! ✨",
                "Mükemmel! Kendini takip etmek başarıyı artırır. Hadi ilerlemenize bakalım! 🌟"
            ]
        ],
        .general: [
            .negative: [
                "Üzgün görünüyorsun. Sana nasıl yardımcı olabilirim? Nefes egzersizi, meditasyon veya sadece konuşmak ister misin? 💙",
                "Anlıyorum. Biraz rahatlama egzersizi yapmak ister misin? Beraber bir şeyler bulalım. 🌸",
                "Zor zamanlar herkesin başına gelir. Nasıl destek olabilirim? 🤗"
            ],
            .neutral: [
                "Merhaba! Sana bugün nasıl yardımcı olabilirim? Stres, uyku, odaklanma veya başka bir konuda mı destek istiyorsun? 🧘",
                "Anlıyorum. Meditasyon, nefes egzersizleri, Pomodoro veya ilerleme takibi konusunda yardımcı olabilirim. Hangi alan ilgini çekiyor? ✨",
                "Senin için buradayım. Ne konuda rehberlik istiyorsun? 🌟"
            ],
            .positive: [
                "Harika bir enerji! Bugün ne yapmak istersin? Meditasyon, odaklanma egzersizi veya ilerleme kontrolü? 🌈",
                "Güzel bir gün gibi görünüyor! Hangi konuda destek istiyorsun? 😊",
                "Mükemmel! Sana nasıl yardımcı olabilirim? Nefes, odaklanma, uyku veya başka? ✨"
            ]
        ]
    ]

    // MARK: - Personalization

    /// Adds personalization to response based on user statistics
    private func addPersonalization(to response: String, with userStats: UserStats?) -> String {
        guard let stats = userStats else {
            return response
        }

        var personalizedResponse = response

        // Add streak information
        if stats.currentStreak > 0 {
            let streakMessage = "\n\n🔥 Bu arada, \(stats.currentStreak) günlük serin devam ediyor!"
            personalizedResponse += streakMessage
        }

        // Add milestone celebration
        if stats.totalMinutes >= 300 && stats.totalMinutes % 100 < 10 {
            let milestoneMessage = "\n\n🎉 \(stats.totalMinutes) dakikayı geçtin! Harika bir başarı!"
            personalizedResponse += milestoneMessage
        }

        return personalizedResponse
    }

    // MARK: - Action Buttons

    /// Gets action button text and URL for intent
    private func getActionButton(for intent: UserIntent) -> (text: String?, url: String?) {
        switch intent {
        case .stress, .breathing:
            return ("Nefes Egzersizi Başlat", intent.deepLinkURL)
        case .focus:
            return ("Pomodoro Başlat", intent.deepLinkURL)
        case .sleep:
            return ("4-7-8 Tekniği", intent.deepLinkURL)
        case .motivation:
            return ("Zen Bahçeni Gör", intent.deepLinkURL)
        case .meditation:
            return ("Meditasyon Öğren", intent.deepLinkURL)
        case .progress:
            return ("İlerlemeni Gör", intent.deepLinkURL)
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
