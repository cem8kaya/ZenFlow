//
//  TreeGrowthStage.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//  Updated by Claude AI on 16.11.2025.
//
//  Tree growth stage model representing the user's meditation progress
//  through a visual metaphor of a growing tree. Each stage requires
//  progressively more meditation time and provides visual feedback.
//

import SwiftUI

/// Tree growth stages representing meditation progress milestones
/// Raw values represent required minutes for each stage
enum TreeGrowthStage: Int, CaseIterable, Identifiable {
    case seed = 0           // Seed - 0 minutes (starting point)
    case sprout = 30        // Sprout - 30 minutes
    case sapling = 120      // Sapling - 2 hours (120 minutes)
    case youngTree = 300    // Young Tree - 5 hours (300 minutes)
    case matureTree = 600   // Mature Tree - 10 hours (600 minutes)
    case ancientTree = 1200 // Ancient Tree - 20 hours (1200 minutes)

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

    /// İkon boyutu (defined in AppConstants.TreeGrowth)
    var iconSize: CGFloat {
        switch self {
        case .seed:
            return AppConstants.TreeGrowth.seedSize
        case .sprout:
            return AppConstants.TreeGrowth.sproutSize
        case .sapling:
            return AppConstants.TreeGrowth.saplingSize
        case .youngTree:
            return AppConstants.TreeGrowth.youngTreeSize
        case .matureTree:
            return AppConstants.TreeGrowth.matureTreeSize
        case .ancientTree:
            return AppConstants.TreeGrowth.ancientTreeSize
        }
    }

    /// Glow yarıçapı (defined in AppConstants.TreeGrowth)
    var glowRadius: CGFloat {
        switch self {
        case .seed:
            return AppConstants.TreeGrowth.seedGlow
        case .sprout:
            return AppConstants.TreeGrowth.sproutGlow
        case .sapling:
            return AppConstants.TreeGrowth.saplingGlow
        case .youngTree:
            return AppConstants.TreeGrowth.youngTreeGlow
        case .matureTree:
            return AppConstants.TreeGrowth.matureTreeGlow
        case .ancientTree:
            return AppConstants.TreeGrowth.ancientTreeGlow
        }
    }

    /// Renk paleti (gradient için)
    var colors: [Color] {
        switch self {
        case .seed:
            return [
                ZenTheme.earthBrown,
                Color(red: 0.5, green: 0.3, blue: 0.15)  // Darker brown
            ]
        case .sprout:
            return [
                Color(red: 0.5, green: 0.8, blue: 0.3),  // Light green
                Color(red: 0.4, green: 0.7, blue: 0.2)
            ]
        case .sapling:
            return [
                Color(red: 0.4, green: 0.7, blue: 0.25), // Mid green
                ZenTheme.sageGreen
            ]
        case .youngTree:
            return [
                ZenTheme.sageGreen,
                ZenTheme.deepSage
            ]
        case .matureTree:
            return [
                ZenTheme.deepSage,
                Color(red: 0.2, green: 0.5, blue: 0.2)   // Forest green
            ]
        case .ancientTree:
            return [
                ZenTheme.deepSage,
                Color(red: 1.0, green: 0.85, blue: 0.4), // Golden
                Color(red: 1.0, green: 0.75, blue: 0.8)  // Sakura pink
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
