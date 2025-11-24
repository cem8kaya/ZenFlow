# ZenFlow App Icon Generator

Professional app icon generator for ZenFlow meditation app.

## Icon Concepts

### 1. Lotus Flower 🪷
Stylized lotus flower with layered petals in gradient colors. Represents:
- Spiritual awakening
- Peace and purity
- Meditation and mindfulness

### 2. Breathing Circles (Recommended) 💫
Concentric circles representing breathing waves. Represents:
- Breathing exercises
- Ripple effects of meditation
- Calm and centered focus

### 3. Zen Stones 🪨
Balanced stone pyramid. Represents:
- Balance and stability
- Zen philosophy
- Grounding and peace

## Color Palette

Based on ZenTheme:
- **Calm Blue**: `#5973D9` - Primary breathing color
- **Serene Purple**: `#8059D9` - Secondary breathing color
- **Soft Purple**: `#7359A6` - Accent color
- **Deep Indigo**: `#2E2659` - Background

## How to Use

### Preview in Xcode

1. Open `IconGenerator.swift` in Xcode
2. Open the Canvas (Editor → Canvas)
3. View live previews of all three icon styles
4. Switch between styles using the picker

### Export Icons

#### Method 1: Using ImageRenderer (Programmatic)

```swift
import SwiftUI

@MainActor
func exportIcon(style: IconStyle, size: CGFloat = 1024) {
    let view = IconExportView(style: style, size: size)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0

    if let image = renderer.uiImage {
        // Save to Photos or Documents
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}
```

#### Method 2: Using Xcode Canvas (Recommended)

1. Open `IconGenerator.swift`
2. Enable Canvas (⌥⌘↩︎)
3. Right-click on preview
4. Select "Export Preview"
5. Save as PNG at desired size

#### Method 3: Screenshot & Export

1. Run app on simulator
2. Display icon at 1024x1024
3. Take screenshot
4. Crop to exact size
5. Save as PNG

### Generate All Sizes

Use the provided export script or Xcode's asset catalog:

1. Export 1024x1024 master icon
2. Place in `Assets.xcassets/AppIcon.appiconset/`
3. Xcode will auto-generate all required sizes

**Required Sizes:**
- iPhone: 20pt, 29pt, 40pt, 60pt (2x, 3x)
- iPad: 20pt, 29pt, 40pt, 76pt, 83.5pt (1x, 2x)
- App Store: 1024pt (1x)

## Apple Guidelines

✅ **DO:**
- Use solid background (no transparency)
- Keep design centered and balanced
- Test on different backgrounds
- Ensure readability at small sizes

❌ **DON'T:**
- Add rounded corners (iOS adds automatically)
- Use transparency
- Include text or words
- Make it too complex

## File Structure

```
ZenFlow/Assets/
├── IconGenerator.swift          # Main generator with 3 styles
└── README_ICONS.md             # This file

ZenFlow/Assets.xcassets/AppIcon.appiconset/
├── Contents.json               # Asset catalog config
├── icon-1024.png              # App Store (1024x1024)
├── icon-60@3x.png             # iPhone App (180x180)
├── icon-60@2x.png             # iPhone App (120x120)
└── [other sizes...]           # All required sizes
```

## Recommended Icon

**Breathing Circles** is recommended because:
- Clear at all sizes
- Represents core app functionality
- Modern and minimalist
- Distinctive in App Store
- Aligns with breathing exercises

## Export Checklist

- [ ] Choose icon style (Breathing Circles recommended)
- [ ] Export at 1024x1024 pixels
- [ ] Verify no transparency
- [ ] Test on light/dark backgrounds
- [ ] Check small size (60x60) readability
- [ ] Place in AppIcon.appiconset folder
- [ ] Verify all sizes in asset catalog
- [ ] Build and test in simulator
- [ ] Submit to App Store

## Technical Details

- **Format**: SwiftUI vector graphics
- **Resolution**: Scalable to any size
- **Export**: PNG at 1024x1024
- **Color Space**: sRGB
- **Bit Depth**: 24-bit RGB
- **Compression**: PNG lossless

## Notes

- Icons are pure SwiftUI, no external assets needed
- Fully scalable vector graphics
- Colors match app's ZenTheme palette
- Compliant with Apple Human Interface Guidelines
- No third-party tools required

---

Created by Claude AI for ZenFlow
Last updated: November 24, 2025
