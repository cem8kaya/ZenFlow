//
//  CoachContext.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Everything the Zen Coach knows about the moment: time of day, streak,
//  today's practice, weekly goal, recent mood and what works best for this
//  user. A plain value so the coach logic can be tested with any situation.
//

import Foundation

struct CoachContext: Equatable {

    enum TimePeriod: Equatable {
        case morning    // 05-11
        case afternoon  // 12-16
        case evening    // 17-21
        case night      // 22-04

        init(hour: Int) {
            switch hour {
            case 5..<12: self = .morning
            case 12..<17: self = .afternoon
            case 17..<22: self = .evening
            default: self = .night
            }
        }
    }

    var period: TimePeriod
    var currentStreak: Int
    var totalSessions: Int
    var practicedToday: Bool
    var activeDaysThisWeek: Int
    var weeklyGoalDays: Int
    /// Average mood (1...5) over the last 7 days, nil without check-ins
    var recentMoodAverage: Double?
    /// Check-ins in the last 7 days
    var recentMoodCount: Int
    /// The exercise that lifts this user's mood the most (exerciseType) and its name
    var bestExerciseType: String?
    var bestExerciseName: String?
    var isPremium: Bool
    /// Pomodoro length currently in effect, in minutes
    var focusMinutes: Int

    // MARK: - Derived

    var weeklyGoalDaysRemaining: Int {
        max(0, weeklyGoalDays - activeDaysThisWeek)
    }

    /// A streak worth protecting that has no session yet today
    var streakAtRisk: Bool {
        currentStreak >= 2 && !practicedToday
    }

    /// Several recent check-ins and a low average
    var recentMoodIsLow: Bool {
        guard let average = recentMoodAverage else { return false }
        return recentMoodCount >= 3 && average <= 2.4
    }

    var isNewUser: Bool { totalSessions == 0 }

    // MARK: - Defaults

    /// A neutral baseline for tests and previews
    static let baseline = CoachContext(
        period: .afternoon,
        currentStreak: 0,
        totalSessions: 5,
        practicedToday: false,
        activeDaysThisWeek: 0,
        weeklyGoalDays: 5,
        recentMoodAverage: nil,
        recentMoodCount: 0,
        bestExerciseType: nil,
        bestExerciseName: nil,
        isPremium: false,
        focusMinutes: 25
    )

    // MARK: - Live context

    /// Builds the context from the app's current data
    static func current(
        now: Date = Date(),
        calendar: Calendar = .current,
        dataManager: LocalDataManager = .shared
    ) -> CoachContext {

        let hour = calendar.component(.hour, from: now)
        let isPremium = StoreManager.cachedPremiumStatus

        // Mood: last 7 days and the best exercise
        let moods = dataManager.moodHistory
        let insights = MoodInsightsEngine.compute(entries: moods, now: now, calendar: calendar)
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        let recentMoods = moods.filter { $0.date >= weekAgo }

        // Only suggest an exercise the user can actually start
        var bestType: String?
        var bestName: String?
        if let best = insights.bestExercise,
           (best.averageChange ?? 0) > 0,
           best.exerciseType != MoodEntry.silentMeditationType,
           let exercise = BreathingExerciseManager.shared.allExercises.first(where: { $0.exerciseType == best.exerciseType }),
           !exercise.isPremium || isPremium {
            bestType = exercise.exerciseType
            bestName = exercise.name
        }

        return CoachContext(
            period: TimePeriod(hour: hour),
            currentStreak: dataManager.isStreakActive() ? dataManager.currentStreak : 0,
            totalSessions: dataManager.totalSessions,
            practicedToday: calendar.isDate(dataManager.lastSessionDate ?? .distantPast, inSameDayAs: now),
            activeDaysThisWeek: dataManager.activeDaysThisWeek,
            weeklyGoalDays: dataManager.weeklyGoalDays,
            recentMoodAverage: insights.averageLast7Days,
            recentMoodCount: recentMoods.count,
            bestExerciseType: bestType,
            bestExerciseName: bestName,
            isPremium: isPremium,
            focusMinutes: FocusSettingsStore.shared.effectiveSettings.workMinutes
        )
    }
}
