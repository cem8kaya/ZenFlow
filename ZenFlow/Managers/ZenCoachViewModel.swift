//
//  ZenCoachViewModel.swift
//  ZenFlow
//
//  Created by Claude AI on 25.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Zen Coach ViewModel - kişiselleştirilmiş içerik yönetimi
//  Kullanıcı bağlamına göre Zen öğretileri ve tavsiyeler sunar
//

import Foundation
import Combine

class ZenCoachViewModel: ObservableObject {
    @Published var dailyTeaching: ZenTeaching?
    @Published var personalizedAdvice: String = ""

    private let wisdomLibrary = ZenWisdomLibrary.shared
    private let localDataManager = LocalDataManager.shared

    init() {
        loadDailyTeaching()
        generatePersonalizedAdvice()
    }

    // MARK: - Public Methods

    func loadDailyTeaching() {
        // Önce kaydedilmiş günlük öğretiyi kontrol et
        if let saved = loadSavedTeaching() {
            dailyTeaching = saved
            return
        }

        // Yeni günlük öğreti yükle
        let totalSessions = localDataManager.totalSessions
        let lastSessionDate = localDataManager.lastSessionDate

        // Kullanıcı bağlamına göre öğreti seç
        dailyTeaching = wisdomLibrary.getTeachingForContext(
            sessionCount: totalSessions,
            lastSessionDate: lastSessionDate,
            currentMood: nil
        )

        // Günlük öğretiyi kaydet
        saveDailyTeaching()
    }

    func refreshTeaching() {
        dailyTeaching = wisdomLibrary.getRandomTeaching()
        generatePersonalizedAdvice()
        saveDailyTeaching()
    }

    // MARK: - Private Methods

    private func generatePersonalizedAdvice() {
        let totalSessions = localDataManager.totalSessions
        let currentStreak = localDataManager.currentStreak
        let lastSessionDate = localDataManager.lastSessionDate

        if totalSessions < 3 {
            personalizedAdvice = """
            Yolculuğunun başındasın. Zen yolu sabır ve süreklilik gerektirir. \
            Her gün küçük bir adım at - nefes al, otur, gözlemle. \
            Mükemmellik arayışında olma, sadece var ol.
            """
        } else if currentStreak >= 7 {
            personalizedAdvice = """
            \(currentStreak) günlük seride harikasın! Ancak unutma: \
            Zen'de hedef, seriyi korumak değil, her anı tam yaşamaktır. \
            Seri kırılırsa da sorun değil - önemli olan şimdiki nefes.
            """
        } else if totalSessions >= 30 {
            personalizedAdvice = """
            \(totalSessions) seans tamamladın. Meditasyon artık yaşamının bir parçası. \
            Ancak asıl dönüşüm yastığın dışında gerçekleşir. Günlük yaşamda ne kadar uyanıksın? \
            Her an bir uygulama fırsatıdır.
            """
        } else if let lastDate = lastSessionDate,
                  Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0 > 3 {
            personalizedAdvice = """
            Bir süredir meditasyon yapmadın. Bu normaldir - hayat bazen bizleri meşgul eder. \
            Ama unutma: Yolculuk bin bir millik yoldan başlar. Bugün küçük bir nefesle başla. \
            Yeniden başlamak, başarısızlık değil, cesaret işaretidir.
            """
        } else {
            personalizedAdvice = """
            Meditasyon yolculuğun güzel ilerliyor. Bazen zihin dağınık olacak, \
            bazen sessiz. Her ikisi de doğaldır. Önemli olan, yargılamadan gözlemlemek. \
            Sen düşüncen değilsin, düşüncelerin gözlemcisisin.
            """
        }
    }

    private func saveDailyTeaching() {
        // Günlük öğretiyi UserDefaults'a kaydet
        guard let teaching = dailyTeaching else { return }

        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: "lastTeachingDate")

        if let encoded = try? JSONEncoder().encode(teaching) {
            UserDefaults.standard.set(encoded, forKey: "dailyTeaching")
        }
    }

    private func loadSavedTeaching() -> ZenTeaching? {
        guard let lastDate = UserDefaults.standard.object(forKey: "lastTeachingDate") as? Date,
              Calendar.current.isDateInToday(lastDate),
              let data = UserDefaults.standard.data(forKey: "dailyTeaching"),
              let teaching = try? JSONDecoder().decode(ZenTeaching.self, from: data) else {
            return nil
        }
        return teaching
    }
}
