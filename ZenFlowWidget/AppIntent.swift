//
//  AppIntent.swift
//  ZenFlowWidget
//
//  Created by Cem Kaya on 11/24/25.
//
import WidgetKit
import AppIntents

// iOS 17.0 kontrolü ekleyin
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}
