// ============================================================================
//  ZenFlow Core2 (Edge Edition) — main.cpp
//
//  M5Stack Core2 for AWS · fully offline mindfulness device.
//  Bridges M5Unified (display + touch + power) to LVGL and assembles the
//  5-tab UI that mirrors the ZenFlow iOS app.
//
//  Tabs: Koç · Nefes · Odak · Bahçe · Ayarlar
// ============================================================================
#include <M5Unified.h>
#include <lvgl.h>

#include "ui.h"
#include "store.h"
#include "hw.h"
#include "sense.h"

// ---- LVGL display plumbing -------------------------------------------------
static const uint16_t SCR_W = 320;
static const uint16_t SCR_H = 240;

static lv_disp_draw_buf_t s_drawBuf;
static lv_color_t s_buf[SCR_W * 40];   // ~25KB, 40-line partial buffer

static void dispFlush(lv_disp_drv_t* drv, const lv_area_t* area, lv_color_t* px) {
    const uint32_t w = area->x2 - area->x1 + 1;
    const uint32_t h = area->y2 - area->y1 + 1;
    M5.Display.startWrite();
    M5.Display.setAddrWindow(area->x1, area->y1, w, h);
    M5.Display.writePixels(reinterpret_cast<uint16_t*>(px), w * h, true /*swap*/);
    M5.Display.endWrite();
    lv_disp_flush_ready(drv);
}

static void touchRead(lv_indev_drv_t* drv, lv_indev_data_t* data) {
    auto t = M5.Touch.getDetail();
    if (t.isPressed()) {
        data->state   = LV_INDEV_STATE_PRESSED;
        data->point.x = t.x;
        data->point.y = t.y;
    } else {
        data->state = LV_INDEV_STATE_RELEASED;
    }
}

static void buildUI() {
    lv_obj_t* tv = lv_tabview_create(lv_scr_act(), LV_DIR_BOTTOM, 40);
    lv_obj_set_style_bg_color(tv, zf::ui::color::bg(), 0);

    lv_obj_t* tCoach = lv_tabview_add_tab(tv, "Koç");
    lv_obj_t* tBreath = lv_tabview_add_tab(tv, "Nefes");
    lv_obj_t* tFocus = lv_tabview_add_tab(tv, "Odak");
    lv_obj_t* tGarden = lv_tabview_add_tab(tv, "Bahçe");
    lv_obj_t* tSet = lv_tabview_add_tab(tv, "Ayarlar");

    zf::ui::buildCoach(tCoach);
    zf::ui::buildBreathing(tBreath);
    zf::ui::buildFocus(tFocus);
    zf::ui::buildGarden(tGarden);
    zf::ui::buildSettings(tSet);
}

void setup() {
    auto cfg = M5.config();
    M5.begin(cfg);
    M5.Display.setRotation(1);
    M5.Display.setBrightness(160);

    zf::Store::begin();
    zf::hw::begin();

    lv_init();
    lv_disp_draw_buf_init(&s_drawBuf, s_buf, nullptr, SCR_W * 40);

    static lv_disp_drv_t dispDrv;
    lv_disp_drv_init(&dispDrv);
    dispDrv.hor_res  = SCR_W;
    dispDrv.ver_res  = SCR_H;
    dispDrv.flush_cb = dispFlush;
    dispDrv.draw_buf = &s_drawBuf;
    lv_disp_drv_register(&dispDrv);

    static lv_indev_drv_t indevDrv;
    lv_indev_drv_init(&indevDrv);
    indevDrv.type    = LV_INDEV_TYPE_POINTER;
    indevDrv.read_cb = touchRead;
    lv_indev_drv_register(&indevDrv);

    buildUI();

    // Phase 7 — start BMI270 breath/stillness + SPM1423 acoustic sensing.
    // Uses lv_timers on this thread, so it must come after lv_init().
    zf::SenseManager::begin(/*enableMic=*/true);
}

void loop() {
    M5.update();          // refresh touch/buttons/power
    lv_timer_handler();   // LVGL tasks (uses millis() tick from lv_conf.h)
    zf::ui::tick();       // hardware time-based effects
    delay(5);
}
