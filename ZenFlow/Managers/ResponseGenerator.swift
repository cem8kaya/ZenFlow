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

    /// Beautiful Zen quotes for inspiration
    private let zenQuotes = [
        "\"Su akıştır, rüzgar esintir, akış ritmini bulmaktır.\" 🌊",
        "\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\" 🌸",
        "\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\" ✨",
        "\"Her nefes, yeni bir başlangıçtır.\" 🫁",
        "\"Sessizlik, tüm cevapları içerir.\" 🤫",
        "\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\" 👣",
        "\"Düşünce bulutları gelir ve geçer. Sen gökyüzüsün.\" ☁️",
        "\"Tam burada, tam şimdi - sonsuzluk bu anda gizli.\" ⏰",
        "\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\" 🌌",
        "\"Barış dışarıda aranmaz, içeride keşfedilir.\" 🕊️",
        "\"Nefes, beden ve zihin arasındaki köprüdür.\" 🌉",
        "\"Gel, gör, kabul et. Bu Zen'in yoludur.\" 🛤️",
        "\"Düşüşte bile zarafet vardır. Kalk ve devam et.\" 🍂",
        "\"Sabır, bilgeliğin meyveleridir.\" 🌳",
        "\"Her an meditasyon fırsatıdır.\" 🧘",
        "\"Zihnin dalgaları dindiğinde, gerçeklik ortaya çıkar.\" 🌊",
        "\"Yolculuk varış noktasından daha önemlidir.\" 🗺️",
        "\"Gözlemci ol, yargılayıcı değil.\" 👁️",
        "\"Hayat şimdi yaşanır, dün değil, yarın değil.\" 🌅",
        "\"Basit ol, sadece ol.\" 🪷"
    ]

    /// Gets a random Zen quote
    private func getRandomZenQuote() -> String {
        zenQuotes.randomElement() ?? zenQuotes[0]
    }

    // MARK: - Response Templates

    /// Gets response template based on intent and sentiment
    private func getResponseTemplate(for intent: UserIntent, sentiment: MessageSentiment) -> String {
        let templates = responseTemplates[intent] ?? [:]
        let sentimentTemplates = templates[sentiment] ?? []

        guard !sentimentTemplates.isEmpty else {
            return "Anlıyorum. Sana nasıl yardımcı olabilirim? 🧘\n\n\(getRandomZenQuote())"
        }

        // Randomly select a template for variety
        return sentimentTemplates.randomElement() ?? sentimentTemplates[0]
    }

    /// Response templates for all intents and sentiments with richer content
    private let responseTemplates: [UserIntent: [MessageSentiment: [String]]] = [
        .stress: [
            .negative: [
                "Stresli hissetmek tamamen normal. Zihnin fırtınada gibi görünse de, nefesle limana dönebilirsin.\n\n\"Su akıştır, rüzgar esintir, akış ritmini bulmaktır.\" 🌊\n\nBox Breathing egzersizi ile başlamak ister misin?",
                "Anlıyorum, zor bir gün geçiriyorsun. Hatırla: Sen düşüncelerin değilsin, onları gözlemleyensin.\n\n\"Düşünce bulutları gelir ve geçer. Sen gökyüzüsün.\" ☁️\n\nBeraber derin nefes alalım mı?",
                "Stres zamanla zihinsel yorgunluk yaratabilir. Ama her nefes, yeni bir başlangıç.\n\n\"Her nefes, yeni bir başlangıçtır.\" 🫁\n\n5 dakikalık nefes egzersizi ile rahatlamaya ne dersin?"
            ],
            .neutral: [
                "Stres yönetimi için en etkili yöntem düzenli nefes egzersizleri. Bilim ve Zen bunda hemfikir.\n\n\"Nefes, beden ve zihin arasındaki köprüdür.\" 🌉\n\nHangi tekniği denemek istersin?",
                "Stresle baş etmenin birçok yolu var. Zen felsefesi bize şunu öğretir: Direnmek yerine, akışa bırak.\n\n\"Barış dışarıda aranmaz, içeride keşfedilir.\" 🕊️\n\nSeninle uygun tekniği bulalım.",
                "Günlük nefes egzersizleri stresi %40 oranında azaltıyor. Zen ise bize şunu söyler:\n\n\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\" ✨\n\nBaşlamak için hazır mısın?"
            ],
            .positive: [
                "Harika! Stresinle baş etmeye hazırsın. Bu farkındalık büyük bir adım.\n\n\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\" 👣\n\nNefes egzersizlerimizi görmek ister misin?",
                "Proaktif yaklaşım mükemmel! Zen bize öğretir: Hazırlıklı ol, ama endişeli olma.\n\n\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\" 🌸\n\nBox Breathing veya 4-7-8 tekniğinden hangisini denemek istersin?",
                "Süper! Stres yönetiminde ilk adım farkındalık, ikinci adım eylem.\n\n\"Gel, gör, kabul et. Bu Zen'in yoludur.\" 🛤️\n\nŞimdi pratik yapalım!"
            ]
        ],
        .focus: [
            .negative: [
                "Odaklanmakta zorlanmak çok yaygın. Modern dünya dikkati parçalıyor. Ama Zen der ki:\n\n\"Zihnin dalgaları dindiğinde, gerçeklik ortaya çıkar.\" 🌊\n\nÖnce zihnini sakinleştir, sonra Pomodoro ile başla. Deneyelim mi?",
                "Dağınık hissetmek normal. Ama hatırla: Odaklanma bir kas gibidir, güçlendirilebilir.\n\n\"Sabır, bilgeliğin meyveleridir.\" 🌳\n\n2 dakika nefes + 25 dakika odaklanma = Harika sonuçlar!",
                "Dikkat dağınıklığı günümüzün en büyük sorunu. Çözüm basittir:\n\n\"Basit ol, sadece ol.\" 🪷\n\nPomodoro tekniği! Gösterayim mi?"
            ],
            .neutral: [
                "Odaklanma için Pomodoro tekniği bilim ve Zen'in buluşma noktası:\n\n\"Her an meditasyon fırsatıdır.\" 🧘\n\n25 dakika derin konsantrasyon + 5 dakika mola. Deneyelim mi?",
                "Verimli çalışmanın sırrı: Kısa aralıklarla yoğun odaklanma.\n\n\"Yolculuk varış noktasından daha önemlidir.\" 🗺️\n\nPomodoro ile başlamaya hazır mısın?",
                "Konsantrasyon kas gibidir, egzersiz gerektirir. Her Pomodoro bir antrenman:\n\n\"Düşüşte bile zarafet vardır. Kalk ve devam et.\" 🍂\n\nGünlük antrenman yapalım!"
            ],
            .positive: [
                "Harika enerji! Şimdi bu enerjiyi odaklanmaya kanalize et!\n\n\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\" 🌌\n\nPomodoro başlatıyoruz!",
                "Motivasyonun yüksek! Bu tam doğru zaman.\n\n\"Tam burada, tam şimdi - sonsuzluk bu anda gizli.\" ⏰\n\nHadi gidelim!",
                "Süper! Zihin berrak olduğunda, her şey mümkün.\n\n\"Gözlemci ol, yargılayıcı değil.\" 👁️\n\nİyi odaklanma + düzenli molalar = Maksimum verim. Başlıyoruz!"
            ]
        ],
        .sleep: [
            .negative: [
                "Uyku için en etkili teknik: 4-7-8 nefes egzersizi. Vücut ve zihin uyum içinde olmalı.\n\n\"Sessizlik, tüm cevapları içerir.\" 🤫\n\nDr. Andrew Weil'in önerisi ile 5 dakikada uyuyabilirsin.",
                "Uykusuzluk zor bir durum. Ama unutma:\n\n\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\" ✨\n\n4-7-8 tekniği sinir sistemini sakinleştirir. Denemeye hazır mısın?",
                "Zihnini yatıştırmak için derin nefes alma egzersizi yapalım.\n\n\"Hayat şimdi yaşanır, dün değil, yarın değil.\" 🌅\n\nVücudun dinlenmeye hazır hale gelecek."
            ],
            .neutral: [
                "Kaliteli uyku için zihinsel gevşeme şart. Zen öğretir:\n\n\"Barış dışarıda aranmaz, içeride keşfedilir.\" 🕊️\n\n4-7-8 nefes tekniği bunun için tasarlandı. Göstereyim mi?",
                "Uyku öncesi rutini çok önemli. Her gece aynı ritüel zihnini hazırlar.\n\n\"Nefes, beden ve zihin arasındaki köprüdür.\" 🌉\n\n5-10 dakika nefes egzersizi ile uyku kalitenizi artırabilirsiniz.",
                "Derin uyku için parasempatik sinir sistemini aktive etmeliyiz.\n\n\"Su akıştır, rüzgar esintir, akış ritmini bulmaktır.\" 🌊\n\nBox Breathing tam bunun için!"
            ],
            .positive: [
                "İyi bir uyku rutini oluşturmak istemen harika!\n\n\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\" 👣\n\n4-7-8 tekniği ile başlayalım.",
                "Uyku hijyeni için proaktif adım atmak mükemmel!\n\n\"Her an meditasyon fırsatıdır.\" 🧘\n\nNefes egzersizlerine bakalım.",
                "Süper! Düzenli uyku rutini = Daha enerjik günler.\n\n\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\" 🌸\n\nHadi başlayalım!"
            ]
        ],
        .breathing: [
            .negative: [
                "Nefes almakta zorlanıyorsan, önce rahat bir pozisyon bul. Hiçbir acele yok.\n\n\"Sabır, bilgeliğin meyveleridir.\" 🌳\n\nBox Breathing ile başlamak ister misin?",
                "Derin nefes alma zihin ve bedeni sakinleştirir. Zen der ki:\n\n\"Her nefes, yeni bir başlangıçtır.\" 🫁\n\nBeraber yavaşça başlayalım.",
                "Nefes egzersizleri çok etkili. 3-4 dakika bile fark yaratıyor.\n\n\"Basit ol, sadece ol.\" 🪷\n\nDenemek ister misin?"
            ],
            .neutral: [
                "Nefes egzersizlerimizde 3 teknik var: Box Breathing, 4-7-8, ve Derin Nefes.\n\n\"Gel, gör, kabul et. Bu Zen'in yoludur.\" 🛤️\n\nHangisini görmek istersin?",
                "Nefes kontrolü meditasyonun temelidir. Eski Zen ustalarının ilk dersi:\n\n\"Nefes, beden ve zihin arasındaki köprüdür.\" 🌉\n\nHangi teknikle başlamak istersin?",
                "Farklı nefes teknikleri farklı amaçlara hizmet eder.\n\n\"Yolculuk varış noktasından daha önemlidir.\" 🗺️\n\nSana uygun olanı bulalım!"
            ],
            .positive: [
                "Harika seçim! Nefes egzersizleri zihin-beden bağlantısını güçlendirir.\n\n\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\" ✨\n\nHadi başlayalım!",
                "Süper! Düzenli nefes pratiği hayat kalitesini artırır.\n\n\"Tam burada, tam şimdi - sonsuzluk bu anda gizli.\" ⏰\n\nHangi tekniği deneyelim?",
                "Mükemmel! Nefes farkındalığı mindfulness'ın kalbidir.\n\n\"Her an meditasyon fırsatıdır.\" 🧘\n\nİlk adımı atalım!"
            ]
        ],
        .motivation: [
            .negative: [
                "Motivasyon eksikliği yaşamak insani. Zen öğretir:\n\n\"Düşüşte bile zarafet vardır. Kalk ve devam et.\" 🍂\n\nKüçük adımlar atmak çok etkili. 2 dakikalık bir egzersiz ile başlamaya ne dersin?",
                "İlham bulmak zor olabilir. Ama bazen sadece başlamak yeterli.\n\n\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\" 👣\n\nBeraber küçük bir adım atalım mı?",
                "Tembellik hissi normaldir. Unutma:\n\n\"Hayat şimdi yaşanır, dün değil, yarın değil.\" 🌅\n\nZen bahçene bakmak veya kısa bir meditasyon seni motive edebilir. Hangisi?"
            ],
            .neutral: [
                "Motivasyon dalgalıdır, önemli olan süreklilik.\n\n\"Sabır, bilgeliğin meyveleridir.\" 🌳\n\nKüçük kazanımlar büyük değişim yaratır. Başlayalım mı?",
                "En zor kısım başlamaktır. Bir kez başladığında momentum gelir.\n\n\"Gel, gör, kabul et. Bu Zen'in yoludur.\" 🛤️\n\n5 dakikalık bir egzersiz ile deneyelim mi?",
                "Zen bahçen ve rozetlerin sana ilham verebilir. Unutma:\n\n\"Yolculuk varış noktasından daha önemlidir.\" 🗺️\n\nİlerlemenize bakmak ister misin?"
            ],
            .positive: [
                "İşte bu enerji! Şimdi bu motivasyonu bir egzersize kanalize edelim!\n\n\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\" 🌌\n\nHadi başlayalım!",
                "Harika! Motivasyonlu anları değerlendirmek çok önemli.\n\n\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\" 🌸\n\nHadi başlayalım!",
                "Süper enerji! Bu momentum ile neler başarabileceğini görelim!\n\n\"Gözlemci ol, yargılayıcı değil.\" 👁️\n\nİleri!"
            ]
        ],
        .meditation: [
            .negative: [
                "Meditasyon öğrenmek göz korkutucu gelebilir, ama Zen der ki:\n\n\"Basit ol, sadece ol.\" 🪷\n\nAslında çok basit. 2 dakikalık bir deneme ile başlamak ister misin?",
                "Herkes meditasyon yapabilir, pratik gerektirir. Unutma:\n\n\"Düşüşte bile zarafet vardır. Kalk ve devam et.\" 🍂\n\nBasit nefes odaklı bir egzersiz ile başlayalım mı?",
                "Meditasyonun 'yanlış' yapılma şekli yoktur. Rahat ol ve deneyelim.\n\n\"Gözlemci ol, yargılayıcı değil.\" 👁️\n\nBaşlamaya hazır mısın?"
            ],
            .neutral: [
                "Meditasyon nefes farkındalığı ile başlar. Zen öğretir:\n\n\"Nefes, beden ve zihin arasındaki köprüdür.\" 🌉\n\nAdım adım öğreneceğiz. İlk egzersizi görmek ister misin?",
                "Mindfulness pratiği hayatı değiştirir. Binlerce yıllık bilgelik:\n\n\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\" ✨\n\nBaşlangıç seviyesi egzersizlerimiz tam sana göre. Bakalım mı?",
                "Meditasyon öğrenmek yolculuktur. Her gün biraz pratik = Büyük gelişim.\n\n\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\" 👣\n\nBaşlayalım mı?"
            ],
            .positive: [
                "Harika karar! Meditasyon öğrenmek en güzel hediyelerden biri.\n\n\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\" 🌸\n\nHadi ilk adımı atalım!",
                "Mükemmel! Meditasyon pratiği zihinsel netlik getirir.\n\n\"Sessizlik, tüm cevapları içerir.\" 🤫\n\nİlk egzersizimizi görelim!",
                "Süper! Meditasyon öğrenmeye istekli olmak başarının yarısı.\n\n\"Her an meditasyon fırsatıdır.\" 🧘\n\nBaşlıyoruz!"
            ]
        ],
        .progress: [
            .negative: [
                "İlerleme görmek zaman alır, ama sen harika gidiyorsun! Zen der ki:\n\n\"Sabır, bilgeliğin meyveleridir.\" 🌳\n\nİstatistiklerini görmek ister misin?",
                "Her küçük adım önemli. Zen bahçen ve rozetlerin gelişimini gösteriyor.\n\n\"Yolculuk varış noktasından daha önemlidir.\" 🗺️\n\nBakalım mı?",
                "Kendini karşılaştırma, kendi yolculuğuna odaklan.\n\n\"Gözlemci ol, yargılayıcı değil.\" 👁️\n\nİlerlemeniz muhtemelen düşündüğünden iyi!"
            ],
            .neutral: [
                "İstatistiklerini görmek motivasyon artırıcı. Her sayı, bir adım:\n\n\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\" 👣\n\nToplam süren, serin ve rozetlerin burada!",
                "Gelişimini takip etmek önemli. Zen bize öğretir:\n\n\"Zihnin dalgaları dindiğinde, gerçeklik ortaya çıkar.\" 🌊\n\nZen bahçene ve rozetlerine bakmaya ne dersin?",
                "İlerleme raporunu görmek ister misin? Her rakam bir başarı:\n\n\"Düşüşte bile zarafet vardır. Kalk ve devam et.\" 🍂\n\nToplam seans, dakika ve başarıların burada!"
            ],
            .positive: [
                "Harika! İlerleme takibi seni daha da motive edecek.\n\n\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\" 🌸\n\nRozetlerine ve Zen bahçene bakalım!",
                "Süper! Başarılarını görmek çok keyifli. Hatırla:\n\n\"Tam burada, tam şimdi - sonsuzluk bu anda gizli.\" ⏰\n\nİstatistiklerin ve rozetlerin burada!",
                "Mükemmel! Kendini takip etmek başarıyı artırır.\n\n\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\" 🌌\n\nHadi ilerlemenize bakalım!"
            ]
        ],
        .general: [
            .negative: [
                "Üzgün görünüyorsun. Sana nasıl yardımcı olabilirim?\n\n\"Barış dışarıda aranmaz, içeride keşfedilir.\" 🕊️\n\nNefes egzersizi, meditasyon veya sadece konuşmak ister misin?",
                "Anlıyorum. Biraz rahatlama egzersizi yapmak ister misin?\n\n\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\" ✨\n\nBeraber bir şeyler bulalım.",
                "Zor zamanlar herkesin başına gelir. Unutma:\n\n\"Her nefes, yeni bir başlangıçtır.\" 🫁\n\nNasıl destek olabilirim?"
            ],
            .neutral: [
                "Merhaba! Sana bugün nasıl yardımcı olabilirim?\n\n\"Gel, gör, kabul et. Bu Zen'in yoludur.\" 🛤️\n\nStres, uyku, odaklanma veya başka bir konuda mı destek istiyorsun?",
                "Anlıyorum. Meditasyon, nefes egzersizleri, Pomodoro veya ilerleme takibi konusunda yardımcı olabilirim.\n\n\"Her an meditasyon fırsatıdır.\" 🧘\n\nHangi alan ilgini çekiyor?",
                "Senin için buradayım. Zen yolculuğunda ne konuda rehberlik istiyorsun?\n\n\"Nefes, beden ve zihin arasındaki köprüdür.\" 🌉"
            ],
            .positive: [
                "Harika bir enerji! Bugün ne yapmak istersin?\n\n\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\" 🌸\n\nMeditasyon, odaklanma egzersizi veya ilerleme kontrolü?",
                "Güzel bir gün gibi görünüyor! Hangi konuda destek istiyorsun?\n\n\"Hayat şimdi yaşanır, dün değil, yarın değil.\" 🌅",
                "Mükemmel! Sana nasıl yardımcı olabilirim?\n\n\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\" 🌌\n\nNefes, odaklanma, uyku veya başka?"
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
            let streakMessage = "\n\n🔥 Bu arada, \(stats.currentStreak) günlük serin devam ediyor! Harika bir disiplin."
            personalizedResponse += streakMessage
        }

        // Add milestone celebration
        if stats.totalMinutes >= 300 && stats.totalMinutes % 100 < 10 {
            let milestoneMessage = "\n\n🎉 \(stats.totalMinutes) dakikayı geçtin! Bu muazzam bir başarı!"
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
