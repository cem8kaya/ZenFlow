//
//  ZenCoachEngine.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  The Zen Coach's brain. Works fully offline and deterministically (apart
//  from picking text variants), in this order:
//
//   1. Safety: a message about self-harm gets a caring, resource-first reply
//      and nothing else - never an exercise, never a quote.
//   2. Small talk: greetings, thanks and "yes"/"no" after a suggestion.
//   3. Intent + sentiment, then a reply built from an opening, an intent body,
//      one context line (time, streak, mood, what works best for the user)
//      and a closing question tied to a button that opens the right screen.
//   4. Progress questions are answered with the user's real numbers.
//

import Foundation

// MARK: - Supporting types

/// A button under a coach reply
struct CoachAction: Equatable {
    let text: String
    let url: String
}

/// What the coach remembers within a conversation
struct CoachConversationState {
    var lastActionText: String?
    var lastActionURL: String?
    /// Last variant index used per text group, so the same line is not repeated
    var lastVariants: [String: Int] = [:]
    /// Day on which the gentle low-mood note was last shown (at most once a day)
    var lastLowMoodNoteDay: Date?

    var lastAction: CoachAction? {
        guard let text = lastActionText, let url = lastActionURL else { return nil }
        return CoachAction(text: text, url: url)
    }
}

/// Quick prompts offered under the chat
enum CoachPromptID: String, CaseIterable {
    case meditation, tired, focus, sleep, motivation, weekly, streak, gratitude, anger

    var text: String { CoachStrings.text("coach_prompt_\(rawValue)") }
}

// MARK: - Strings

/// Coach texts live in Localizable.xcstrings under dynamic keys (marked
/// "manual" there, because Xcode cannot extract keys built at runtime).
/// `ZenCoachEngineTests` fails if any key is missing, which would otherwise
/// show up in the chat as a raw key.
enum CoachStrings {

    /// Number of variants of each text group (keys are "<group>_<index>")
    static let variantCounts: [String: Int] = [
        "coach_open_negative": 4, "coach_open_neutral": 3, "coach_open_positive": 4,
        "coach_body_stress": 3, "coach_body_anger": 3, "coach_body_focus": 3, "coach_body_sleep": 3,
        "coach_body_breathing": 3, "coach_body_motivation": 3, "coach_body_meditation": 3,
        "coach_body_general": 3, "coach_body_gratitude": 3,
        "coach_close_breathing": 2, "coach_close_focus": 2, "coach_close_sleep": 2,
        "coach_close_garden": 2, "coach_close_gratitude": 2, "coach_close_report": 2,
        "coach_thanks": 2, "coach_followup_yes": 2, "coach_followup_no": 2,
        "coach_quote": 20
    ]

    /// Single keys (no variants)
    static let singleKeys: [String] = [
        "coach_greeting_morning", "coach_greeting_afternoon", "coach_greeting_evening", "coach_greeting_night",
        "coach_greeting_followup", "coach_followup_yes_noaction", "coach_crisis",
        "coach_ctx_low_mood", "coach_ctx_streak_risk", "coach_ctx_first_time", "coach_ctx_goal_close",
        "coach_ctx_best_exercise", "coach_ctx_streak_celebrate", "coach_ctx_focus_length",
        "coach_progress_summary", "coach_progress_streak", "coach_progress_more", "coach_progress_less",
        "coach_progress_goal_reached", "coach_progress_empty", "coach_progress_best_day",
        "coach_action_breathing", "coach_action_sleep", "coach_action_focus", "coach_action_garden",
        "coach_action_gratitude", "coach_action_report"
    ] + CoachPromptID.allCases.map { "coach_prompt_\($0.rawValue)" }

    /// Every key the coach can look up
    static var allKeys: [String] {
        var keys = singleKeys
        for (group, count) in variantCounts {
            keys += (0..<count).map { "\(group)_\($0)" }
        }
        return keys
    }

    static func text(_ key: String) -> String {
        NSLocalizedString(key, comment: "Zen Coach")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), arguments: arguments)
    }
}

// MARK: - Engine

struct ZenCoachEngine {

    /// Random source for text variants (replaceable in tests)
    var randomIndex: (Int) -> Int = { Int.random(in: 0..<$0) }
    var calendar: Calendar = .current
    var now: () -> Date = { Date() }
    /// Weekly numbers for progress questions (replaceable in tests)
    var reportProvider: () -> WeeklyReport = { WeeklyReport.current() }
    /// Display name of an exercise type (replaceable in tests)
    var exerciseName: (String) -> String? = { type in
        BreathingExerciseManager.shared.allExercises.first { $0.exerciseType == type }?.name
    }
    /// Lets an exercise through only if the user may start it
    var allowedExercise: (String, Bool) -> String = { type, isPremium in
        BreathingExerciseManager.allowedExerciseType(type, isPremium: isPremium)
    }

    // Percent of neutral/negative replies that get a Zen quote
    private let quoteChance = 35

    // MARK: - Reply

    func reply(
        to text: String,
        context: CoachContext,
        state: inout CoachConversationState
    ) -> ZenCoachResponse {

        let normalized = CoachIntentScorer.normalize(text)
        let words = CoachIntentScorer.tokens(of: normalized)

        // 1. Safety first
        if Self.indicatesSelfHarm(normalized) {
            state.lastActionText = nil
            state.lastActionURL = nil
            return ZenCoachResponse(
                text: CoachStrings.text("coach_crisis"),
                intent: .general,
                sentiment: .negative,
                kind: .crisis
            )
        }

        // 2. Small talk
        if let smallTalk = smallTalkReply(normalized: normalized, words: words, context: context, state: &state) {
            return smallTalk
        }

        // 3. A real request
        let intent = IntentClassifier.shared.classifyIntent(from: text)
        let sentiment = IntentClassifier.shared.analyzeSentiment(from: text)

        let response: ZenCoachResponse
        if intent == .progress {
            response = progressReply(sentiment: sentiment, context: context, state: &state)
        } else {
            response = standardReply(intent: intent, sentiment: sentiment, context: context, state: &state)
        }

        state.lastActionText = response.actionText
        state.lastActionURL = response.actionURL
        return response
    }

    // MARK: - Safety

    /// Phrases (diacritics folded) that suggest the user may harm themselves.
    /// Deliberately broad: a false alarm costs a kind message, a miss costs far more.
    private static let selfHarmPhrases: [String] = [
        "intihar", "kendimi oldur", "kendime zarar", "kendimi kes", "yasamak istemiyorum",
        "olmek istiyorum", "hayatima son", "yasamanin anlami yok", "olsem daha iyi",
        "suicide", "suicidal", "kill myself", "killing myself", "end my life", "want to die",
        "wanna die", "self harm", "self-harm", "hurt myself", "dont want to live",
        "don't want to live", "no reason to live", "better off dead"
    ]

    static func indicatesSelfHarm(_ normalizedText: String) -> Bool {
        let text = normalizedText.replacingOccurrences(of: "’", with: "'")
        return selfHarmPhrases.contains { text.contains($0) }
    }

    // MARK: - Small talk

    private static let greetingWords: Set<String> = [
        "merhaba", "selam", "selamlar", "slm", "mrb", "hey", "hello", "hi", "hola", "gunaydin"
    ]
    private static let thanksWords: Set<String> = [
        "tesekkur", "tesekkurler", "tsk", "saol", "sagol", "thanks", "thank", "thx"
    ]
    private static let yesWords: Set<String> = [
        "evet", "olur", "tamam", "tabi", "tabii", "peki", "hadi", "baslayalim", "yes", "yeah", "yep", "ok", "okay", "sure"
    ]
    private static let noWords: Set<String> = [
        "hayir", "yok", "istemiyorum", "no", "nope", "later", "sonra"
    ]

    private func smallTalkReply(
        normalized: String,
        words: [String],
        context: CoachContext,
        state: inout CoachConversationState
    ) -> ZenCoachResponse? {

        let isShort = words.count <= 4

        // "yes" / "no" to a suggestion
        if isShort, let action = state.lastAction {
            let saysNo = !Set(words).isDisjoint(with: Self.noWords)
                || normalized.contains("simdi degil") || normalized.contains("not now")
            let saysYes = !Set(words).isDisjoint(with: Self.yesWords)
                || normalized.contains("let's go") || normalized.contains("lets go")

            if saysNo {
                state.lastActionText = nil
                state.lastActionURL = nil
                return ZenCoachResponse(
                    text: variant("coach_followup_no", state: &state),
                    intent: .general, sentiment: .neutral, kind: .followUp
                )
            }
            if saysYes {
                return ZenCoachResponse(
                    text: variant("coach_followup_yes", state: &state),
                    intent: .general, sentiment: .positive,
                    actionText: action.text, actionURL: action.url, kind: .followUp
                )
            }
        } else if isShort, !Set(words).isDisjoint(with: Self.yesWords), words.count <= 2 {
            // A bare "yes" with nothing to say yes to
            return ZenCoachResponse(
                text: CoachStrings.text("coach_followup_yes_noaction"),
                intent: .general, sentiment: .positive, kind: .followUp
            )
        }

        // Greeting
        if words.count <= 4,
           !Set(words).isDisjoint(with: Self.greetingWords)
            || normalized.contains("iyi aksamlar") || normalized.contains("good morning") || normalized.contains("good evening") {
            let greetingKey: String
            switch context.period {
            case .morning: greetingKey = "coach_greeting_morning"
            case .afternoon: greetingKey = "coach_greeting_afternoon"
            case .evening: greetingKey = "coach_greeting_evening"
            case .night: greetingKey = "coach_greeting_night"
            }
            return ZenCoachResponse(
                text: CoachStrings.text(greetingKey) + " " + CoachStrings.text("coach_greeting_followup"),
                intent: .general, sentiment: .positive, kind: .greeting
            )
        }

        // Thanks
        if words.count <= 5,
           !Set(words).isDisjoint(with: Self.thanksWords)
            || normalized.contains("sag ol") || normalized.contains("thank you") {
            return ZenCoachResponse(
                text: variant("coach_thanks", state: &state),
                intent: .general, sentiment: .positive, kind: .thanks
            )
        }

        return nil
    }

    // MARK: - Standard reply

    private func standardReply(
        intent: UserIntent,
        sentiment: MessageSentiment,
        context: CoachContext,
        state: inout CoachConversationState
    ) -> ZenCoachResponse {

        let action = suggestedAction(for: intent, context: context)

        // Opening, then the intent's body
        var firstParagraph = ""
        switch sentiment {
        case .negative:
            firstParagraph = variant("coach_open_negative", state: &state)
        case .positive:
            firstParagraph = variant("coach_open_positive", state: &state)
        case .neutral:
            firstParagraph = variant("coach_open_neutral", state: &state)
        }
        firstParagraph += " " + variant("coach_body_\(Self.bodyGroup(for: intent))", state: &state)

        var paragraphs = [firstParagraph]

        // A Zen quote now and then, but not when the user is struggling
        if sentiment != .negative, randomIndex(100) < quoteChance {
            paragraphs.append(variant("coach_quote", state: &state))
        }

        // At most one context line
        if let line = contextLine(intent: intent, sentiment: sentiment, context: context, action: action, state: &state) {
            paragraphs.append(line)
        }

        // Closing question that points at the button
        if let closing = closingKey(for: intent, action: action) {
            paragraphs.append(variant(closing, state: &state))
        }

        return ZenCoachResponse(
            text: paragraphs.joined(separator: "\n\n"),
            intent: intent,
            sentiment: sentiment,
            actionText: action?.text,
            actionURL: action?.url
        )
    }

    private static func bodyGroup(for intent: UserIntent) -> String {
        switch intent {
        case .progress: return "general" // progress never reaches here; kept total for safety
        default: return intent.rawValue
        }
    }

    // MARK: - Actions

    /// The button that best fits the intent and the user's situation
    func suggestedAction(for intent: UserIntent, context: CoachContext) -> CoachAction? {
        switch intent {
        case .stress:
            return breathingAction(preferred: context.bestExerciseType ?? (context.isPremium ? "sigh" : "box"), context: context)
        case .anger:
            return breathingAction(preferred: context.bestExerciseType ?? (context.isPremium ? "calming" : "box"), context: context)
        case .breathing:
            return breathingAction(preferred: context.bestExerciseType ?? "box", context: context)
        case .meditation:
            let preferred = context.isNewUser ? "box" : (context.isPremium ? "calming" : "box")
            return breathingAction(preferred: preferred, context: context)
        case .sleep:
            return CoachAction(text: CoachStrings.text("coach_action_sleep"), url: "zenflow://sleep")
        case .focus:
            return CoachAction(text: CoachStrings.text("coach_action_focus"), url: "zenflow://focus")
        case .motivation:
            // Not practiced yet today: a short session beats a look at the garden
            return context.practicedToday
                ? CoachAction(text: CoachStrings.text("coach_action_garden"), url: "zenflow://garden")
                : breathingAction(preferred: "box", context: context)
        case .gratitude:
            return CoachAction(text: CoachStrings.text("coach_action_gratitude"), url: "zenflow://dailyzen")
        case .progress:
            return CoachAction(text: CoachStrings.text("coach_action_report"), url: "zenflow://report")
        case .general:
            return nil
        }
    }

    private func breathingAction(preferred: String, context: CoachContext) -> CoachAction {
        // Never point a free user at an exercise behind the paywall
        let type = allowedExercise(preferred, context.isPremium)
        let name = exerciseName(type) ?? exerciseName("box") ?? "Box Breathing"
        return CoachAction(
            text: CoachStrings.format("coach_action_breathing", name),
            url: "zenflow://breathing?exercise=\(type)"
        )
    }

    private func closingKey(for intent: UserIntent, action: CoachAction?) -> String? {
        guard let action else { return nil }
        if action.url.hasPrefix("zenflow://breathing") { return "coach_close_breathing" }
        if action.url == "zenflow://sleep" { return "coach_close_sleep" }
        if action.url == "zenflow://focus" { return "coach_close_focus" }
        if action.url == "zenflow://garden" { return "coach_close_garden" }
        if action.url == "zenflow://dailyzen" { return "coach_close_gratitude" }
        if action.url == "zenflow://report" { return "coach_close_report" }
        return nil
    }

    // MARK: - Context line

    /// The single most relevant remark about the user's situation, if any
    private func contextLine(
        intent: UserIntent,
        sentiment: MessageSentiment,
        context: CoachContext,
        action: CoachAction?,
        state: inout CoachConversationState
    ) -> String? {

        let today = calendar.startOfDay(for: now())

        // 1. A gentle note when recent moods have been low (once a day)
        let lowMoodIntents: Set<UserIntent> = [.stress, .anger, .general, .meditation, .sleep]
        if context.recentMoodIsLow,
           sentiment == .negative || lowMoodIntents.contains(intent),
           state.lastLowMoodNoteDay != today {
            state.lastLowMoodNoteDay = today
            return CoachStrings.text("coach_ctx_low_mood")
        }

        // 2. Protect a streak
        let streakIntents: Set<UserIntent> = [.motivation, .general, .focus, .meditation]
        if context.streakAtRisk, streakIntents.contains(intent) {
            return CoachStrings.format("coach_ctx_streak_risk", context.currentStreak)
        }

        // 3. First session
        let newUserIntents: Set<UserIntent> = [.meditation, .general, .breathing, .motivation]
        if context.isNewUser, newUserIntents.contains(intent) {
            return CoachStrings.text("coach_ctx_first_time")
        }

        // 4. Weekly goal within reach
        if (1...2).contains(context.weeklyGoalDaysRemaining),
           context.activeDaysThisWeek > 0,
           intent == .motivation || intent == .general {
            return CoachStrings.format("coach_ctx_goal_close", context.weeklyGoalDaysRemaining)
        }

        // 5. What works best for this user
        let calmingIntents: Set<UserIntent> = [.stress, .anger, .breathing]
        if let name = context.bestExerciseName, calmingIntents.contains(intent) {
            return CoachStrings.format("coach_ctx_best_exercise", name)
        }

        // 6. Celebrate a streak milestone
        let milestones: Set<Int> = [3, 7, 14, 30, 60, 100]
        if milestones.contains(context.currentStreak), context.practicedToday,
           intent == .motivation || intent == .general || intent == .gratitude {
            return CoachStrings.format("coach_ctx_streak_celebrate", context.currentStreak)
        }

        // 7. Current focus length
        if intent == .focus {
            return CoachStrings.format("coach_ctx_focus_length", context.focusMinutes)
        }

        return nil
    }

    // MARK: - Progress

    private func progressReply(
        sentiment: MessageSentiment,
        context: CoachContext,
        state: inout CoachConversationState
    ) -> ZenCoachResponse {

        let report = reportProvider()
        var paragraphs: [String] = []

        if sentiment == .negative {
            paragraphs.append(variant("coach_open_negative", state: &state))
        }

        if report.isEmpty {
            paragraphs.append(CoachStrings.text("coach_progress_empty"))
            let action = breathingAction(preferred: "box", context: context)
            return ZenCoachResponse(
                text: paragraphs.joined(separator: "\n\n"),
                intent: .progress, sentiment: sentiment,
                actionText: action.text, actionURL: action.url, kind: .progress
            )
        }

        var lines = [
            CoachStrings.format(
                "coach_progress_summary",
                report.activeDays, report.goalDays, report.meditationMinutes, report.completedFocusSessions
            )
        ]
        if context.currentStreak > 0 {
            lines.append(CoachStrings.format("coach_progress_streak", context.currentStreak))
        }
        if let percent = report.minutesChangePercent, percent != 0 {
            let percentText = "%\(abs(percent))"
            lines.append(CoachStrings.format(percent > 0 ? "coach_progress_more" : "coach_progress_less", percentText))
        }
        if report.reachedGoal {
            lines.append(CoachStrings.text("coach_progress_goal_reached"))
        } else if let bestDay = report.bestDay {
            let dayName = bestDay.formatted(.dateTime.weekday(.wide))
            lines.append(CoachStrings.format("coach_progress_best_day", dayName, report.bestDayMinutes))
        }
        paragraphs.append(lines.joined(separator: " "))
        paragraphs.append(variant("coach_close_report", state: &state))

        return ZenCoachResponse(
            text: paragraphs.joined(separator: "\n\n"),
            intent: .progress, sentiment: sentiment,
            actionText: CoachStrings.text("coach_action_report"),
            actionURL: "zenflow://report",
            kind: .progress
        )
    }

    // MARK: - Suggested prompts

    /// Quick prompts that fit the moment: time of day, streak, newness
    static func suggestedPrompts(for context: CoachContext, limit: Int = 5) -> [CoachPromptID] {
        var result: [CoachPromptID] = []
        func add(_ prompt: CoachPromptID) {
            if !result.contains(prompt) { result.append(prompt) }
        }

        if context.isNewUser { add(.meditation) }
        if context.streakAtRisk { add(.streak) }

        switch context.period {
        case .morning:
            add(.motivation)
            add(.focus)
        case .afternoon:
            add(.focus)
            add(.tired)
        case .evening:
            add(.gratitude)
            add(.sleep)
        case .night:
            add(.sleep)
            add(.tired)
        }

        if context.totalSessions > 0 { add(.weekly) }
        if context.recentMoodIsLow { add(.tired) }

        // Fill up with the evergreens
        for prompt in [CoachPromptID.meditation, .tired, .focus, .sleep, .motivation, .anger] {
            add(prompt)
        }
        return Array(result.prefix(limit))
    }

    // MARK: - Variants

    /// A text of the group that differs from the last one used
    private func variant(_ group: String, state: inout CoachConversationState) -> String {
        let count = CoachStrings.variantCounts[group] ?? 1
        var index = randomIndex(count)
        if count > 1, state.lastVariants[group] == index {
            index = (index + 1) % count
        }
        state.lastVariants[group] = index
        return CoachStrings.text("\(group)_\(index)")
    }
}
