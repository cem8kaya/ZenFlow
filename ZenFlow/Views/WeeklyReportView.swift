//
//  WeeklyReportView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  "Your week in Zen": minutes, sessions, active days against the goal,
//  average mood and the best day, for this week or the last one, with a
//  shareable image card. Opened from the stats screen, the Sunday
//  notification or zenflow://report.
//

import SwiftUI

struct WeeklyReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: LocalDataManager

    private enum Week: Int, CaseIterable {
        case current, previous
    }

    @State private var week: Week = .current
    @State private var shareImage: Image?

    private var calendar: Calendar { Calendar.current }

    private var referenceDate: Date {
        switch week {
        case .current:
            return Date()
        case .previous:
            return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }
    }

    private var report: WeeklyReport {
        WeeklyReport.current(weekContaining: referenceDate, dataManager: dataManager)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZenTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        weekPicker

                        let report = report

                        if report.isEmpty {
                            emptyState
                        } else {
                            headline(report)
                            statGrid(report)
                            highlights(report)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(String(localized: "weekly_report_title", defaultValue: "Haftalık Zen Raporu", comment: "Weekly report title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let shareImage, !report.isEmpty {
                        ShareLink(
                            item: shareImage,
                            preview: SharePreview(
                                String(localized: "weekly_report_title", defaultValue: "Haftalık Zen Raporu", comment: "Weekly report title"),
                                image: shareImage
                            )
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .foregroundColor(ZenTheme.lightLavender)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "daily_zen_done", defaultValue: "Tamam", comment: "Done button")) {
                        dismiss()
                    }
                    .foregroundColor(ZenTheme.lightLavender)
                }
            }
            .onAppear { renderShareImage() }
            .onChange(of: week) { _, _ in renderShareImage() }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Pieces

    private var weekPicker: some View {
        Picker("", selection: $week) {
            Text(String(localized: "weekly_report_this_week", defaultValue: "Bu hafta", comment: "This week")).tag(Week.current)
            Text(String(localized: "weekly_report_last_week", defaultValue: "Geçen hafta", comment: "Last week")).tag(Week.previous)
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf")
                .font(.system(size: 40))
                .foregroundColor(ZenTheme.softPurple)
            Text(String(localized: "weekly_report_empty", defaultValue: "Bu hafta henüz seans yok. Kısa bir nefes bile bir başlangıçtır.", comment: "Weekly report empty state"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(ZenTheme.lightLavender.opacity(0.8))
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
    }

    private func headline(_ report: WeeklyReport) -> some View {
        VStack(spacing: 6) {
            Text(String(localized: "weekly_report_range", defaultValue: "\(report.weekStart.formatted(.dateTime.day().month(.abbreviated))) – \(lastDay(of: report).formatted(.dateTime.day().month(.abbreviated)))", comment: "Week date range"))
                .font(.footnote)
                .foregroundColor(ZenTheme.softPurple)

            Text(report.reachedGoal
                 ? String(localized: "weekly_report_goal_reached", defaultValue: "Haftalık hedefine ulaştın 🎉", comment: "Goal reached headline")
                 : String(localized: "weekly_report_goal_progress", defaultValue: "Hedefin: \(report.activeDays)/\(report.goalDays) gün", comment: "Goal progress headline"))
                .font(.title3.weight(.semibold))
                .foregroundColor(ZenTheme.lightLavender)
        }
    }

    private func statGrid(_ report: WeeklyReport) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            statTile(
                icon: "clock.fill",
                color: ZenTheme.calmBlue,
                value: String(localized: "weekly_report_minutes_value", defaultValue: "\(report.meditationMinutes) dk", comment: "Minutes value"),
                title: String(localized: "weekly_report_minutes", defaultValue: "Meditasyon", comment: "Meditation minutes tile")
            )
            statTile(
                icon: "leaf.fill",
                color: ZenTheme.sageGreen,
                value: "\(report.meditationSessions)",
                title: String(localized: "weekly_report_sessions", defaultValue: "Seans", comment: "Sessions tile")
            )
            statTile(
                icon: "timer",
                color: ZenTheme.mysticalViolet,
                value: "\(report.completedFocusSessions)",
                title: String(localized: "weekly_report_focus", defaultValue: "Odak seansı", comment: "Focus sessions tile")
            )
            statTile(
                icon: "calendar",
                color: ZenTheme.serenePurple,
                value: "\(report.activeDays)/\(report.goalDays)",
                title: String(localized: "weekly_report_active_days", defaultValue: "Aktif gün", comment: "Active days tile")
            )
        }
    }

    private func statTile(icon: String, color: Color, value: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .accessibilityElement(children: .combine)
    }

    private func highlights(_ report: WeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let percent = report.minutesChangePercent {
                // Passed as an argument so the literal "%" never sits inside a format string
                let percentText = "%\(abs(percent))"
                highlightRow(
                    icon: percent >= 0 ? "arrow.up.right" : "arrow.down.right",
                    color: percent >= 0 ? ZenTheme.sageGreen : .orange,
                    text: percent >= 0
                        ? String(localized: "weekly_report_more", defaultValue: "Geçen haftadan \(percentText) daha fazla meditasyon yaptın.", comment: "More minutes than last week")
                        : String(localized: "weekly_report_less", defaultValue: "Geçen haftadan \(percentText) daha az. Küçük adımlar da sayılır.", comment: "Fewer minutes than last week")
                )
            }

            if let bestDay = report.bestDay {
                highlightRow(
                    icon: "star.fill",
                    color: .yellow,
                    text: String(localized: "weekly_report_best_day", defaultValue: "En iyi gün: \(bestDay.formatted(.dateTime.weekday(.wide))) (\(report.bestDayMinutes) dk)", comment: "Best day of the week")
                )
            }

            if let mood = report.averageMood {
                highlightRow(
                    icon: "heart.fill",
                    color: ZenTheme.mysticalViolet,
                    text: String(localized: "weekly_report_mood", defaultValue: "Ortalama ruh halin: \(Mood.nearest(toValue: mood).emoji) \(String(format: "%.1f", mood))/5", comment: "Average mood of the week")
                )
            }

            highlightRow(
                icon: "flame.fill",
                color: .orange,
                text: String(localized: "weekly_report_streak", defaultValue: "Güncel serin: \(dataManager.currentStreak) gün", comment: "Current streak")
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
    }

    private func highlightRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundColor(ZenTheme.lightLavender.opacity(0.9))
        }
    }

    // MARK: - Helpers

    /// Last calendar day of the report's week (weekEnd is exclusive)
    private func lastDay(of report: WeeklyReport) -> Date {
        calendar.date(byAdding: .day, value: -1, to: report.weekEnd) ?? report.weekEnd
    }

    private func renderShareImage() {
        let renderer = ImageRenderer(content: WeeklyReportShareCard(report: report))
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Share card

/// Image rendered from a report for sharing
struct WeeklyReportShareCard: View {
    let report: WeeklyReport

    static let size = CGSize(width: 360, height: 450)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ZenTheme.deepIndigo, Color(red: 0.10, green: 0.08, blue: 0.22), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(ZenTheme.mysticalViolet.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: -110, y: -150)

            VStack(spacing: 20) {
                Text(String(localized: "weekly_report_card_title", defaultValue: "Haftam Zen'de", comment: "Share card title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ZenTheme.softPurple)
                    .textCase(.uppercase)

                VStack(spacing: 4) {
                    Text("\(report.meditationMinutes)")
                        .font(.system(size: 76, weight: .thin, design: .rounded))
                        .foregroundColor(ZenTheme.lightLavender)
                    Text(String(localized: "weekly_report_card_minutes", defaultValue: "dakika meditasyon", comment: "Share card minutes caption"))
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }

                HStack(spacing: 18) {
                    cardStat("\(report.meditationSessions)", String(localized: "weekly_report_sessions", defaultValue: "Seans", comment: "Sessions tile"))
                    cardStat("\(report.activeDays)/\(report.goalDays)", String(localized: "weekly_report_active_days", defaultValue: "Aktif gün", comment: "Active days tile"))
                    if let mood = report.averageMood {
                        cardStat(Mood.nearest(toValue: mood).emoji, String(localized: "weekly_report_card_mood", defaultValue: "Ruh hali", comment: "Mood caption"))
                    } else {
                        cardStat("\(report.completedFocusSessions)", String(localized: "weekly_report_focus", defaultValue: "Odak seansı", comment: "Focus sessions tile"))
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                    Text("MyZenFlow")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
            }
            .padding(28)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }

    private func cardStat(_ value: String, _ title: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
