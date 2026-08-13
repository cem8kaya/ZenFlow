// ============================================================================
//  screen_coach.cpp — offline Zen Coach. Port of ZenCoachView + Enhanced view.
//
//  The 2" screen has no comfortable keyboard, so input is via suggested-prompt
//  chips (SuggestedPromptsView) feeding the on-device CoachEngine. Fully
//  offline: intent classification + template response, no network.
// ============================================================================
#include "ui.h"
#include "content.h"
#include "coach_engine.h"

namespace zf { namespace ui {

static lv_obj_t* c_reply    = nullptr;
static lv_obj_t* c_actBtn   = nullptr;
static lv_obj_t* c_actLbl   = nullptr;

// Canned prompts mirror SuggestedPromptsView starter chips.
static const char* PROMPTS[] = {
    "Çok stresliyim",
    "Odaklanamıyorum",
    "Uyuyamıyorum",
    "Nefes egzersizi",
    "Motivasyona ihtiyacım var",
    "İlerlemem nasıl?",
};

static void promptCb(lv_event_t* e) {
    const char* prompt = (const char*)lv_event_get_user_data(e);
    CoachReply r = CoachEngine::respond(String(prompt));
    lv_label_set_text(c_reply, r.text.c_str());

    if (r.actionLabel.length() > 0) {
        lv_label_set_text(c_actLbl, r.actionLabel.c_str());
        lv_obj_clear_flag(c_actBtn, LV_OBJ_FLAG_HIDDEN);
        // NOTE: Phase 5 wires actionTarget -> tabview navigation.
    } else {
        lv_obj_add_flag(c_actBtn, LV_OBJ_FLAG_HIDDEN);
    }
}

void buildCoach(lv_obj_t* parent) {
    lv_obj_set_style_bg_color(parent, color::bg(), 0);
    lv_obj_set_flex_flow(parent, LV_FLEX_FLOW_COLUMN);
    lv_obj_set_flex_align(parent, LV_FLEX_ALIGN_START, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);
    lv_obj_set_style_pad_all(parent, 8, 0);
    lv_obj_set_style_pad_row(parent, 6, 0);

    lv_obj_t* title = lv_label_create(parent);
    lv_label_set_text(title, "Zen Koç");
    lv_obj_set_style_text_font(title, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(title, color::text(), 0);

    // Reply card.
    lv_obj_t* card = lv_obj_create(parent);
    lv_obj_set_size(card, 300, 96);
    lv_obj_set_style_bg_color(card, color::card(), 0);
    lv_obj_set_style_border_width(card, 0, 0);
    lv_obj_clear_flag(card, LV_OBJ_FLAG_SCROLLABLE);
    c_reply = lv_label_create(card);
    lv_label_set_long_mode(c_reply, LV_LABEL_LONG_WRAP);
    lv_obj_set_width(c_reply, 280);
    lv_obj_set_style_text_color(c_reply, color::text(), 0);
    lv_label_set_text(c_reply, "Nasıl hissettiğini seç, seni dinliyorum.");
    lv_obj_center(c_reply);

    // Action button (hidden until a reply provides one).
    c_actBtn = lv_btn_create(parent);
    lv_obj_set_style_bg_color(c_actBtn, color::accent(), 0);
    c_actLbl = lv_label_create(c_actBtn);
    lv_label_set_text(c_actLbl, "");
    lv_obj_center(c_actLbl);
    lv_obj_add_flag(c_actBtn, LV_OBJ_FLAG_HIDDEN);

    // Suggested prompt chips.
    lv_obj_t* chips = lv_obj_create(parent);
    lv_obj_set_size(chips, 310, 84);
    lv_obj_set_style_bg_opa(chips, LV_OPA_0, 0);
    lv_obj_set_style_border_width(chips, 0, 0);
    lv_obj_set_flex_flow(chips, LV_FLEX_FLOW_ROW_WRAP);
    lv_obj_set_flex_align(chips, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);
    lv_obj_set_style_pad_all(chips, 2, 0);

    for (auto p : PROMPTS) {
        lv_obj_t* chip = lv_btn_create(chips);
        lv_obj_set_style_bg_color(chip, color::card(), 0);
        lv_obj_set_style_pad_all(chip, 6, 0);
        lv_obj_add_event_cb(chip, promptCb, LV_EVENT_CLICKED, (void*)p);
        lv_obj_t* lbl = lv_label_create(chip);
        lv_label_set_text(lbl, p);
        lv_obj_set_style_text_color(lbl, color::text(), 0);
    }
}

}} // namespace zf::ui
