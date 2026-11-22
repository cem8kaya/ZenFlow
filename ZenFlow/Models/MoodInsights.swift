//
//  MoodInsights.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Pure, testable analytics over mood check-ins: weekly averages and trend,
//  a daily series for charts, how much a session shifts the user's mood and
//  which breathing exercise works best for them.
//

import Foundation

struct MoodInsights {

    /// Average mood (1...5) for one calendar day
    struct DayPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let average: Double
    }

    /// Aggregated results for one breathing exercise
    struct ExerciseImpact: Identifiable {
        var id: String { exerciseType }
        let exerciseType: String
        /// Number of check-ins recorded after this exercise
        let sessions: Int
        /// Average mood (1...5) after the exercise
        let averageAfter: Double
        /// Average (after - before) over check-ins that have a before-mood
        let averageChange: Double?
        /// How many check-ins contributed to `averageChange`
        let changeSamples: Int
    }

    let totalCheckIns: Int
    /// Average mood over the last 7 days, nil without data
    let averageLast7Days: Double?
    /// Average mood over the 7 days before that, nil without data
    let averagePrevious7Days: Double?
    /// Daily averages for the last 14 days (days without data are omitted)
    let dailyAverages: [DayPoint]
    /// Average mood change over all sessions with a before-mood
    let overallChange: Double?
    let changeSamples: Int
    /// Exercises ranked by average mood change, then by mood after
    let exerciseImpacts: [ExerciseImpact]

    /// Week-over-week change of the average mood
    var weeklyTrend: Double? {
        guard let current = averageLast7Days, let previous = averagePrevious7Days else { return nil }
        return current - previous
    }

    /// Best exercise for the user: needs at least two check-ins to be meaningful
    var bestExercise: ExerciseImpact? {
        exerciseImpacts.first { $0.sessions >= MoodInsightsEngine.minimumSessionsForRanking }
    }

    /// Whether there is enough before/after data to talk about session impact
    var hasSessionImpact: Bool {
        changeSamples >= MoodInsightsEngine.minimumChangeSamples && overallChange != nil
    }
}

enum MoodInsightsEngine {

    static let minimumSessionsForRanking = 2
    static let minimumChangeSamples = 3
    static let chartDays = 14

    static func compute(
        entries: [MoodEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> MoodInsights {

        func average(_ values: [Int]) -> Double? {
            values.isEmpty ? nil : Double(values.reduce(0, +)) / Double(values.count)
        }

        let startOfToday = calendar.startOfDay(for: now)

        // Weekly windows are day-aligned: [today-6, today] and [today-13, today-7]
        let last7Start = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        let previous7Start = calendar.date(byAdding: .day, value: -13, to: startOfToday) ?? startOfToday
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        let last7 = entries.filter { $0.date >= last7Start && $0.date < tomorrow }
        let previous7 = entries.filter { $0.date >= previous7Start && $0.date < last7Start }

        // Daily series for the chart (last 14 days)
        let recent = entries.filter { $0.date >= previous7Start && $0.date < tomorrow }
        let grouped = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.date) }
        let dailyAverages: [MoodInsights.DayPoint] = grouped
            .compactMap { day, dayEntries in
                average(dayEntries.map { $0.mood.value }).map { MoodInsights.DayPoint(date: day, average: $0) }
            }
            .sorted { $0.date < $1.date }

        // Before/after change
        let changes = entries.compactMap { $0.change }
        let overallChange = average(changes)

        // Per-exercise impact
        let byExercise = Dictionary(grouping: entries.filter { $0.exerciseType != nil }) { $0.exerciseType! }
        let impacts: [MoodInsights.ExerciseImpact] = byExercise.compactMap { type, list in
            guard let after = average(list.map { $0.mood.value }) else { return nil }
            let exerciseChanges = list.compactMap { $0.change }
            return MoodInsights.ExerciseImpact(
                exerciseType: type,
                sessions: list.count,
                averageAfter: after,
                averageChange: average(exerciseChanges),
                changeSamples: exerciseChanges.count
            )
        }
        .sorted { lhs, rhs in
            switch (lhs.averageChange, rhs.averageChange) {
            case let (l?, r?) where l != r:
                return l > r
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            default:
                if lhs.averageAfter != rhs.averageAfter { return lhs.averageAfter > rhs.averageAfter }
                // Deterministic order for ties
                return lhs.exerciseType < rhs.exerciseType
            }
        }

        return MoodInsights(
            totalCheckIns: entries.count,
            averageLast7Days: average(last7.map { $0.mood.value }),
            averagePrevious7Days: average(previous7.map { $0.mood.value }),
            dailyAverages: dailyAverages,
            overallChange: overallChange,
            changeSamples: changes.count,
            exerciseImpacts: impacts
        )
    }
}
