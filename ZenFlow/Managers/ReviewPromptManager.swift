//
//  ReviewPromptManager.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Asks for an App Store rating at a good moment only: right after a session
//  the user just rated as feeling good, once they have actually used the app.
//  Rate-limited by us (once per app version, at most every 120 days) on top of
//  the system's own limit.
//

import Foundation
import StoreKit
import UIKit

class ReviewPromptManager {

    // MARK: - Singleton

    static let shared = ReviewPromptManager()

    // MARK: - Policy

    enum Policy {
        /// Completed meditation sessions before the first prompt
        static let minimumSessions = 5
        /// ...or a streak of this many days
        static let minimumStreak = 3
        /// Minimum days between our own prompts
        static let minimumDaysBetweenPrompts = 120
        /// Mood value (1...5) that counts as "feeling good"
        static let minimumMoodValue = 4
    }

    private enum Keys {
        static let lastPromptDate = "reviewPromptLastDate"
        static let lastPromptVersion = "reviewPromptLastVersion"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Decision (pure)

    /// Whether this is a good moment to ask for a rating
    static func shouldPrompt(
        mood: Mood?,
        totalSessions: Int,
        currentStreak: Int,
        lastPromptDate: Date?,
        lastPromptVersion: String?,
        currentVersion: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        // Only ask when the user just told us they feel good
        guard let mood, mood.value >= Policy.minimumMoodValue else { return false }

        // Only after real engagement
        guard totalSessions >= Policy.minimumSessions || currentStreak >= Policy.minimumStreak else { return false }

        // At most once per app version
        if lastPromptVersion == currentVersion { return false }

        // And not too often overall
        if let lastPromptDate {
            let days = calendar.dateComponents([.day], from: lastPromptDate, to: now).day ?? 0
            if days < Policy.minimumDaysBetweenPrompts { return false }
        }

        return true
    }

    // MARK: - Request

    /// Call after a session ends with the mood the user picked (nil if skipped)
    func requestIfAppropriate(after mood: Mood?) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

        let shouldAsk = Self.shouldPrompt(
            mood: mood,
            totalSessions: LocalDataManager.shared.totalSessions,
            currentStreak: LocalDataManager.shared.currentStreak,
            lastPromptDate: defaults.object(forKey: Keys.lastPromptDate) as? Date,
            lastPromptVersion: defaults.string(forKey: Keys.lastPromptVersion),
            currentVersion: version
        )
        guard shouldAsk else { return }

        // Let the session-complete overlay finish dismissing first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
                return
            }

            self?.defaults.set(Date(), forKey: Keys.lastPromptDate)
            self?.defaults.set(version, forKey: Keys.lastPromptVersion)

            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
            print("⭐️ Requested App Store review")
        }
    }
}
