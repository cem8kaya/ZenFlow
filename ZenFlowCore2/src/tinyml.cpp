// ============================================================================
//  tinyml.cpp — heuristic classifier (default) + Edge Impulse drop-in skeleton.
// ============================================================================
#include "tinyml.h"

namespace zf { namespace ml {

const char* activityName(Activity a) {
    switch (a) {
        case Activity::Still:     return "Sabit";
        case Activity::Breathing: return "Nefes";
        case Activity::Moving:    return "Hareket";
        default:                  return "—";
    }
}

#if !defined(ZF_USE_EDGE_IMPULSE)

// ---------------------------------------------------------------------------
//  Default heuristic. Good enough to drive UI feedback; replace with an Edge
//  Impulse model when you have labelled IMU/audio data.
// ---------------------------------------------------------------------------
Activity classifyActivity(const Features& f) {
    if (f.stillness > 75.0f && f.breathingRateBpm >= 4.0f && f.breathAmp > 0.004f)
        return Activity::Breathing;
    if (f.stillness > 85.0f)
        return Activity::Still;
    if (f.stillness < 55.0f)
        return Activity::Moving;
    return Activity::Unknown;
}

#else

// ---------------------------------------------------------------------------
//  Edge Impulse integration skeleton.
//
//  1. Train a model at https://studio.edgeimpulse.com (IMU window + optional
//     audio MFCC) with classes Still / Breathing / Moving.
//  2. Export as an Arduino library and add it to lib_deps in platformio.ini.
//  3. Build with -D ZF_USE_EDGE_IMPULSE. Map the DSP Features (or, better, a
//     raw sample window) into the classifier signal below.
//
//  This block is intentionally compiled only when the EI SDK is present.
// ---------------------------------------------------------------------------
#include "edge-impulse-sdk/classifier/ei_run_classifier.h"

Activity classifyActivity(const Features& f) {
    // Minimal example feeding the 4 scalar features. For real accuracy, feed a
    // raw accel window instead and match EI_CLASSIFIER_RAW_SAMPLE_COUNT.
    float features[] = { f.stillness, f.breathingRateBpm, f.breathAmp, f.loudness01 };

    signal_t signal;
    numpy::signal_from_buffer(features, sizeof(features) / sizeof(features[0]), &signal);

    ei_impulse_result_t result = { 0 };
    if (run_classifier(&signal, &result, false) != EI_IMPULSE_OK)
        return Activity::Unknown;

    int best = -1; float bestScore = 0.0f;
    for (size_t i = 0; i < EI_CLASSIFIER_LABEL_COUNT; ++i) {
        if (result.classification[i].value > bestScore) {
            bestScore = result.classification[i].value;
            best = (int)i;
        }
    }
    // Assumes label order Still=0, Breathing=1, Moving=2 from the studio project.
    if (best < 0 || bestScore < 0.6f) return Activity::Unknown;
    return (Activity)best;
}

#endif // ZF_USE_EDGE_IMPULSE

}} // namespace zf::ml
