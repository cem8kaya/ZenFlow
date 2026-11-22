//
//  WeeklyReport.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Pure summary of one calendar week: meditation minutes and sessions,
//  completed focus sessions, active days against the weekly goal, average
//  mood and the best day, plus a comparison with the week before.
//

import Foundation

struct WeeklyReport {

    /// First instant of the week (start of day)
    let weekStart: Date
    /// First instant of the following week (exclusive end)
    let weekEnd: Date

    let meditationMinutes: Int
    let meditationSessions: Int
    let completedFocusSessions: Int
    let focusMinutes: Int
    let activeDays: Int
    let goalDays: Int
    let moodCheckIns: Int
    /// Average mood (1...5), nil without check-ins
    let averageMood: Double?
    /// Start of the day with the most meditation minutes, nil if none
    let bestDay: Date?
    let bestDayMinutes: Int
    /// Meditation minutes of the previous calendar week
    let previousWeekMinutes: Int

    // MARK: - Derived

    var reachedGoal: Bool { activeDays >= goalDays }

    var isEmpty: Bool {
        meditationSessions == 0 && completedFocusSessions == 0
    }

    /// Percentage change of meditation minutes vs the previous week.
    /// nil when the previous week had no minutes (no meaningful baseline).
    var minutesChangePercent: Int? {
        guard previousWeekMinutes > 0 else { return nil }
        let change = Double(meditationMinutes - previousWeekMinutes) / Double(previousWeekMinutes) * 100
        return Int(change.rounded())
    }

    // MARK: - Factory

    static func make(
        weekContaining date: Date,
        sessions: [LocalDataManager.SessionData],
        focusSessions: [FocusSessionData],
        moods: [MoodEntry],
        goalDays: Int,
        calendar: Calendar = .current
    ) -> WeeklyReport {

        let interval = calendar.dateInterval(of: .weekOfYear, for: date)
        let start = interval?.start ?? calendar.startOfDay(for: date)
        let end = interval?.end ?? calendar.date(byAdding: .day, value: 7, to: start) ?? start
        let previousStart = calendar.date(byAdding: .day, value: -7, to: start) ?? start

        func inWeek(_ day: Date) -> Bool { day >= start && day < end }

        let weekSessions = sessions.filter { inWeek($0.date) }
        let previousMinutes = sessions
            .filter { $0.date >= previousStart && $0.date < start }
            .reduce(0) { $0 + $1.durationMinutes }

        let weekFocus = focusSessions.filter { $0.mode == .work && $0.completed && inWeek($0.date) }
        let weekMoods = moods.filter { inWeek($0.date) }

        // Minutes per day (meditation only) for the best day
        var minutesPerDay: [Date: Int] = [:]
        for session in weekSessions {
            minutesPerDay[calendar.startOfDay(for: session.date), default: 0] += session.durationMinutes
        }
        // Earliest day wins ties so the result is deterministic
        let best = minutesPerDay.sorted { lhs, rhs in
            lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key < rhs.key
        }.first

        var activeDaySet = Set(weekSessions.map { calendar.startOfDay(for: $0.date) })
        for focus in weekFocus {
            activeDaySet.insert(calendar.startOfDay(for: focus.date))
        }

        let moodAverage: Double? = weekMoods.isEmpty
            ? nil
            : Double(weekMoods.reduce(0) { $0 + $1.mood.value }) / Double(weekMoods.count)

        return WeeklyReport(
            weekStart: start,
            weekEnd: end,
            meditationMinutes: weekSessions.reduce(0) { $0 + $1.durationMinutes },
            meditationSessions: weekSessions.count,
            completedFocusSessions: weekFocus.count,
            focusMinutes: weekFocus.reduce(0) { $0 + $1.durationMinutes },
            activeDays: activeDaySet.count,
            goalDays: max(1, goalDays),
            moodCheckIns: weekMoods.count,
            averageMood: moodAverage,
            bestDay: best?.key,
            bestDayMinutes: best?.value ?? 0,
            previousWeekMinutes: previousMinutes
        )
    }

    /// Convenience: report for the week containing `date`, using stored data
    static func current(
        weekContaining date: Date = Date(),
        dataManager: LocalDataManager = .shared,
        calendar: Calendar = .current
    ) -> WeeklyReport {
        make(
            weekContaining: date,
            sessions: dataManager.sessionHistory,
            focusSessions: dataManager.focusSessionHistory,
            moods: dataManager.moodHistory,
            goalDays: dataManager.weeklyGoalDays,
            calendar: calendar
        )
    }
}
