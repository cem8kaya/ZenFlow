//
//  ZenFlowWidgetViews.swift
//  ZenFlowWidget
//
//  Created by ZenFlow Widget Extension
//  SwiftUI views for ZenFlow widgets using ZenTheme styling
//

import SwiftUI
import WidgetKit

// MARK: - ZenTheme Colors for Widget
// Extracted from the main app's ZenTheme for use in the widget extension

extension Color {
    /// ZenFlow primary colors matching the main app theme
    static let zenPrimary = Color(red: 0.18, green: 0.15, blue: 0.35)          // Deep indigo
    static let zenSecondary = Color(red: 0.45, green: 0.35, blue: 0.65)        // Soft purple
    static let zenAccent = Color(red: 0.55, green: 0.40, blue: 0.75)           // Mystical violet
    static let zenTextHighlight = Color(red: 0.85, green: 0.80, blue: 0.95)    // Light lavender
    static let zenSageGreen = Color(red: 0.42, green: 0.56, blue: 0.14)        // Sage green
    static let zenDeepSage = Color(red: 0.13, green: 0.55, blue: 0.13)         // Deep sage

    /// Background gradient matching main app
    static var zenBackgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [zenPrimary, Color.black]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Accent gradient for progress indicators
    static var zenAccentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [zenSecondary, zenAccent]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Tree growth gradient
    static var zenTreeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [zenSageGreen, zenDeepSage]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - System Small Widget View

/// Main widget view for systemSmall and systemMedium families
/// Shows tree icon with circular progress indicator
struct ZenFlowWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: ZenFlowWidgetEntry

    var body: some View {
        ZStack {
            // Background gradient
            Color.zenBackgroundGradient
                .ignoresSafeArea()

            if widgetFamily == .systemMedium {
                mediumWidgetContent
            } else {
                smallWidgetContent
            }
        }
    }

    // MARK: - Small Widget Content
    private var smallWidgetContent: some View {
        VStack(spacing: 8) {
            // Top row: Total minutes
            HStack {
                Text(entry.formattedMinutes)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.zenTextHighlight)
                Spacer()
            }

            Spacer()

            // Center: Tree icon with circular progress
            treeProgressView(size: 80, iconSize: 36, lineWidth: 8)

            Spacer()

            // Bottom row: Streak and stage info
            HStack {
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("\(entry.currentStreak)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.zenTextHighlight)
                }

                Spacer()

                // Stage name
                Text(entry.treeStage.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.zenSageGreen)
            }
        }
        .padding(12)
    }

    // MARK: - Medium Widget Content
    private var mediumWidgetContent: some View {
        HStack(spacing: 16) {
            // Left side: Tree with progress
            VStack(spacing: 8) {
                treeProgressView(size: 100, iconSize: 44, lineWidth: 10)

                Text(entry.treeStage.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.zenSageGreen)
            }
            .frame(maxWidth: .infinity)

            // Right side: Stats
            VStack(alignment: .leading, spacing: 12) {
                // Total meditation time
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "widget_total_time", defaultValue: "Toplam Süre", comment: "Total meditation time label"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.zenTextHighlight.opacity(0.7))

                    Text(entry.formattedMinutes)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.zenTextHighlight)
                }

                Divider()
                    .background(Color.zenSecondary.opacity(0.3))

                // Current streak
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "widget_daily_streak", defaultValue: "Günlük Seri", comment: "Daily streak label"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.zenTextHighlight.opacity(0.7))

                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text(String(localized: "widget_days_count", defaultValue: "\(entry.currentStreak) Gün", comment: "Days count with number"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.zenTextHighlight)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }

    // MARK: - Reusable Tree Progress View
    private func treeProgressView(size: CGFloat, iconSize: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.zenSecondary.opacity(0.3), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress circle
            Circle()
                .trim(from: 0, to: entry.treeStage.progress)
                .stroke(
                    Color.zenAccentGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: entry.treeStage.progress)

            // Tree icon
            Image(systemName: entry.treeStage.iconName)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(Color.zenTreeGradient)
        }
    }
}

// MARK: - Lock Screen Widget View

/// Lock screen widget view (accessoryRectangular)
/// Shows streak count with motivating icon
struct ZenFlowLockScreenView: View {
    let entry: ZenFlowWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left: Streak icon
            Image(systemName: "flame.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.orange)

            // Right: Streak information
            VStack(alignment: .leading, spacing: 2) {
                // Streak count
                Text(String(localized: "widget_days_streak", defaultValue: "\(entry.currentStreak) Gün Serisi", comment: "Days streak with count"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                // Tree stage
                HStack(spacing: 4) {
                    Image(systemName: entry.treeStage.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text(entry.treeStage.name)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Alternative Lock Screen Views

/// Circular lock screen widget (accessoryCircular)
/// Compact circular design for lock screen
struct ZenFlowLockScreenCircularView: View {
    let entry: ZenFlowWidgetEntry

    var body: some View {
        ZStack {
            // Background circle with progress
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 4)

            Circle()
                .trim(from: 0, to: entry.treeStage.progress)
                .stroke(
                    Color.green,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 2) {
                Image(systemName: entry.treeStage.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(entry.currentStreak)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}

/// Inline lock screen widget (accessoryInline)
/// Single line text for lock screen inline placement
struct ZenFlowLockScreenInlineView: View {
    let entry: ZenFlowWidgetEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.fill")
            Text(String(localized: "widget_streak_inline", defaultValue: "\(entry.currentStreak) gün serisi", comment: "Inline streak count"))
            Text("•")
            Text(String(localized: "widget_minutes_inline", defaultValue: "\(entry.totalMinutes) dk", comment: "Inline minutes count"))
        }
        .font(.system(size: 14, weight: .medium, design: .rounded))
    }
}

// MARK: - Preview Provider

struct ZenFlowWidgetViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // System Small Widget Previews
            ZenFlowWidgetEntryView(entry: .beginnerEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - Beginner (Seed)")

            ZenFlowWidgetEntryView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - Intermediate (Sapling)")

            ZenFlowWidgetEntryView(entry: .advancedEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - Advanced (Ancient)")

            // System Medium Widget Previews
            ZenFlowWidgetEntryView(entry: .beginnerEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - Beginner (Seed)")

            ZenFlowWidgetEntryView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - Intermediate (Sapling)")

            ZenFlowWidgetEntryView(entry: .advancedEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - Advanced (Ancient)")

            // Lock Screen Rectangular
            ZenFlowLockScreenView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Lock Screen - Rectangular")

            // Lock Screen Circular
            ZenFlowLockScreenCircularView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Lock Screen - Circular")

            // Lock Screen Inline
            ZenFlowLockScreenInlineView(entry: .intermediateEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Lock Screen - Inline")
        }
    }
}

// MARK: - Helper Extensions

extension ZenFlowWidgetEntry {
    /// Get a motivational message based on current streak
    var motivationalMessage: String {
        switch currentStreak {
        case 0:
            return String(localized: "widget_message_new_start", defaultValue: "Yeni bir başlangıç!", comment: "New beginning motivational message")
        case 1...6:
            return String(localized: "widget_message_great_going", defaultValue: "Harika gidiyorsun!", comment: "Great progress motivational message")
        case 7...13:
            return String(localized: "widget_message_week_completed", defaultValue: "Bir hafta tamamlandı! 🎉", comment: "One week completed motivational message")
        case 14...29:
            return String(localized: "widget_message_amazing_progress", defaultValue: "İnanılmaz ilerleme!", comment: "Amazing progress motivational message")
        case 30...89:
            return String(localized: "widget_message_month_passed", defaultValue: "Bir ay geçti! Muhteşem! 🌟", comment: "One month passed motivational message")
        case 90...179:
            return String(localized: "widget_message_ninety_days", defaultValue: "90 gün! Efsane! 💪", comment: "90 days completed motivational message")
        default:
            return String(localized: "widget_message_zen_master", defaultValue: "Zen ustası! 🧘‍♂️", comment: "Zen master motivational message")
        }
    }

    /// Get color for streak based on milestone
    var streakColor: Color {
        switch currentStreak {
        case 0:
            return .gray
        case 1...6:
            return .orange
        case 7...29:
            return .yellow
        case 30...89:
            return .green
        default:
            return .purple
        }
    }
}
