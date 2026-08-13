// ============================================================================
//  sense.h — SenseManager: bridges BMI270 + SPM1423 to the DSP + TinyML layer.
//
//  Sampling runs as lv_timers on the main (LVGL) thread so all I2C sensor
//  access is serialized with M5.update() — no cross-core bus contention. The UI
//  reads a plain snapshot; there is a single writer, so no locking is needed.
// ============================================================================
#pragma once
#include <stdint.h>
#include "tinyml.h"

namespace zf {

struct SenseState {
    bool  imuAvailable = false;
    bool  micAvailable = false;

    // IMU / breathing
    float breathingRateBpm = 0.0f;  // 0 = not enough signal
    float breathPhase      = 0.0f;  // -1..+1 (+ = inhaling)
    float breathAmp        = 0.0f;  // respiratory band amplitude (rad)
    float stillness        = 0.0f;  // 0..100
    bool  breathingDetected = false;

    // Mic / acoustic
    float loudnessDb   = -90.0f;
    float level01      = 0.0f;      // 0..1 VU
    bool  acousticOnset = false;

    // Derived
    float coherence = 0.0f;         // 0..100 — how well breath follows the guide
    ml::Activity activity = ml::Activity::Unknown;

    uint32_t updatedAtMs = 0;
};

class SenseManager {
public:
    static void begin(bool enableMic = true);
    static SenseState snapshot();

    // Breathing screen feeds the guided target each frame so we can score how
    // well the user's detected breath follows it. guidedSigned: -1..+1 (+inhale).
    static void setGuidedPhase(float guidedSigned, bool active);

    static void setMicEnabled(bool on); // turn mic off when the speaker needs I2S
};

} // namespace zf
