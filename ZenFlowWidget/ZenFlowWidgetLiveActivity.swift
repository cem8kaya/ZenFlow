//
//  ZenFlowWidgetLiveActivity.swift
//  ZenFlowWidget
//
//  Created by Cem Kaya on 11/24/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ZenFlowWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

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
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
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

extension ZenFlowWidgetAttributes {
    fileprivate static var preview: ZenFlowWidgetAttributes {
        ZenFlowWidgetAttributes(name: "World")
    }
}

extension ZenFlowWidgetAttributes.ContentState {
    fileprivate static var smiley: ZenFlowWidgetAttributes.ContentState {
        ZenFlowWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ZenFlowWidgetAttributes.ContentState {
         ZenFlowWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ZenFlowWidgetAttributes.preview) {
   ZenFlowWidgetLiveActivity()
} contentStates: {
    ZenFlowWidgetAttributes.ContentState.smiley
    ZenFlowWidgetAttributes.ContentState.starEyes
}
