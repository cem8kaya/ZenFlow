//
//  ZenFlowWidget.swift
//  ZenFlowWidget
//
//  Created by Cem Kaya on 11/24/25.
//

import WidgetKit
import SwiftUI

struct ZenFlowWidget: Widget {
    let kind: String = "ZenFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenFlowWidgetProvider()) { entry in
            ZenFlowWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(String(localized: "widget_config_name", defaultValue: "ZenFlow Widget", comment: "Main widget configuration name"))
        .description(String(localized: "widget_config_description", defaultValue: "Meditasyon ilerlemenizi ve ağacınızı takip edin", comment: "Main widget configuration description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Lock Screen Widgets

struct ZenFlowLockScreenWidget: Widget {
    let kind: String = "ZenFlowLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenFlowWidgetProvider()) { entry in
            ZenFlowLockScreenView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget_lockscreen_config_name", defaultValue: "ZenFlow Kilit Ekranı", comment: "Lock screen widget configuration name"))
        .description(String(localized: "widget_lockscreen_config_description", defaultValue: "Meditasyon serinizi kilit ekranında görün", comment: "Lock screen widget configuration description"))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct ZenFlowLockScreenCircularWidget: Widget {
    let kind: String = "ZenFlowLockScreenCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenFlowWidgetProvider()) { entry in
            ZenFlowLockScreenCircularView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget_circular_config_name", defaultValue: "ZenFlow Dairesel", comment: "Circular widget configuration name"))
        .description(String(localized: "widget_circular_config_description", defaultValue: "Kompakt dairesel widget", comment: "Circular widget configuration description"))
        .supportedFamilies([.accessoryCircular])
    }
}

struct ZenFlowLockScreenInlineWidget: Widget {
    let kind: String = "ZenFlowLockScreenInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenFlowWidgetProvider()) { entry in
            ZenFlowLockScreenInlineView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget_inline_config_name", defaultValue: "ZenFlow Satır İçi", comment: "Inline widget configuration name"))
        .description(String(localized: "widget_inline_config_description", defaultValue: "Tek satırlık seri göstergesi", comment: "Inline widget configuration description"))
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Preview

#Preview("Small Widget", as: .systemSmall) {
    ZenFlowWidget()
} timeline: {
    ZenFlowWidgetEntry.beginnerEntry
    ZenFlowWidgetEntry.intermediateEntry
    ZenFlowWidgetEntry.advancedEntry
}

#Preview("Medium Widget", as: .systemMedium) {
    ZenFlowWidget()
} timeline: {
    ZenFlowWidgetEntry.beginnerEntry
    ZenFlowWidgetEntry.intermediateEntry
    ZenFlowWidgetEntry.advancedEntry
}
