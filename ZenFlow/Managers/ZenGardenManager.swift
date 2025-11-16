//
//  ZenGardenManager.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import SwiftUI
import Combine

/// Zen bahçesi ağaç büyüme sistemi yöneticisi
class ZenGardenManager: ObservableObject {
    // MARK: - Properties

    private let localDataManager = LocalDataManager.shared
    private let sessionTracker = SessionTracker.shared
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?

    // MARK: - Published Properties

    /// Mevcut ağaç aşaması
    @Published private(set) var currentStage: TreeGrowthStage = .seed

    /// Bir önceki aşama (animasyon için)
    @Published private(set) var previousStage: TreeGrowthStage? = nil

    /// Aşama ilerleme yüzdesi (0.0 - 1.0)
    @Published private(set) var stageProgress: Double = 0.0

    /// Bir sonraki aşamaya kalan dakika
    @Published private(set) var minutesUntilNextStage: Int? = nil

    /// Toplam egzersiz süresi (dakika)
    @Published private(set) var totalMinutes: Int = 0

    /// Aşama değişimi animasyonu tetiklendi mi?
    @Published var shouldCelebrate: Bool = false

    // MARK: - Initialization

    init() {
        // LocalDataManager'dan ilk veriyi al
        totalMinutes = localDataManager.totalMinutes
        updateTreeState()

        // LocalDataManager değişikliklerini dinle
        localDataManager.objectWillChange
            .sink { [weak self] _ in
                self?.handleDataManagerUpdate()
            }
            .store(in: &cancellables)

        // SessionTracker'ı dinle - aktif meditasyon sırasında güncelleme için
        sessionTracker.$isActive
            .sink { [weak self] isActive in
                self?.handleSessionStateChange(isActive: isActive)
            }
            .store(in: &cancellables)

        // Saniyede bir güncelleme yap (aktif session varsa)
        startUpdateTimer()
    }

    deinit {
        updateTimer?.invalidate()
    }

    // MARK: - Timer Management

    /// Güncelleme timer'ını başlat
    private func startUpdateTimer() {
        // Her saniye güncelle
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTreeStateWithActiveSession()
        }
    }

    /// Session durumu değiştiğinde çağrılır
    private func handleSessionStateChange(isActive: Bool) {
        if isActive {
            print("🌳 Active meditation session detected - starting real-time updates")
        } else {
            print("🌳 Meditation session ended - updating final state")
        }
        updateTreeStateWithActiveSession()
    }

    // MARK: - Data Updates

    /// LocalDataManager güncellendiğinde çağrılır
    private func handleDataManagerUpdate() {
        let newTotalMinutes = localDataManager.totalMinutes

        // Toplam dakika değişti mi kontrol et
        guard newTotalMinutes != totalMinutes else {
            return
        }

        // Eski aşamayı sakla
        let oldStage = currentStage

        // Toplam dakikayı güncelle
        totalMinutes = newTotalMinutes

        // Ağaç durumunu güncelle
        updateTreeState()

        // Aşama değişimi oldu mu?
        if oldStage != currentStage {
            handleStageTransition(from: oldStage, to: currentStage)
        }
    }

    /// Ağaç durumunu güncelle
    private func updateTreeState() {
        // Mevcut aşamayı hesapla
        currentStage = TreeGrowthStage.stage(for: totalMinutes)

        // İlerleme yüzdesini hesapla
        stageProgress = currentStage.progress(for: totalMinutes)

        // Bir sonraki aşamaya kalan süreyi hesapla
        minutesUntilNextStage = currentStage.minutesUntilNextStage(currentMinutes: totalMinutes)

        print("🌳 Tree state updated:")
        print("   - Stage: \(currentStage.title)")
        print("   - Total minutes: \(totalMinutes)")
        print("   - Progress: \(Int(stageProgress * 100))%")
        if let remaining = minutesUntilNextStage {
            print("   - Minutes until next stage: \(remaining)")
        } else {
            print("   - Maximum stage reached!")
        }
    }

    /// Aktif session dahil ağaç durumunu güncelle
    private func updateTreeStateWithActiveSession() {
        // Toplam dakikayı al (kayıtlı + aktif session)
        let savedMinutes = localDataManager.totalMinutes
        let activeMinutes = sessionTracker.isActive ? Int(sessionTracker.duration / 60.0) : 0
        let effectiveTotalMinutes = savedMinutes + activeMinutes

        // Eski aşamayı sakla
        let oldStage = currentStage

        // Mevcut aşamayı hesapla
        currentStage = TreeGrowthStage.stage(for: effectiveTotalMinutes)

        // İlerleme yüzdesini hesapla
        stageProgress = currentStage.progress(for: effectiveTotalMinutes)

        // Bir sonraki aşamaya kalan süreyi hesapla
        minutesUntilNextStage = currentStage.minutesUntilNextStage(currentMinutes: effectiveTotalMinutes)

        // Toplam dakikayı güncelle (görüntüleme için)
        totalMinutes = effectiveTotalMinutes

        // Aşama değişimi oldu mu kontrol et
        if oldStage != currentStage && activeMinutes > 0 {
            handleStageTransition(from: oldStage, to: currentStage)
        }
    }

    /// Aşama geçişini yönet
    /// - Parameters:
    ///   - oldStage: Eski aşama
    ///   - newStage: Yeni aşama
    private func handleStageTransition(from oldStage: TreeGrowthStage, to newStage: TreeGrowthStage) {
        print("🎉 Stage transition: \(oldStage.title) → \(newStage.title)")

        // Önceki aşamayı sakla
        previousStage = oldStage

        // Kutlama animasyonunu tetikle
        triggerCelebration()
    }

    // MARK: - Celebration

    /// Kutlama animasyonunu tetikle
    func triggerCelebration() {
        // Ana thread'de çalıştır
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Kutlama bayrağını set et
            self.shouldCelebrate = true

            // Haptic feedback
            self.playStageTransitionHaptic()

            // 2.5 saniye sonra kutlamayı kapat
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.shouldCelebrate = false
                self.previousStage = nil
            }
        }
    }

    /// Aşama geçişi için haptic feedback oynat
    private func playStageTransitionHaptic() {
        let hapticManager = HapticManager.shared

        // Success pattern oluştur
        guard hapticManager.isHapticsAvailable else {
            print("⚠️ Haptics not available")
            return
        }

        hapticManager.startEngine()

        // Üç kademeli haptic: kısa-orta-uzun
        DispatchQueue.main.async {
            // İlk vuruş
            let impactFeedback1 = UIImpactFeedbackGenerator(style: .light)
            impactFeedback1.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // İkinci vuruş
            let impactFeedback2 = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback2.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Üçüncü vuruş (success)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }

        print("🎮 Haptic feedback played for stage transition")
    }

    // MARK: - Manual Refresh

    /// Manuel olarak veriyi yenile (debug için)
    func refresh() {
        totalMinutes = localDataManager.totalMinutes
        updateTreeState()
    }

    // MARK: - Formatted Strings

    /// Kalan süreyi formatlanmış string olarak döndür
    func formattedTimeUntilNextStage() -> String? {
        guard let minutes = minutesUntilNextStage else {
            return nil
        }

        if minutes < 60 {
            return "\(minutes) dakika"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60

            if remainingMinutes == 0 {
                return "\(hours) saat"
            } else {
                return "\(hours) saat \(remainingMinutes) dakika"
            }
        }
    }

    /// İlerleme yüzdesini formatlanmış string olarak döndür
    func formattedProgress() -> String {
        "\(Int(stageProgress * 100))%"
    }

    /// Toplam süreyi formatlanmış string olarak döndür
    func formattedTotalTime() -> String {
        if totalMinutes < 60 {
            return "\(totalMinutes) dakika"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60

            if minutes == 0 {
                return "\(hours) saat"
            } else {
                return "\(hours) saat \(minutes) dakika"
            }
        }
    }
}
