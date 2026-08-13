// ============================================================================
//  screen_settings.cpp — stats + breathing selection + about. Port of SettingsView.
//
//  Offline stats summary (LocalDataManager equivalent) plus the breathing
//  exercise picker (BreathingExerciseManager). Reminder/theme/premium panes
//  from the iOS app are intentionally out of scope for the offline device.
// ============================================================================
#include "ui.h"
#include "content.h"
#include "store.h"

namespace zf { namespace ui {

static lv_obj_t* s_statsLbl = nullptr;
static lv_obj_t* s_roller   = nullptr;

static void refreshStats() {
    Stats s = Store::load();
    char buf[128];
    snprintf(buf, sizeof(buf),
             "Toplam: %lu dk\nSeans: %lu\nSeri: %u gün (en iyi %u)\nPomodoro: %u",
             (unsigned long)s.totalMinutes, (unsigned long)s.totalSessions,
             s.currentStreak, s.longestStreak, s.pomodoroSessions);
    lv_label_set_text(s_statsLbl, buf);
}

static void rollerCb(lv_event_t* e) {
    lv_obj_t* roller = lv_event_get_target(e);
    uint16_t idx = lv_roller_get_selected(roller);
    Store::setSelectedBreathingIndex((uint8_t)idx);
}

void buildSettings(lv_obj_t* parent) {
    lv_obj_set_style_bg_color(parent, color::bg(), 0);
    lv_obj_set_flex_flow(parent, LV_FLEX_FLOW_COLUMN);
    lv_obj_set_flex_align(parent, LV_FLEX_ALIGN_START, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);
    lv_obj_set_style_pad_all(parent, 10, 0);
    lv_obj_set_style_pad_row(parent, 8, 0);

    lv_obj_t* title = lv_label_create(parent);
    lv_label_set_text(title, "İstatistik");
    lv_obj_set_style_text_font(title, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(title, color::text(), 0);

    s_statsLbl = lv_label_create(parent);
    lv_obj_set_style_text_color(s_statsLbl, color::muted(), 0);
    refreshStats();

    lv_obj_t* pick = lv_label_create(parent);
    lv_label_set_text(pick, "Nefes Egzersizi");
    lv_obj_set_style_text_color(pick, color::text(), 0);

    // Build roller options from the ported breathing list.
    String opts;
    for (size_t i = 0; i < BREATHING_COUNT; ++i) {
        opts += BREATHING[i].nameTr;
        if (i + 1 < BREATHING_COUNT) opts += "\n";
    }
    s_roller = lv_roller_create(parent);
    lv_roller_set_options(s_roller, opts.c_str(), LV_ROLLER_MODE_NORMAL);
    lv_roller_set_visible_row_count(s_roller, 3);
    lv_roller_set_selected(s_roller, Store::selectedBreathingIndex(), LV_ANIM_OFF);
    lv_obj_set_style_bg_color(s_roller, color::card(), 0);
    lv_obj_set_style_text_color(s_roller, color::text(), 0);
    lv_obj_add_event_cb(s_roller, rollerCb, LV_EVENT_VALUE_CHANGED, nullptr);
}

}} // namespace zf::ui
