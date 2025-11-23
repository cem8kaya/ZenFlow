# Widget Integration Guide for Main App

Quick reference for integrating widget updates into the ZenFlow main app.

## 1. Update LocalDataManager.swift

Add WidgetKit import and reload calls to trigger widget updates.

### File: `/home/user/ZenFlow/ZenFlow/Managers/LocalDataManager.swift`

```swift
import Foundation
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

class LocalDataManager: ObservableObject {
    static let shared = LocalDataManager()

    // IMPORTANT: Use App Group UserDefaults instead of standard UserDefaults
    private let defaults: UserDefaults

    private init() {
        // Initialize with App Group UserDefaults
        if let appGroupDefaults = UserDefaults(suiteName: "group.com.zenflow.app") {
            self.defaults = appGroupDefaults
        } else {
            // Fallback to standard UserDefaults
            print("⚠️ Warning: Failed to initialize App Group UserDefaults")
            self.defaults = UserDefaults.standard
        }
    }

    // ... existing properties ...

    // UPDATE: Add widget reload to saveSession
    func saveSession(durationMinutes: Int) {
        let session = SessionData(
            date: Date(),
            durationMinutes: durationMinutes,
            dateString: DateFormatter.shortDate.string(from: Date())
        )

        // Save session
        var sessions = getSessions()
        sessions.append(session)
        defaults.set(try? JSONEncoder().encode(sessions), forKey: "sessions")

        // Update totals
        let total = totalMinutes + durationMinutes
        defaults.set(total, forKey: "totalMinutes")

        // Update last session date
        defaults.set(Date(), forKey: "lastSessionDate")

        // Update streak
        updateStreak()

        // Publish updates
        objectWillChange.send()

        // ✨ RELOAD WIDGETS
        reloadWidgets()
    }

    // UPDATE: Add widget reload to updateStreak
    func updateStreak() {
        guard let lastSession = getLastSessionDate() else {
            currentStreak = 0
            defaults.set(0, forKey: "currentStreak")
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastSessionDay = calendar.startOfDay(for: lastSession)

        let daysDifference = calendar.dateComponents([.day], from: lastSessionDay, to: today).day ?? 0

        if daysDifference == 0 {
            // Session today - streak continues
            // Don't increment if we already counted today
        } else if daysDifference == 1 {
            // Session was yesterday - increment streak
            currentStreak += 1
            defaults.set(currentStreak, forKey: "currentStreak")

            // Update longest streak if needed
            if currentStreak > longestStreak {
                longestStreak = currentStreak
                defaults.set(longestStreak, forKey: "longestStreak")
            }
        } else {
            // Gap in sessions - reset streak
            currentStreak = 1
            defaults.set(1, forKey: "currentStreak")
        }

        // ✨ RELOAD WIDGETS
        reloadWidgets()
    }

    // ✨ NEW: Widget reload helper
    private func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
```

## 2. Verify App Group Configuration

### Check Current UserDefaults Usage

Search for all UserDefaults usage in LocalDataManager:

```bash
# Find all UserDefaults references
grep -n "defaults\." ZenFlow/Managers/LocalDataManager.swift
```

### Migrate Existing Data (If Needed)

If users already have data in standard UserDefaults, migrate it:

```swift
// Add to LocalDataManager.init()
private init() {
    // Initialize with App Group UserDefaults
    if let appGroupDefaults = UserDefaults(suiteName: "group.com.zenflow.app") {
        self.defaults = appGroupDefaults

        // One-time migration from standard UserDefaults
        migrateFromStandardUserDefaults()
    } else {
        print("⚠️ Warning: Failed to initialize App Group UserDefaults")
        self.defaults = UserDefaults.standard
    }
}

private func migrateFromStandardUserDefaults() {
    let standardDefaults = UserDefaults.standard
    let migrationKey = "hasCompletedUserDefaultsMigration"

    // Check if migration already completed
    guard !defaults.bool(forKey: migrationKey) else { return }

    print("🔄 Migrating UserDefaults to App Group...")

    // List of keys to migrate
    let keysToMigrate = [
        "totalMinutes",
        "currentStreak",
        "longestStreak",
        "lastSessionDate",
        "sessions",
        "focusSessions",
        "totalFocusSessions"
    ]

    // Migrate each key
    for key in keysToMigrate {
        if let value = standardDefaults.object(forKey: key) {
            defaults.set(value, forKey: key)
            print("✅ Migrated: \(key)")
        }
    }

    // Mark migration as completed
    defaults.set(true, forKey: migrationKey)
    defaults.synchronize()

    print("✅ Migration completed successfully")
}
```

## 3. Test Widget Updates

### Testing Checklist

1. **Build and run main app**
   ```bash
   # In Xcode, select ZenFlow scheme and run
   ```

2. **Add widget to home screen**
   - Long press on home screen
   - Tap + button
   - Search "ZenFlow"
   - Add widget

3. **Complete a meditation session**
   - Start a meditation in the app
   - Complete it (even 1 minute is fine for testing)
   - Return to home screen
   - Widget should update within 1-2 seconds

4. **Verify data synchronization**
   - Check that widget shows correct total minutes
   - Check that streak count is accurate
   - Check that tree stage is correct

### Debug Widget Data

Add this helper to LocalDataManager for debugging:

```swift
func printWidgetData() {
    print("📊 Widget Data Debug:")
    print("  Total Minutes: \(totalMinutes)")
    print("  Current Streak: \(currentStreak)")
    print("  Longest Streak: \(longestStreak)")
    print("  Last Session: \(getLastSessionDate() ?? Date())")
    print("  UserDefaults Suite: \(defaults.dictionaryRepresentation().keys.contains("totalMinutes") ? "✅" : "❌")")
}

// Call after saving session
func saveSession(durationMinutes: Int) {
    // ... existing code ...

    #if DEBUG
    printWidgetData()
    #endif
}
```

## 4. Common Issues and Solutions

### Issue: Widget Shows 0 Minutes After Migration

**Cause:** Data not migrated from standard UserDefaults to App Group.

**Solution:**
```swift
// In LocalDataManager, verify initialization
init() {
    if let appGroupDefaults = UserDefaults(suiteName: "group.com.zenflow.app") {
        self.defaults = appGroupDefaults
        print("✅ Using App Group UserDefaults")
    } else {
        self.defaults = UserDefaults.standard
        print("⚠️ Falling back to standard UserDefaults")
    }

    // Print current data
    print("Total minutes: \(defaults.integer(forKey: "totalMinutes"))")
}
```

### Issue: Widget Not Updating After Session

**Cause:** WidgetCenter.reloadAllTimelines() not being called.

**Solution:**
```swift
// Verify import at top of file
#if canImport(WidgetKit)
import WidgetKit
#endif

// Verify reload call
func saveSession(durationMinutes: Int) {
    // ... save logic ...

    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadAllTimelines()
    print("🔄 Widget reload triggered")
    #endif
}
```

### Issue: App Groups Not Working

**Cause:** App Group not configured correctly in Xcode.

**Solution:**
1. Open project in Xcode
2. Select **ZenFlow** target
3. Go to **Signing & Capabilities**
4. Verify **App Groups** capability exists
5. Verify `group.com.zenflow.app` is checked
6. Repeat for **ZenFlowWidget** target
7. Clean build folder (Cmd+Shift+K)
8. Rebuild

## 5. Performance Optimization

### Debounce Widget Reloads

If you're calling saveSession multiple times rapidly:

```swift
private var widgetReloadTimer: Timer?

private func reloadWidgets() {
    // Debounce: only reload once every 2 seconds
    widgetReloadTimer?.invalidate()
    widgetReloadTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
```

### Selective Widget Reload

Reload only ZenFlow widgets:

```swift
private func reloadWidgets() {
    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadTimelines(ofKind: "ZenFlowWidget")
    WidgetCenter.shared.reloadTimelines(ofKind: "ZenFlowLockScreenWidget")
    #endif
}
```

## 6. Validation Script

Run this in Xcode Debug Console to verify setup:

```swift
// Paste in Xcode Debug Console (after pausing execution)
po UserDefaults(suiteName: "group.com.zenflow.app")?.dictionaryRepresentation().keys

// Should show your data keys: totalMinutes, currentStreak, etc.
```

## 7. App Store Submission Notes

### Info.plist Updates

No special configuration needed - widgets are automatically included.

### App Privacy

Update Privacy Policy to mention:
- "Widget displays your meditation progress on home screen and lock screen"
- "No data leaves your device - all widget data is stored locally"

### Screenshots

Capture screenshots showing:
- Home screen widget in different sizes
- Lock screen widget
- Widget customization screen

---

## Quick Reference

### App Group ID
```
group.com.zenflow.app
```

### UserDefaults Keys Used by Widget
```swift
"totalMinutes"      // Int
"currentStreak"     // Int
"longestStreak"     // Int
"lastSessionDate"   // Date
"sessions"          // Data (encoded [SessionData])
```

### Widget Kinds
```swift
"ZenFlowWidget"              // Home screen widgets
"ZenFlowLockScreenWidget"    // Lock screen widgets
```

### Manual Widget Reload (for testing)
```swift
// Call from anywhere in main app
#if canImport(WidgetKit)
import WidgetKit
WidgetCenter.shared.reloadAllTimelines()
#endif
```

---

**Next Steps:**
1. ✅ Update LocalDataManager with App Group UserDefaults
2. ✅ Add WidgetKit import and reload calls
3. ✅ Configure App Groups in Xcode
4. ✅ Test widget updates
5. ✅ Add widget to Xcode project
6. 🚀 Build and deploy!
