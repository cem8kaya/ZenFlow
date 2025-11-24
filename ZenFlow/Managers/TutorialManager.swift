//
//  TutorialManager.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//
//  Manages first-time tutorial tooltips, tracking which tutorials
//  have been shown to avoid repetition.
//

import Foundation
import Combine

/// Tutorial step identifiers
enum TutorialStep: String, CaseIterable {
    case firstBreathing = "first_breathing"
    case firstMeditation = "first_meditation"
    case zenGarden = "zen_garden"
    case focusTimer = "focus_timer"
    case achievementEarned = "achievement_earned"
}

/// Manager for first-time tutorial tooltips
class TutorialManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TutorialManager()

    // MARK: - Published Properties

    /// Currently active tutorial step
    @Published var activeTutorial: TutorialStep?

    // MARK: - Private Properties

    private var completedTutorials: Set<String> = []

    // MARK: - Constants

    private enum Keys {
        static let completedTutorials = "completedTutorials"
    }

    // MARK: - Initialization

    private init() {
        loadCompletedTutorials()
    }

    // MARK: - Public Methods

    /// Check if a tutorial should be shown
    func shouldShow(_ tutorial: TutorialStep) -> Bool {
        return !completedTutorials.contains(tutorial.rawValue)
    }

    /// Mark a tutorial as shown
    func markAsShown(_ tutorial: TutorialStep) {
        completedTutorials.insert(tutorial.rawValue)
        saveCompletedTutorials()

        // Clear active tutorial if it matches
        if activeTutorial == tutorial {
            activeTutorial = nil
        }
    }

    /// Show a tutorial (sets it as active if not already shown)
    func showTutorial(_ tutorial: TutorialStep) {
        guard shouldShow(tutorial) else { return }
        activeTutorial = tutorial
    }

    /// Dismiss the currently active tutorial
    func dismissActiveTutorial() {
        if let tutorial = activeTutorial {
            markAsShown(tutorial)
        }
        activeTutorial = nil
    }

    /// Reset all tutorials (useful for testing)
    func resetAllTutorials() {
        completedTutorials.removeAll()
        saveCompletedTutorials()
        activeTutorial = nil
    }

    // MARK: - Private Methods

    private func loadCompletedTutorials() {
        if let saved = UserDefaults.standard.array(forKey: Keys.completedTutorials) as? [String] {
            completedTutorials = Set(saved)
        }
    }

    private func saveCompletedTutorials() {
        UserDefaults.standard.set(Array(completedTutorials), forKey: Keys.completedTutorials)
    }
}
