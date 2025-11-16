//
//  TreeGrowthStage.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import SwiftUI

/// Ağaç büyüme aşamaları
enum TreeGrowthStage: Int, CaseIterable, Identifiable {
    case seed = 0           // Tohum - 0 dakika
    case sprout = 30        // Filiz - 30 dakika
    case sapling = 120      // Fidan - 2 saat (120 dakika)
    case youngTree = 300    // Genç Ağaç - 5 saat (300 dakika)
    case matureTree = 600   // Olgun Ağaç - 10 saat (600 dakika)
    case ancientTree = 1200 // Kadim Ağaç - 20 saat (1200 dakika)

    var id: Int { rawValue }

    // MARK: - Localized Names

    /// Türkçe başlık
    var title: String {
        switch self {
        case .seed:
            return "Tohum"
        case .sprout:
            return "Filiz"
        case .sapling:
            return "Fidan"
        case .youngTree:
            return "Genç Ağaç"
        case .matureTree:
            return "Olgun Ağaç"
        case .ancientTree:
            return "Kadim Ağaç"
        }
    }

    /// Aşama açıklaması
    var description: String {
        switch self {
        case .seed:
            return "Yolculuğun başlangıcı. Her büyük değişim küçük bir tohumla başlar."
        case .sprout:
            return "İlk adımları attın! Sabır ve özveriyle büyümeye devam et."
        case .sapling:
            return "Güçlü temeller atıyorsun. Her gün daha da büyüyorsun."
        case .youngTree:
            return "Artık güçlü bir ağaçsın! Egzersiz alışkanlığın kökleniyor."
        case .matureTree:
            return "Olgunlaştın ve güçlendin. Zen bahçenin görkemli ağacı."
        case .ancientTree:
            return "Efsanevi bir yolculuk tamamladın! Bilgelik ve güç sahibisin."
        }
    }

    // MARK: - Visual Properties

    /// SF Symbol adı
    var symbolName: String {
        switch self {
        case .seed:
            return "circle.fill"
        case .sprout:
            return "leaf.fill"
        case .sapling:
            return "tree"
        case .youngTree:
            return "tree.fill"
        case .matureTree:
            return "tree.fill"
        case .ancientTree:
            return "sparkles"
        }
    }

    /// İkon boyutu
    var iconSize: CGFloat {
        switch self {
        case .seed:
            return 50
        case .sprout:
            return 90
        case .sapling:
            return 140
        case .youngTree:
            return 190
        case .matureTree:
            return 240
        case .ancientTree:
            return 280
        }
    }

    /// Glow yarıçapı
    var glowRadius: CGFloat {
        switch self {
        case .seed:
            return 60
        case .sprout:
            return 100
        case .sapling:
            return 150
        case .youngTree:
            return 200
        case .matureTree:
            return 260
        case .ancientTree:
            return 320
        }
    }

    /// Renk paleti (gradient için)
    var colors: [Color] {
        switch self {
        case .seed:
            return [
                Color(red: 0.6, green: 0.4, blue: 0.2),  // Kahverengi
                Color(red: 0.5, green: 0.3, blue: 0.15)
            ]
        case .sprout:
            return [
                Color(red: 0.5, green: 0.8, blue: 0.3),  // Açık yeşil
                Color(red: 0.4, green: 0.7, blue: 0.2)
            ]
        case .sapling:
            return [
                Color(red: 0.2, green: 0.7, blue: 0.3),  // Orta yeşil
                Color(red: 0.15, green: 0.6, blue: 0.25)
            ]
        case .youngTree:
            return [
                Color(red: 0.1, green: 0.6, blue: 0.3),  // Koyu yeşil
                ZenTheme.calmBlue
            ]
        case .matureTree:
            return [
                ZenTheme.mysticalViolet,
                ZenTheme.calmBlue
            ]
        case .ancientTree:
            return [
                ZenTheme.lightLavender,
                Color(red: 1.0, green: 0.8, blue: 0.4),  // Altın sarısı
                ZenTheme.mysticalViolet
            ]
        }
    }

    /// Glow rengi
    var glowColor: Color {
        colors[0]
    }

    // MARK: - Stage Progression

    /// Gerekli dakika
    var requiredMinutes: Int {
        rawValue
    }

    /// Bir sonraki aşama (varsa)
    var nextStage: TreeGrowthStage? {
        let allStages = TreeGrowthStage.allCases
        guard let currentIndex = allStages.firstIndex(of: self),
              currentIndex < allStages.count - 1 else {
            return nil
        }
        return allStages[currentIndex + 1]
    }

    /// Bir sonraki aşama için gereken dakika (varsa)
    var nextStageRequiredMinutes: Int? {
        nextStage?.requiredMinutes
    }

    /// Bir önceki aşama (varsa)
    var previousStage: TreeGrowthStage? {
        let allStages = TreeGrowthStage.allCases
        guard let currentIndex = allStages.firstIndex(of: self),
              currentIndex > 0 else {
            return nil
        }
        return allStages[currentIndex - 1]
    }

    // MARK: - Stage Calculation

    /// Toplam dakikadan aşama hesapla
    /// - Parameter minutes: Toplam egzersiz dakikası
    /// - Returns: İlgili aşama
    static func stage(for minutes: Int) -> TreeGrowthStage {
        // En yüksek aşamadan başla, aşağı doğru kontrol et
        let sortedStages = TreeGrowthStage.allCases.sorted { $0.rawValue > $1.rawValue }

        for stage in sortedStages {
            if minutes >= stage.rawValue {
                return stage
            }
        }

        return .seed // Minimum aşama
    }

    /// İki aşama arasındaki ilerleme yüzdesi
    /// - Parameter currentMinutes: Mevcut toplam dakika
    /// - Returns: 0.0 - 1.0 arası ilerleme
    func progress(for currentMinutes: Int) -> Double {
        guard let nextMinutes = nextStageRequiredMinutes else {
            // Maksimum aşamadayız
            return 1.0
        }

        let currentStageMinutes = requiredMinutes
        let stageRange = nextMinutes - currentStageMinutes
        let progressInStage = currentMinutes - currentStageMinutes

        return min(1.0, max(0.0, Double(progressInStage) / Double(stageRange)))
    }

    /// Bir sonraki aşamaya kalan dakika
    /// - Parameter currentMinutes: Mevcut toplam dakika
    /// - Returns: Kalan dakika (nil = maksimum aşama)
    func minutesUntilNextStage(currentMinutes: Int) -> Int? {
        guard let nextMinutes = nextStageRequiredMinutes else {
            return nil
        }
        return max(0, nextMinutes - currentMinutes)
    }
}
