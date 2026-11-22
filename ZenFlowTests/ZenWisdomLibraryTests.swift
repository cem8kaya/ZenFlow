//
//  ZenWisdomLibraryTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Guards the teaching library. The texts are looked up by dynamically built
//  keys (zen_teaching_<n>_<field>), so a missing string would silently show
//  the raw key to users; these tests catch that.
//

import XCTest
@testable import ZenFlow

final class ZenWisdomLibraryTests: XCTestCase {

    private let library = ZenWisdomLibrary.shared

    func testLibraryHasExpectedNumberOfTeachings() {
        XCTAssertEqual(library.teachingCount, ZenWisdomLibrary.totalTeachings)
        XCTAssertGreaterThanOrEqual(library.teachingCount, 40)
    }

    func testTeachingIndicesAreSequential() {
        for index in 0..<library.teachingCount {
            XCTAssertEqual(library.getTeaching(at: index)?.teachingIndex, index)
        }
    }

    func testEveryCategoryHasTheSameNumberOfTeachings() {
        let counts = ZenCategory.allCases.map { category in
            (0..<library.teachingCount).filter { library.getTeaching(at: $0)?.category == category.rawValue }.count
        }
        XCTAssertEqual(Set(counts).count, 1, "Categories are unbalanced: \(counts)")
    }

    func testEveryTeachingHasAllLocalizedFields() {
        for index in 0..<library.teachingCount {
            guard let teaching = library.getTeaching(at: index) else {
                XCTFail("Missing teaching \(index)")
                continue
            }
            XCTAssertNotEqual(teaching.title, "zen_teaching_\(index)_title", "title \(index)")
            XCTAssertNotEqual(teaching.content, "zen_teaching_\(index)_content", "content \(index)")
            XCTAssertNotEqual(teaching.practicalAdvice, "zen_teaching_\(index)_advice", "advice \(index)")
            XCTAssertNotNil(teaching.quote, "quote \(index)")
            XCTAssertNotEqual(teaching.quote, "zen_teaching_\(index)_quote", "quote \(index)")
            XCTAssertNotEqual(teaching.author, "zen_teaching_\(index)_author", "author \(index)")
            XCTAssertFalse(teaching.title.isEmpty)
            XCTAssertFalse(teaching.content.isEmpty)
        }
    }

    func testEveryCategoryHasADisplayName() {
        for category in ZenCategory.allCases {
            XCTAssertNotEqual(category.displayName, "zen_category_\(category.rawValue)")
        }
    }

    func testDailyRotationCoversTheWholeLibrary() {
        let calendar = Calendar.current
        let count = library.teachingCount
        let start = Date()
        let indices = (0..<count).map { offset -> Int in
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            return DailyZenManager.dailyRotationIndex(for: day, count: count)
        }
        XCTAssertEqual(Set(indices).count, count, "Rotation should not repeat within \(count) days")
    }
}
