//
//  ZenSessionLiveActivity.swift
//  ZenFlowWidget
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Lock screen banner and Dynamic Island for a running breathing, focus or
//  silent meditation session: the exercise name and a live countdown.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct ZenSessionLiveActivity: Widget {

    private let deepIndigo = Color(red: 0.18, green: 0.15, blue: 0.35)
    private let lavender = Color(red: 0.85, green: 0.80, blue: 0.95)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ZenSessionActivityAttributes.self) { context in
            // Lock screen / banner
            HStack(spacing: 14) {
                Image(systemName: context.attributes.kind.iconName)
                    .font(.title2)
                    .foregroundStyle(lavender)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if context.state.isPaused {
                        Text("Paused")
                            .font(.caption)
                            .foregroundStyle(lavender.opacity(0.7))
                    }
                }

                Spacer()

                countdown(for: context.state)
                    .font(.system(size: 30, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
            }
            .padding(16)
            .activityBackgroundTint(deepIndigo)
            .activitySystemActionForegroundColor(.white)
            .widgetURL(URL(string: context.attributes.kind.deepLink))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.kind.iconName)
                        .font(.title2)
                        .foregroundStyle(lavender)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(for: context.state)
                        .font(.system(size: 26, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.title)
                        .font(.subheadline)
                        .foregroundStyle(lavender)
                }
            } compactLeading: {
                Image(systemName: context.attributes.kind.iconName)
                    .foregroundStyle(lavender)
            } compactTrailing: {
                countdown(for: context.state)
                    .font(.caption.monospacedDigit())
                    .frame(width: 46)
            } minimal: {
                Image(systemName: context.attributes.kind.iconName)
                    .foregroundStyle(lavender)
            }
            .widgetURL(URL(string: context.attributes.kind.deepLink))
        }
    }

    /// Live countdown, or the frozen remaining time while paused
    @ViewBuilder
    private func countdown(for state: ZenSessionActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(Self.formatted(state.pausedRemaining))
        } else {
            // A range with lower > upper traps, so clamp when the end has passed
            let start = min(Date.now, state.endDate)
            Text(timerInterval: start...state.endDate, countsDown: true)
        }
    }

    private static func formatted(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
