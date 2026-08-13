// ============================================================================
//  sense_imu.h — BMI270 breathing + stillness DSP (hardware-independent).
//
//  Pure signal processing: feed raw accel (g) + gyro (deg/s) samples and read
//  back an estimated breathing rate, breath phase, respiratory amplitude and a
//  stillness score. No M5/Arduino dependency here so the math is unit-testable
//  on a host; the actual BMI270 reads happen in sense.cpp.
//
//  Method (no training required):
//    * Track gravity with a slow per-axis low-pass.
//    * Respiratory signal = angle between instantaneous accel and gravity,
//      band-passed to 0.1–0.6 Hz (≈6–36 breaths/min). This captures the small
//      chest/abdomen tilt oscillation of breathing regardless of orientation.
//    * Breathing rate = interval between rising zero-crossings (EMA-smoothed).
//    * Phase sign = derivative of the band-passed signal (rising = inhale).
//    * Stillness = EMA of gyro magnitude + linear-accel deviation, mapped 0..100.
//
//  Works best when the device shares the breathing motion (rested on the chest/
//  abdomen, or held against it). Stillness works in any pose.
// ============================================================================
#pragma once
#include <math.h>

namespace zf {

class ImuBreath {
public:
    void reset();

    // One IMU sample. dt seconds; accel in g; gyro in deg/s.
    void update(float ax, float ay, float az,
                float gx, float gy, float gz, float dt);

    float breathingRateBpm() const { return _bpm; }     // 0 = not enough signal
    float phaseSigned()      const { return _phase; }    // -1..+1 (+ = inhaling)
    float amplitude()        const { return _amp; }      // respiratory band amplitude (rad)
    float stillness()        const { return _stillness; }// 0..100
    bool  breathingDetected() const { return _amp > kAmpThreshold && _bpm > 0.0f; }

private:
    static constexpr float kGravityFc = 0.05f; // Hz — gravity tracker
    static constexpr float kFastFc    = 0.60f; // Hz — band-pass upper
    static constexpr float kSlowFc    = 0.10f; // Hz — band-pass lower
    static constexpr float kAmpThreshold = 0.004f; // rad (~0.23°) min breath tilt
    static constexpr float kStillScale   = 6.0f;   // deg/s e-fold for stillness

    static float lpAlpha(float fc, float dt) {
        const float rc = 1.0f / (2.0f * (float)M_PI * fc);
        return dt / (rc + dt);
    }

    bool  _init = false;
    float _grX = 0, _grY = 0, _grZ = 1;   // gravity estimate
    float _lpFast = 0, _lpSlow = 0;       // band-pass low-passes
    float _bpPrev = 0;
    float _ampEma = 0;
    float _timeSinceCross = 0;
    int   _lastSign = 0;

    float _bpm = 0, _phase = 0, _amp = 0;
    float _motionEma = 0, _stillness = 0;
};

} // namespace zf
