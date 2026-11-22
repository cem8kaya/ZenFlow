//
//  FocusSettingsTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the customizable Pomodoro lengths and the premium rule.
//

import XCTest
@testable import ZenFlow

final class FocusSettingsTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "zenflow.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsAreTheClassicRhythm() {
        let defaults = FocusSettings.defaults
        XCTAssertEqual(defaults.workMinutes, 25)
        XCTAssertEqual(defaults.shortBreakMinutes, 5)
        XCTAssertEqual(defaults.longBreakMinutes, 15)
        XCTAssertEqual(defaults.sessionsBeforeLongBreak, 4)
    }

    func testMinutesPerMode() {
        let settings = FocusSettings(workMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 30, sessionsBeforeLongBreak: 3)
        XCTAssertEqual(settings.minutes(for: .work), 50)
        XCTAssertEqual(settings.minutes(for: .shortBreak), 10)
        XCTAssertEqual(settings.minutes(for: .longBreak), 30)
    }

    func testSanitizedClampsToRanges() {
        let wild = FocusSettings(workMinutes: 1, shortBreakMinutes: 99, longBreakMinutes: 0, sessionsBeforeLongBreak: 50).sanitized()
        XCTAssertEqual(wild.workMinutes, FocusSettings.workRange.lowerBound)
        XCTAssertEqual(wild.shortBreakMinutes, FocusSettings.shortBreakRange.upperBound)
        XCTAssertEqual(wild.longBreakMinutes, FocusSettings.longBreakRange.lowerBound)
        XCTAssertEqual(wild.sessionsBeforeLongBreak, FocusSettings.sessionsBeforeLongBreakRange.upperBound)
    }

    func testDefaultsLiveInsideTheirRanges() {
        let defaults = FocusSettings.defaults
        XCTAssertEqual(defaults, defaults.sanitized())
    }

    func testNextModeFollowsTheConfiguredCycle() {
        let classic = FocusSettings.defaults
        XCTAssertEqual(classic.nextMode(after: .work, completedSessions: 1), .shortBreak)
        XCTAssertEqual(classic.nextMode(after: .work, completedSessions: 3), .shortBreak)
        XCTAssertEqual(classic.nextMode(after: .work, completedSessions: 4), .longBreak)
        XCTAssertEqual(classic.nextMode(after: .work, completedSessions: 8), .longBreak)
        XCTAssertEqual(classic.nextMode(after: .shortBreak, completedSessions: 4), .work)
        XCTAssertEqual(classic.nextMode(after: .longBreak, completedSessions: 4), .work)

        var custom = FocusSettings.defaults
        custom.sessionsBeforeLongBreak = 2
        XCTAssertEqual(custom.nextMode(after: .work, completedSessions: 2), .longBreak)
        XCTAssertEqual(custom.nextMode(after: .work, completedSessions: 3), .shortBreak)
    }

    func testNoLongBreakBeforeAnySessionIsCompleted() {
        XCTAssertEqual(FocusSettings.defaults.nextMode(after: .work, completedSessions: 0), .shortBreak)
    }

    // MARK: - Store

    func testFreeUsersAlwaysGetTheClassicRhythm() {
        let store = FocusSettingsStore(defaults: defaults)
        store.isPremiumProvider = { false }
        store.update(FocusSettings(workMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 30, sessionsBeforeLongBreak: 3))

        XCTAssertEqual(store.effectiveSettings, .defaults)
        XCTAssertEqual(store.settings.workMinutes, 50, "The configured value is kept for when premium returns")
    }

    func testPremiumUsersGetTheirOwnRhythm() {
        let store = FocusSettingsStore(defaults: defaults)
        store.isPremiumProvider = { true }
        store.update(FocusSettings(workMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 30, sessionsBeforeLongBreak: 3))

        XCTAssertEqual(store.effectiveSettings.workMinutes, 50)
        XCTAssertEqual(store.effectiveSettings.sessionsBeforeLongBreak, 3)
    }

    func testSettingsPersistAndAreSanitizedOnLoad() {
        let store = FocusSettingsStore(defaults: defaults)
        store.update(FocusSettings(workMinutes: 45, shortBreakMinutes: 8, longBreakMinutes: 20, sessionsBeforeLongBreak: 5))

        let reloaded = FocusSettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.settings.workMinutes, 45)

        store.update(FocusSettings(workMinutes: 1000, shortBreakMinutes: 8, longBreakMinutes: 20, sessionsBeforeLongBreak: 5))
        XCTAssertEqual(store.settings.workMinutes, FocusSettings.workRange.upperBound)
    }

    func testResetToDefaults() {
        let store = FocusSettingsStore(defaults: defaults)
        store.update(FocusSettings(workMinutes: 45, shortBreakMinutes: 8, longBreakMinutes: 20, sessionsBeforeLongBreak: 5))
        store.resetToDefaults()
        XCTAssertEqual(store.settings, .defaults)
    }
}
