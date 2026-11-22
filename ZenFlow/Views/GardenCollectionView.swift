//
//  GardenCollectionView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Lists every garden decoration with its unlock requirement and progress.
//

import SwiftUI

struct GardenCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: LocalDataManager

    private var stats: GardenStats {
        GardenStats(
            totalSessions: dataManager.totalSessions,
            totalMinutes: dataManager.totalMinutes,
            longestStreak: dataManager.longestStreak
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZenTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        Text(String(localized: "garden_collection_intro", defaultValue: "Düzenli pratik bahçeni güzelleştirir. Her nesne belli bir hedefe ulaşınca bahçende belirir.", comment: "Garden collection intro"))
                            .font(.subheadline)
                            .foregroundColor(ZenTheme.softPurple)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)

                        ForEach(GardenDecoration.allCases) { decoration in
                            row(decoration)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(String(localized: "garden_collection_title", defaultValue: "Bahçe Koleksiyonu", comment: "Garden collection title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "daily_zen_done", defaultValue: "Tamam", comment: "Done button")) {
                        dismiss()
                    }
                    .foregroundColor(ZenTheme.lightLavender)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func row(_ decoration: GardenDecoration) -> some View {
        let unlocked = decoration.isUnlocked(in: stats)
        let requirement = decoration.requirement

        return HStack(spacing: 14) {
            Text(decoration.emoji)
                .font(.system(size: 32))
                .opacity(unlocked ? 1 : 0.35)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(decoration.name)
                    .font(.headline)
                    .foregroundColor(unlocked ? ZenTheme.lightLavender : ZenTheme.lightLavender.opacity(0.6))

                Text(decoration.requirementText)
                    .font(.caption)
                    .foregroundColor(ZenTheme.softPurple)

                if !unlocked {
                    ProgressView(value: decoration.progress(in: stats))
                        .tint(ZenTheme.calmBlue)
                    Text("\(requirement.current(in: stats))/\(requirement.target)")
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                .foregroundColor(unlocked ? ZenTheme.sageGreen : ZenTheme.softPurple.opacity(0.6))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .accessibilityElement(children: .combine)
    }
}
