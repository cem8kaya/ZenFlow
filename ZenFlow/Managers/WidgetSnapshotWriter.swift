//
//  WidgetSnapshotWriter.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Keeps the widget snapshot up to date: writes it when the app launches,
//  changes scene phase or the user's data changes, then asks WidgetKit to
//  reload. Does nothing (and costs nothing) until the App Group is set up.
//

import Combine
import Foundation
import WidgetKit

class WidgetSnapshotWriter {

    static let shared = WidgetSnapshotWriter()

    private var cancellables = Set<AnyCancellable>()
    private var started = false

    private init() {}

    /// Begin observing data changes (call once at launch)
    func start() {
        guard !started else { return }
        started = true

        // objectWillChange fires before the change lands, so wait a moment
        LocalDataManager.shared.objectWillChange
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        refresh()
    }

    /// Rebuild and store the snapshot, then reload the widgets
    func refresh() {
        let teaching = DailyZenManager.shared.teachingOfTheDay
        let snapshot = Self.makeSnapshot(
            dataManager: LocalDataManager.shared,
            teachingTitle: teaching.title,
            teachingQuote: teaching.quote ?? ""
        )

        if snapshot.save() {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Snapshot

    static func makeSnapshot(
        dataManager: LocalDataManager,
        teachingTitle: String,
        teachingQuote: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WidgetSnapshot {

        let streakActive = dataManager.isStreakActive()

        // The streak stays alive through tomorrow after the last session
        var expiry: Date?
        if let last = dataManager.lastSessionDate {
            expiry = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: last))
        }

        let stage = TreeGrowthStage.stage(for: dataManager.totalMinutes)

        let minutesToday = dataManager.sessionHistory
            .filter { calendar.isDate($0.date, inSameDayAs: now) }
            .reduce(0) { $0 + $1.durationMinutes }

        return WidgetSnapshot(
            streak: streakActive ? dataManager.currentStreak : 0,
            streakExpiresAt: expiry,
            totalMinutes: dataManager.totalMinutes,
            minutesToday: minutesToday,
            activeDaysThisWeek: dataManager.activeDaysThisWeek,
            weeklyGoalDays: dataManager.weeklyGoalDays,
            treeStageName: stage.title,
            treeProgress: stage.progress(for: dataManager.totalMinutes),
            teachingTitle: teachingTitle,
            teachingQuote: teachingQuote,
            generatedAt: now
        )
    }
}
