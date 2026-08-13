// ============================================================================
//  sense_mic.cpp
// ============================================================================
#include "sense_mic.h"
#include <math.h>

namespace zf {

static inline float clampf(float v, float lo, float hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

void MicAcoustic::reset() {
    _init = false;
    _eShort = _eLong = 0;
    _db = -90.0f; _level = 0.0f; _onset = false;
}

void MicAcoustic::update(const int16_t* buf, size_t n) {
    if (!buf || n == 0) return;

    double sum = 0.0;
    for (size_t i = 0; i < n; ++i) {
        const float s = (float)buf[i];
        sum += (double)s * s;
    }
    const float rms = sqrtf((float)(sum / (double)n));
    _db    = 20.0f * log10f(rms / 32768.0f + 1e-6f);
    _level = clampf((_db + 60.0f) / 60.0f, 0.0f, 1.0f); // -60..0 dB → 0..1

    const float e = rms * rms;
    if (!_init) { _eShort = _eLong = e; _init = true; }
    _eShort += kShortAlpha * (e - _eShort);
    _eLong  += kLongAlpha  * (e - _eLong);

    _onset = (_eShort > _eLong * kOnsetRatio) && (_db > kOnsetFloorDb);
}

} // namespace zf
