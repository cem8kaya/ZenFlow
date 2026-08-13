// ============================================================================
//  ui_common.cpp — shared UI helpers.
// ============================================================================
#include "ui.h"
#include "hw.h"

namespace zf { namespace ui {

void tick() {
    // Forward to hardware time-based effects (vibration auto-stop, LED fades).
    hw::tick();
}

}} // namespace zf::ui
