// ============================================================================
//  store.h — on-device persistence (ESP32 NVS via Preferences).
//
//  Replaces the iOS LocalDataManager / UserDefaults. Fully offline: mindful
//  minutes, streaks and session counts live in flash, never leave the device.
// ============================================================================
#pragma once
#include <Arduino.h>

namespace zf {

struct Stats {
    uint32_t totalMinutes  = 0;
    uint32_t totalSessions = 0;
    uint16_t currentStreak = 0;
    uint16_t longestStreak = 0;
    uint16_t pomodoroSessions = 0;
    uint32_t lastSessionDay = 0; // days since epoch, for streak logic
};

class Store {
public:
    static void  begin();
    static Stats load();
    static void  save(const Stats& s);

    // Convenience: record a completed mindful session of `minutes`.
    static void  recordSession(uint16_t minutes);
    static void  recordPomodoro();

    // Selected breathing exercise index (index into zf::BREATHING).
    static uint8_t selectedBreathingIndex();
    static void    setSelectedBreathingIndex(uint8_t idx);
};

} // namespace zf
