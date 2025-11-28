//
//  StatsView.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Detailed statistics view with GitHub-style contribution grid,
//  weekly/monthly summaries, and bar charts.
//

import SwiftUI
import Charts
import Combine

struct StatsView: View {
    // MARK: - Environment Objects (Performance Optimization)
    @EnvironmentObject var dataManager: LocalDataManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Haftalık Aktivite Grid
                weeklyActivityGrid

                // Aylık Özet Kartları
                monthlySummaryCards

                // Grafik: Son 7 Gün
                last7DaysChart

                // Detaylı Metrikler
                detailedMetrics
            }
            .padding()
        }
        .refreshable {
            // Refresh data from LocalDataManager
            await refreshStats()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.1, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Refresh Function

    private func refreshStats() async {
        // Simulate a brief refresh delay for UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Trigger a UI update by accessing the data manager
        // The @StateObject will automatically refresh the view
        await MainActor.run {
            dataManager.objectWillChange.send()
        }
    }

    // MARK: - Haftalık Aktivite Grid (GitHub Tarzı)

    private var weeklyActivityGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son 4 Hafta Aktivite")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                // Gün başlıkları
                HStack(spacing: 6) {
                    ForEach(["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"], id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                    }
                }

                // 4 haftalık grid
                ForEach(0..<4, id: \.self) { week in
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { day in
                            let dayData = getDayData(week: week, day: day)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(activityColor(for: dayData.minutes))
                                .frame(height: 40)
                                .overlay(
                                    VStack(spacing: 2) {
                                        if dayData.minutes > 0 {
                                            Text("\(dayData.minutes)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            Text("dk")
                                                .font(.system(size: 8))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                )
                        }
                    }
                }

                // Renk açıklaması
                HStack(spacing: 12) {
                    Spacer()
                    Text("Az")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 4) {
                        ForEach([0, 5, 15, 35], id: \.self) { minutes in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(activityColor(for: minutes))
                                .frame(width: 12, height: 12)
                        }
                    }

                    Text("Çok")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Aylık Özet Kartları

    private var monthlySummaryCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bu Ay Özeti")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack(spacing: 12) {
                SummaryCard(
                    icon: "calendar",
                    title: "Bu Ay",
                    value: "\(thisMonthMinutes) dk",
                    color: ZenTheme.calmBlue
                )

                SummaryCard(
                    icon: "calendar.badge.clock",
                    title: "Bu Hafta",
                    value: "\(thisWeekMinutes) dk",
                    color: ZenTheme.serenePurple
                )
            }

            HStack(spacing: 12) {
                SummaryCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Ortalama",
                    value: "\(averageSessionMinutes) dk",
                    color: ZenTheme.deepSage
                )

                SummaryCard(
                    icon: "star.fill",
                    title: "En Uzun",
                    value: "\(longestSessionMinutes) dk",
                    color: ZenTheme.mysticalViolet
                )
            }
        }
    }

    // MARK: - Son 7 Gün Grafik

    private var last7DaysChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son 7 Gün")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Group {
                if #available(iOS 16.0, *) {
                    chartView
                } else {
                    fallbackChartView
                }
            }
        }
    }
    
    @available(iOS 16.0, *)
    private var chartView: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(last7DaysData, id: \.date) { data in
                    BarMark(
                        x: .value("Gün", data.dayName),
                        y: .value("Dakika", data.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [ZenTheme.calmBlue, ZenTheme.serenePurple]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.6))
                        .font(.caption)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.8))
                        .font(.caption)
                }
            }
            .frame(height: 200)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private var fallbackChartView: some View {
        // iOS 16 öncesi için basit bar görünümü
        VStack(spacing: 8) {
            ForEach(last7DaysData, id: \.date) { data in
                HStack {
                    Text(data.dayName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40, alignment: .leading)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [ZenTheme.calmBlue, ZenTheme.serenePurple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat(data.minutes) / CGFloat(max(last7DaysData.map(\.minutes).max() ?? 1, 1)) * geo.size.width)
                    }
                    .frame(height: 20)

                    Text("\(data.minutes)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Detaylı Metrikler

    private var detailedMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tüm Zamanlar")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                MetricRow(
                    icon: "figure.mind.and.body",
                    title: "Toplam Meditasyon Süresi",
                    value: formatTotalDuration(dataManager.totalMinutes),
                    color: ZenTheme.calmBlue
                )

                MetricRow(
                    icon: "number",
                    title: "Toplam Seans Sayısı",
                    value: "\(dataManager.totalSessions)",
                    color: ZenTheme.serenePurple
                )

                MetricRow(
                    icon: "flame.fill",
                    title: "Mevcut Seri",
                    value: "\(dataManager.currentStreak) gün",
                    color: .orange
                )

                MetricRow(
                    icon: "trophy.fill",
                    title: "En Uzun Seri",
                    value: "\(dataManager.longestStreak) gün",
                    color: .yellow
                )

                MetricRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Ortalama Seans Süresi",
                    value: "\(averageSessionMinutes) dakika",
                    color: ZenTheme.deepSage
                )

                MetricRow(
                    icon: "star.fill",
                    title: "En Uzun Tek Seans",
                    value: "\(longestSessionMinutes) dakika",
                    color: ZenTheme.mysticalViolet
                )

                MetricRow(
                    icon: "brain.head.profile",
                    title: "En Çok Kullanılan Tür",
                    value: mostUsedExerciseType,
                    color: .cyan
                )

                MetricRow(
                    icon: "clock.fill",
                    title: "Toplam Odaklanma Seansı",
                    value: "\(dataManager.totalFocusSessions)",
                    color: .mint
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Helper Methods

    private func getDayData(week: Int, day: Int) -> (date: Date, minutes: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate the date for this cell (going backwards from today)
        let daysBack = (3 - week) * 7 + (6 - day)
        guard let date = calendar.date(byAdding: .day, value: -daysBack, to: today) else {
            return (Date(), 0)
        }

        // Get sessions for this day
        let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
        let sessions = dataManager.getSessions(from: date, to: nextDay)
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }

        return (date, totalMinutes)
    }

    private func activityColor(for minutes: Int) -> Color {
        switch minutes {
        case 0:
            return Color.white.opacity(0.1)
        case 1..<10:
            return ZenTheme.deepSage.opacity(0.3)
        case 10..<30:
            return ZenTheme.deepSage.opacity(0.6)
        default:
            return ZenTheme.deepSage
        }
    }

    private var last7DaysData: [(date: Date, dayName: String, minutes: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).map { daysBack in
            guard let date = calendar.date(byAdding: .day, value: -daysBack, to: today) else {
                return (Date(), "", 0)
            }

            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            let sessions = dataManager.getSessions(from: date, to: nextDay)
            let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.dateFormat = "EEE"
            let dayName = formatter.string(from: date)

            return (date, dayName, totalMinutes)
        }.reversed()
    }

    private var thisWeekMinutes: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else { return 0 }

        let sessions = dataManager.getSessions(from: weekStart, to: Date())
        return sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    private var thisMonthMinutes: Int {
        let calendar = Calendar.current
        let today = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else { return 0 }

        let sessions = dataManager.getSessions(from: monthStart, to: today)
        return sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    private var averageSessionMinutes: Int {
        guard dataManager.totalSessions > 0 else { return 0 }
        return dataManager.totalMinutes / dataManager.totalSessions
    }

    private var longestSessionMinutes: Int {
        let allSessions = dataManager.sessionHistory
        return allSessions.map(\.durationMinutes).max() ?? 0
    }

    private var mostUsedExerciseType: String {
        // LocalDataManager'da egzersiz türü bilgisi saklanmıyor
        // Gelecekte eklenebilir, şimdilik "N/A" döndürüyoruz
        return "Tüm Türler"
    }

    private func formatTotalDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)s \(mins)d"
        } else {
            return "\(mins) dakika"
        }
    }
}

// MARK: - Summary Card Component

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Metric Row Component

struct MetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    StatsView()
}
