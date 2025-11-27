//
//  ZenFlowWidgetLiveActivity.swift
//  ZenFlowWidget
//
//  Created by Cem Kaya on 11/24/25.
//
// ZenFlowWidget/ZenFlowWidgetLiveActivity.swift

import ActivityKit
import WidgetKit
import SwiftUI

// Canlı etkinlikler iOS 16.1 gerektirir
@available(iOS 16.1, *)
struct ZenFlowWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

// Widget yapısı iOS 16.1 gerektirir
@available(iOS 16.1, *)
struct ZenFlowWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ZenFlowWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

// Önizleme yardımcıları iOS 16.1+ olabilir
@available(iOS 16.1, *)
extension ZenFlowWidgetAttributes {
    fileprivate static var preview: ZenFlowWidgetAttributes {
        ZenFlowWidgetAttributes(name: "World")
    }
}

@available(iOS 16.1, *)
extension ZenFlowWidgetAttributes.ContentState {
    fileprivate static var smiley: ZenFlowWidgetAttributes.ContentState {
        ZenFlowWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ZenFlowWidgetAttributes.ContentState {
         ZenFlowWidgetAttributes.ContentState(emoji: "🤩")
     }
}

// 🚨 KRİTİK DÜZELTME: Widget #Preview makrosu iOS 17.0+ gerektirir
@available(iOS 17.0, *)
#Preview("Notification", as: .content, using: ZenFlowWidgetAttributes.preview) {
   ZenFlowWidgetLiveActivity()
} contentStates: {
    ZenFlowWidgetAttributes.ContentState.smiley
    ZenFlowWidgetAttributes.ContentState.starEyes
}
