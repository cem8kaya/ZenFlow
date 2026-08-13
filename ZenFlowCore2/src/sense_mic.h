// ============================================================================
//  sense_mic.h — SPM1423 acoustic cues DSP (hardware-independent).
//
//  Feed a block of int16 PCM samples (from the SPM1423 PDM mic) and read back
//  an approximate loudness (dBFS), a 0..1 level for meters, and an onset flag
//  (transient / acoustic anomaly) from short- vs long-term energy. No training
//  required. The mic capture itself lives in sense.cpp.
// ============================================================================
#pragma once
#include <stdint.h>
#include <stddef.h>

namespace zf {

class MicAcoustic {
public:
    void reset();
    void update(const int16_t* buf, size_t n);

    float loudnessDb() const { return _db; }     // approx dBFS (-90..0)
    float level01()    const { return _level; }   // 0..1 for a VU meter
    bool  onset()      const { return _onset; }    // transient detected this block

private:
    static constexpr float kShortAlpha = 0.50f;
    static constexpr float kLongAlpha  = 0.02f;
    static constexpr float kOnsetRatio = 3.0f;
    static constexpr float kOnsetFloorDb = -45.0f;

    bool  _init  = false;
    float _eShort = 0, _eLong = 0;
    float _db = -90.0f, _level = 0.0f;
    bool  _onset = false;
};

} // namespace zf
