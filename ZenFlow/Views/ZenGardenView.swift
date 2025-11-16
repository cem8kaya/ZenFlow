//
//  ZenGardenView.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import SwiftUI

/// Ağaç büyüme aşamaları
enum TreeStage: Int, CaseIterable {
    case seed = 0       // 0-10 dakika
    case sprout = 10    // 10-30 dakika
    case young = 30     // 30-60 dakika
    case mature = 60    // 60-120 dakika
    case ancient = 120  // 120+ dakika

    var title: String {
        switch self {
        case .seed:
            return "Tohum"
        case .sprout:
            return "Fidan"
        case .young:
            return "Genç Ağaç"
        case .mature:
            return "Olgun Ağaç"
        case .ancient:
            return "Çınar"
        }
    }

    var symbolName: String {
        switch self {
        case .seed:
            return "circle.fill"
        case .sprout:
            return "leaf.fill"
        case .young:
            return "tree"
        case .mature:
            return "tree.fill"
        case .ancient:
            return "tree.fill"
        }
    }

    var size: CGFloat {
        switch self {
        case .seed:
            return 40
        case .sprout:
            return 80
        case .young:
            return 140
        case .mature:
            return 200
        case .ancient:
            return 260
        }
    }

    var nextStageMinutes: Int? {
        let allStages = TreeStage.allCases
        guard let currentIndex = allStages.firstIndex(of: self),
              currentIndex < allStages.count - 1 else {
            return nil
        }
        return allStages[currentIndex + 1].rawValue
    }

    var color: Color {
        switch self {
        case .seed:
            return Color.brown.opacity(0.8)
        case .sprout:
            return Color.green.opacity(0.6)
        case .young:
            return Color.green.opacity(0.8)
        case .mature:
            return ZenTheme.mysticalViolet
        case .ancient:
            return ZenTheme.lightLavender
        }
    }

    static func stage(for minutes: Int) -> TreeStage {
        if minutes >= ancient.rawValue {
            return .ancient
        } else if minutes >= mature.rawValue {
            return .mature
        } else if minutes >= young.rawValue {
            return .young
        } else if minutes >= sprout.rawValue {
            return .sprout
        } else {
            return .seed
        }
    }
}

struct ZenGardenView: View {
    @StateObject private var localDataManager = LocalDataManager.shared
    @State private var currentStage: TreeStage = .seed
    @State private var progress: Double = 0.0

    private var totalMinutes: Int {
        localDataManager.totalMinutes
    }

    private var minutesUntilNextStage: Int {
        guard let nextStageMinutes = currentStage.nextStageMinutes else {
            return 0
        }
        return max(0, nextStageMinutes - totalMinutes)
    }

    var body: some View {
        ZStack {
            // Dark gradient background (mor-mavi-siyah)
            LinearGradient(
                colors: [
                    ZenTheme.deepIndigo,
                    Color(red: 0.12, green: 0.08, blue: 0.25),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Başlık
                Text("Zen Bahçem")
                    .font(ZenTheme.title)
                    .foregroundColor(ZenTheme.lightLavender)
                    .padding(.top, 60)

                Spacer()

                // Ağaç gösterim alanı (merkezi, büyük)
                VStack(spacing: 30) {
                    // Ağaç ikonu
                    ZStack {
                        // Glow efekti
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        currentStage.color.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: currentStage.size
                                )
                            )
                            .frame(width: currentStage.size * 2, height: currentStage.size * 2)

                        // Ağaç
                        Image(systemName: currentStage.symbolName)
                            .font(.system(size: currentStage.size))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        currentStage.color,
                                        currentStage.color.opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: currentStage.color.opacity(0.5), radius: 20)
                    }
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: currentStage)

                    // Aşama adı
                    Text(currentStage.title)
                        .font(ZenTheme.headline)
                        .foregroundColor(ZenTheme.lightLavender)

                    // Toplam süre
                    Text("\(totalMinutes) dakika")
                        .font(ZenTheme.body)
                        .foregroundColor(ZenTheme.softPurple)
                }
                .padding(.vertical, 40)

                Spacer()

                // İlerleme göstergesi
                VStack(spacing: 20) {
                    if let nextStageMinutes = currentStage.nextStageMinutes {
                        // Sonraki aşama bilgisi
                        VStack(spacing: 8) {
                            Text("Sonraki Aşamaya")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ZenTheme.softPurple)

                            Text("\(minutesUntilNextStage) dakika")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(ZenTheme.lightLavender)
                        }

                        // İlerleme çubuğu
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Arka plan
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 12)

                                    // İlerleme
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    ZenTheme.calmBlue,
                                                    ZenTheme.mysticalViolet
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progress, height: 12)
                                        .animation(.easeInOut(duration: 0.5), value: progress)
                                }
                            }
                            .frame(height: 12)

                            // Yüzde göstergesi
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(ZenTheme.softPurple.opacity(0.8))
                        }
                        .padding(.horizontal, 40)

                    } else {
                        // Maksimum seviyeye ulaşıldı
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ZenTheme.lightLavender)

                            Text("Maksimum Seviye!")
                                .font(ZenTheme.headline)
                                .foregroundColor(ZenTheme.lightLavender)

                            Text("Harika bir yolculuk!")
                                .font(ZenTheme.body)
                                .foregroundColor(ZenTheme.softPurple)
                        }
                    }
                }
                .padding(.bottom, 60)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            updateTreeStage()
        }
        .onChange(of: totalMinutes) { _ in
            updateTreeStage()
        }
    }

    // MARK: - Helper Methods

    private func updateTreeStage() {
        let newStage = TreeStage.stage(for: totalMinutes)
        currentStage = newStage

        // İlerleme hesapla
        if let nextStageMinutes = currentStage.nextStageMinutes {
            let currentStageMinutes = currentStage.rawValue
            let stageRange = nextStageMinutes - currentStageMinutes
            let progressInStage = totalMinutes - currentStageMinutes
            progress = min(1.0, Double(progressInStage) / Double(stageRange))
        } else {
            progress = 1.0
        }
    }
}

#Preview {
    ZenGardenView()
}
