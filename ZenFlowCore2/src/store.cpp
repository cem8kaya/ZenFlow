// ============================================================================
//  store.cpp
// ============================================================================
#include "store.h"
#include <Preferences.h>

namespace zf {

static Preferences prefs;
static const char* NS = "zenflow";

void Store::begin() {
    prefs.begin(NS, false);
}

Stats Store::load() {
    Stats s;
    s.totalMinutes     = prefs.getUInt("min", 0);
    s.totalSessions    = prefs.getUInt("ses", 0);
    s.currentStreak    = prefs.getUShort("streak", 0);
    s.longestStreak    = prefs.getUShort("lstreak", 0);
    s.pomodoroSessions = prefs.getUShort("pomo", 0);
    s.lastSessionDay   = prefs.getUInt("lastday", 0);
    return s;
}

void Store::save(const Stats& s) {
    prefs.putUInt("min", s.totalMinutes);
    prefs.putUInt("ses", s.totalSessions);
    prefs.putUShort("streak", s.currentStreak);
    prefs.putUShort("lstreak", s.longestStreak);
    prefs.putUShort("pomo", s.pomodoroSessions);
    prefs.putUInt("lastday", s.lastSessionDay);
}

static uint32_t todayIndex() {
    // Days since boot epoch. With no RTC sync (offline), this uses time(nullptr)
    // if set, else a coarse millis-based day counter. Replace with BM8563 RTC read.
    time_t now = time(nullptr);
    if (now > 100000) return (uint32_t)(now / 86400);
    return (uint32_t)(millis() / 86400000UL);
}

void Store::recordSession(uint16_t minutes) {
    Stats s = load();
    s.totalMinutes  += minutes;
    s.totalSessions += 1;

    uint32_t today = todayIndex();
    if (s.lastSessionDay == 0) {
        s.currentStreak = 1;
    } else if (today == s.lastSessionDay) {
        // same day, streak unchanged
    } else if (today == s.lastSessionDay + 1) {
        s.currentStreak += 1;
    } else {
        s.currentStreak = 1;
    }
    if (s.currentStreak > s.longestStreak) s.longestStreak = s.currentStreak;
    s.lastSessionDay = today;
    save(s);
}

void Store::recordPomodoro() {
    Stats s = load();
    s.pomodoroSessions += 1;
    save(s);
}

uint8_t Store::selectedBreathingIndex() {
    return (uint8_t)prefs.getUChar("brx", 0);
}

void Store::setSelectedBreathingIndex(uint8_t idx) {
    prefs.putUChar("brx", idx);
}

} // namespace zf
