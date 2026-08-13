// ============================================================================
//  content.h — ZenFlow domain content, ported from the iOS app (offline).
//
//  Source of truth mirrored from:
//    ZenFlow/Models/BreathingExercise.swift  (breathing patterns)
//    ZenFlow/Models/UserIntent.swift          (intents + keywords)
//    ZenFlow/Models/Constants.swift           (tree stages, badges, pomodoro)
//    ZenFlow/Managers/ResponseGenerator.swift (openings + quotes)
//
//  All content is compiled into flash. No network/cloud is used.
// ============================================================================
#pragma once
#include <stdint.h>
#include <stddef.h>

namespace zf {

// ---------------------------------------------------------------------------
//  Breathing
// ---------------------------------------------------------------------------
enum class Phase : uint8_t { Inhale, Hold, Exhale, HoldAfterExhale };

struct BreathingPhase {
    Phase   type;
    uint8_t durationSec;
};

struct BreathingExercise {
    const char*          key;            // "box", "478", "calming", "energy", "deep"
    const char*          nameTr;
    const char*          nameEn;
    const BreathingPhase* phases;
    uint8_t              phaseCount;
    uint8_t              recommendedMin;
};

// Matches BreathingExercise.allExercises (durations in seconds).
extern const BreathingExercise BREATHING[];
extern const size_t            BREATHING_COUNT;

// ---------------------------------------------------------------------------
//  Zen Coach — intents (mirrors UserIntent.swift)
// ---------------------------------------------------------------------------
enum class Intent : uint8_t {
    Stress, Focus, Sleep, Breathing, Motivation, Meditation, Progress, General
};

struct IntentDef {
    Intent       intent;
    const char*  displayNameTr;
    const char** keywords;      // lowercase, TR + EN
    size_t       keywordCount;
    const char*  actionTarget;  // in-app screen id the action button jumps to
};

extern const IntentDef INTENTS[];
extern const size_t     INTENT_COUNT;

// ---------------------------------------------------------------------------
//  Coach response building blocks (mirrors ResponseGenerator.swift)
// ---------------------------------------------------------------------------
extern const char* EMPATHETIC_OPENINGS[];
extern const size_t EMPATHETIC_OPENINGS_COUNT;

extern const char* ZEN_QUOTES[];
extern const size_t ZEN_QUOTES_COUNT;

// ---------------------------------------------------------------------------
//  Zen Garden — tree growth stages (minutes thresholds, Constants.TreeGrowth)
// ---------------------------------------------------------------------------
struct TreeStage {
    const char* nameTr;
    uint16_t    minMinutes;   // accumulated mindful minutes to reach this stage
};
extern const TreeStage TREE_STAGES[];
extern const size_t     TREE_STAGE_COUNT;

// ---------------------------------------------------------------------------
//  Gamification — badges (Constants.Badges / Pomodoro)
// ---------------------------------------------------------------------------
enum class BadgeMetric : uint8_t { Minutes, StreakDays, PomodoroSessions };

struct BadgeDef {
    const char* id;
    const char* nameTr;
    BadgeMetric metric;
    uint16_t    threshold;
};
extern const BadgeDef BADGES[];
extern const size_t    BADGE_COUNT;

// Pomodoro timing (Constants.Pomodoro)
constexpr int POMODORO_WORK_MIN        = 25;
constexpr int POMODORO_SHORT_BREAK_MIN = 5;
constexpr int POMODORO_LONG_BREAK_MIN  = 15;
constexpr int POMODORO_SESSIONS_BEFORE_LONG_BREAK = 4;

} // namespace zf
