//
//  DailyZenMomentView.swift
//  ZenFlow
//
//  Created by Claude AI on 13.07.2026.
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Daily zen ritual sheet: shows the teaching of the day from the
//  wisdom library and invites the user to write a one-line gratitude
//  note. A streak counter rewards returning every day.
//

import SwiftUI

struct DailyZenMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dailyZen = DailyZenManager.shared

    @State private var gratitudeText: String = ""
    @State private var showSavedConfirmation = false
    @FocusState private var isGratitudeFocused: Bool

    private var teaching: ZenTeaching {
        dailyZen.teachingOfTheDay
    }

    private var teachingCategory: ZenCategory {
        ZenCategory(rawValue: teaching.category) ?? .mindfulness
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZenTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Date + streak header
                        headerView

                        // Teaching of the day
                        teachingCard

                        // Gratitude journal
                        gratitudeCard

                        // Recent gratitude notes
                        if !dailyZen.recentEntries().isEmpty {
                            recentEntriesCard
                        }

                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(String(localized: "daily_zen_title", defaultValue: "Günün Zen Anı", comment: "Daily Zen Moment title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "daily_zen_done", defaultValue: "Tamam", comment: "Done button")) {
                        dismiss()
                    }
                    .foregroundColor(ZenTheme.lightLavender)
                }
            }
            .onAppear {
                gratitudeText = dailyZen.todayEntry?.text ?? ""
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(), style: .date)
                    .font(.system(size: 14))
                    .foregroundColor(ZenTheme.softPurple)

                Text(String(localized: "daily_zen_greeting", defaultValue: "Bugün için bir an dur", comment: "Daily zen greeting"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)
            }

            Spacer()

            // Gratitude streak
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                Text("\(dailyZen.currentStreak)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
            .accessibilityLabel(String(localized: "daily_zen_streak_accessibility", defaultValue: "Şükran serisi: \(dailyZen.currentStreak) gün", comment: "Gratitude streak accessibility"))
        }
    }

    // MARK: - Teaching Card

    private var teachingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category chip
            HStack(spacing: 8) {
                Image(systemName: ZenWisdomLibrary.shared.iconForCategory(teachingCategory))
                    .font(.system(size: 14))

                Text(teachingCategory.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(ZenTheme.lightLavender)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(ZenTheme.mysticalViolet.opacity(0.3))
            )

            // Title
            Text(teaching.title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(ZenTheme.lightLavender)

            // Content
            Text(teaching.content)
                .font(.system(size: 16))
                .foregroundColor(ZenTheme.lightLavender.opacity(0.85))
                .lineSpacing(4)

            // Quote
            if let quote = teaching.quote, !quote.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\u{201C}\(quote)\u{201D}")
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(ZenTheme.softPurple)

                    if let author = teaching.author, !author.isEmpty {
                        Text("— \(author)")
                            .font(.system(size: 14))
                            .foregroundColor(ZenTheme.softPurple.opacity(0.8))
                    }
                }
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ZenTheme.mysticalViolet.opacity(0.6))
                        .frame(width: 3)
                }
            }

            // Practical advice
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow.opacity(0.8))

                Text(teaching.practicalAdvice)
                    .font(.system(size: 14))
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.8))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Gratitude Card

    private var gratitudeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.pink.opacity(0.8))

                Text(String(localized: "daily_zen_gratitude_title", defaultValue: "Bugün ne için minnettarsın?", comment: "Gratitude question"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)
            }

            TextField(
                String(localized: "daily_zen_gratitude_placeholder", defaultValue: "Tek bir cümle yeter...", comment: "Gratitude placeholder"),
                text: $gratitudeText,
                axis: .vertical
            )
            .lineLimit(2...4)
            .focused($isGratitudeFocused)
            .padding(12)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )

            Button(action: saveGratitude) {
                HStack {
                    Spacer()
                    Image(systemName: showSavedConfirmation ? "checkmark.circle.fill" : "leaf.fill")
                        .font(.system(size: 16))
                    Text(showSavedConfirmation
                         ? String(localized: "daily_zen_gratitude_saved", defaultValue: "Kaydedildi", comment: "Gratitude saved")
                         : String(localized: "daily_zen_gratitude_save", defaultValue: "Kaydet", comment: "Save gratitude button"))
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: showSavedConfirmation
                                    ? [ZenTheme.sageGreen, ZenTheme.deepSage]
                                    : [ZenTheme.calmBlue, ZenTheme.mysticalViolet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(gratitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(gratitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Recent Entries

    private var recentEntriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "daily_zen_recent_title", defaultValue: "Son Notların", comment: "Recent gratitude notes title"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ZenTheme.lightLavender)

            ForEach(dailyZen.recentEntries()) { entry in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ZenTheme.sageGreen)
                        .padding(.top, 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(ZenTheme.softPurple)

                        Text(entry.text)
                            .font(.system(size: 14))
                            .foregroundColor(ZenTheme.lightLavender.opacity(0.85))
                    }

                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func saveGratitude() {
        dailyZen.saveTodayGratitude(gratitudeText)
        isGratitudeFocused = false
        HapticManager.shared.playSessionComplete()

        withAnimation(.easeInOut(duration: 0.3)) {
            showSavedConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSavedConfirmation = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DailyZenMomentView()
}
