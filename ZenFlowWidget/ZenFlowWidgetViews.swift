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

/// Main widget view for systemSmall family
/// Shows tree icon with circular progress indicator
struct ZenFlowWidgetEntryView: View {
    let entry: ZenFlowWidgetEntry

    var body: some View {
        ZStack {
            // Background gradient
            Color.zenBackgroundGradient
                .ignoresSafeArea()

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
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.zenSecondary.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: entry.treeStage.progress)
                        .stroke(
                            Color.zenAccentGradient,
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round
                            )
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: entry.treeStage.progress)

                    // Tree icon
                    Image(systemName: entry.treeStage.iconName)
                        .font(.system(size: 36, weight: .regular))
                        .foregroundStyle(Color.zenTreeGradient)
                }

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
                Text("\(entry.currentStreak) Gün Serisi")
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
            Text("\(entry.currentStreak) gün serisi")
            Text("•")
            Text("\(entry.totalMinutes) dk")
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
            return "Yeni bir başlangıç!"
        case 1...6:
            return "Harika gidiyorsun!"
        case 7...13:
            return "Bir hafta tamamlandı! 🎉"
        case 14...29:
            return "İnanılmaz ilerleme!"
        case 30...89:
            return "Bir ay geçti! Muhteşem! 🌟"
        case 90...179:
            return "90 gün! Efsane! 💪"
        default:
            return "Zen ustası! 🧘‍♂️"
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
