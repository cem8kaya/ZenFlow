//
//  ZenFlowWidgetProvider.swift
//  ZenFlowWidget
//
//  Created by ZenFlow Widget Extension
//  Timeline provider for fetching and updating widget data
//

import WidgetKit
import SwiftUI

/// Timeline provider for the ZenFlow widget
/// Manages when and how the widget data is refreshed
struct ZenFlowWidgetProvider: TimelineProvider {

    // MARK: - TimelineProvider Protocol

    /// Provides a placeholder entry for the widget while loading
    /// This is shown in the widget gallery before the widget is added
    func placeholder(in context: Context) -> ZenFlowWidgetEntry {
        return ZenFlowWidgetEntry.placeholder()
    }

    /// Provides a snapshot entry for quick preview
    /// Used when the widget needs to display quickly (e.g., widget gallery)
    /// - Parameters:
    ///   - context: The context in which the snapshot is being generated
    ///   - completion: Completion handler to call with the snapshot entry
    func getSnapshot(in context: Context, completion: @escaping (ZenFlowWidgetEntry) -> Void) {
        // For previews and widget gallery, fetch real data if possible
        let widgetData = SharedDataManager.getWidgetData()
        let entry = ZenFlowWidgetEntry.fromWidgetData(widgetData)
        completion(entry)
    }

    /// Provides the timeline of entries for the widget
    /// This determines when the widget will refresh and what data it will show
    /// - Parameters:
    ///   - context: The context in which the timeline is being generated
    ///   - completion: Completion handler to call with the timeline
    func getTimeline(in context: Context, completion: @escaping (Timeline<ZenFlowWidgetEntry>) -> Void) {
        // Fetch current widget data from App Group UserDefaults
        let widgetData = SharedDataManager.getWidgetData()

        // Create entry with current data
        let currentDate = Date()
        let entry = ZenFlowWidgetEntry.fromWidgetData(widgetData, at: currentDate)

        // Create timeline with single entry
        // Policy: .never means the widget won't auto-refresh
        // The main app will explicitly reload the widget using WidgetCenter.shared.reloadAllTimelines()
        // when the user completes a meditation session or when data changes
        let timeline = Timeline(entries: [entry], policy: .never)

        // Alternative policy options:
        // .atEnd - Widget refreshes after the current entry expires (good for scheduled updates)
        // .after(date) - Widget refreshes at a specific date/time
        // .never - Widget only refreshes when explicitly requested by the app

        completion(timeline)
    }
}

// MARK: - Widget Reload Helpers

/// Extension to provide helper methods for reloading widgets from the main app
extension ZenFlowWidgetProvider {

    /// Call this method from the main app to reload all ZenFlow widgets
    /// Example usage in LocalDataManager after saving a session:
    ///
    /// ```swift
    /// import WidgetKit
    ///
    /// func saveSession(durationMinutes: Int) {
    ///     // ... save session logic ...
    ///
    ///     // Reload widgets to show updated data
    ///     WidgetCenter.shared.reloadAllTimelines()
    /// }
    /// ```
    static func reloadAllWidgets() {
        #if !targetEnvironment(simulator)
        // Only reload on real devices (simulators can be flaky)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    /// Reload only ZenFlow widgets (more efficient than reloading all widgets)
    /// Use the widget kind string from your ZenFlowWidget configuration
    static func reloadZenFlowWidgets(kind: String = "ZenFlowWidget") {
        #if !targetEnvironment(simulator)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        #endif
    }
}

// MARK: - Preview Provider for Xcode Previews

/// Simplified provider for Xcode previews
struct ZenFlowWidgetProvider_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Beginner preview
            ZenFlowWidgetEntryView(entry: .beginnerEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Beginner - Seed Stage")

            // Intermediate preview
            ZenFlowWidgetEntryView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Intermediate - Sapling")

            // Advanced preview
            ZenFlowWidgetEntryView(entry: .advancedEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Advanced - Ancient Tree")

            // Lock screen preview
            ZenFlowLockScreenView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Lock Screen Widget")
        }
    }
}

// MARK: - Implementation Notes

/*
 TIMELINE UPDATE STRATEGY:

 The widget uses a `.never` refresh policy, which means it only updates when
 explicitly requested by the main app. This is the most efficient approach for
 meditation tracking where data changes are triggered by user actions.

 TO ENABLE WIDGET UPDATES FROM MAIN APP:

 1. Import WidgetKit in your LocalDataManager or wherever you save sessions:
    ```swift
    import WidgetKit
    ```

 2. Add this line after saving a meditation session:
    ```swift
    WidgetCenter.shared.reloadAllTimelines()
    ```

 3. Example implementation in LocalDataManager:
    ```swift
    func saveSession(durationMinutes: Int) {
        let session = SessionData(
            date: Date(),
            durationMinutes: durationMinutes,
            dateString: DateFormatter.shortDate.string(from: Date())
        )

        // Save to UserDefaults
        var sessions = getSessions()
        sessions.append(session)
        defaults.set(try? JSONEncoder().encode(sessions), forKey: "sessions")

        // Update totals
        let total = totalMinutes + durationMinutes
        defaults.set(total, forKey: "totalMinutes")

        // Update streak
        updateStreak()

        // RELOAD WIDGETS - Add this line
        WidgetCenter.shared.reloadAllTimelines()
    }
    ```

 APP GROUP SETUP:

 Don't forget to configure App Groups in Xcode:
 1. Select your main app target → Signing & Capabilities
 2. Click "+ Capability" → Add "App Groups"
 3. Create/select group: "group.com.zenflow.app"
 4. Repeat steps 1-3 for the ZenFlowWidget target
 5. Update SharedDataManager.appGroupIdentifier if using a different group name
 6. Update LocalDataManager to use App Group UserDefaults instead of standard UserDefaults:
    ```swift
    private let defaults = UserDefaults(suiteName: "group.com.zenflow.app")!
    ```
 */
