/**
 * lv_conf.h — LVGL v8 configuration for ZenFlow Core2
 * Target display: M5Stack Core2 for AWS, 320x240, RGB565.
 *
 * Trimmed to the widgets/fonts this project uses to keep flash/RAM low.
 * Enabled via build flag -D LV_CONF_INCLUDE_SIMPLE.
 */
#ifndef LV_CONF_H
#define LV_CONF_H

#include <stdint.h>

/*==================
 *   COLOR
 *==================*/
#define LV_COLOR_DEPTH 16
/* Pixel byte-swap is handled in the flush callback (M5.Display.writePixels swap=true). */
#define LV_COLOR_16_SWAP 0

/*=========================
 *   MEMORY
 *=========================*/
/* Use LVGL's own allocator. 48KB is comfortable for these screens. */
#define LV_MEM_CUSTOM 0
#define LV_MEM_SIZE (48U * 1024U)

/*====================
 *   HAL / TICK
 *====================*/
/* Let LVGL read time from Arduino millis() — no manual lv_tick_inc needed. */
#define LV_TICK_CUSTOM 1
#define LV_TICK_CUSTOM_INCLUDE "Arduino.h"
#define LV_TICK_CUSTOM_SYS_TIME_EXPR (millis())

#define LV_DPI_DEF 130

/*=======================
 *   FEATURE USAGE
 *=======================*/
#define LV_USE_PERF_MONITOR 0
#define LV_USE_MEM_MONITOR 0
#define LV_USE_ANIMIMG 0

/*==================
 *   FONTS
 *==================*/
#define LV_FONT_MONTSERRAT_14 1
#define LV_FONT_MONTSERRAT_20 1
#define LV_FONT_MONTSERRAT_28 1
#define LV_FONT_MONTSERRAT_48 1
#define LV_FONT_DEFAULT &lv_font_montserrat_14

/*==================
 *   WIDGETS
 *==================*/
#define LV_USE_ARC 1
#define LV_USE_BAR 1
#define LV_USE_BTN 1
#define LV_USE_LABEL 1
#define LV_USE_TABVIEW 1
#define LV_USE_LIST 1
#define LV_USE_SLIDER 1
#define LV_USE_SWITCH 1
#define LV_USE_IMG 1
#define LV_USE_LINE 1

/*==================
 *   THEME
 *==================*/
#define LV_USE_THEME_DEFAULT 1
#define LV_THEME_DEFAULT_DARK 1
#define LV_USE_THEME_BASIC 1

#endif /* LV_CONF_H */
