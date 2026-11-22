//
//  WeeklyGoalCard.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Weekly goal ring with a day-by-day strip and streak-freeze status.
//  Practice days are days with a meditation or a completed focus session.
//  A missed day is automatically covered by a streak freeze (1 per month,
//  3 for premium) so a single slip does not wipe out a long streak.
//

import SwiftUI

struct WeeklyGoalCard: View {
    @EnvironmentObject var dataManager: LocalDataManager

    private var calendar: Calendar { Calendar.current }

    /// Start-of-day dates for the 7 days of the current week
    private var weekDays: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        let active = dataManager.practiceDaysInWeek()
        let goal = dataManager.weeklyGoalDays
        let activeCount = active.count
        let progress = min(1.0, Double(activeCount) / Double(goal))
        let frozen = Set(dataManager.frozenDays.map { calendar.startOfDay(for: $0) })

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ring(progress: progress, activeCount: activeCount, goal: goal)

                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "weekly_goal_title", defaultValue: "Haftalık Hedef", comment: "Weekly goal card title"))
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(statusText(activeCount: activeCount, goal: goal))
                        .font(.subheadline)
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)

                    goalMenu(goal: goal)
                }

                Spacer(minLength: 0)
            }

            weekStrip(active: active, frozen: frozen)

            freezeRow
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
        .accessibilityElement(children: .contain)
    }

    // MARK: - Ring

    private func ring(progress: Double, activeCount: Int, goal: Int) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 9)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [ZenTheme.calmBlue, ZenTheme.mysticalViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)

            VStack(spacing: 0) {
                Text("\(activeCount)/\(goal)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Image(systemName: progress >= 1 ? "checkmark.seal.fill" : "leaf.fill")
                    .font(.system(size: 11))
                    .foregroundColor(progress >= 1 ? ZenTheme.sageGreen : ZenTheme.softPurple)
            }
        }
        .frame(width: 84, height: 84)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "weekly_goal_title", defaultValue: "Haftalık Hedef", comment: "Weekly goal card title"))
        .accessibilityValue(String(localized: "weekly_goal_progress", defaultValue: "\(activeCount) / \(goal) gün", comment: "Weekly goal progress"))
    }

    private func statusText(activeCount: Int, goal: Int) -> String {
        if activeCount >= goal {
            return String(localized: "weekly_goal_done", defaultValue: "Bu haftaki hedefine ulaştın! 🎉", comment: "Weekly goal reached")
        }
        let remaining = goal - activeCount
        return String(localized: "weekly_goal_remaining", defaultValue: "Hedefe \(remaining) gün kaldı", comment: "Days remaining to reach weekly goal")
    }

    // MARK: - Goal menu

    private func goalMenu(goal: Int) -> some View {
        Menu {
            ForEach(1...7, id: \.self) { days in
                Button {
                    dataManager.weeklyGoalDays = days
                    HapticManager.shared.playImpact(style: .light)
                } label: {
                    if days == goal {
                        Label(String(localized: "weekly_goal_option", defaultValue: "\(days) gün", comment: "Weekly goal option in days"), systemImage: "checkmark")
                    } else {
                        Text(String(localized: "weekly_goal_option", defaultValue: "\(days) gün", comment: "Weekly goal option in days"))
                    }
                }
            }
        } label: {
            Label(String(localized: "weekly_goal_change", defaultValue: "Hedefi değiştir", comment: "Change weekly goal"), systemImage: "slider.horizontal.3")
                .font(.caption.weight(.semibold))
                .foregroundColor(ZenTheme.calmBlue)
        }
    }

    // MARK: - Week strip

    private func weekStrip(active: Set<Date>, frozen: Set<Date>) -> some View {
        let today = calendar.startOfDay(for: Date())
        let symbols = calendar.veryShortWeekdaySymbols

        return HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                let isActive = active.contains(day)
                let isFrozen = frozen.contains(day)
                let isToday = day == today
                let weekdayIndex = calendar.component(.weekday, from: day) - 1

                VStack(spacing: 6) {
                    Text(symbols[weekdayIndex])
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))

                    ZStack {
                        Circle()
                            .fill(isActive ? ZenTheme.calmBlue : Color.white.opacity(0.08))
                            .overlay(
                                Circle().stroke(
                                    isToday ? ZenTheme.lightLavender : Color.clear,
                                    lineWidth: 1.5
                                )
                            )

                        if isActive {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else if isFrozen {
                            Image(systemName: "snowflake")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.6, green: 0.85, blue: 1.0))
                        }
                    }
                    .frame(width: 28, height: 28)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Streak freeze

    private var freezeRow: some View {
        let remaining = dataManager.freezesRemaining
        let allowance = dataManager.monthlyFreezeAllowance

        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "snowflake")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.6, green: 0.85, blue: 1.0))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                if dataManager.didUseFreezeYesterday {
                    Text(String(localized: "streak_freeze_used_yesterday", defaultValue: "Dünü kaçırdın ama seri korumasıyla serin güvende.", comment: "Streak freeze was used yesterday"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                }

                Text(remaining > 0
                     ? String(localized: "streak_freeze_remaining", defaultValue: "Seri koruması: bu ay \(remaining)/\(allowance) hak kaldı", comment: "Streak freezes remaining this month")
                     : String(localized: "streak_freeze_none", defaultValue: "Bu ayki seri koruma hakkın bitti", comment: "No streak freezes left this month"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Text(String(localized: "streak_freeze_info", defaultValue: "Bir günü kaçırırsan serin otomatik olarak korunur.", comment: "Streak freeze explanation"))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

#Preview {
    WeeklyGoalCard()
        .environmentObject(LocalDataManager.shared)
        .padding()
        .background(Color.black)
}
