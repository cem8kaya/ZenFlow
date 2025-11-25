//
//  SharedDataManager.swift
//  ZenFlowWidget
//
//  Created by ZenFlow Widget Extension
//  Manages shared data access between the main app and widget via App Group UserDefaults
//

import Foundation

/// Manages shared data access between the main app and widget extension
/// Uses App Group UserDefaults for cross-target data sharing
class SharedDataManager {

    // MARK: - App Group Configuration

    /// App Group identifier - IMPORTANT: Configure this in your Xcode project
    /// 1. Add App Groups capability to both main app and widget extension
    /// 2. Use the same group identifier (e.g., "group.com.zenflow.app")
    private static let appGroupIdentifier = "group.com.zenflow.app"

    /// Shared UserDefaults instance using App Group
    /// Cached to avoid repeated initialization and reduce console warnings
    private static let sharedDefaults: UserDefaults? = {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("⚠️ Failed to initialize App Group UserDefaults with identifier: \(appGroupIdentifier)")
            return nil
        }
        return defaults
    }()

    // MARK: - UserDefaults Keys
    // These keys must match the ones used in LocalDataManager

    private enum Keys {
        static let totalMinutes = "zenflow_total_minutes"
        static let currentStreak = "zenflow_current_streak"
        static let longestStreak = "zenflow_longest_streak"
        static let lastSessionDate = "zenflow_last_session_date"
        static let sessions = "zenflow_session_history"
    }

    // MARK: - Data Access Methods

    /// Get total meditation minutes
    static func getTotalMinutes() -> Int {
        return sharedDefaults?.integer(forKey: Keys.totalMinutes) ?? 0
    }

    /// Get current streak days
    static func getCurrentStreak() -> Int {
        return sharedDefaults?.integer(forKey: Keys.currentStreak) ?? 0
    }

    /// Get longest streak days
    static func getLongestStreak() -> Int {
        return sharedDefaults?.integer(forKey: Keys.longestStreak) ?? 0
    }

    /// Get last session date
    static func getLastSessionDate() -> Date? {
        return sharedDefaults?.object(forKey: Keys.lastSessionDate) as? Date
    }

    /// Get current tree growth stage based on total minutes
    static func getCurrentTreeStage() -> TreeStageData {
        let totalMinutes = getTotalMinutes()

        // Define tree stages matching the main app's TreeGrowthStage
        let stages: [(name: String, minMinutes: Int, iconName: String)] = [
            ("Tohum", 0, "circle.fill"),           // Seed: 0-29 minutes
            ("Filiz", 30, "leaf.fill"),            // Sprout: 30-119 minutes
            ("Fidan", 120, "tree"),                // Sapling: 120-299 minutes
            ("Genç Ağaç", 300, "tree.fill"),       // Young Tree: 300-599 minutes
            ("Olgun Ağaç", 600, "tree.fill"),      // Mature Tree: 600-1199 minutes
            ("Kadim Ağaç", 1200, "sparkles")       // Ancient Tree: 1200+ minutes
        ]

        // Find current stage
        var currentStage = stages[0]
        var nextStage: (name: String, minMinutes: Int, iconName: String)?

        for (index, stage) in stages.enumerated() {
            if totalMinutes >= stage.minMinutes {
                currentStage = stage
                // Set next stage if not at the final stage
                if index < stages.count - 1 {
                    nextStage = stages[index + 1]
                }
            } else {
                break
            }
        }

        // Calculate progress to next stage (0.0 to 1.0)
        let progress: Double
        if let next = nextStage {
            let minutesInCurrentStage = totalMinutes - currentStage.minMinutes
            let minutesNeededForNextStage = next.minMinutes - currentStage.minMinutes
            progress = Double(minutesInCurrentStage) / Double(minutesNeededForNextStage)
        } else {
            // At max stage
            progress = 1.0
        }

        return TreeStageData(
            name: currentStage.name,
            iconName: currentStage.iconName,
            currentMinutes: totalMinutes,
            nextStageMinutes: nextStage?.minMinutes,
            progress: min(max(progress, 0.0), 1.0) // Clamp between 0 and 1
        )
    }

    /// Get widget data snapshot
    static func getWidgetData() -> WidgetData {
        return WidgetData(
            totalMinutes: getTotalMinutes(),
            currentStreak: getCurrentStreak(),
            longestStreak: getLongestStreak(),
            treeStage: getCurrentTreeStage()
        )
    }
}

// MARK: - Data Models

/// Represents tree stage information for the widget
struct TreeStageData {
    let name: String              // Turkish name of the stage
    let iconName: String          // SF Symbol name
    let currentMinutes: Int       // Total meditation minutes
    let nextStageMinutes: Int?    // Minutes needed for next stage (nil if at max)
    let progress: Double          // Progress to next stage (0.0 to 1.0)
}

/// Widget data snapshot containing all necessary information
struct WidgetData {
    let totalMinutes: Int
    let currentStreak: Int
    let longestStreak: Int
    let treeStage: TreeStageData

    /// Formatted total minutes string (e.g., "125 dk")
    var formattedMinutes: String {
        return "\(totalMinutes) dk"
    }

    /// Formatted streak string (e.g., "7 gün")
    var formattedStreak: String {
        return "\(currentStreak) gün"
    }
}
