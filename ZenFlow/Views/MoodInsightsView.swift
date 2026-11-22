//
//  MoodInsightsView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Turns the mood check-ins recorded after sessions into insights: weekly
//  average and trend, a 14-day chart, how much sessions lift the mood and
//  which breathing exercise works best. A 7-day summary is free; the deeper
//  analysis is part of Premium.
//

import SwiftUI
import Charts

struct MoodInsightsView: View {
    @EnvironmentObject var dataManager: LocalDataManager
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var showPaywall = false

    var body: some View {
        let insights = MoodInsightsEngine.compute(entries: dataManager.moodHistory)

        VStack(alignment: .leading, spacing: 16) {
            header

            if insights.totalCheckIns == 0 {
                emptyState
            } else {
                summaryRow(insights)

                if storeManager.isPremiumUnlocked {
                    chart(insights)
                    impactSection(insights)
                    exerciseRanking(insights)
                } else {
                    lockedTeaser
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }

    // MARK: - Header / empty

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.text.square.fill")
                .foregroundColor(ZenTheme.mysticalViolet)
            Text(String(localized: "mood_insights_title", defaultValue: "Ruh Hali İçgörüleri", comment: "Mood insights card title"))
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
            Spacer()
            if !storeManager.isPremiumUnlocked {
                Image(systemName: "crown.fill")
                    .font(.footnote)
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.8))
            }
        }
    }

    private var emptyState: some View {
        Text(String(localized: "mood_insights_empty", defaultValue: "Seans sonunda ruh halini kaydettiğinde içgörüler burada belirir.", comment: "Mood insights empty state"))
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.7))
    }

    // MARK: - Summary (free)

    private func summaryRow(_ insights: MoodInsights) -> some View {
        HStack(spacing: 14) {
            if let average = insights.averageLast7Days {
                Text(Mood.nearest(toValue: average).emoji)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "mood_insights_avg_7d", defaultValue: "Son 7 gün ortalaması", comment: "Average mood over the last 7 days"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.1f / 5", average))
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                    if let trend = insights.weeklyTrend {
                        trendLabel(trend)
                    }
                }
            } else {
                Text(String(localized: "mood_insights_no_week_data", defaultValue: "Son 7 günde kayıt yok.", comment: "No mood check-ins in the last 7 days"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer(minLength: 0)
        }
    }

    private func trendLabel(_ trend: Double) -> some View {
        let text: String
        let icon: String
        let color: Color

        if trend > 0.2 {
            text = String(localized: "mood_insights_trend_up", defaultValue: "Geçen haftaya göre yükselişte", comment: "Mood trend up")
            icon = "arrow.up.right"
            color = ZenTheme.sageGreen
        } else if trend < -0.2 {
            text = String(localized: "mood_insights_trend_down", defaultValue: "Geçen haftaya göre düşüşte", comment: "Mood trend down")
            icon = "arrow.down.right"
            color = .orange
        } else {
            text = String(localized: "mood_insights_trend_flat", defaultValue: "Geçen haftayla aynı seviyede", comment: "Mood trend flat")
            icon = "arrow.right"
            color = ZenTheme.softPurple
        }

        return Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundColor(color)
    }

    // MARK: - Locked teaser (free)

    private var lockedTeaser: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(String(localized: "mood_insights_locked_title", defaultValue: "Gelişmiş içgörüler", comment: "Locked mood insights title"), systemImage: "lock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(ZenTheme.lightLavender)

            Text(String(localized: "mood_insights_locked_desc", defaultValue: "14 günlük grafik, seansların ruh haline etkisi ve sana en iyi gelen nefes egzersizi Premium ile açılır.", comment: "Locked mood insights description"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Button {
                showPaywall = true
            } label: {
                Text(String(localized: "mood_insights_unlock", defaultValue: "Premium'u Keşfet", comment: "Explore premium button"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(ZenTheme.mysticalViolet.opacity(0.8)))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    // MARK: - Chart (premium)

    @ViewBuilder
    private func chart(_ insights: MoodInsights) -> some View {
        if insights.dailyAverages.count >= 2 {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "mood_insights_chart_title", defaultValue: "Son 14 gün", comment: "Mood chart title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))

                Chart(insights.dailyAverages) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Mood", point.average)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(ZenTheme.calmBlue)

                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Mood", point.average)
                    )
                    .foregroundStyle(ZenTheme.mysticalViolet)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5]) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            if let level = value.as(Int.self) {
                                Text(Mood.nearest(toValue: Double(level)).emoji)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .frame(height: 140)
            }
        }
    }

    // MARK: - Session impact (premium)

    private func impactSection(_ insights: MoodInsights) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "mood_insights_impact_title", defaultValue: "Seansların etkisi", comment: "Session impact title"))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.85))

            if insights.hasSessionImpact, let change = insights.overallChange {
                let magnitude = String(format: "%.1f", abs(change))
                Text(impactMessage(change: change, magnitude: magnitude))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
            } else {
                Text(String(localized: "mood_insights_impact_hint", defaultValue: "Seans öncesi ruh halini de seçersen (başlangıç ekranındaki 🙂 simgesi) seansların etkisini burada görürsün.", comment: "Hint to record a before-session mood"))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private func impactMessage(change: Double, magnitude: String) -> String {
        if change > 0.2 {
            return String(localized: "mood_insights_impact_positive", defaultValue: "Seanslardan sonra ruh halin ortalama \(magnitude) puan yükseliyor.", comment: "Sessions lift mood")
        } else if change < -0.2 {
            return String(localized: "mood_insights_impact_negative", defaultValue: "Seanslardan sonra ruh halin ortalama \(magnitude) puan düşüyor. Farklı bir egzersiz denemek isteyebilirsin.", comment: "Sessions lower mood")
        } else {
            return String(localized: "mood_insights_impact_neutral", defaultValue: "Seans öncesi ve sonrası ruh halin benzer seviyede.", comment: "Sessions keep mood stable")
        }
    }

    // MARK: - Exercise ranking (premium)

    @ViewBuilder
    private func exerciseRanking(_ insights: MoodInsights) -> some View {
        if !insights.exerciseImpacts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                if let best = insights.bestExercise, let info = exerciseInfo(for: best.exerciseType) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(ZenTheme.lightLavender)
                        Text(String(localized: "mood_insights_best_title", defaultValue: "Sana en iyi gelen: \(info.name)", comment: "Best exercise for the user"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }

                Text(String(localized: "mood_insights_ranking_title", defaultValue: "Egzersize göre", comment: "By exercise title"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                ForEach(insights.exerciseImpacts) { impact in
                    exerciseRow(impact)
                }
            }
        }
    }

    private func exerciseRow(_ impact: MoodInsights.ExerciseImpact) -> some View {
        let info = exerciseInfo(for: impact.exerciseType)

        return HStack(spacing: 10) {
            Image(systemName: info?.iconName ?? "wind")
                .frame(width: 24)
                .foregroundColor(ZenTheme.calmBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(info?.name ?? impact.exerciseType)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(String(localized: "mood_insights_sessions_count", defaultValue: "\(impact.sessions) kayıt", comment: "Number of mood check-ins"))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            if let change = impact.averageChange {
                Text(String(format: "%+.1f", change))
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundColor(change >= 0 ? ZenTheme.sageGreen : .orange)
            }

            Text(Mood.nearest(toValue: impact.averageAfter).emoji)
                .font(.title3)
        }
    }

    private func exerciseInfo(for type: String) -> BreathingExercise? {
        BreathingExerciseManager.allExercises.first { $0.exerciseType == type }
    }
}

#Preview {
    ScrollView {
        MoodInsightsView()
            .environmentObject(LocalDataManager.shared)
            .padding()
    }
    .background(Color.black)
}
