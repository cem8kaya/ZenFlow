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
            Text(String(localized: "stats_last_4_weeks", defaultValue: "Son 4 Hafta Aktivite", comment: "Last 4 weeks activity title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                // Gün başlıkları
                HStack(spacing: 6) {
                    // Gün isimlerini lokalize ediyoruz
                    let days = [
                        String(localized: "weekday_short_mon", defaultValue: "Pzt", comment: "Monday short"),
                        String(localized: "weekday_short_tue", defaultValue: "Sal", comment: "Tuesday short"),
                        String(localized: "weekday_short_wed", defaultValue: "Çar", comment: "Wednesday short"),
                        String(localized: "weekday_short_thu", defaultValue: "Per", comment: "Thursday short"),
                        String(localized: "weekday_short_fri", defaultValue: "Cum", comment: "Friday short"),
                        String(localized: "weekday_short_sat", defaultValue: "Cmt", comment: "Saturday short"),
                        String(localized: "weekday_short_sun", defaultValue: "Paz", comment: "Sunday short")
                    ]
                    
                    ForEach(days, id: \.self) { day in
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
                                            Text(String(localized: "unit_min_short", defaultValue: "dk", comment: "Minutes short unit"))
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
                    Text(String(localized: "stats_legend_less", defaultValue: "Az", comment: "Less activity"))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 4) {
                        ForEach([0, 5, 15, 35], id: \.self) { minutes in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(activityColor(for: minutes))
                                .frame(width: 12, height: 12)
                        }
                    }

                    Text(String(localized: "stats_legend_more", defaultValue: "Çok", comment: "More activity"))
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
            Text(String(localized: "stats_monthly_summary", defaultValue: "Bu Ay Özeti", comment: "Monthly summary title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack(spacing: 12) {
                SummaryCard(
                    icon: "calendar",
                    title: String(localized: "stats_this_month", defaultValue: "Bu Ay", comment: "This month"),
                    value: "\(thisMonthMinutes) \(String(localized: "unit_min_short", defaultValue: "dk"))",
                    color: ZenTheme.calmBlue
                )

                SummaryCard(
                    icon: "calendar.badge.clock",
                    title: String(localized: "stats_this_week", defaultValue: "Bu Hafta", comment: "This week"),
                    value: "\(thisWeekMinutes) \(String(localized: "unit_min_short", defaultValue: "dk"))",
                    color: ZenTheme.serenePurple
                )
            }

            HStack(spacing: 12) {
                SummaryCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: String(localized: "stats_average", defaultValue: "Ortalama", comment: "Average"),
                    value: "\(averageSessionMinutes) \(String(localized: "unit_min_short", defaultValue: "dk"))",
                    color: ZenTheme.deepSage
                )

                SummaryCard(
                    icon: "star.fill",
                    title: String(localized: "stats_longest", defaultValue: "En Uzun", comment: "Longest"),
                    value: "\(longestSessionMinutes) \(String(localized: "unit_min_short", defaultValue: "dk"))",
                    color: ZenTheme.mysticalViolet
                )
            }
        }
    }

    // MARK: - Son 7 Gün Grafik

    private var last7DaysChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "stats_last_7_days", defaultValue: "Son 7 Gün", comment: "Last 7 days title"))
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
                        x: .value(String(localized: "stats_chart_day", defaultValue: "Gün"), data.dayName),
                        y: .value(String(localized: "stats_chart_minutes", defaultValue: "Dakika"), data.minutes)
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
            Text(String(localized: "stats_all_time", defaultValue: "Tüm Zamanlar", comment: "All time stats title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                MetricRow(
                    icon: "figure.mind.and.body",
                    title: String(localized: "stats_total_meditation_time", defaultValue: "Toplam Meditasyon Süresi", comment: "Total meditation time label"),
                    value: formatTotalDuration(dataManager.totalMinutes),
                    color: ZenTheme.calmBlue
                )

                MetricRow(
                    icon: "number",
                    title: String(localized: "stats_total_sessions", defaultValue: "Toplam Seans Sayısı", comment: "Total sessions label"),
                    value: "\(dataManager.totalSessions)",
                    color: ZenTheme.serenePurple
                )

                MetricRow(
                    icon: "flame.fill",
                    title: String(localized: "stats_current_streak", defaultValue: "Mevcut Seri", comment: "Current streak label"),
                    value: "\(dataManager.currentStreak) \(String(localized: "unit_days", defaultValue: "gün"))",
                    color: .orange
                )

                MetricRow(
                    icon: "trophy.fill",
                    title: String(localized: "stats_longest_streak", defaultValue: "En Uzun Seri", comment: "Longest streak label"),
                    value: "\(dataManager.longestStreak) \(String(localized: "unit_days", defaultValue: "gün"))",
                    color: .yellow
                )

                MetricRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: String(localized: "stats_avg_session_duration", defaultValue: "Ortalama Seans Süresi", comment: "Average session duration label"),
                    value: "\(averageSessionMinutes) \(String(localized: "unit_minutes", defaultValue: "dakika"))",
                    color: ZenTheme.deepSage
                )

                MetricRow(
                    icon: "star.fill",
                    title: String(localized: "stats_longest_single_session", defaultValue: "En Uzun Tek Seans", comment: "Longest single session label"),
                    value: "\(longestSessionMinutes) \(String(localized: "unit_minutes", defaultValue: "dakika"))",
                    color: ZenTheme.mysticalViolet
                )

                MetricRow(
                    icon: "brain.head.profile",
                    title: String(localized: "stats_most_used_type", defaultValue: "En Çok Kullanılan Tür", comment: "Most used type label"),
                    value: mostUsedExerciseType,
                    color: .cyan
                )

                MetricRow(
                    icon: "clock.fill",
                    title: String(localized: "stats_total_focus_sessions", defaultValue: "Toplam Odaklanma Seansı", comment: "Total focus sessions label"),
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
            // DÜZELTME: Sabit tr_TR yerine cihazın mevcut locale'i kullanılıyor
            formatter.locale = Locale.autoupdatingCurrent
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
        // Gelecekte eklenebilir, şimdilik varsayılan değer döndürüyoruz
        return String(localized: "stats_all_types", defaultValue: "Tüm Türler", comment: "All exercise types")
    }

    private func formatTotalDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        let hourShort = String(localized: "unit_hour_short", defaultValue: "s", comment: "Hours short symbol")
        let minShort = String(localized: "unit_min_short", defaultValue: "d", comment: "Minutes short symbol")

        if hours > 0 {
            return "\(hours)\(hourShort) \(mins)\(minShort)"
        } else {
            return "\(mins) \(String(localized: "unit_minutes", defaultValue: "dakika"))"
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
