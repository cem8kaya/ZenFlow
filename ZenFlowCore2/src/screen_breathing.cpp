// ============================================================================
//  screen_breathing.cpp — flagship module.
//
//  Animated breathing circle synced to the selected pattern, with the phase
//  driving BOTH the vibration motor and the SK6812 LED bar — the embodied
//  experience the phone cannot give. Port of BreathingView.
// ============================================================================
#include "ui.h"
#include "content.h"
#include "store.h"
#include "hw.h"

namespace zf { namespace ui {

// --- Breathing state machine -----------------------------------------------
static const BreathingExercise* s_ex = nullptr;
static uint8_t  s_phaseIdx  = 0;
static uint32_t s_phaseStart = 0;
static bool     s_running    = false;

static lv_obj_t* s_circle    = nullptr;
static lv_obj_t* s_phaseLbl  = nullptr;
static lv_obj_t* s_titleLbl  = nullptr;
static lv_obj_t* s_startBtn  = nullptr;
static lv_obj_t* s_startLbl  = nullptr;
static lv_timer_t* s_timer   = nullptr;

static const uint16_t CIRCLE_MIN = 90;
static const uint16_t CIRCLE_MAX = 200;

static const char* phaseText(Phase p) {
    switch (p) {
        case Phase::Inhale:          return "Nefes Al";
        case Phase::Hold:            return "Tut";
        case Phase::Exhale:          return "Nefes Ver";
        case Phase::HoldAfterExhale: return "Tut";
    }
    return "";
}

// Target size at the END of a phase (inhale/hold expanded, exhale contracted).
static float phaseTargetScale(Phase p) {
    switch (p) {
        case Phase::Inhale:          return 1.0f; // grow to max
        case Phase::Hold:            return 1.0f; // stay expanded
        case Phase::Exhale:          return 0.0f; // shrink to min
        case Phase::HoldAfterExhale: return 0.0f; // stay contracted
    }
    return 0.0f;
}
static float phaseStartScale(Phase p) {
    switch (p) {
        case Phase::Inhale:          return 0.0f;
        case Phase::Hold:            return 1.0f;
        case Phase::Exhale:          return 1.0f;
        case Phase::HoldAfterExhale: return 0.0f;
    }
    return 0.0f;
}

static void applyScale(float scale01) {
    uint16_t size = (uint16_t)(CIRCLE_MIN + (CIRCLE_MAX - CIRCLE_MIN) * scale01);
    lv_obj_set_size(s_circle, size, size);
    lv_obj_set_style_radius(s_circle, LV_RADIUS_CIRCLE, 0);
    hw::ledsBreath(0x1E, 0x88, 0xC7, scale01); // cyan glow follows the breath
}

static void enterPhase(uint8_t idx) {
    s_phaseIdx   = idx;
    s_phaseStart = millis();
    Phase p = s_ex->phases[idx].type;
    lv_label_set_text(s_phaseLbl, phaseText(p));
    if (p == Phase::Inhale) hw::vibrate(140, 180); // gentle cue at each inhale
}

static void breathingTick(lv_timer_t*) {
    if (!s_running || !s_ex) return;
    const BreathingPhase& ph = s_ex->phases[s_phaseIdx];
    uint32_t elapsed = millis() - s_phaseStart;
    uint32_t dur     = (uint32_t)ph.durationSec * 1000UL;
    float t = dur ? (float)elapsed / (float)dur : 1.0f;
    if (t > 1.0f) t = 1.0f;

    float from = phaseStartScale(ph.type);
    float to   = phaseTargetScale(ph.type);
    applyScale(from + (to - from) * t);

    if (elapsed >= dur) {
        uint8_t next = (s_phaseIdx + 1) % s_ex->phaseCount;
        enterPhase(next);
    }
}

static void toggleRun() {
    s_running = !s_running;
    if (s_running) {
        s_ex = &BREATHING[Store::selectedBreathingIndex() % BREATHING_COUNT];
        lv_label_set_text(s_titleLbl, s_ex->nameTr);
        enterPhase(0);
        lv_label_set_text(s_startLbl, "Durdur");
    } else {
        lv_label_set_text(s_startLbl, "Başlat");
        lv_label_set_text(s_phaseLbl, "Hazır");
        hw::ledsClear();
        applyScale(0.0f);
    }
}

static void startBtnCb(lv_event_t*) { toggleRun(); }

void buildBreathing(lv_obj_t* parent) {
    lv_obj_set_style_bg_color(parent, color::bg(), 0);
    lv_obj_clear_flag(parent, LV_OBJ_FLAG_SCROLLABLE);

    s_ex = &BREATHING[Store::selectedBreathingIndex() % BREATHING_COUNT];

    s_titleLbl = lv_label_create(parent);
    lv_label_set_text(s_titleLbl, s_ex->nameTr);
    lv_obj_set_style_text_color(s_titleLbl, color::text(), 0);
    lv_obj_align(s_titleLbl, LV_ALIGN_TOP_MID, 0, 6);

    // Breathing circle.
    s_circle = lv_obj_create(parent);
    lv_obj_set_size(s_circle, CIRCLE_MIN, CIRCLE_MIN);
    lv_obj_set_style_radius(s_circle, LV_RADIUS_CIRCLE, 0);
    lv_obj_set_style_bg_color(s_circle, color::accent(), 0);
    lv_obj_set_style_bg_opa(s_circle, LV_OPA_60, 0);
    lv_obj_set_style_border_width(s_circle, 2, 0);
    lv_obj_set_style_border_color(s_circle, color::accent(), 0);
    lv_obj_clear_flag(s_circle, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_align(s_circle, LV_ALIGN_CENTER, 0, -6);

    s_phaseLbl = lv_label_create(parent);
    lv_label_set_text(s_phaseLbl, "Hazır");
    lv_obj_set_style_text_font(s_phaseLbl, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(s_phaseLbl, color::text(), 0);
    lv_obj_align(s_phaseLbl, LV_ALIGN_CENTER, 0, -6);

    s_startBtn = lv_btn_create(parent);
    lv_obj_set_size(s_startBtn, 140, 44);
    lv_obj_align(s_startBtn, LV_ALIGN_BOTTOM_MID, 0, -8);
    lv_obj_set_style_bg_color(s_startBtn, color::accent2(), 0);
    lv_obj_add_event_cb(s_startBtn, startBtnCb, LV_EVENT_CLICKED, nullptr);
    s_startLbl = lv_label_create(s_startBtn);
    lv_label_set_text(s_startLbl, "Başlat");
    lv_obj_center(s_startLbl);

    s_timer = lv_timer_create(breathingTick, 33, nullptr); // ~30fps
}

}} // namespace zf::ui
