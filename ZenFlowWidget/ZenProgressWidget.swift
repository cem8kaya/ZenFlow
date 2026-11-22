//
//  ZenProgressWidget.swift
//  ZenFlowWidget
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Home screen (small, medium) and lock screen (circular, rectangular, inline)
//  widget: streak, weekly goal, today's minutes and the teaching of the day.
//  Data comes from WidgetSnapshot, written by the app into the App Group.
//

import SwiftUI
import WidgetKit

// MARK: - Palette (the extension cannot see the app's ZenTheme)

private enum WidgetPalette {
    static let deepIndigo = Color(red: 0.18, green: 0.15, blue: 0.35)
    static let night = Color(red: 0.07, green: 0.06, blue: 0.14)
    static let lavender = Color(red: 0.85, green: 0.80, blue: 0.95)
    static let softPurple = Color(red: 0.62, green: 0.52, blue: 0.82)
    static let calmBlue = Color(red: 0.35, green: 0.45, blue: 0.85)
    static let violet = Color(red: 0.55, green: 0.40, blue: 0.75)

    static var background: LinearGradient {
        LinearGradient(colors: [deepIndigo, night], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Timeline

struct ZenEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct ZenProvider: TimelineProvider {

    /// Shown before the app has ever written data
    private var emptySnapshot: WidgetSnapshot {
        WidgetSnapshot(
            streak: 0,
            streakExpiresAt: nil,
            totalMinutes: 0,
            minutesToday: 0,
            activeDaysThisWeek: 0,
            weeklyGoalDays: 5,
            treeStageName: "",
            treeProgress: 0,
            teachingTitle: "",
            teachingQuote: "",
            generatedAt: Date()
        )
    }

    func placeholder(in context: Context) -> ZenEntry {
        ZenEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ZenEntry) -> Void) {
        let snapshot = context.isPreview ? WidgetSnapshot.placeholder : (WidgetSnapshot.load() ?? emptySnapshot)
        completion(ZenEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZenEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load() ?? emptySnapshot
        let now = Date()
        let calendar = Calendar.current

        // Re-evaluate at the moments the display changes by itself: when the
        // streak expires and at midnight (minutes today, teaching of the day)
        let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime)
            ?? now.addingTimeInterval(3600 * 6)

        var dates: [Date] = [now]
        if let expiry = snapshot.streakExpiresAt, expiry > now {
            dates.append(expiry)
        }
        dates.append(midnight)

        let entries = Set(dates).sorted().map { ZenEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }
}

// MARK: - Widget

struct ZenProgressWidget: Widget {
    let kind = "ZenProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenProvider()) { entry in
            ZenProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Zen Progress")
        .description("Your streak, weekly goal and today's teaching.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Views

struct ZenProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ZenEntry

    private var streak: Int { entry.snapshot.displayedStreak(at: entry.date) }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .accessoryCircular:
                circularView
            case .accessoryRectangular:
                rectangularView
            case .accessoryInline:
                inlineView
            default:
                smallView
            }
        }
        .widgetURL(URL(string: "zenflow://breathing"))
        .containerBackground(for: .widget) {
            WidgetPalette.background
        }
    }

    // MARK: Home screen

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Day streak")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WidgetPalette.lavender.opacity(0.7))
            }

            Text("\(streak)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 0)

            weeklyGoalBar
        }
    }

    private var mediumView: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Day streak")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WidgetPalette.lavender.opacity(0.7))
                }

                Text("\(streak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer(minLength: 0)

                weeklyGoalBar
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text("\(entry.snapshot.displayedMinutesToday(at: entry.date)) min today")
                } icon: {
                    Image(systemName: "clock.fill")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(WidgetPalette.lavender)

                if !entry.snapshot.treeStageName.isEmpty {
                    Label {
                        Text(entry.snapshot.treeStageName)
                    } icon: {
                        Image(systemName: "tree.fill")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WidgetPalette.lavender)
                }

                Spacer(minLength: 0)

                if entry.snapshot.hasTeachingForToday(at: entry.date) {
                    Text(entry.snapshot.teachingTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    if !entry.snapshot.teachingQuote.isEmpty {
                        Text(entry.snapshot.teachingQuote)
                            .font(.system(size: 11, design: .serif).italic())
                            .foregroundStyle(WidgetPalette.softPurple)
                            .lineLimit(3)
                    }
                } else {
                    Text("Open MyZenFlow to begin")
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.softPurple)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var weeklyGoalBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: entry.snapshot.weeklyProgress)
                .tint(WidgetPalette.calmBlue)
            Text("\(entry.snapshot.activeDaysThisWeek)/\(entry.snapshot.weeklyGoalDays) days this week")
                .font(.system(size: 11))
                .foregroundStyle(WidgetPalette.lavender.opacity(0.75))
        }
    }

    // MARK: Lock screen

    private var circularView: some View {
        Gauge(value: entry.snapshot.weeklyProgress) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(streak)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text("\(streak)-day streak")
            } icon: {
                Image(systemName: "flame.fill")
            }
            .font(.headline)

            Gauge(value: entry.snapshot.weeklyProgress) {
                Text("\(entry.snapshot.activeDaysThisWeek)/\(entry.snapshot.weeklyGoalDays) days this week")
            }
            .gaugeStyle(.accessoryLinear)
        }
    }

    private var inlineView: some View {
        Label {
            Text("\(streak)-day streak")
        } icon: {
            Image(systemName: "flame.fill")
        }
    }
}

#Preview("Small", as: .systemSmall) {
    ZenProgressWidget()
} timeline: {
    ZenEntry(date: .now, snapshot: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    ZenProgressWidget()
} timeline: {
    ZenEntry(date: .now, snapshot: .placeholder)
}
