//
//  GardenDecoration.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Objects that appear in the Zen Garden as the user keeps practicing: stones,
//  bamboo, a stone lantern and a koi pond. Unlocking depends only on a small
//  stats value, so the rules are pure and easy to test.
//

import Foundation

/// The progress numbers that decide which decorations are unlocked
struct GardenStats: Equatable {
    var totalSessions: Int
    var totalMinutes: Int
    var longestStreak: Int
}

enum GardenDecoration: String, CaseIterable, Identifiable {
    case stones
    case bamboo
    case lantern
    case pond

    var id: String { rawValue }

    // MARK: - Unlock rules

    /// Which stat the decoration depends on
    enum Requirement: Equatable {
        case sessions(Int)
        case minutes(Int)
        case streakDays(Int)

        var target: Int {
            switch self {
            case .sessions(let value), .minutes(let value), .streakDays(let value):
                return value
            }
        }

        func current(in stats: GardenStats) -> Int {
            switch self {
            case .sessions: return stats.totalSessions
            case .minutes: return stats.totalMinutes
            case .streakDays: return stats.longestStreak
            }
        }
    }

    var requirement: Requirement {
        switch self {
        case .stones: return .sessions(1)
        case .bamboo: return .minutes(120)
        case .lantern: return .streakDays(7)
        case .pond: return .sessions(25)
        }
    }

    func isUnlocked(in stats: GardenStats) -> Bool {
        requirement.current(in: stats) >= requirement.target
    }

    /// 0...1 progress towards unlocking
    func progress(in stats: GardenStats) -> Double {
        let target = requirement.target
        guard target > 0 else { return 1 }
        return min(1, Double(requirement.current(in: stats)) / Double(target))
    }

    /// All decorations unlocked by `stats`
    static func unlocked(in stats: GardenStats) -> Set<GardenDecoration> {
        Set(allCases.filter { $0.isUnlocked(in: stats) })
    }

    // MARK: - Presentation

    var emoji: String {
        switch self {
        case .stones: return "🪨"
        case .bamboo: return "🎋"
        case .lantern: return "🏮"
        case .pond: return "🐟"
        }
    }

    var name: String {
        switch self {
        case .stones:
            return String(localized: "garden_deco_stones", defaultValue: "Zen Taşları", comment: "Garden decoration: stones")
        case .bamboo:
            return String(localized: "garden_deco_bamboo", defaultValue: "Bambu", comment: "Garden decoration: bamboo")
        case .lantern:
            return String(localized: "garden_deco_lantern", defaultValue: "Taş Fener", comment: "Garden decoration: stone lantern")
        case .pond:
            return String(localized: "garden_deco_pond", defaultValue: "Koi Gölü", comment: "Garden decoration: koi pond")
        }
    }

    /// How to unlock, e.g. "Complete 25 sessions"
    var requirementText: String {
        switch requirement {
        case .sessions(let count):
            return String(localized: "garden_req_sessions", defaultValue: "\(count) meditasyon seansı tamamla", comment: "Garden requirement: sessions")
        case .minutes(let count):
            return String(localized: "garden_req_minutes", defaultValue: "Toplam \(count) dakika meditasyon yap", comment: "Garden requirement: minutes")
        case .streakDays(let count):
            return String(localized: "garden_req_streak", defaultValue: "\(count) günlük seriye ulaş", comment: "Garden requirement: streak")
        }
    }
}
