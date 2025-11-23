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
        .configurationDisplayName("ZenFlow Widget")
        .description("Meditasyon ilerlemenizi ve ağacınızı takip edin")
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
        .configurationDisplayName("ZenFlow Kilit Ekranı")
        .description("Meditasyon serinizi kilit ekranında görün")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct ZenFlowLockScreenCircularWidget: Widget {
    let kind: String = "ZenFlowLockScreenCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenFlowWidgetProvider()) { entry in
            ZenFlowLockScreenCircularView(entry: entry)
        }
        .configurationDisplayName("ZenFlow Dairesel")
        .description("Kompakt dairesel widget")
        .supportedFamilies([.accessoryCircular])
    }
}

struct ZenFlowLockScreenInlineWidget: Widget {
    let kind: String = "ZenFlowLockScreenInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenFlowWidgetProvider()) { entry in
            ZenFlowLockScreenInlineView(entry: entry)
        }
        .configurationDisplayName("ZenFlow Satır İçi")
        .description("Tek satırlık seri göstergesi")
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
