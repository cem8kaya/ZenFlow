// ============================================================================
//  ui.h — screen builders + shared visual language.
//
//  Mirrors the iOS tab structure (ZenFlowApp.SwipeableTabView):
//    0 Coach · 1 Breathing · 2 Focus · 3 Garden · 4 Settings
// ============================================================================
#pragma once
#include <lvgl.h>

namespace zf { namespace ui {

// Palette (dark, calming — mirrors the app's preferredColorScheme(.dark)).
namespace color {
    inline lv_color_t bg()      { return lv_color_hex(0x0E1B2A); }
    inline lv_color_t card()    { return lv_color_hex(0x16263A); }
    inline lv_color_t accent()  { return lv_color_hex(0x4FC3F7); } // zen cyan
    inline lv_color_t accent2() { return lv_color_hex(0x66BB6A); } // garden green
    inline lv_color_t text()    { return lv_color_hex(0xE8F1F8); }
    inline lv_color_t muted()   { return lv_color_hex(0x8FA6B8); }
}

// Screen builders — each receives its tabview page as parent.
void buildCoach(lv_obj_t* parent);
void buildBreathing(lv_obj_t* parent);
void buildFocus(lv_obj_t* parent);
void buildGarden(lv_obj_t* parent);
void buildSettings(lv_obj_t* parent);

// Called from loop() for effects that ride outside LVGL's own timers.
void tick();

}} // namespace zf::ui
