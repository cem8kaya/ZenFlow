//
//  DailyZenManagerTests.swift
//  ZenFlowTests
//
//  Created by Claude AI on 13.07.2026.
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Unit tests for the Daily Zen Moment logic: gratitude streak
//  computation, the deterministic daily teaching rotation, and
//  gratitude entry persistence encoding.
//

import XCTest
@testable import ZenFlow

final class DailyZenStreakTests: XCTestCase {

    private let calendar = Calendar.current

    /// Helper: a date `days` before today at noon (mid-day avoids DST edges)
    private func day(_ daysAgo: Int, from reference: Date = Date()) -> Date {
        let start = calendar.startOfDay(for: reference)
        let target = calendar.date(byAdding: .day, value: -daysAgo, to: start)!
        return calendar.date(byAdding: .hour, value: 12, to: target)!
    }

    func testEmptyEntriesGiveZeroStreak() {
        XCTAssertEqual(DailyZenManager.computeStreak(entryDates: [], today: Date()), 0)
    }

    func testSingleEntryTodayGivesStreakOfOne() {
        XCTAssertEqual(DailyZenManager.computeStreak(entryDates: [day(0)], today: Date()), 1)
    }

    func testConsecutiveDaysAccumulate() {
        let entries = [day(0), day(1), day(2)]
        XCTAssertEqual(DailyZenManager.computeStreak(entryDates: entries, today: Date()), 3)
    }

    func testGapBreaksStreak() {
        // today, yesterday, then a hole, then 3 days ago
        let entries = [day(0), day(1), day(3)]
        XCTAssertEqual(DailyZenManager.computeStreak(entryDates: entries, today: Date()), 2)
    }

    func testMissingTodayCountsFromYesterday() {
        // No entry yet today: an unbroken run ending yesterday must not read as zero
        let entries = [day(1), day(2)]
        XCTAssertEqual(DailyZenManager.computeStreak(entryDates: entries, today: Date()), 2)
    }

    func testEntryOnlyTwoDaysAgoGivesZero() {
        XCTAssertEqual(DailyZenManager.computeStreak(entryDates: [day(2)], today: Date()), 0)
    }

    func testMultipleEntriesSameDayCountOnce() {
        let entries = [day(0), day(0), day(0), day(1)]
        XCTAssertEqual(DailyZenManager.computeStreak(entryDates: entries, today: Date()), 2)
    }

    func testFutureEntriesDoNotInflateStreak() {
        // An entry dated tomorrow (clock skew) must not break the walk from today
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: day(0))!
        let entries = [tomorrow, day(0), day(1)]
        XCTAssertEqual(DailyZenManager.computeStreak(entryDates: entries, today: Date()), 2)
    }
}

final class DailyRotationTests: XCTestCase {

    private let calendar = Calendar.current

    func testIndexIsInRange() {
        for offset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: offset, to: Date())!
            let index = DailyZenManager.dailyRotationIndex(for: date, count: 10)
            XCTAssertTrue((0..<10).contains(index), "index \(index) out of range on day offset \(offset)")
        }
    }

    func testIndexIsStableWithinADay() {
        let morning = calendar.startOfDay(for: Date()).addingTimeInterval(60)
        let night = calendar.startOfDay(for: Date()).addingTimeInterval(23 * 3600)
        XCTAssertEqual(
            DailyZenManager.dailyRotationIndex(for: morning, count: 10),
            DailyZenManager.dailyRotationIndex(for: night, count: 10)
        )
    }

    func testIndexAdvancesByOneEachDay() {
        let today = Date()
        let count = ZenWisdomLibrary.shared.teachingCount
        let indexToday = DailyZenManager.dailyRotationIndex(for: today, count: count)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let indexTomorrow = DailyZenManager.dailyRotationIndex(for: tomorrow, count: count)
        XCTAssertEqual(indexTomorrow, (indexToday + 1) % count)
    }

    func testZeroCountDoesNotCrash() {
        XCTAssertEqual(DailyZenManager.dailyRotationIndex(for: Date(), count: 0), 0)
    }

    func testTeachingOfTheDayComesFromLibrary() {
        let teaching = DailyZenManager.shared.teachingOfTheDay
        let count = ZenWisdomLibrary.shared.teachingCount
        XCTAssertTrue((0..<count).contains(teaching.teachingIndex))

        // Category must match what the library itself stores for that index
        let libraryTeaching = ZenWisdomLibrary.shared.getTeaching(at: teaching.teachingIndex)
        XCTAssertEqual(teaching.category, libraryTeaching?.category)
    }
}

final class GratitudeEntryTests: XCTestCase {

    func testCodableRoundTrip() throws {
        let entry = GratitudeEntry(text: "Sabah kahvesi ve sessizlik")
        let data = try JSONEncoder().encode([entry])
        let decoded = try JSONDecoder().decode([GratitudeEntry].self, from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].id, entry.id)
        XCTAssertEqual(decoded[0].text, entry.text)
        XCTAssertEqual(
            decoded[0].date.timeIntervalSinceReferenceDate,
            entry.date.timeIntervalSinceReferenceDate,
            accuracy: 0.001
        )
    }
}
