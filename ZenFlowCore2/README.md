# ZenFlow Core2 (Edge Edition)

A fully **offline** port of the [ZenFlow](../ZenFlow) iOS mindfulness app to the
**M5Stack Core2 for AWS** (ESP32‑D0WDQ6‑V3, 16 MB flash, 8 MB PSRAM). No cloud,
no AWS backend — the breathing engine, focus timer, Zen garden, gamification and
the offline Zen Coach all run on‑device. Wi‑Fi/ATECC608/AWS IoT are intentionally
left unused in this build.

> This is a **separate development** that reuses ZenFlow's *content* and *domain
> logic* (which are platform‑independent), reimplements the UI in **LVGL**, and
> leans on the Core2 hardware for an embodied experience the phone cannot give
> (haptic + LED breathing pacing).

---

## Why this device fits ZenFlow

ZenFlow's core value is **breath/focus/mindfulness pacing + content (Zen quotes,
coach templates) + progress gamification**. Crucially, the iOS "Zen Coach AI" is
**not an LLM** — it is a keyword classifier (`IntentClassifier`) plus a template
response builder (`ResponseGenerator`). That means the coach runs *verbatim*
on‑device, so the "8 MB PSRAM can't host an SLM" constraint never bites: we chose
the **offline rule engine**, not a cloud LLM.

## Feature mapping (iOS → Core2, offline)

| ZenFlow feature | Core2 realization | Status here |
|---|---|---|
| Breathing exercises (box, 4‑7‑8, calming, energy, deep) | LVGL circle + **vibration** pacing + **10× SK6812** glow + phase labels | ✅ functional (`screen_breathing.cpp`) |
| Focus timer (Pomodoro 25/5/15) | Countdown + progress arc + LED session ring + haptic transitions | ✅ functional (`screen_focus.cpp`) |
| Zen Garden (tree growth by minutes) | Stage computed from accumulated minutes + progress bar | ✅ display (`screen_garden.cpp`), sprites = Phase 3 |
| Zen Coach (rule‑based) | On‑device intent classify + template reply, suggested‑prompt chips | ✅ functional offline (`coach_engine.*`, `screen_coach.cpp`) |
| Gamification (streaks, badges) | NVS persistence + badge thresholds | ✅ data + store; badge UI = Phase 3 |
| Stats / progress | NVS (`Store`) summary in Settings | ✅ functional (`screen_settings.cpp`) |
| Ambient sounds / Zen mixes | I²S WAV from SD, optional 2‑stream mix | ⏳ Phase 4 (`hw` audio stub) |
| Mindfulness bell / Daily Zen moment | Scheduled chime + LED + daily quote rotation | ⏳ Phase 4 |
| TR/EN localization | Content already dual‑language in `content.cpp` | ✅ TR seeded; EN table present |
| HealthKit | Apple‑only → replaced by on‑device session log | ➖ dropped by design |
| StoreKit / premium paywall | No commerce on device | ➖ dropped by design |
| Notifications / reminders | On‑device RTC (BM8563) reminder → screen/LED/vibration | ⏳ Phase 4 |

## Architecture (offline)

```
┌──────────────── M5Stack Core2 (no cloud) ────────────────┐
│  UI  : LVGL 8 · tabview (Koç · Nefes · Odak · Bahçe · Ayarlar)
│  HW  : vibration motor + 10× SK6812 LEDs + I²S speaker
│  Data: content.cpp (breathing/intents/quotes/tree/badges — ported 1:1)
│  Coach: coach_engine.cpp (IntentClassifier + ResponseGenerator port)
│  State: store.cpp (NVS/Preferences: minutes, streak, badges) — never leaves device
└──────────────────────────────────────────────────────────┘
                 M5Unified (Display/Touch/Power/Speaker)
```

### Source layout
```
ZenFlowCore2/
├── platformio.ini          # env: m5stack-core2, 16MB, PSRAM, LVGL+M5Unified+NeoPixel
├── partitions_16MB.csv
├── include/lv_conf.h        # LVGL config for 320×240 RGB565
└── src/
    ├── main.cpp             # M5Unified↔LVGL bridge + 5-tab assembly
    ├── content.{h,cpp}      # domain content ported from ZenFlow models
    ├── coach_engine.{h,cpp} # offline Zen Coach (classifier + generator)
    ├── store.{h,cpp}        # NVS persistence (stats/streaks/selection)
    ├── hw.{h,cpp}           # vibration + SK6812 LED wrappers
    ├── ui.h / ui_common.cpp # palette + screen-builder declarations
    └── screen_*.cpp         # coach / breathing / focus / garden / settings
```

### What was ported 1:1 (see comments citing the Swift source)
- Breathing patterns — `BreathingExercise.allExercises`
- Intents + TR/EN keywords — `UserIntent.keywords`
- Empathetic openings + Zen quotes — `ResponseGenerator`
- Tree stages (minute thresholds) — `Constants.TreeGrowth`
- Badges + Pomodoro timing — `Constants.Badges` / `Constants.Pomodoro`

## Build & flash

Requires [PlatformIO](https://platformio.org/) (CLI or VS Code extension).

```bash
cd ZenFlowCore2
pio run                 # build
pio run -t upload       # flash over USB (CP2104/USB-C)
pio device monitor      # 115200 baud serial
```

First build downloads the ESP32 toolchain + libraries; allow a few minutes.

## Hardware notes to verify before relying on peripherals

These are the two board‑specific values that must be confirmed against the
**Core2 for AWS** schematic (left as build‑time overrides so no code change is
needed):

- **SK6812 data pin** — `ZF_LED_PIN` in `hw.h` (default `25`, marked TODO).
  Set the correct GPIO via `-D ZF_LED_PIN=<n>` in `platformio.ini` if different.
- **Vibration API** — `hw.cpp` calls `M5.Power.setVibration()`. If your
  M5Unified version lacks it, drive the AXP192 vibration LDO directly in that
  one function.

## Roadmap (phases)

| Phase | Scope | State |
|---|---|---|
| 0 | Scaffold: PlatformIO + M5Unified + LVGL, 5‑tab nav, content/logic port | **done (this commit)** |
| 1 | Breathing: circle + haptic + LED pacing | **done** (polish: per‑phase LED color, session save) |
| 2 | Focus/Pomodoro + LED progress ring | **done** (polish: long‑break flow, sound) |
| 3 | Persistence + stats + streak + badges + tree **sprites** | store done; badge/garden art pending |
| 4 | Ambient sounds (I²S/SD mixer) + mindfulness bell + daily Zen moment | pending |
| 5 | Coach: wire action buttons → tab navigation; optional mic/IMU input | engine done; navigation pending |
| 6 | Onboarding + themes + settings (brightness, volume, reminders via RTC) | pending |
| 7 | TinyML: BMI270 breath/stillness + SPM1423 acoustic cues (Edge Impulse) | pending |

## Relationship to the iOS app

This lives beside the untouched `ZenFlow/` Xcode project. It is a **new,
independent codebase** — not a wrapper — that treats ZenFlow's content and
constants as the shared source of truth. When the app's breathing patterns,
quotes or thresholds change, update the mirrored tables in `src/content.cpp`
(a small export script can automate this later).
