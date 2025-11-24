# ZenFlow App Icon Generation

## Overview
This directory contains tools for generating production-ready iOS app icons for the ZenFlow meditation app.

## Generated Icons
All iOS app icons have been generated using the **Breathing Circles** design, which represents the core breathing meditation feature of ZenFlow.

### Design Details
- **Style**: Breathing Circles with concentric rings
- **Colors**: Based on ZenTheme (Calm Blue #5973D9, Serene Purple #8059D9, Deep Indigo #2E2659)
- **Format**: PNG, RGB (no alpha channel), sRGB color space
- **Location**: `ZenFlow/Assets.xcassets/AppIcon.appiconset/`

### Icon Sizes Generated
✅ **18 icon sizes** covering all iOS requirements:

#### iPhone Icons
- 20pt @ 2x, 3x (Notification)
- 29pt @ 2x, 3x (Settings)
- 40pt @ 2x, 3x (Spotlight)
- 60pt @ 2x, 3x (App)

#### iPad Icons
- 20pt @ 1x, 2x (Notification)
- 29pt @ 1x, 2x (Settings)
- 40pt @ 1x, 2x (Spotlight)
- 76pt @ 1x, 2x (App)
- 83.5pt @ 2x (iPad Pro)

#### App Store
- 1024pt @ 1x (App Store Marketing)

## Files

### Python Generator (Recommended)
**`generate_app_icons.py`** - Production Python script that generates all icons
- Uses Pillow (PIL) for image generation
- Renders Breathing Circles design at all required sizes
- Automatically creates Contents.json
- Can be run on any platform with Python 3

**Usage:**
```bash
# Install dependencies
pip install Pillow

# Generate all icons
python3 Scripts/generate_app_icons.py
```

### Swift Generators
1. **`GenerateAppIcons.swift`** - Command-line Swift script (macOS only)
   - Uses AppKit/Core Graphics for rendering
   - Run with: `swift Scripts/GenerateAppIcons.swift`

2. **`AppIconExporter.swift`** - SwiftUI-based exporter
   - Integrates with Xcode project
   - Can be used as an in-app preview or export tool
   - Located in `ZenFlow/Assets/`

## Verification

All generated icons have been verified:
- ✅ Correct dimensions for each size
- ✅ RGB color mode (no transparency)
- ✅ Proper file naming convention
- ✅ Valid Contents.json with all references
- ✅ Ready for Xcode build and App Store submission

## Re-generating Icons

If you need to regenerate the icons:

1. **Using Python (Any platform):**
   ```bash
   python3 Scripts/generate_app_icons.py
   ```

2. **Using Swift (macOS only):**
   ```bash
   swift Scripts/GenerateAppIcons.swift
   ```

3. **Using Xcode:**
   - Add AppIconExporter.swift to your target
   - Use ImageRenderer to export from previews
   - Or integrate AppIconExporterView into the app

## Design Modifications

To modify the icon design:

1. **Edit Python script:** Modify `draw_breathing_circles_icon()` function in `generate_app_icons.py`
2. **Edit Swift design:** Modify `BreathingCirclesIconView` in `ZenFlow/Assets/IconGenerator.swift`
3. **Colors:** Update color constants at the top of each file

## App Store Submission

The generated icons are production-ready:
- ✅ All required sizes included
- ✅ No alpha channel (as required by Apple)
- ✅ sRGB color space
- ✅ Properly organized in AppIcon.appiconset
- ✅ Contents.json correctly configured

Simply build your Xcode project and the icons will be included automatically.

## Notes

- The Breathing Circles design is optimized to remain clear and recognizable at small sizes
- All icons use the same ZenTheme color palette for brand consistency
- The design features a calming gradient background with concentric circles representing breath cycles
- The center circle represents focus and mindfulness

---

**Generated:** November 24, 2025
**Design:** Breathing Circles
**Status:** Production Ready ✅
