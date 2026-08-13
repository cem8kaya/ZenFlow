// ============================================================================
//  screen_garden.cpp — Zen Garden. Port of ZenGardenView.
//
//  Tree growth is a pure function of accumulated mindful minutes
//  (Constants.TreeGrowth). Shown here as stage name + progress to next stage.
//  Phase 3 will swap the placeholder glyph for staged tree sprites.
// ============================================================================
#include "ui.h"
#include "content.h"
#include "store.h"

namespace zf { namespace ui {

static lv_obj_t* g_stageLbl = nullptr;
static lv_obj_t* g_treeLbl  = nullptr;
static lv_obj_t* g_bar      = nullptr;
static lv_obj_t* g_infoLbl  = nullptr;

static size_t stageForMinutes(uint32_t minutes) {
    size_t stage = 0;
    for (size_t i = 0; i < TREE_STAGE_COUNT; ++i)
        if (minutes >= TREE_STAGES[i].minMinutes) stage = i;
    return stage;
}

static void refresh() {
    Stats s = Store::load();
    size_t stage = stageForMinutes(s.totalMinutes);
    lv_label_set_text(g_stageLbl, TREE_STAGES[stage].nameTr);

    // Placeholder tree: ASCII glyph grows with stage (real sprites land in Phase 3).
    static const char* glyphs[] = {".", "i", "Y", "T", "#", "@"};
    lv_label_set_text(g_treeLbl, glyphs[stage < 6 ? stage : 5]);

    // Progress to next stage.
    if (stage + 1 < TREE_STAGE_COUNT) {
        uint32_t cur  = TREE_STAGES[stage].minMinutes;
        uint32_t next = TREE_STAGES[stage + 1].minMinutes;
        int pct = (int)((s.totalMinutes - cur) * 100 / (next - cur));
        lv_bar_set_value(g_bar, pct, LV_ANIM_OFF);
        char buf[64];
        snprintf(buf, sizeof(buf), "%lu dk  •  sonraki: %lu dk",
                 (unsigned long)s.totalMinutes, (unsigned long)next);
        lv_label_set_text(g_infoLbl, buf);
    } else {
        lv_bar_set_value(g_bar, 100, LV_ANIM_OFF);
        char buf[48];
        snprintf(buf, sizeof(buf), "%lu dk  •  en yüksek aşama",
                 (unsigned long)s.totalMinutes);
        lv_label_set_text(g_infoLbl, buf);
    }
}

void buildGarden(lv_obj_t* parent) {
    lv_obj_set_style_bg_color(parent, color::bg(), 0);
    lv_obj_clear_flag(parent, LV_OBJ_FLAG_SCROLLABLE);

    g_treeLbl = lv_label_create(parent);
    lv_obj_set_style_text_font(g_treeLbl, &lv_font_montserrat_48, 0);
    lv_obj_set_style_text_color(g_treeLbl, color::accent2(), 0);
    lv_obj_align(g_treeLbl, LV_ALIGN_CENTER, 0, -30);

    g_stageLbl = lv_label_create(parent);
    lv_obj_set_style_text_font(g_stageLbl, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(g_stageLbl, color::text(), 0);
    lv_obj_align(g_stageLbl, LV_ALIGN_CENTER, 0, 24);

    g_bar = lv_bar_create(parent);
    lv_obj_set_size(g_bar, 220, 10);
    lv_bar_set_range(g_bar, 0, 100);
    lv_obj_set_style_bg_color(g_bar, color::card(), LV_PART_MAIN);
    lv_obj_set_style_bg_color(g_bar, color::accent2(), LV_PART_INDICATOR);
    lv_obj_align(g_bar, LV_ALIGN_CENTER, 0, 56);

    g_infoLbl = lv_label_create(parent);
    lv_obj_set_style_text_color(g_infoLbl, color::muted(), 0);
    lv_obj_align(g_infoLbl, LV_ALIGN_CENTER, 0, 80);

    refresh();
}

}} // namespace zf::ui
