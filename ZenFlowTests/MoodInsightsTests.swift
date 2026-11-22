//
//  MoodInsightsTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for mood analytics and for backward-compatible decoding of
//  mood entries saved by earlier app versions.
//

import XCTest
@testable import ZenFlow

final class MoodInsightsTests: XCTestCase {

    private let calendar = Calendar.current

    /// Fixed "now": noon on 15 March 2026
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 12))!
    }

    private func daysAgo(_ days: Int, hour: Int = 9) -> Date {
        let start = calendar.startOfDay(for: now)
        let day = calendar.date(byAdding: .day, value: -days, to: start)!
        return calendar.date(byAdding: .hour, value: hour, to: day)!
    }

    private func entry(
        _ mood: Mood,
        daysAgo days: Int,
        pre: Mood? = nil,
        exercise: String? = nil,
        hour: Int = 9
    ) -> MoodEntry {
        MoodEntry(date: daysAgo(days, hour: hour), mood: mood, preMood: pre, exerciseType: exercise)
    }

    // MARK: - Empty / basic

    func testEmptyEntries() {
        let insights = MoodInsightsEngine.compute(entries: [], now: now)
        XCTAssertEqual(insights.totalCheckIns, 0)
        XCTAssertNil(insights.averageLast7Days)
        XCTAssertNil(insights.weeklyTrend)
        XCTAssertNil(insights.overallChange)
        XCTAssertNil(insights.bestExercise)
        XCTAssertTrue(insights.dailyAverages.isEmpty)
        XCTAssertFalse(insights.hasSessionImpact)
    }

    func testWeeklyAveragesAndTrend() {
        let entries = [
            entry(.veryHappy, daysAgo: 0),  // 5  (this week)
            entry(.happy, daysAgo: 3),      // 4  (this week)
            entry(.neutral, daysAgo: 8),    // 3  (previous week)
            entry(.sad, daysAgo: 12),       // 2  (previous week)
            entry(.verySad, daysAgo: 30)    // outside both windows
        ]
        let insights = MoodInsightsEngine.compute(entries: entries, now: now)

        XCTAssertEqual(insights.totalCheckIns, 5)
        XCTAssertEqual(insights.averageLast7Days ?? -1, 4.5, accuracy: 0.0001)
        XCTAssertEqual(insights.averagePrevious7Days ?? -1, 2.5, accuracy: 0.0001)
        XCTAssertEqual(insights.weeklyTrend ?? -1, 2.0, accuracy: 0.0001)
    }

    func testWindowBoundaries() {
        // Day 6 ago is still "this week", day 7 ago is the previous week
        let entries = [entry(.happy, daysAgo: 6), entry(.sad, daysAgo: 7)]
        let insights = MoodInsightsEngine.compute(entries: entries, now: now)
        XCTAssertEqual(insights.averageLast7Days ?? -1, 4.0, accuracy: 0.0001)
        XCTAssertEqual(insights.averagePrevious7Days ?? -1, 2.0, accuracy: 0.0001)
    }

    func testDailyAveragesGroupByDayAndAreSorted() {
        let entries = [
            entry(.happy, daysAgo: 1, hour: 8),
            entry(.neutral, daysAgo: 1, hour: 20), // same day: average (4 + 3) / 2
            entry(.veryHappy, daysAgo: 4),
            entry(.sad, daysAgo: 20)               // outside the 14-day chart window
        ]
        let insights = MoodInsightsEngine.compute(entries: entries, now: now)

        XCTAssertEqual(insights.dailyAverages.count, 2)
        XCTAssertLessThan(insights.dailyAverages[0].date, insights.dailyAverages[1].date)
        XCTAssertEqual(insights.dailyAverages[0].average, 5.0, accuracy: 0.0001)
        XCTAssertEqual(insights.dailyAverages[1].average, 3.5, accuracy: 0.0001)
    }

    // MARK: - Session impact

    func testOverallChangeUsesOnlyEntriesWithPreMood() {
        let entries = [
            entry(.happy, daysAgo: 1, pre: .sad),      // +2
            entry(.neutral, daysAgo: 2, pre: .neutral),// 0
            entry(.happy, daysAgo: 3, pre: .neutral),  // +1
            entry(.veryHappy, daysAgo: 4)              // no pre-mood: ignored
        ]
        let insights = MoodInsightsEngine.compute(entries: entries, now: now)

        XCTAssertEqual(insights.changeSamples, 3)
        XCTAssertEqual(insights.overallChange ?? -99, 1.0, accuracy: 0.0001)
        XCTAssertTrue(insights.hasSessionImpact)
    }

    func testSessionImpactNeedsEnoughSamples() {
        let entries = [
            entry(.happy, daysAgo: 1, pre: .sad),
            entry(.happy, daysAgo: 2, pre: .sad)
        ]
        let insights = MoodInsightsEngine.compute(entries: entries, now: now)
        XCTAssertEqual(insights.changeSamples, 2)
        XCTAssertFalse(insights.hasSessionImpact)
    }

    func testMoodEntryChange() {
        XCTAssertEqual(MoodEntry(mood: .happy, preMood: .verySad).change, 3)
        XCTAssertEqual(MoodEntry(mood: .sad, preMood: .happy).change, -2)
        XCTAssertNil(MoodEntry(mood: .happy).change)
    }

    // MARK: - Exercise ranking

    func testExerciseRankingPrefersLargestMoodGain() {
        let entries = [
            entry(.veryHappy, daysAgo: 1, pre: .sad, exercise: "box"),     // +3
            entry(.happy, daysAgo: 2, pre: .neutral, exercise: "box"),     // +1  -> avg +2
            entry(.happy, daysAgo: 3, pre: .neutral, exercise: "calming"), // +1
            entry(.happy, daysAgo: 4, pre: .neutral, exercise: "calming"), // +1  -> avg +1
            entry(.veryHappy, daysAgo: 5, pre: .verySad, exercise: "478")  // +4, only 1 session
        ]
        let insights = MoodInsightsEngine.compute(entries: entries, now: now)

        XCTAssertEqual(insights.exerciseImpacts.map { $0.exerciseType }, ["478", "box", "calming"])

        // The 478 session has the best change but a single session is not
        // enough to be crowned "best"
        XCTAssertEqual(insights.bestExercise?.exerciseType, "box")
        XCTAssertEqual(insights.bestExercise?.averageChange ?? -99, 2.0, accuracy: 0.0001)
        XCTAssertEqual(insights.bestExercise?.sessions, 2)
    }

    func testExercisesWithoutChangeDataRankAfterThoseWithData() {
        let entries = [
            entry(.veryHappy, daysAgo: 1, exercise: "energy"),             // no pre-mood
            entry(.neutral, daysAgo: 2, pre: .neutral, exercise: "box")    // change 0
        ]
        let insights = MoodInsightsEngine.compute(entries: entries, now: now)
        XCTAssertEqual(insights.exerciseImpacts.first?.exerciseType, "box")
        XCTAssertNil(insights.exerciseImpacts.last?.averageChange)
    }

    func testEntriesWithoutExerciseAreNotRanked() {
        let insights = MoodInsightsEngine.compute(entries: [entry(.happy, daysAgo: 1)], now: now)
        XCTAssertTrue(insights.exerciseImpacts.isEmpty)
    }

    // MARK: - Mood helpers & persistence compatibility

    func testNearestMoodRoundsAndClamps() {
        XCTAssertEqual(Mood.nearest(toValue: 3.4), .neutral)
        XCTAssertEqual(Mood.nearest(toValue: 3.6), .happy)
        XCTAssertEqual(Mood.nearest(toValue: 0), .verySad)
        XCTAssertEqual(Mood.nearest(toValue: 9), .veryHappy)
    }

    func testLegacyMoodEntryJSONStillDecodes() throws {
        // Shape written by v1.0: id, date, mood only
        let json = """
        [{"id":"7B3C1E55-2F7A-4C57-9F1D-0A4F5B9E1C11","date":700000000,"mood":"happy"}]
        """
        let entries = try JSONDecoder().decode([MoodEntry].self, from: Data(json.utf8))

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].mood, .happy)
        XCTAssertNil(entries[0].preMood)
        XCTAssertNil(entries[0].exerciseType)
        XCTAssertNil(entries[0].durationMinutes)
    }

    func testNewMoodEntryRoundTrip() throws {
        let original = MoodEntry(mood: .veryHappy, preMood: .sad, exerciseType: "box", durationMinutes: 10)
        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([MoodEntry].self, from: data)

        XCTAssertEqual(decoded.first?.preMood, .sad)
        XCTAssertEqual(decoded.first?.exerciseType, "box")
        XCTAssertEqual(decoded.first?.durationMinutes, 10)
    }

    func testSaveMoodPersistsSessionContext() {
        let suite = "zenflow.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let manager = LocalDataManager(defaults: defaults)
        manager.saveMood(.happy, preMood: .sad, exerciseType: "478", durationMinutes: 5)

        let saved = manager.moodHistory
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].preMood, .sad)
        XCTAssertEqual(saved[0].exerciseType, "478")
        XCTAssertEqual(saved[0].durationMinutes, 5)
    }
}
