// ============================================================================
//  sense_imu.cpp
// ============================================================================
#include "sense_imu.h"

namespace zf {

static inline float clampf(float v, float lo, float hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

void ImuBreath::reset() {
    _init = false;
    _grX = 0; _grY = 0; _grZ = 1;
    _lpFast = _lpSlow = _bpPrev = _ampEma = 0;
    _timeSinceCross = 0; _lastSign = 0;
    _bpm = _phase = _amp = 0;
    _motionEma = _stillness = 0;
}

void ImuBreath::update(float ax, float ay, float az,
                       float gx, float gy, float gz, float dt) {
    if (dt <= 0.0f || dt > 0.5f) dt = 0.02f; // guard against jitter/first sample

    if (!_init) { _grX = ax; _grY = ay; _grZ = az; _init = true; }

    // --- gravity tracker (slow LP) ---
    const float ga = lpAlpha(kGravityFc, dt);
    _grX += ga * (ax - _grX);
    _grY += ga * (ay - _grY);
    _grZ += ga * (az - _grZ);

    // --- respiratory signal: angle between accel and gravity estimate ---
    const float dot = ax * _grX + ay * _grY + az * _grZ;
    const float na  = sqrtf(ax * ax + ay * ay + az * az) + 1e-6f;
    const float ng  = sqrtf(_grX * _grX + _grY * _grY + _grZ * _grZ) + 1e-6f;
    const float angle = acosf(clampf(dot / (na * ng), -1.0f, 1.0f)); // radians

    // --- band-pass (fast LP - slow LP) ---
    _lpFast += lpAlpha(kFastFc, dt) * (angle - _lpFast);
    _lpSlow += lpAlpha(kSlowFc, dt) * (angle - _lpSlow);
    const float bp = _lpFast - _lpSlow;

    // --- amplitude envelope ---
    _ampEma += 0.05f * (fabsf(bp) - _ampEma);
    _amp = _ampEma;

    // --- phase from derivative (rising = inhale) ---
    const float deriv = bp - _bpPrev;
    _phase = clampf(deriv / (dt + 1e-6f) * 4.0f, -1.0f, 1.0f);

    // --- rate from rising zero-crossings ---
    const int sign = (bp > 0) ? 1 : (bp < 0 ? -1 : 0);
    _timeSinceCross += dt;
    if (_lastSign <= 0 && sign > 0 && _amp > kAmpThreshold) {
        const float period = _timeSinceCross;      // full cycle between rising crossings
        if (period > 1.5f && period < 15.0f) {      // 4..40 bpm plausibility gate
            const float bpm = 60.0f / period;
            _bpm = (_bpm <= 0.0f) ? bpm : _bpm + 0.3f * (bpm - _bpm);
        }
        _timeSinceCross = 0;
    }
    if (sign != 0) _lastSign = sign;
    _bpPrev = bp;

    // drop the estimate if breathing motion has been absent for a while
    if (_amp < kAmpThreshold && _timeSinceCross > 12.0f) _bpm = 0.0f;

    // --- stillness ---
    const float gyroMag = sqrtf(gx * gx + gy * gy + gz * gz); // deg/s
    const float linAcc  = fabsf(na - ng);                     // g deviation from gravity
    const float motion  = gyroMag + 200.0f * linAcc;
    _motionEma += 0.1f * (motion - _motionEma);
    _stillness = 100.0f * expf(-_motionEma / kStillScale);
}

} // namespace zf
