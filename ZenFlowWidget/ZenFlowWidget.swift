//
//  ZenFlowWidget.swift
//  ZenFlowWidget
//
//  Created by ZenFlow Widget Extension
//  Main widget configuration and entry point
//

import WidgetKit
import SwiftUI

/// Main widget configuration for ZenFlow
@main
struct ZenFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        // System widget (small, medium, large)
        ZenFlowWidget()

        // Lock screen widgets (iOS 16+)
        if #available(iOS 16.0, *) {
            ZenFlowLockScreenWidget()
        }
    }
}

// MARK: - System Widget (Home Screen)

/// Main ZenFlow widget for home screen
/// Supports systemSmall, systemMedium, and systemLarge families
struct ZenFlowWidget: Widget {
    let kind: String = "ZenFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenFlowWidgetProvider()) { entry in
            ZenFlowWidgetView(entry: entry)
        }
        .configurationDisplayName("ZenFlow")
        .description("Meditasyon ilerlemenizi ve ağaç büyümenizi takip edin.")
        .supportedFamilies([.systemSmall]) // Start with small, can add .systemMedium, .systemLarge later
        .contentMarginsDisabled() // iOS 17+ feature for edge-to-edge content
    }
}

/// Widget view that adapts to different widget families
struct ZenFlowWidgetView: View {
    let entry: ZenFlowWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            ZenFlowWidgetEntryView(entry: entry)

        case .systemMedium:
            ZenFlowMediumWidgetView(entry: entry)

        case .systemLarge:
            ZenFlowLargeWidgetView(entry: entry)

        default:
            ZenFlowWidgetEntryView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widgets (iOS 16+)

@available(iOS 16.0, *)
struct ZenFlowLockScreenWidget: Widget {
    let kind: String = "ZenFlowLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenFlowWidgetProvider()) { entry in
            ZenFlowLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("ZenFlow Seri")
        .description("Kilit ekranında meditasyon serinizi görüntüleyin.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

@available(iOS 16.0, *)
struct ZenFlowLockScreenWidgetView: View {
    let entry: ZenFlowWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            ZenFlowLockScreenView(entry: entry)

        case .accessoryCircular:
            ZenFlowLockScreenCircularView(entry: entry)

        case .accessoryInline:
            ZenFlowLockScreenInlineView(entry: entry)

        default:
            ZenFlowLockScreenView(entry: entry)
        }
    }
}

// MARK: - Medium Widget View

/// Medium-sized widget showing more detailed information
struct ZenFlowMediumWidgetView: View {
    let entry: ZenFlowWidgetEntry

    var body: some View {
        ZStack {
            Color.zenBackgroundGradient
                .ignoresSafeArea()

            HStack(spacing: 16) {
                // Left side: Tree with progress circle
                ZStack {
                    Circle()
                        .stroke(Color.zenSecondary.opacity(0.3), lineWidth: 10)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: entry.treeStage.progress)
                        .stroke(
                            Color.zenAccentGradient,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: entry.treeStage.iconName)
                        .font(.system(size: 44, weight: .regular))
                        .foregroundStyle(Color.zenTreeGradient)
                }
                .frame(width: 100)

                // Right side: Stats
                VStack(alignment: .leading, spacing: 12) {
                    // Tree stage
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.treeStage.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.zenTextHighlight)

                        Text("\(entry.progressPercentage)% sonraki aşamaya")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.zenSecondary)
                    }

                    Divider()
                        .background(Color.zenSecondary.opacity(0.3))

                    // Total minutes
                    StatRow(
                        icon: "timer",
                        label: "Toplam",
                        value: entry.formattedMinutes
                    )

                    // Current streak
                    StatRow(
                        icon: "flame.fill",
                        label: "Seri",
                        value: entry.formattedStreak,
                        iconColor: .orange
                    )

                    // Longest streak
                    StatRow(
                        icon: "star.fill",
                        label: "En Uzun",
                        value: "\(entry.longestStreak) gün",
                        iconColor: .yellow
                    )
                }

                Spacer()
            }
            .padding(16)
        }
    }
}

// MARK: - Large Widget View

/// Large-sized widget with comprehensive statistics
struct ZenFlowLargeWidgetView: View {
    let entry: ZenFlowWidgetEntry

    var body: some View {
        ZStack {
            Color.zenBackgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("ZenFlow")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.zenTextHighlight)
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.zenSageGreen)
                }

                // Main tree display
                ZStack {
                    Circle()
                        .stroke(Color.zenSecondary.opacity(0.3), lineWidth: 12)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: entry.treeStage.progress)
                        .stroke(
                            Color.zenAccentGradient,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Image(systemName: entry.treeStage.iconName)
                            .font(.system(size: 52, weight: .regular))
                            .foregroundStyle(Color.zenTreeGradient)

                        Text(entry.treeStage.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.zenSageGreen)
                    }
                }

                // Progress text
                if let minutesUntilNext = entry.minutesUntilNextStage {
                    Text("Sonraki aşamaya \(minutesUntilNext) dk")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.zenSecondary)
                } else {
                    Text("Maksimum seviye! 🎉")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.zenAccent)
                }

                Divider()
                    .background(Color.zenSecondary.opacity(0.3))

                // Statistics grid
                HStack(spacing: 20) {
                    StatCard(
                        icon: "timer",
                        title: "Toplam Süre",
                        value: entry.formattedMinutes
                    )

                    StatCard(
                        icon: "flame.fill",
                        title: "Güncel Seri",
                        value: "\(entry.currentStreak) gün",
                        iconColor: .orange
                    )

                    StatCard(
                        icon: "star.fill",
                        title: "En Uzun Seri",
                        value: "\(entry.longestStreak) gün",
                        iconColor: .yellow
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Helper Views

/// Stat row for medium widget
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var iconColor: Color = .zenAccent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(iconColor)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.zenTextHighlight.opacity(0.7))

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.zenTextHighlight)
        }
    }
}

/// Stat card for large widget
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    var iconColor: Color = .zenAccent

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.zenTextHighlight.opacity(0.7))
                .multilineTextAlignment(.center)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.zenTextHighlight)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

struct ZenFlowWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small widget
            ZenFlowWidgetEntryView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")

            // Medium widget
            ZenFlowMediumWidgetView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")

            // Large widget
            ZenFlowLargeWidgetView(entry: .advancedEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
        }
    }
}
