// ============================================================================
//  hw.h — thin hardware wrappers so UI code never touches raw peripherals.
//
//  Maps ZenFlow's iOS embodiment (CoreHaptics) onto Core2 hardware:
//    HapticManager  -> vibration motor (AXP192)
//    (new)          -> 10x SK6812 side LEDs as a breathing / progress light bar
// ============================================================================
#pragma once
#include <Arduino.h>

// -- SK6812 side LED bar -----------------------------------------------------
//  NOTE: confirm the data GPIO against the M5Stack Core2 for AWS schematic
//  before relying on the LEDs. Left as a build-time override.
#ifndef ZF_LED_PIN
#define ZF_LED_PIN 25          // TODO: verify (Core2-for-AWS SK6812 data line)
#endif
#ifndef ZF_LED_COUNT
#define ZF_LED_COUNT 10
#endif

namespace zf { namespace hw {

void begin();

// Haptics -------------------------------------------------------------------
void vibrate(uint16_t ms, uint8_t strength = 200); // strength 0..255
void vibrateStop();

// LED bar -------------------------------------------------------------------
void ledsFill(uint8_t r, uint8_t g, uint8_t b);
void ledsBreath(uint8_t r, uint8_t g, uint8_t b, float phase01); // brightness by 0..1
void ledsProgress(uint8_t litCount, uint8_t r, uint8_t g, uint8_t b); // n of 10 lit
void ledsClear();

// Called from loop() so time-based effects (fades) can advance.
void tick();

}} // namespace zf::hw
