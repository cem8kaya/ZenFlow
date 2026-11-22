//
//  ZenFlowIntents.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Siri, Spotlight and Shortcuts support: start a breathing exercise, a focus
//  session or Sleep Mode, or open the weekly report, by voice or from the
//  Shortcuts app. Each intent opens the app and hands a zenflow:// link to
//  DeepLinkHandler, which queues it until the UI is ready (cold launch safe).
//
//  The intent types are `nonisolated` because the project defaults to
//  MainActor isolation, while App Intents are instantiated by the system.
//

import AppIntents

// MARK: - Exercise parameter

nonisolated enum BreathingExerciseOption: String, AppEnum {
    case box
    case calming
    case energy
    case deep
    case fourSevenEight = "478"
    case coherent
    case sigh
    case triangle

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Breathing Exercise")

    static let caseDisplayRepresentations: [BreathingExerciseOption: DisplayRepresentation] = [
        .box: DisplayRepresentation(title: "Box Breathing"),
        .calming: DisplayRepresentation(title: "Calming Breath"),
        .energy: DisplayRepresentation(title: "Energy Breath"),
        .deep: DisplayRepresentation(title: "Deep Relaxation"),
        .fourSevenEight: DisplayRepresentation(title: "4-7-8 Technique"),
        .coherent: DisplayRepresentation(title: "Coherent Breathing 5-5"),
        .sigh: DisplayRepresentation(title: "Physiological Sigh"),
        .triangle: DisplayRepresentation(title: "Triangle Breath")
    ]
}

// MARK: - Intents

nonisolated struct StartBreathingIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Breathing"
    static let description = IntentDescription("Opens MyZenFlow and gets a breathing exercise ready.")
    static let openAppWhenRun = true

    @Parameter(title: "Exercise", default: .box)
    var exercise: BreathingExerciseOption

    @MainActor
    func perform() async throws -> some IntentResult {
        // Premium exercises stay behind the paywall: fall back to Box Breathing
        let type = StartBreathingIntent.allowedExerciseType(exercise.rawValue, isPremium: StoreManager.cachedPremiumStatus)
        DeepLinkHandler.shared.enqueue("zenflow://breathing?exercise=\(type)")
        return .result()
    }

    /// The exercise a user may start via Shortcuts: premium ones only with premium
    @MainActor
    static func allowedExerciseType(_ type: String, isPremium: Bool) -> String {
        BreathingExerciseManager.allowedExerciseType(type, isPremium: isPremium)
    }
}

nonisolated struct StartFocusIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Focus Session"
    static let description = IntentDescription("Opens the MyZenFlow focus timer.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLinkHandler.shared.enqueue("zenflow://focus")
        return .result()
    }
}

nonisolated struct StartSleepModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Sleep Mode"
    static let description = IntentDescription("Opens MyZenFlow Sleep Mode with calming sounds and a timer.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLinkHandler.shared.enqueue("zenflow://sleep")
        return .result()
    }
}

nonisolated struct ShowWeeklyReportIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Weekly Zen Report"
    static let description = IntentDescription("Shows your meditation summary for the week.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLinkHandler.shared.enqueue("zenflow://report")
        return .result()
    }
}

// MARK: - Shortcuts

nonisolated struct ZenFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartBreathingIntent(),
            phrases: [
                "Start breathing in \(.applicationName)",
                "Breathe with \(.applicationName)"
            ],
            shortTitle: "Breathe",
            systemImageName: "wind"
        )

        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start focus in \(.applicationName)",
                "Focus with \(.applicationName)"
            ],
            shortTitle: "Focus",
            systemImageName: "timer"
        )

        AppShortcut(
            intent: StartSleepModeIntent(),
            phrases: [
                "Start sleep mode in \(.applicationName)",
                "Help me sleep with \(.applicationName)"
            ],
            shortTitle: "Sleep",
            systemImageName: "moon.stars.fill"
        )

        AppShortcut(
            intent: ShowWeeklyReportIntent(),
            phrases: [
                "Show my weekly report in \(.applicationName)",
                "My week in \(.applicationName)"
            ],
            shortTitle: "Weekly Report",
            systemImageName: "doc.text.fill"
        )
    }
}
