// ============================================================================
//  screen_focus.cpp — Pomodoro focus timer. Port of FocusTimerView.
//
//  Big countdown + progress arc; the 10-LED bar doubles as a session-count
//  ring (n of 4 before a long break). Vibrates on work/break transitions.
// ============================================================================
#include "ui.h"
#include "content.h"
#include "store.h"
#include "hw.h"
#include "sense.h"

namespace zf { namespace ui {

static lv_obj_t*  f_arc      = nullptr;
static lv_obj_t*  f_timeLbl  = nullptr;
static lv_obj_t*  f_stateLbl = nullptr;
static lv_obj_t*  f_btnLbl   = nullptr;
static lv_obj_t*  f_stillLbl = nullptr;   // BMI270 stillness during focus
static lv_timer_t* f_timer   = nullptr;

static bool     f_running   = false;
static bool     f_isWork    = true;
static uint8_t  f_completed = 0;          // work sessions completed in this cycle
static int32_t  f_remaining = POMODORO_WORK_MIN * 60;
static int32_t  f_total     = POMODORO_WORK_MIN * 60;

static void renderTime() {
    char buf[8];
    snprintf(buf, sizeof(buf), "%02d:%02d", f_remaining / 60, f_remaining % 60);
    lv_label_set_text(f_timeLbl, buf);
    int pct = f_total ? (int)(100 - (f_remaining * 100) / f_total) : 0;
    lv_arc_set_value(f_arc, pct);
    hw::ledsProgress(f_completed % (POMODORO_SESSIONS_BEFORE_LONG_BREAK + 1),
                     0x66, 0x9E, 0x30);
}

static void startPhase(bool work) {
    f_isWork    = work;
    f_total     = (work ? POMODORO_WORK_MIN
                        : ((f_completed % POMODORO_SESSIONS_BEFORE_LONG_BREAK == 0)
                               ? POMODORO_LONG_BREAK_MIN : POMODORO_SHORT_BREAK_MIN)) * 60;
    f_remaining = f_total;
    lv_label_set_text(f_stateLbl, work ? "Odaklan" : "Mola");
    renderTime();
}

static void focusTick(lv_timer_t*) {
    // Stillness feedback updates once per second, running or not.
    if (f_stillLbl) {
        SenseState st = SenseManager::snapshot();
        if (st.imuAvailable) {
            char b[24];
            snprintf(b, sizeof(b), "Sabitlik %d%%", (int)(st.stillness + 0.5f));
            lv_label_set_text(f_stillLbl, b);
        }
    }

    if (!f_running) return;
    if (f_remaining > 0) {
        f_remaining--;
        renderTime();
        return;
    }
    // phase complete
    hw::vibrate(400, 220);
    if (f_isWork) {
        f_completed++;
        Store::recordPomodoro();
        Store::recordSession(POMODORO_WORK_MIN); // count focus time as mindful minutes
        startPhase(false);
    } else {
        startPhase(true);
    }
}

static void toggleCb(lv_event_t*) {
    f_running = !f_running;
    lv_label_set_text(f_btnLbl, f_running ? "Duraklat" : "Başlat");
}

void buildFocus(lv_obj_t* parent) {
    lv_obj_set_style_bg_color(parent, color::bg(), 0);
    lv_obj_clear_flag(parent, LV_OBJ_FLAG_SCROLLABLE);

    f_stateLbl = lv_label_create(parent);
    lv_label_set_text(f_stateLbl, "Odaklan");
    lv_obj_set_style_text_color(f_stateLbl, color::muted(), 0);
    lv_obj_align(f_stateLbl, LV_ALIGN_TOP_MID, 0, 6);

    f_stillLbl = lv_label_create(parent);
    lv_label_set_text(f_stillLbl, "Sabitlik --%");
    lv_obj_set_style_text_color(f_stillLbl, color::muted(), 0);
    lv_obj_align(f_stillLbl, LV_ALIGN_TOP_RIGHT, -6, 6);

    f_arc = lv_arc_create(parent);
    lv_obj_set_size(f_arc, 180, 180);
    lv_arc_set_rotation(f_arc, 270);
    lv_arc_set_bg_angles(f_arc, 0, 360);
    lv_arc_set_range(f_arc, 0, 100);
    lv_arc_set_value(f_arc, 0);
    lv_obj_remove_style(f_arc, nullptr, LV_PART_KNOB);
    lv_obj_clear_flag(f_arc, LV_OBJ_FLAG_CLICKABLE);
    lv_obj_set_style_arc_color(f_arc, color::accent2(), LV_PART_INDICATOR);
    lv_obj_set_style_arc_color(f_arc, color::card(), LV_PART_MAIN);
    lv_obj_align(f_arc, LV_ALIGN_CENTER, 0, -6);

    f_timeLbl = lv_label_create(parent);
    lv_obj_set_style_text_font(f_timeLbl, &lv_font_montserrat_48, 0);
    lv_obj_set_style_text_color(f_timeLbl, color::text(), 0);
    lv_obj_align(f_timeLbl, LV_ALIGN_CENTER, 0, -6);

    lv_obj_t* btn = lv_btn_create(parent);
    lv_obj_set_size(btn, 140, 44);
    lv_obj_align(btn, LV_ALIGN_BOTTOM_MID, 0, -8);
    lv_obj_set_style_bg_color(btn, color::accent(), 0);
    lv_obj_add_event_cb(btn, toggleCb, LV_EVENT_CLICKED, nullptr);
    f_btnLbl = lv_label_create(btn);
    lv_label_set_text(f_btnLbl, "Başlat");
    lv_obj_center(f_btnLbl);

    startPhase(true);
    f_timer = lv_timer_create(focusTick, 1000, nullptr);
}

}} // namespace zf::ui
