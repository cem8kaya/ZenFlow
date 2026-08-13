// ============================================================================
//  coach_engine.cpp
// ============================================================================
#include "coach_engine.h"

namespace zf {

// Turkish-aware lowercasing is imperfect on 8-bit; we lowercase ASCII and rely
// on the keyword tables already containing lowercase Turkish forms. Matching is
// substring-based, exactly like IntentClassifier.classifyIntent.
static String toLowerAscii(const String& in) {
    String out = in;
    out.toLowerCase();
    return out;
}

Intent CoachEngine::classifyIntent(const String& text) {
    String t = toLowerAscii(text);
    t.trim();

    // Primary: keyword matching in declared intent order (General has none).
    for (size_t i = 0; i < INTENT_COUNT; ++i) {
        const IntentDef& def = INTENTS[i];
        for (size_t k = 0; k < def.keywordCount; ++k) {
            if (t.indexOf(def.keywords[k]) >= 0) {
                return def.intent;
            }
        }
    }
    return Intent::General;
}

Sentiment CoachEngine::analyzeSentiment(const String& text) {
    static const char* POS[] = {"iyi","güzel","mutlu","harika","huzur","sakin","teşekkür","seviyorum",
                                "good","great","happy","calm","peace","love","thanks","better"};
    static const char* NEG[] = {"kötü","üzgün","stres","kaygı","yorgun","sinirli","panik","korku","bunalım","zor",
                                "bad","sad","stress","anxiety","tired","angry","panic","fear","hard","overwhelmed"};
    String t = toLowerAscii(text);
    int pos = 0, neg = 0;
    for (auto w : POS) if (t.indexOf(w) >= 0) ++pos;
    for (auto w : NEG) if (t.indexOf(w) >= 0) ++neg;
    if (pos > neg) return Sentiment::Positive;
    if (neg > pos) return Sentiment::Negative;
    return Sentiment::Neutral;
}

static const IntentDef& defFor(Intent intent) {
    for (size_t i = 0; i < INTENT_COUNT; ++i)
        if (INTENTS[i].intent == intent) return INTENTS[i];
    return INTENTS[INTENT_COUNT - 1]; // General
}

static String actionLabelFor(Intent intent) {
    switch (intent) {
        case Intent::Stress:
        case Intent::Breathing:  return "Nefes Egzersizi Başlat";
        case Intent::Focus:      return "Pomodoro Başlat";
        case Intent::Sleep:      return "4-7-8 Tekniği";
        case Intent::Motivation: return "Zen Bahçeni Gör";
        case Intent::Meditation: return "Meditasyon Öğren";
        case Intent::Progress:   return "İlerlemeni Gör";
        default:                 return "";
    }
}

CoachReply CoachEngine::respond(const String& text) {
    CoachReply r;
    r.intent    = classifyIntent(text);
    r.sentiment = analyzeSentiment(text);

    // ResponseGenerator: empathetic opening + (usually) a Zen quote.
    const char* opening = EMPATHETIC_OPENINGS[random(EMPATHETIC_OPENINGS_COUNT)];
    r.text = String(opening);
    if (random(10) > 3) { // ~60% of the time append a quote (mirrors shouldAddQuote)
        r.text += "\n\n";
        r.text += ZEN_QUOTES[random(ZEN_QUOTES_COUNT)];
    }

    const IntentDef& def = defFor(r.intent);
    r.actionLabel  = actionLabelFor(r.intent);
    r.actionTarget = def.actionTarget;
    return r;
}

} // namespace zf
