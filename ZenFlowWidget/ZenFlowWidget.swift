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
            // iOS 17 ve sonrası için containerBackground kullan
            if #available(iOS 17.0, *) {
                ZenFlowWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                // iOS 16 için standart görünüm (Arka plan View içinde zaten tanımlı)
                ZenFlowWidgetEntryView(entry: entry)
                    .background(Color.zenBackgroundGradient) // Gerekirse explicit background
            }
        }
        .configurationDisplayName(String(localized: "widget_config_name", defaultValue: "ZenFlow Widget", comment: "Main widget configuration name"))
        .description(String(localized: "widget_config_description", defaultValue: "Meditasyon ilerlemenizi ve ağacınızı takip edin", comment: "Main widget configuration description"))
        .supportedFamilies([.systemSmall, .systemMedium])
        // iOS 15/16 için içerik kenar boşluklarını kaldırmak gerekebilir
        .contentMarginsDisabledIfAvailable()
    }
}

// MARK: - Helper Extension for iOS 15/16 Margins
extension WidgetConfiguration {
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        if #available(iOS 15.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
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

// MARK: - Preview (iOS 17+ Only)

@available(iOS 17.0, *)
#Preview("Small Widget", as: .systemSmall) {
    ZenFlowWidget()
} timeline: {
    ZenFlowWidgetEntry.beginnerEntry
    ZenFlowWidgetEntry.intermediateEntry
    ZenFlowWidgetEntry.advancedEntry
}

@available(iOS 17.0, *)
#Preview("Medium Widget", as: .systemMedium) {
    ZenFlowWidget()
} timeline: {
    ZenFlowWidgetEntry.beginnerEntry
    ZenFlowWidgetEntry.intermediateEntry
    ZenFlowWidgetEntry.advancedEntry
}
