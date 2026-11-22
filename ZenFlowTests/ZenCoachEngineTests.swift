//
//  ZenCoachEngineTests.swift
//  ZenFlowTests
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Tests for the Zen Coach: intent scoring, safety handling, small talk,
//  context-aware actions and lines, progress answers and suggested prompts.
//  Assertions use structure (action URLs, reply kinds, expected strings built
//  from the same keys), so they hold in Turkish and English alike.
//

import XCTest
@testable import ZenFlow

// MARK: - Strings

final class CoachStringsTests: XCTestCase {

    /// A missing key would show up in the chat as raw "coach_..." text
    func testEveryCoachStringExists() {
        for key in CoachStrings.allKeys {
            let value = CoachStrings.text(key)
            XCTAssertNotEqual(value, key, "Missing string for \(key)")
            XCTAssertFalse(value.isEmpty, "Empty string for \(key)")
        }
    }

    func testFormatStringsTakeTheirArguments() {
        XCTAssertTrue(CoachStrings.format("coach_ctx_streak_risk", 5).contains("5"))
        XCTAssertTrue(CoachStrings.format("coach_ctx_goal_close", 2).contains("2"))
        XCTAssertTrue(CoachStrings.format("coach_ctx_best_exercise", "Box").contains("Box"))
        XCTAssertTrue(CoachStrings.format("coach_action_breathing", "Box").contains("Box"))
        XCTAssertTrue(CoachStrings.format("coach_progress_summary", 3, 5, 42, 2).contains("42"))
    }

    func testCrisisTextGivesRealResources() {
        let text = CoachStrings.text("coach_crisis")
        XCTAssertTrue(text.contains("112"))
        XCTAssertTrue(text.contains("988"))
        XCTAssertTrue(text.contains("findahelpline.com"))
    }
}

// MARK: - Intent scoring

final class CoachIntentScorerTests: XCTestCase {

    func testNormalizationFoldsCaseDiacriticsAndDotlessI() {
        XCTAssertEqual(CoachIntentScorer.normalize("İŞ"), "is")
        XCTAssertEqual(CoachIntentScorer.normalize("Uyuyamıyorum"), "uyuyamiyorum")
        XCTAssertEqual(CoachIntentScorer.normalize("KAYGILANIYORUM"), "kaygilaniyorum")
        XCTAssertEqual(CoachIntentScorer.normalize("Çağrı, Öğün, Şeker"), "cagri, ogun, seker")
    }

    func testIntentsFromRealSentences() {
        let cases: [(String, UserIntent)] = [
            ("Gece rahat uyuyamıyorum", .sleep),
            ("UYUYAMIYORUM", .sleep),
            ("uyuyamiyorum", .sleep),
            ("I can't sleep well at night", .sleep),
            ("Çok stresli hissediyorum", .stress),
            ("Kaygılarımı nasıl kontrol ederim?", .stress),
            ("Zihinsel olarak yorgunum, yardım et", .stress),
            ("I'm so stressed and nervous", .stress),
            ("Odaklanmamı nasıl artırabilirim?", .focus),
            ("I can't concentrate", .focus),
            ("Çok sinirliyim", .anger),
            ("I'm really angry", .anger),
            ("Bu hafta nasıl gidiyorum?", .progress),
            ("How am I doing this week?", .progress),
            ("Serimi nasıl korurum?", .progress),
            ("Bugün için minnettarım", .gratitude),
            ("I'm grateful for today", .gratitude),
            ("Bugün için motivasyon lazım", .motivation),
            ("Meditasyona nasıl başlarım?", .meditation),
            ("How do I start meditating?", .meditation),
            ("Nefes egzersizi göster", .breathing)
        ]
        for (text, expected) in cases {
            XCTAssertEqual(CoachIntentScorer.bestIntent(for: text), expected, "“\(text)”")
        }
    }

    func testWholeWordMatchingAvoidsSubstringFalsePositives() {
        // Plain substring matching used to hit "rest" inside "interesting" and "iş" inside "is"
        XCTAssertNil(CoachIntentScorer.bestIntent(for: "That is an interesting question"))
        XCTAssertNil(CoachIntentScorer.bestIntent(for: "xyz qwerty"))
    }

    func testNoMatchWithoutKeywords() {
        XCTAssertTrue(CoachIntentScorer.scores(for: "").isEmpty)
        XCTAssertNil(CoachIntentScorer.bestIntent(for: "   "))
    }

    func testEveryPromptIsClassifiedAsIntended() {
        let expected: [CoachPromptID: UserIntent] = [
            .meditation: .meditation, .tired: .stress, .focus: .focus, .sleep: .sleep,
            .motivation: .motivation, .weekly: .progress, .streak: .progress,
            .gratitude: .gratitude, .anger: .anger
        ]
        for prompt in CoachPromptID.allCases {
            let cleaned = ZenCoachManager.cleanPrompt(prompt.text)
            XCTAssertEqual(CoachIntentScorer.bestIntent(for: cleaned), expected[prompt], "Prompt \(prompt.rawValue): “\(cleaned)”")
        }
    }
}

// MARK: - Engine

final class ZenCoachEngineTests: XCTestCase {

    private var state = CoachConversationState()

    /// Deterministic engine: last variant, never a quote
    private func makeEngine(report: WeeklyReport? = nil) -> ZenCoachEngine {
        var engine = ZenCoachEngine()
        engine.randomIndex = { count in count - 1 }
        if let report {
            engine.reportProvider = { report }
        }
        return engine
    }

    private func reply(_ text: String, context: CoachContext = .baseline, engine: ZenCoachEngine? = nil) -> ZenCoachResponse {
        (engine ?? makeEngine()).reply(to: text, context: context, state: &state)
    }

    private func context(_ change: (inout CoachContext) -> Void) -> CoachContext {
        var context = CoachContext.baseline
        change(&context)
        return context
    }

    // MARK: Safety

    func testSelfHarmGetsTheCrisisReplyAndNothingElse() {
        let messages = [
            "Kendime zarar vermek istiyorum",
            "İNTİHAR etmeyi düşünüyorum",
            "yaşamak istemiyorum artık",
            "I want to kill myself",
            "I don't want to live anymore",
            "I don’t want to live anymore", // typographic apostrophe
            "thinking about suicide"
        ]
        for message in messages {
            let response = reply(message)
            XCTAssertEqual(response.kind, .crisis, "“\(message)”")
            XCTAssertTrue(response.isCrisis)
            XCTAssertEqual(response.text, CoachStrings.text("coach_crisis"))
            XCTAssertNil(response.actionURL, "No exercise button after a crisis message")
            XCTAssertNil(response.actionText)
        }
    }

    func testCrisisClearsAPendingSuggestion() {
        state.lastActionText = "Start"
        state.lastActionURL = "zenflow://focus"
        _ = reply("I want to end my life")
        XCTAssertNil(state.lastAction)
    }

    func testOrdinaryStressIsNotACrisis() {
        XCTAssertNotEqual(reply("Çok stresli hissediyorum").kind, .crisis)
        XCTAssertNotEqual(reply("I'm dying to know how to meditate").kind, .crisis)
    }

    // MARK: Small talk

    func testGreetingFollowsTheTimeOfDay() {
        let periods: [(CoachContext.TimePeriod, String)] = [
            (.morning, "coach_greeting_morning"), (.afternoon, "coach_greeting_afternoon"),
            (.evening, "coach_greeting_evening"), (.night, "coach_greeting_night")
        ]
        for (period, key) in periods {
            let response = reply("Merhaba", context: context { $0.period = period })
            XCTAssertEqual(response.kind, .greeting)
            XCTAssertTrue(response.text.contains(CoachStrings.text(key)), "\(period)")
            XCTAssertNil(response.actionURL)
        }
        XCTAssertEqual(reply("hello").kind, .greeting)
    }

    func testThanksAreAnswered() {
        XCTAssertEqual(reply("Teşekkürler").kind, .thanks)
        XCTAssertEqual(reply("thanks a lot").kind, .thanks)
        XCTAssertEqual(reply("sağ ol").kind, .thanks)
    }

    func testYesRepeatsTheLastSuggestionAndNoClearsIt() {
        state.lastActionText = "Open Sleep Mode"
        state.lastActionURL = "zenflow://sleep"

        let yes = reply("evet")
        XCTAssertEqual(yes.kind, .followUp)
        XCTAssertEqual(yes.actionURL, "zenflow://sleep")
        XCTAssertEqual(yes.actionText, "Open Sleep Mode")

        let no = reply("şimdi değil")
        XCTAssertEqual(no.kind, .followUp)
        XCTAssertNil(no.actionURL)
        XCTAssertNil(state.lastAction, "A declined suggestion is forgotten")
    }

    func testBareYesWithoutASuggestionAsksWhereToStart() {
        let response = reply("tamam")
        XCTAssertEqual(response.kind, .followUp)
        XCTAssertEqual(response.text, CoachStrings.text("coach_followup_yes_noaction"))
    }

    func testLongMessagesAreNeverTreatedAsYesOrNo() {
        state.lastActionText = "Start"
        state.lastActionURL = "zenflow://focus"
        let response = reply("evet ama önce uyku konusunda yardım istiyorum çünkü uyuyamıyorum")
        XCTAssertEqual(response.kind, .standard)
        XCTAssertEqual(response.intent, .sleep)
    }

    // MARK: Actions

    func testSleepOpensSleepMode() {
        let response = reply("Uyuyamıyorum")
        XCTAssertEqual(response.intent, .sleep)
        XCTAssertEqual(response.actionURL, "zenflow://sleep")
        XCTAssertEqual(response.actionText, CoachStrings.text("coach_action_sleep"))
    }

    func testStressUsesBoxForFreeUsersAndSighForPremium() {
        XCTAssertEqual(reply("Çok stresliyim", context: context { $0.isPremium = false }).actionURL,
                       "zenflow://breathing?exercise=box")
        XCTAssertEqual(reply("Çok stresliyim", context: context { $0.isPremium = true }).actionURL,
                       "zenflow://breathing?exercise=sigh")
    }

    func testAngerUsesBoxForFreeUsersAndCalmingForPremium() {
        XCTAssertEqual(reply("Çok sinirliyim", context: context { $0.isPremium = false }).actionURL,
                       "zenflow://breathing?exercise=box")
        XCTAssertEqual(reply("Çok sinirliyim", context: context { $0.isPremium = true }).actionURL,
                       "zenflow://breathing?exercise=calming")
    }

    func testTheUsersBestExerciseIsPreferredWhenAccessible() {
        let response = reply("Çok stresliyim", context: context {
            $0.isPremium = true
            $0.bestExerciseType = "478"
            $0.bestExerciseName = "4-7-8"
        })
        XCTAssertEqual(response.actionURL, "zenflow://breathing?exercise=478")
        XCTAssertTrue(response.text.contains(CoachStrings.format("coach_ctx_best_exercise", "4-7-8")))
    }

    func testAPremiumExerciseIsNeverSuggestedToAFreeUser() {
        // Even if stale data says the best exercise is premium
        let response = reply("Çok stresliyim", context: context {
            $0.isPremium = false
            $0.bestExerciseType = "478"
        })
        XCTAssertEqual(response.actionURL, "zenflow://breathing?exercise=box")
    }

    func testFocusMentionsTheConfiguredLength() {
        let response = reply("Odaklanamıyorum", context: context { $0.focusMinutes = 50 })
        XCTAssertEqual(response.actionURL, "zenflow://focus")
        XCTAssertTrue(response.text.contains(CoachStrings.format("coach_ctx_focus_length", 50)))
    }

    func testMotivationDependsOnTodaysPractice() {
        XCTAssertEqual(reply("Motivasyon lazım", context: context { $0.practicedToday = false }).actionURL,
                       "zenflow://breathing?exercise=box")
        XCTAssertEqual(reply("Motivasyon lazım", context: context { $0.practicedToday = true }).actionURL,
                       "zenflow://garden")
    }

    func testGratitudeOpensTheDailyZenMoment() {
        XCTAssertEqual(reply("Bugün için minnettarım").actionURL, "zenflow://dailyzen")
    }

    func testGeneralChatHasNoButton() {
        let response = reply("xyz qwerty")
        XCTAssertEqual(response.intent, .general)
        XCTAssertNil(response.actionURL)
    }

    func testReplyNeverContainsRawKeys() {
        for message in ["Çok stresliyim", "Uyuyamıyorum", "Odaklanamıyorum", "Motivasyon lazım", "Bu hafta nasıl gidiyorum?", "xyz"] {
            XCTAssertFalse(reply(message).text.contains("coach_"), "“\(message)”")
        }
    }

    // MARK: Context lines

    func testLowMoodNoteAppearsOncePerDay() {
        let low = context {
            $0.recentMoodAverage = 1.8
            $0.recentMoodCount = 4
        }
        let note = CoachStrings.text("coach_ctx_low_mood")

        XCTAssertTrue(reply("Çok stresliyim", context: low).text.contains(note))
        XCTAssertFalse(reply("Çok stresliyim", context: low).text.contains(note), "Not repeated on the same day")
    }

    func testNoLowMoodNoteWithTooFewCheckIns() {
        let few = context {
            $0.recentMoodAverage = 1.5
            $0.recentMoodCount = 2
        }
        XCTAssertFalse(reply("Çok stresliyim", context: few).text.contains(CoachStrings.text("coach_ctx_low_mood")))
    }

    func testStreakAtRiskReminder() {
        let atRisk = context {
            $0.currentStreak = 5
            $0.practicedToday = false
        }
        XCTAssertTrue(reply("Motivasyon lazım", context: atRisk).text.contains(CoachStrings.format("coach_ctx_streak_risk", 5)))

        let safe = context {
            $0.currentStreak = 5
            $0.practicedToday = true
        }
        XCTAssertFalse(reply("Motivasyon lazım", context: safe).text.contains(CoachStrings.format("coach_ctx_streak_risk", 5)))
    }

    func testFirstSessionHintForNewUsers() {
        let newUser = context { $0.totalSessions = 0 }
        XCTAssertTrue(reply("Meditasyona nasıl başlarım?", context: newUser).text.contains(CoachStrings.text("coach_ctx_first_time")))
    }

    func testOnlyOneContextLineIsShown() {
        // Low mood, streak at risk and a new-user hint all apply; only the most important shows
        let crowded = context {
            $0.recentMoodAverage = 1.5
            $0.recentMoodCount = 5
            $0.currentStreak = 4
            $0.totalSessions = 0
        }
        // Meditation questions qualify for all three lines
        let text = reply("Meditasyona nasıl başlarım?", context: crowded).text
        XCTAssertTrue(text.contains(CoachStrings.text("coach_ctx_low_mood")))
        XCTAssertFalse(text.contains(CoachStrings.format("coach_ctx_streak_risk", 4)))
        XCTAssertFalse(text.contains(CoachStrings.text("coach_ctx_first_time")))
    }

    func testReplyVariantsDoNotRepeat() {
        var engine = ZenCoachEngine()
        engine.randomIndex = { _ in 0 } // would always pick variant 0 (and a quote)
        let first = engine.reply(to: "Çok stresliyim", context: .baseline, state: &state)
        let second = engine.reply(to: "Çok stresliyim", context: .baseline, state: &state)
        XCTAssertNotEqual(first.text, second.text)
    }

    // MARK: Progress

    private func report(sessions: [(daysAgo: Int, minutes: Int)]) -> WeeklyReport {
        let calendar = Calendar.current
        let data = sessions.map {
            LocalDataManager.SessionData(
                date: calendar.date(byAdding: .day, value: -$0.daysAgo, to: Date())!,
                durationMinutes: $0.minutes
            )
        }
        return WeeklyReport.make(
            weekContaining: Date(),
            sessions: data,
            focusSessions: [],
            moods: [],
            goalDays: 5
        )
    }

    func testProgressAnswerUsesRealNumbers() {
        // Sessions today count in the current week whatever weekday it is
        let weekly = report(sessions: [(0, 12), (0, 8)])
        let response = reply("Bu hafta nasıl gidiyorum?", engine: makeEngine(report: weekly))

        XCTAssertEqual(response.kind, .progress)
        XCTAssertEqual(response.actionURL, "zenflow://report")
        XCTAssertTrue(response.text.contains("20"), "Total minutes should appear")
        XCTAssertTrue(response.text.contains(CoachStrings.format("coach_progress_summary", 1, 5, 20, 0)))
    }

    func testProgressWithNoSessionsEncouragesAFirstBreath() {
        let response = reply("İlerlemem nasıl?", engine: makeEngine(report: report(sessions: [])))
        XCTAssertEqual(response.kind, .progress)
        XCTAssertTrue(response.text.contains(CoachStrings.text("coach_progress_empty")))
        XCTAssertEqual(response.actionURL, "zenflow://breathing?exercise=box")
    }

    func testProgressMentionsTheStreak() {
        let weekly = report(sessions: [(0, 10)])
        let response = reply("Serim nasıl?", context: context { $0.currentStreak = 6 }, engine: makeEngine(report: weekly))
        XCTAssertTrue(response.text.contains(CoachStrings.format("coach_progress_streak", 6)))
    }

    // MARK: Suggested prompts

    func testSuggestedPromptsAreUniqueAndLimited() {
        for period in [CoachContext.TimePeriod.morning, .afternoon, .evening, .night] {
            let prompts = ZenCoachEngine.suggestedPrompts(for: context { $0.period = period })
            XCTAssertEqual(prompts.count, 5)
            XCTAssertEqual(Set(prompts).count, prompts.count)
        }
        XCTAssertEqual(ZenCoachEngine.suggestedPrompts(for: .baseline, limit: 3).count, 3)
    }

    func testSuggestedPromptsFitTheMoment() {
        XCTAssertEqual(ZenCoachEngine.suggestedPrompts(for: context { $0.totalSessions = 0 }).first, .meditation)
        XCTAssertTrue(ZenCoachEngine.suggestedPrompts(for: context { $0.period = .night }).contains(.sleep))
        XCTAssertTrue(ZenCoachEngine.suggestedPrompts(for: context { $0.period = .morning }).contains(.motivation))
        XCTAssertTrue(ZenCoachEngine.suggestedPrompts(for: context { $0.currentStreak = 4; $0.practicedToday = false }).contains(.streak))
        XCTAssertFalse(ZenCoachEngine.suggestedPrompts(for: context { $0.totalSessions = 0 }).contains(.weekly))
    }

    func testCleanPromptRemovesLeadingEmoji() {
        XCTAssertEqual(ZenCoachManager.cleanPrompt("😴 Gece rahat uyuyamıyorum"), "Gece rahat uyuyamıyorum")
        XCTAssertEqual(ZenCoachManager.cleanPrompt("🔥 Serimi nasıl korurum?"), "Serimi nasıl korurum?")
        XCTAssertEqual(ZenCoachManager.cleanPrompt("Plain text"), "Plain text")
    }
}

// MARK: - Context

final class CoachContextTests: XCTestCase {

    func testTimePeriodBoundaries() {
        XCTAssertEqual(CoachContext.TimePeriod(hour: 4), .night)
        XCTAssertEqual(CoachContext.TimePeriod(hour: 5), .morning)
        XCTAssertEqual(CoachContext.TimePeriod(hour: 11), .morning)
        XCTAssertEqual(CoachContext.TimePeriod(hour: 12), .afternoon)
        XCTAssertEqual(CoachContext.TimePeriod(hour: 16), .afternoon)
        XCTAssertEqual(CoachContext.TimePeriod(hour: 17), .evening)
        XCTAssertEqual(CoachContext.TimePeriod(hour: 21), .evening)
        XCTAssertEqual(CoachContext.TimePeriod(hour: 22), .night)
        XCTAssertEqual(CoachContext.TimePeriod(hour: 0), .night)
    }

    func testDerivedFlags() {
        var context = CoachContext.baseline
        context.currentStreak = 3
        context.practicedToday = false
        XCTAssertTrue(context.streakAtRisk)
        context.practicedToday = true
        XCTAssertFalse(context.streakAtRisk)

        context.recentMoodAverage = 2.4
        context.recentMoodCount = 3
        XCTAssertTrue(context.recentMoodIsLow)
        context.recentMoodAverage = 2.5
        XCTAssertFalse(context.recentMoodIsLow)

        context.weeklyGoalDays = 5
        context.activeDaysThisWeek = 7
        XCTAssertEqual(context.weeklyGoalDaysRemaining, 0)
    }

    func testLiveContextCanBeBuilt() {
        let context = CoachContext.current()
        XCTAssertGreaterThanOrEqual(context.weeklyGoalDays, 1)
        XCTAssertGreaterThan(context.focusMinutes, 0)
    }
}

// MARK: - Legacy history and deep links

final class ZenCoachMessageTests: XCTestCase {

    func testMessagesSavedBeforeActionsExistedStillDecode() throws {
        let json = """
        [{"id":"7B3C1E55-2F7A-4C57-9F1D-0A4F5B9E1C11","text":"Merhaba","isUser":false,"timestamp":700000000,"intent":"stress","sentiment":"neutral"}]
        """
        let messages = try JSONDecoder().decode([ZenCoachMessage].self, from: Data(json.utf8))
        XCTAssertEqual(messages.first?.intent, .stress)
        XCTAssertNil(messages.first?.actionText)
        XCTAssertNil(messages.first?.actionURL)
    }

    func testResponseCarriesItsActionIntoTheMessage() {
        let response = ZenCoachResponse(text: "x", intent: .sleep, sentiment: .neutral, actionText: "Sleep", actionURL: "zenflow://sleep")
        let message = response.toChatMessage()
        XCTAssertEqual(message.actionText, "Sleep")
        XCTAssertEqual(message.actionURL, "zenflow://sleep")
        XCTAssertFalse(message.isUser)
    }

    func testReplacingTextKeepsTheRest() {
        let response = ZenCoachResponse(text: "a", intent: .focus, sentiment: .positive, actionText: "t", actionURL: "u", kind: .progress)
        let changed = response.replacingText("b")
        XCTAssertEqual(changed.text, "b")
        XCTAssertEqual(changed.intent, .focus)
        XCTAssertEqual(changed.actionURL, "u")
        XCTAssertEqual(changed.kind, .progress)
    }

    func testEveryIntentHasADeepLinkOrNone() {
        for intent in UserIntent.allCases {
            if let link = intent.deepLinkURL {
                XCTAssertTrue(link.hasPrefix("zenflow://"), "\(intent)")
            }
        }
        XCTAssertEqual(UserIntent.sleep.deepLinkURL, "zenflow://sleep")
        XCTAssertEqual(UserIntent.progress.deepLinkURL, "zenflow://report")
    }
}

final class OnDeviceCoachAssistantTests: XCTestCase {

    func testPromptCarriesTheUserMessageDraftAndButton() {
        let draft = ZenCoachResponse(
            text: "First paragraph\n\nSecond paragraph",
            intent: .sleep, sentiment: .neutral,
            actionText: "Open Sleep Mode", actionURL: "zenflow://sleep"
        )
        let prompt = OnDeviceCoachAssistant.makePrompt(userText: "I can't sleep", draft: draft)
        XCTAssertTrue(prompt.contains("I can't sleep"))
        XCTAssertTrue(prompt.contains("First paragraph Second paragraph"))
        XCTAssertTrue(prompt.contains("Open Sleep Mode"))
    }

    func testSafetyRulesAreInTheInstructions() {
        XCTAssertTrue(OnDeviceCoachAssistant.instructions.contains("never diagnose"))
        XCTAssertTrue(OnDeviceCoachAssistant.instructions.contains("self-harm"))
    }

    func testCleaningTrimsCapsAndRejectsEmpty() {
        XCTAssertNil(OnDeviceCoachAssistant.cleaned("   \n "))
        XCTAssertEqual(OnDeviceCoachAssistant.cleaned("  Hello there.  "), "Hello there.")

        let long = String(repeating: "Calm breath. ", count: 80)
        let cleaned = OnDeviceCoachAssistant.cleaned(long)
        XCTAssertNotNil(cleaned)
        XCTAssertLessThanOrEqual(cleaned!.count, OnDeviceCoachAssistant.maximumReplyLength)
        XCTAssertTrue(cleaned!.hasSuffix("."), "Cut at a sentence end")
    }

    func testInactiveWithoutTheBuildFlag() async {
        if !OnDeviceCoachAssistant.isCompiledIn {
            XCTAssertFalse(OnDeviceCoachAssistant.shared.isActive)
            let draft = ZenCoachResponse(text: "x", intent: .general, sentiment: .neutral)
            let rewritten = await OnDeviceCoachAssistant.shared.rewrite(userText: "hi", draft: draft)
            XCTAssertNil(rewritten)
        }
    }

    func testCrisisRepliesAreNeverRewritten() async {
        let crisis = ZenCoachResponse(text: "x", intent: .general, sentiment: .negative, kind: .crisis)
        let rewritten = await OnDeviceCoachAssistant.shared.rewrite(userText: "hi", draft: crisis)
        XCTAssertNil(rewritten)
    }
}
