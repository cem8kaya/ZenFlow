// ============================================================================
//  coach_engine.h — Offline Zen Coach.
//
//  Port of IntentClassifier + ResponseGenerator (the iOS "Zen Coach" is NOT an
//  LLM — it is a keyword classifier + template response builder, so it runs
//  fully on-device with no cloud). Apple's NaturalLanguage sentiment is
//  replaced with a lightweight keyword heuristic.
// ============================================================================
#pragma once
#include <Arduino.h>
#include "content.h"

namespace zf {

enum class Sentiment : uint8_t { Positive, Neutral, Negative };

struct CoachReply {
    String text;          // full response (opening + optional quote)
    Intent intent;
    Sentiment sentiment;
    String actionLabel;   // "" if none
    String actionTarget;  // screen id, e.g. "breathing:box"
};

class CoachEngine {
public:
    // Classify the user's free text into an intent (keyword match).
    static Intent classifyIntent(const String& text);

    // Very small sentiment heuristic (positive/negative keyword counting).
    static Sentiment analyzeSentiment(const String& text);

    // Build a full coach reply for the given text.
    static CoachReply respond(const String& text);
};

} // namespace zf
