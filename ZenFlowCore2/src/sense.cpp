// ============================================================================
//  sense.cpp
// ============================================================================
#include "sense.h"
#include "sense_imu.h"
#include "sense_mic.h"

#include <Arduino.h>
#include <lvgl.h>
#include <M5Unified.h>
#include <math.h>

namespace zf {

// --- module state (single writer: the lv_timer callbacks) ------------------
static SenseState  g_state;
static ImuBreath   g_imu;
static MicAcoustic g_mic;

static bool     g_micEnabled = true;
static uint32_t g_lastImuMicros = 0;

static bool     g_guidedActive = false;
static float    g_guidedSigned = 0.0f;
static float    g_coherenceEma = 0.0f;

// SPM1423 capture block: 256 samples @ 16 kHz ≈ 16 ms.
static constexpr uint32_t kMicRate   = 16000;
static constexpr size_t   kMicBlock  = 256;
static int16_t  g_micBuf[kMicBlock];

static inline int signf(float v) { return v > 0 ? 1 : (v < 0 ? -1 : 0); }

// ---------------------------------------------------------------------------
static void imuTimerCb(lv_timer_t*) {
    if (!g_state.imuAvailable) return;

    float ax, ay, az, gx, gy, gz;
    if (!M5.Imu.getAccel(&ax, &ay, &az)) return;
    if (!M5.Imu.getGyro(&gx, &gy, &gz)) { gx = gy = gz = 0.0f; }

    const uint32_t now = micros();
    float dt = g_lastImuMicros ? (now - g_lastImuMicros) * 1e-6f : 0.02f;
    g_lastImuMicros = now;

    g_imu.update(ax, ay, az, gx, gy, gz, dt);

    g_state.breathingRateBpm  = g_imu.breathingRateBpm();
    g_state.breathPhase       = g_imu.phaseSigned();
    g_state.breathAmp         = g_imu.amplitude();
    g_state.stillness         = g_imu.stillness();
    g_state.breathingDetected = g_imu.breathingDetected();

    // Coherence vs the guided pace (only while a session is guiding).
    if (g_guidedActive && fabsf(g_guidedSigned) > 0.1f && g_imu.breathingDetected()) {
        const float match = (signf(g_state.breathPhase) == signf(g_guidedSigned)) ? 100.0f : 0.0f;
        g_coherenceEma += 0.05f * (match - g_coherenceEma);
    } else if (!g_guidedActive) {
        g_coherenceEma += 0.02f * (0.0f - g_coherenceEma); // relax toward 0
    }
    g_state.coherence = g_coherenceEma;

    // TinyML seam.
    ml::Features f{ g_state.stillness, g_state.breathingRateBpm,
                    g_state.breathAmp, g_state.level01 };
    g_state.activity = ml::classifyActivity(f);

    g_state.updatedAtMs = millis();
}

// ---------------------------------------------------------------------------
static void micTimerCb(lv_timer_t*) {
    if (!g_state.micAvailable || !g_micEnabled) return;

    if (!M5.Mic.record(g_micBuf, kMicBlock, kMicRate)) return;
    // Bounded wait for the async DMA capture to finish (~16 ms).
    uint32_t guard = 0;
    while (M5.Mic.isRecording() && guard++ < 60) delay(1);

    g_mic.update(g_micBuf, kMicBlock);
    g_state.loudnessDb    = g_mic.loudnessDb();
    g_state.level01       = g_mic.level01();
    g_state.acousticOnset = g_mic.onset();
}

// ---------------------------------------------------------------------------
void SenseManager::begin(bool enableMic) {
    g_imu.reset();
    g_mic.reset();

    // IMU (BMI270). M5.begin() usually starts it; begin() again is idempotent.
    g_state.imuAvailable = M5.Imu.begin();

    // Mic (SPM1423, PDM/I2S). NOTE: mic and speaker share I2S on Core2 — only
    // one may be active. Speaker playback (Phase 4) must call setMicEnabled(false).
    g_micEnabled = enableMic;
    if (enableMic) {
        auto cfg = M5.Mic.config();
        cfg.sample_rate = kMicRate;
        M5.Mic.config(cfg);
        g_state.micAvailable = M5.Mic.begin();
    }

    lv_timer_create(imuTimerCb, 20, nullptr);   // ~50 Hz IMU sampling
    lv_timer_create(micTimerCb, 500, nullptr);  // 2 Hz acoustic blocks
}

SenseState SenseManager::snapshot() { return g_state; }

void SenseManager::setGuidedPhase(float guidedSigned, bool active) {
    g_guidedSigned = guidedSigned;
    g_guidedActive = active;
}

void SenseManager::setMicEnabled(bool on) {
    g_micEnabled = on;
    if (!on && g_state.micAvailable) M5.Mic.end();
    else if (on && !M5.Mic.isEnabled()) g_state.micAvailable = M5.Mic.begin();
}

} // namespace zf
