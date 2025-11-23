# ZenFlow Widget Extension

Complete WidgetKit implementation for the ZenFlow meditation app, featuring home screen and lock screen widgets.

## 📱 Widget Types

### Home Screen Widgets
1. **System Small** - Compact tree icon with circular progress
2. **System Medium** - Detailed stats with tree visualization
3. **System Large** - Comprehensive dashboard with full statistics

### Lock Screen Widgets (iOS 16+)
1. **Rectangular** - Streak count with motivating flame icon
2. **Circular** - Compact tree progress indicator
3. **Inline** - Single-line streak and minutes display

## 📂 File Structure

```
ZenFlowWidget/
├── ZenFlowWidget.swift              # Main widget entry point & configurations
├── ZenFlowWidgetProvider.swift      # Timeline provider for data fetching
├── ZenFlowWidgetEntry.swift         # Timeline entry model
├── ZenFlowWidgetViews.swift         # SwiftUI widget views
├── SharedDataManager.swift          # App Group UserDefaults manager
├── Info.plist                       # Widget extension configuration
└── Assets.xcassets/                 # Widget assets
    ├── AppIcon.appiconset/
    └── WidgetBackground.colorset/
```

## 🚀 Setup Instructions

### Step 1: Add Widget Extension Target to Xcode Project

1. **Open your ZenFlow project in Xcode**
   ```
   open ZenFlow.xcodeproj
   ```

2. **Add Widget Extension target:**
   - File → New → Target
   - Select "Widget Extension"
   - Product Name: `ZenFlowWidget`
   - Check "Include Configuration Intent" (optional for future customization)
   - Click Finish

3. **Add Swift files to the widget target:**
   - In Xcode Project Navigator, select all `.swift` files in the `ZenFlowWidget` folder
   - In File Inspector (right panel), ensure "Target Membership" includes `ZenFlowWidget`
   - Files to add:
     - ZenFlowWidget.swift
     - ZenFlowWidgetProvider.swift
     - ZenFlowWidgetEntry.swift
     - ZenFlowWidgetViews.swift
     - SharedDataManager.swift

### Step 2: Configure App Groups

App Groups allow data sharing between the main app and widget extension.

#### For Main App Target (ZenFlow):

1. Select the **ZenFlow** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** → Add **App Groups**
4. Click **+** to create a new App Group
5. Enter: `group.com.zenflow.app` (or your preferred identifier)
6. Enable the checkbox

#### For Widget Extension Target (ZenFlowWidget):

1. Select the **ZenFlowWidget** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** → Add **App Groups**
4. Select the **same** App Group: `group.com.zenflow.app`
5. Enable the checkbox

⚠️ **Important:** Both targets MUST use the exact same App Group identifier!

### Step 3: Update LocalDataManager to Use App Group

Modify `/home/user/ZenFlow/ZenFlow/Managers/LocalDataManager.swift`:

```swift
import Foundation
import WidgetKit  // Add this import

class LocalDataManager: ObservableObject {
    static let shared = LocalDataManager()

    // BEFORE: private let defaults = UserDefaults.standard
    // AFTER: Use App Group UserDefaults
    private let defaults: UserDefaults

    private init() {
        // Initialize with App Group UserDefaults
        if let appGroupDefaults = UserDefaults(suiteName: "group.com.zenflow.app") {
            self.defaults = appGroupDefaults
        } else {
            // Fallback to standard UserDefaults (should not happen in production)
            print("⚠️ Warning: Failed to initialize App Group UserDefaults")
            self.defaults = UserDefaults.standard
        }
    }

    // ... rest of your existing code ...

    // Add widget reload after saving sessions
    func saveSession(durationMinutes: Int) {
        let session = SessionData(
            date: Date(),
            durationMinutes: durationMinutes,
            dateString: DateFormatter.shortDate.string(from: Date())
        )

        // Existing save logic
        var sessions = getSessions()
        sessions.append(session)
        defaults.set(try? JSONEncoder().encode(sessions), forKey: "sessions")

        // Update totals
        let total = totalMinutes + durationMinutes
        defaults.set(total, forKey: "totalMinutes")

        // Update streak
        updateStreak()

        // ✨ NEW: Reload widgets to show updated data
        WidgetCenter.shared.reloadAllTimelines()
    }

    // Also add reload after streak updates
    func updateStreak() {
        // ... existing streak logic ...

        // ✨ NEW: Reload widgets after streak changes
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

### Step 4: Update SharedDataManager App Group Identifier

If you used a different App Group identifier, update `SharedDataManager.swift`:

```swift
// In SharedDataManager.swift, line 19
private static let appGroupIdentifier = "group.com.zenflow.app"  // Update if needed
```

### Step 5: Build and Run

1. **Select the ZenFlowWidget scheme** in Xcode toolbar
2. **Run** (Cmd+R)
3. Xcode will prompt you to select a widget to preview
4. Choose "ZenFlowWidget" from the list
5. The widget will appear on the simulator/device home screen

### Step 6: Add Widget to Home Screen

**On Simulator/Device:**
1. Long-press on the home screen
2. Tap the **+** button (top-left)
3. Search for "ZenFlow"
4. Select widget size (Small, Medium, or Large)
5. Tap "Add Widget"

**Lock Screen Widget (iOS 16+):**
1. Long-press on the lock screen
2. Tap "Customize"
3. Tap widget area below the clock
4. Search for "ZenFlow Seri"
5. Add rectangular, circular, or inline widget

## 🎨 Widget Designs

### System Small Widget
```
┌─────────────┐
│  125 dk     │  ← Total minutes
│             │
│   ╭───╮     │  ← Circular progress
│   │ 🌳 │    │  ← Tree icon (SF Symbol)
│   ╰───╯     │
│             │
│  🔥 7  Fidan│  ← Streak & Stage name
└─────────────┘
```

### System Medium Widget
```
┌──────────────────────────────┐
│  ╭───╮      Fidan            │
│  │ 🌳 │     67% sonraki...    │
│  ╰───╯      ───────────       │
│             ⏱ Toplam: 200 dk  │
│             🔥 Seri: 14 gün   │
│             ⭐ En Uzun: 21 gün│
└──────────────────────────────┘
```

### Lock Screen Rectangular
```
┌────────────────────┐
│ 🔥 14 Gün Serisi   │
│    🌳 Fidan        │
└────────────────────┘
```

## 🔄 Data Flow

1. **User completes meditation** in main app
2. **LocalDataManager** saves session to App Group UserDefaults
3. **WidgetCenter.shared.reloadAllTimelines()** is called
4. **ZenFlowWidgetProvider** fetches updated data via SharedDataManager
5. **Widget UI updates** with new tree stage, minutes, and streak

## 📊 Data Mapping

### From LocalDataManager → Widget

| Main App Key | Widget Access | Description |
|--------------|---------------|-------------|
| `totalMinutes` | `SharedDataManager.getTotalMinutes()` | Total meditation minutes |
| `currentStreak` | `SharedDataManager.getCurrentStreak()` | Current streak days |
| `longestStreak` | `SharedDataManager.getLongestStreak()` | Longest streak record |
| `sessions` | *(not used in widget)* | Session history |

### Tree Stage Calculation

Tree stages are calculated in `SharedDataManager.getCurrentTreeStage()`:

| Stage | Minutes Required | Icon | Progress Calculation |
|-------|------------------|------|---------------------|
| Tohum (Seed) | 0-29 | circle.fill | 0-100% to Filiz |
| Filiz (Sprout) | 30-119 | leaf.fill | 0-100% to Fidan |
| Fidan (Sapling) | 120-299 | tree | 0-100% to Genç Ağaç |
| Genç Ağaç (Young) | 300-599 | tree.fill | 0-100% to Olgun Ağaç |
| Olgun Ağaç (Mature) | 600-1199 | tree.fill | 0-100% to Kadim Ağaç |
| Kadim Ağaç (Ancient) | 1200+ | sparkles | 100% (max) |

## 🎨 Theme Colors (ZenTheme)

Extracted from main app's `ZenTheme.swift`:

```swift
static let zenPrimary = Color(red: 0.18, green: 0.15, blue: 0.35)     // Deep indigo
static let zenSecondary = Color(red: 0.45, green: 0.35, blue: 0.65)   // Soft purple
static let zenAccent = Color(red: 0.55, green: 0.40, blue: 0.75)      // Mystical violet
static let zenTextHighlight = Color(red: 0.85, green: 0.80, blue: 0.95) // Light lavender
static let zenSageGreen = Color(red: 0.42, green: 0.56, blue: 0.14)   // Sage green
static let zenDeepSage = Color(red: 0.13, green: 0.55, blue: 0.13)    // Deep sage
```

## 🐛 Troubleshooting

### Widget Not Updating

**Problem:** Widget shows old data after completing meditation.

**Solution:**
1. Verify App Groups are configured identically for both targets
2. Check that `WidgetCenter.shared.reloadAllTimelines()` is called in `LocalDataManager.saveSession()`
3. Restart the app and widget (remove and re-add widget)

### "Failed to Load" Error

**Problem:** Widget shows error message or blank screen.

**Solution:**
1. Check SharedDataManager App Group identifier matches Xcode configuration
2. Verify widget target has all Swift files added
3. Clean build folder (Cmd+Shift+K) and rebuild

### Widget Shows Default/Placeholder Data

**Problem:** Widget displays sample data instead of real user data.

**Solution:**
1. Complete at least one meditation session in the main app
2. Verify LocalDataManager is writing to App Group UserDefaults
3. Check App Group identifier spelling (case-sensitive)

### Xcode Build Error: "No such module 'WidgetKit'"

**Problem:** Import WidgetKit fails in main app target.

**Solution:**
1. Only import WidgetKit in files that are part of ZenFlowWidget target
2. For LocalDataManager, use conditional compilation:
   ```swift
   #if canImport(WidgetKit)
   import WidgetKit
   #endif
   ```

## 📝 Testing Checklist

- [ ] Widget Extension builds without errors
- [ ] App Groups configured for both targets with same identifier
- [ ] LocalDataManager uses App Group UserDefaults
- [ ] WidgetCenter.reloadAllTimelines() called after saveSession()
- [ ] System Small widget displays correctly
- [ ] System Medium widget displays correctly (if enabled)
- [ ] System Large widget displays correctly (if enabled)
- [ ] Lock Screen rectangular widget works
- [ ] Lock Screen circular widget works
- [ ] Lock Screen inline widget works
- [ ] Widget updates after completing meditation
- [ ] Tree stage progresses correctly at milestones (30, 120, 300, 600, 1200 minutes)
- [ ] Streak count updates daily
- [ ] Circular progress animates smoothly

## 🚀 Future Enhancements

### Configuration Intent (Optional)
Add user customization options:
- Choose which stat to highlight (minutes vs streak)
- Toggle tree icon visibility
- Select preferred tree stage icons
- Custom color themes

### Interactive Widget (iOS 17+)
Add Button or Toggle components:
- Quick meditation timer launcher
- Streak celebration animations
- Deep link to specific app screens

### Timeline Caching
Implement intelligent caching:
- Predict next milestone updates
- Pre-calculate timeline entries
- Reduce widget reload frequency

## 📚 References

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [App Groups Setup Guide](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [Widget Best Practices](https://developer.apple.com/design/human-interface-guidelines/widgets)
- [Lock Screen Widgets (iOS 16+)](https://developer.apple.com/documentation/widgetkit/creating-lock-screen-widgets-and-watch-complications)

## 📄 License

This widget extension is part of the ZenFlow app. All rights reserved.

---

**Created by:** ZenFlow Development Team
**Last Updated:** 2025-01-23
**iOS Version:** 16.0+
**Xcode Version:** 15.0+
