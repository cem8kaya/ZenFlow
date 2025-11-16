//
//  GamificationManager.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import Foundation
import Combine
import SwiftUI

class GamificationManager: ObservableObject {
    // MARK: - Singleton

    static let shared = GamificationManager()

    // MARK: - Published Properties

    @Published var badges: [Badge] = []
    @Published var newlyUnlockedBadge: Badge?
    @Published var showBadgeAlert: Bool = false
    @Published var showBadgeUnlockAnimation: Bool = false

    // MARK: - Private Properties

    private let localDataManager = LocalDataManager.shared
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let badges = "zenflow_badges"
    }

    // MARK: - Initialization

    private init() {
        loadBadges()
        setupObservers()
    }

    // MARK: - Setup

    /// LocalDataManager değişikliklerini dinle
    private func setupObservers() {
        // LocalDataManager'daki değişiklikleri dinle
        localDataManager.objectWillChange
            .sink { [weak self] _ in
                // Veri değiştiğinde rozetleri kontrol et
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.checkAndUnlockBadges()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Badge Management

    /// Rozetleri UserDefaults'tan yükle
    private func loadBadges() {
        if let data = defaults.data(forKey: Keys.badges),
           let savedBadges = try? JSONDecoder().decode([Badge].self, from: data) {
            self.badges = savedBadges
            print("🏆 Badges loaded: \(badges.count) total, \(badges.filter { $0.isUnlocked }.count) unlocked")
        } else {
            // İlk çalıştırma - önceden tanımlı rozetleri yükle
            self.badges = Badge.getAllBadges()
            saveBadges()
            print("🏆 Initialized with \(badges.count) predefined badges")
        }
    }

    /// Rozetleri UserDefaults'a kaydet
    private func saveBadges() {
        if let data = try? JSONEncoder().encode(badges) {
            defaults.set(data, forKey: Keys.badges)
            print("💾 Badges saved: \(badges.count) total")
        }
    }

    /// Rozetleri kontrol et ve kilidi açılması gerekenleri aç
    func checkAndUnlockBadges() {
        print("🔍 Checking badges for unlock conditions...")

        var hasNewUnlock = false

        for index in badges.indices {
            // Zaten açılmış rozetleri atla
            if badges[index].isUnlocked {
                continue
            }

            // Gerekli değeri al
            let currentValue = getCurrentValue(for: badges[index].requirementType)

            // Gereksinimi kontrol et
            if badges[index].checkRequirement(value: currentValue) {
                print("✅ Badge unlocked: \(badges[index].name)")

                // Rozeti aç
                badges[index].unlock()

                // Bildirim göster
                showBadgeUnlockNotification(badge: badges[index])

                hasNewUnlock = true
            }
        }

        // Değişiklik olduysa kaydet
        if hasNewUnlock {
            saveBadges()
        }
    }

    /// Rozet türüne göre mevcut değeri al
    /// - Parameter type: Gereksinim türü
    /// - Returns: Mevcut değer
    private func getCurrentValue(for type: RequirementType) -> Int {
        switch type {
        case .streak:
            return getDailyStreak()
        case .totalMinutes:
            return localDataManager.totalMinutes
        }
    }

    /// Günlük streak hesapla
    /// - Returns: Mevcut streak değeri
    func getDailyStreak() -> Int {
        // LocalDataManager'dan streak'i al
        let streak = localDataManager.currentStreak

        // Streak hala aktif mi kontrol et
        if !localDataManager.isStreakActive() {
            print("⚠️ Streak is broken! Current: 0")
            return 0
        }

        print("🔥 Current streak: \(streak) days")
        return streak
    }

    // MARK: - Notifications

    /// Yeni rozet kazanıldığında bildirim göster
    /// - Parameter badge: Kazanılan rozet
    private func showBadgeUnlockNotification(badge: Badge) {
        DispatchQueue.main.async { [weak self] in
            self?.newlyUnlockedBadge = badge
            self?.showBadgeUnlockAnimation = true

            // Play heavy haptic for important achievement
            HapticManager.shared.playNotification(type: .success)

            print("🎉 BADGE UNLOCKED: \(badge.name)")
            print("📝 \(badge.description)")
        }
    }

    /// Bildirim penceresini kapat
    func dismissBadgeAlert() {
        showBadgeAlert = false
        showBadgeUnlockAnimation = false
        newlyUnlockedBadge = nil
    }

    // MARK: - Statistics

    /// Kilidi açılmış rozet sayısını getir
    var unlockedBadgesCount: Int {
        badges.filter { $0.isUnlocked }.count
    }

    /// Toplam rozet sayısını getir
    var totalBadgesCount: Int {
        badges.count
    }

    /// İlerleme yüzdesini hesapla
    var progressPercentage: Double {
        guard totalBadgesCount > 0 else { return 0 }
        return Double(unlockedBadgesCount) / Double(totalBadgesCount) * 100
    }

    /// Kilidi açılmış rozetleri getir
    var unlockedBadges: [Badge] {
        badges.filter { $0.isUnlocked }.sorted { $0.unlockedDate ?? Date.distantPast > $1.unlockedDate ?? Date.distantPast }
    }

    /// Kilidi açılmamış rozetleri getir
    var lockedBadges: [Badge] {
        badges.filter { !$0.isUnlocked }.sorted { badge1, badge2 in
            // Önce requirement type'a göre sırala
            if badge1.requirementType != badge2.requirementType {
                return badge1.requirementType.rawValue < badge2.requirementType.rawValue
            }
            // Sonra required value'ya göre sırala (küçükten büyüğe)
            return badge1.requiredValue < badge2.requiredValue
        }
    }

    /// Bir sonraki kazanılacak rozeti getir
    var nextBadgeToUnlock: Badge? {
        lockedBadges.first
    }

    /// Bir sonraki rozet için ilerleme yüzdesini hesapla
    /// - Parameter badge: İlerleme hesaplanacak rozet
    /// - Returns: İlerleme yüzdesi (0-100)
    func getProgress(for badge: Badge) -> Double {
        let currentValue = Double(getCurrentValue(for: badge.requirementType))
        let requiredValue = Double(badge.requiredValue)

        guard requiredValue > 0 else { return 0 }

        let progress = min((currentValue / requiredValue) * 100, 100)
        return progress
    }

    /// Rozetleri sıfırla (debug amaçlı)
    func resetAllBadges() {
        badges = Badge.getAllBadges()
        saveBadges()
        print("🔄 All badges have been reset")
    }

    /// İstatistikleri yazdır
    func printStatistics() {
        print("🏆 === Gamification İstatistikleri ===")
        print("🏆 Toplam Rozet: \(totalBadgesCount)")
        print("🏆 Kazanılan Rozet: \(unlockedBadgesCount)")
        print("🏆 İlerleme: \(String(format: "%.1f", progressPercentage))%")
        print("🏆 Güncel Streak: \(getDailyStreak()) gün")

        if let nextBadge = nextBadgeToUnlock {
            print("🏆 Sıradaki Rozet: \(nextBadge.name)")
            print("🏆 Gereksinim: \(nextBadge.requiredValue) \(nextBadge.requirementType.rawValue)")
            print("🏆 İlerleme: \(String(format: "%.1f", getProgress(for: nextBadge)))%")
        }

        print("🏆 ====================================")
    }
}
