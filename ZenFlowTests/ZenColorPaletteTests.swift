//
//  ZenColorPaletteTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the breathing themes and their premium rule.
//

import XCTest
@testable import ZenFlow

final class ZenColorPaletteTests: XCTestCase {

    func testOnlySereneIsFree() {
        XCTAssertFalse(ZenColorPalette.serene.isPremium)
        XCTAssertTrue(ZenColorPalette.allCases.filter { $0 != .serene }.allSatisfy { $0.isPremium })
    }

    func testPremiumPalettesFallBackToSereneForFreeUsers() {
        for palette in ZenColorPalette.allCases {
            XCTAssertEqual(palette.effective(isPremiumUser: false), .serene)
            XCTAssertEqual(palette.effective(isPremiumUser: true), palette)
        }
    }

    func testEveryPaletteIsLocalizedAndHasEnoughColors() {
        let rawKeys = ["palette_serene_name", "palette_forest_name", "palette_sunset_name", "palette_midnight_name"]
        for palette in ZenColorPalette.allCases {
            XCTAssertFalse(rawKeys.contains(palette.displayName), "Missing name for \(palette.rawValue)")
            XCTAssertFalse(palette.displayName.isEmpty)
            XCTAssertFalse(palette.description.isEmpty)
            XCTAssertGreaterThanOrEqual(palette.colors.count, 3)
        }
    }

    func testPaletteNamesAreDistinct() {
        let names = ZenColorPalette.allCases.map { $0.displayName }
        XCTAssertEqual(names.count, Set(names).count)
    }
}
