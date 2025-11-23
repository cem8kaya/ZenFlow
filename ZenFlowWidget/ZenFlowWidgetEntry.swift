//
//  ZenFlowWidgetEntry.swift
//  ZenFlowWidget
//
//  Created by ZenFlow Widget Extension
//  Timeline entry model for the ZenFlow widget
//

import WidgetKit
import SwiftUI

/// Timeline entry for the ZenFlow widget
/// Contains all data needed to render the widget at a specific time
struct ZenFlowWidgetEntry: TimelineEntry {

    // MARK: - TimelineEntry Protocol

    /// The date at which this entry is relevant
    let date: Date

    // MARK: - Widget Data

    /// Total meditation minutes accumulated
    let totalMinutes: Int

    /// Current meditation streak in days
    let currentStreak: Int

    /// Longest meditation streak in days
    let longestStreak: Int

    /// Current tree stage information
    let treeStage: TreeStageData

    // MARK: - Computed Properties

    /// Formatted total minutes for display (e.g., "125 dk")
    var formattedMinutes: String {
        return "\(totalMinutes) dk"
    }

    /// Formatted current streak for display (e.g., "7 gün")
    var formattedStreak: String {
        return "\(currentStreak) gün"
    }

    /// Short streak display (e.g., "7🔥")
    var shortStreakDisplay: String {
        return "\(currentStreak)🔥"
    }

    /// Progress percentage to next tree stage (0-100)
    var progressPercentage: Int {
        return Int(treeStage.progress * 100)
    }

    /// Minutes until next tree stage (nil if at max stage)
    var minutesUntilNextStage: Int? {
        guard let nextStageMinutes = treeStage.nextStageMinutes else {
            return nil
        }
        return nextStageMinutes - totalMinutes
    }

    // MARK: - Placeholder Entry

    /// Creates a placeholder entry with sample data for widget preview
    static func placeholder() -> ZenFlowWidgetEntry {
        let sampleTreeStage = TreeStageData(
            name: "Fidan",
            iconName: "tree",
            currentMinutes: 150,
            nextStageMinutes: 300,
            progress: 0.5
        )

        return ZenFlowWidgetEntry(
            date: Date(),
            totalMinutes: 150,
            currentStreak: 7,
            longestStreak: 14,
            treeStage: sampleTreeStage
        )
    }

    // MARK: - Snapshot Entry

    /// Creates a snapshot entry for quick widget preview in widget gallery
    static func snapshot(widgetData: WidgetData? = nil) -> ZenFlowWidgetEntry {
        if let data = widgetData {
            return ZenFlowWidgetEntry(
                date: Date(),
                totalMinutes: data.totalMinutes,
                currentStreak: data.currentStreak,
                longestStreak: data.longestStreak,
                treeStage: data.treeStage
            )
        } else {
            return placeholder()
        }
    }

    // MARK: - Entry from Widget Data

    /// Creates a timeline entry from widget data
    static func fromWidgetData(_ data: WidgetData, at date: Date = Date()) -> ZenFlowWidgetEntry {
        return ZenFlowWidgetEntry(
            date: date,
            totalMinutes: data.totalMinutes,
            currentStreak: data.currentStreak,
            longestStreak: data.longestStreak,
            treeStage: data.treeStage
        )
    }
}

// MARK: - Preview Entries

extension ZenFlowWidgetEntry {

    /// Sample entry for beginner (seed stage)
    static var beginnerEntry: ZenFlowWidgetEntry {
        let treeStage = TreeStageData(
            name: "Tohum",
            iconName: "circle.fill",
            currentMinutes: 15,
            nextStageMinutes: 30,
            progress: 0.5
        )

        return ZenFlowWidgetEntry(
            date: Date(),
            totalMinutes: 15,
            currentStreak: 3,
            longestStreak: 5,
            treeStage: treeStage
        )
    }

    /// Sample entry for intermediate (sapling stage)
    static var intermediateEntry: ZenFlowWidgetEntry {
        let treeStage = TreeStageData(
            name: "Fidan",
            iconName: "tree",
            currentMinutes: 200,
            nextStageMinutes: 300,
            progress: 0.67
        )

        return ZenFlowWidgetEntry(
            date: Date(),
            totalMinutes: 200,
            currentStreak: 14,
            longestStreak: 21,
            treeStage: treeStage
        )
    }

    /// Sample entry for advanced (ancient tree stage)
    static var advancedEntry: ZenFlowWidgetEntry {
        let treeStage = TreeStageData(
            name: "Kadim Ağaç",
            iconName: "sparkles",
            currentMinutes: 1500,
            nextStageMinutes: nil,
            progress: 1.0
        )

        return ZenFlowWidgetEntry(
            date: Date(),
            totalMinutes: 1500,
            currentStreak: 45,
            longestStreak: 60,
            treeStage: treeStage
        )
    }
}
