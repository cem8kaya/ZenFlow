// ============================================================================
//  hw.cpp
// ============================================================================
#include "hw.h"
#include <M5Unified.h>
#include <Adafruit_NeoPixel.h>

namespace zf { namespace hw {

static Adafruit_NeoPixel g_leds(ZF_LED_COUNT, ZF_LED_PIN, NEO_GRB + NEO_KHZ800);
static uint32_t g_vibeStopAt = 0;

void begin() {
    g_leds.begin();
    g_leds.setBrightness(120);
    g_leds.clear();
    g_leds.show();
}

// --- Haptics ---------------------------------------------------------------
void vibrate(uint16_t ms, uint8_t strength) {
    // M5Unified maps this to the AXP192 vibration motor on Core2.
    // If your M5Unified version lacks setVibration(), drive AXP192 LDO3 directly.
    M5.Power.setVibration(strength);
    g_vibeStopAt = millis() + ms;
}

void vibrateStop() {
    M5.Power.setVibration(0);
    g_vibeStopAt = 0;
}

// --- LEDs ------------------------------------------------------------------
void ledsFill(uint8_t r, uint8_t g, uint8_t b) {
    for (int i = 0; i < ZF_LED_COUNT; ++i) g_leds.setPixelColor(i, g_leds.Color(r, g, b));
    g_leds.show();
}

void ledsBreath(uint8_t r, uint8_t g, uint8_t b, float phase01) {
    if (phase01 < 0) phase01 = 0;
    if (phase01 > 1) phase01 = 1;
    uint8_t br = (uint8_t)(20 + phase01 * 180); // never fully dark; gentle glow floor
    for (int i = 0; i < ZF_LED_COUNT; ++i) {
        g_leds.setPixelColor(i, g_leds.Color((r * br) / 255, (g * br) / 255, (b * br) / 255));
    }
    g_leds.show();
}

void ledsProgress(uint8_t litCount, uint8_t r, uint8_t g, uint8_t b) {
    for (int i = 0; i < ZF_LED_COUNT; ++i) {
        if (i < litCount) g_leds.setPixelColor(i, g_leds.Color(r, g, b));
        else              g_leds.setPixelColor(i, 0);
    }
    g_leds.show();
}

void ledsClear() {
    g_leds.clear();
    g_leds.show();
}

void tick() {
    if (g_vibeStopAt && millis() >= g_vibeStopAt) vibrateStop();
}

}} // namespace zf::hw
