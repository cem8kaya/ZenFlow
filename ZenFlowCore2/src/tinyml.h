// ============================================================================
//  tinyml.h — the TinyML seam.
//
//  The default build classifies user state with a lightweight heuristic over
//  the DSP features (no model, no training). This is the single, localized
//  point where an Edge Impulse model drops in: build with
//  -D ZF_USE_EDGE_IMPULSE and implement classifyActivity() against
//  run_classifier() (skeleton in tinyml.cpp). Everything upstream/downstream
//  (sensors, UI) is unchanged by the swap.
// ============================================================================
#pragma once

namespace zf { namespace ml {

enum class Activity : int { Unknown = -1, Still = 0, Breathing = 1, Moving = 2 };

// Features handed to the classifier (already computed by the DSP layer).
struct Features {
    float stillness;          // 0..100
    float breathingRateBpm;   // 0 = none
    float breathAmp;          // respiratory band amplitude (rad)
    float loudness01;         // 0..1 ambient level
};

const char* activityName(Activity a);

// Classify current state. Default: heuristic. With ZF_USE_EDGE_IMPULSE: model.
Activity classifyActivity(const Features& f);

}} // namespace zf::ml
