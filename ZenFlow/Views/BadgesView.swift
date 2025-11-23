//
//  BadgesView.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import SwiftUI

struct BadgesView: View {
    // MARK: - Properties

    @StateObject private var gamificationManager = GamificationManager.shared
    @State private var selectedBadge: Badge?
    @State private var showingBadgeDetail = false
    @State private var selectedTab = 0 // 0: Rozetler, 1: İstatistikler

    // Grid layout configuration
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segment Control
                    segmentControl
                        .padding(.horizontal)
                        .padding(.top, 16)

                    // Content based on selected tab
                    if selectedTab == 0 {
                        // Rozetler
                        ScrollView {
                            VStack(spacing: 24) {
                                // Header with progress
                                headerView

                                // Unlocked Badges Section
                                if !gamificationManager.unlockedBadges.isEmpty {
                                    badgeSectionView(
                                        title: "Kazanılan Rozetler",
                                        badges: gamificationManager.unlockedBadges,
                                        isUnlocked: true
                                    )
                                }

                                // Locked Badges Section
                                if !gamificationManager.lockedBadges.isEmpty {
                                    badgeSectionView(
                                        title: "Kilitli Rozetler",
                                        badges: gamificationManager.lockedBadges,
                                        isUnlocked: false
                                    )
                                }
                            }
                            .padding()
                        }
                    } else {
                        // İstatistikler
                        StatsView()
                    }
                }
            }
            .navigationTitle("Başarılar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingBadgeDetail) {
                if let badge = selectedBadge {
                    BadgeDetailView(
                        badge: badge,
                        progress: gamificationManager.getProgress(for: badge),
                        currentValue: getCurrentValue(for: badge)
                    )
                }
            }
            .overlay(
                Group {
                    if gamificationManager.showBadgeUnlockAnimation,
                       let badge = gamificationManager.newlyUnlockedBadge {
                        BadgeUnlockAnimationView(badge: badge) {
                            gamificationManager.dismissBadgeAlert()
                        }
                        .transition(.opacity)
                    }
                }
            )
        }
    }

    // MARK: - Segment Control

    private var segmentControl: some View {
        HStack(spacing: 0) {
            // Rozetler Tab
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
                HapticManager.shared.playImpact(style: .light)
            }) {
                Text("Rozetler")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(selectedTab == 0 ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedTab == 0 ? Color.white.opacity(0.2) : Color.clear)
                    )
            }

            // İstatistikler Tab
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
                HapticManager.shared.playImpact(style: .light)
            }) {
                Text("İstatistikler")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(selectedTab == 1 ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedTab == 1 ? Color.white.opacity(0.2) : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(
                        Color.white.opacity(0.2),
                        lineWidth: 8
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: gamificationManager.progressPercentage / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: gamificationManager.progressPercentage)

                VStack(spacing: 4) {
                    Text("\(gamificationManager.unlockedBadgesCount)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("/\(gamificationManager.totalBadgesCount)")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Text(String(format: "%.0f%% Tamamlandı", gamificationManager.progressPercentage))
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical)
    }

    // MARK: - Badge Section View

    @ViewBuilder
    private func badgeSectionView(title: String, badges: [Badge], isUnlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(badges) { badge in
                    BadgeCardView(
                        badge: badge,
                        isUnlocked: isUnlocked,
                        progress: gamificationManager.getProgress(for: badge)
                    )
                    .zenCardPress {
                        selectedBadge = badge
                        showingBadgeDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func getCurrentValue(for badge: Badge) -> Int {
        switch badge.requirementType {
        case .streak:
            return gamificationManager.getDailyStreak()
        case .totalMinutes:
            return LocalDataManager.shared.totalMinutes
        case .focusSessions:
            return LocalDataManager.shared.totalFocusSessions
        case .focusSessionsDaily:
            return LocalDataManager.shared.todayFocusSessions
        }
    }
}

// MARK: - Badge Card View

struct BadgeCardView: View {
    let badge: Badge
    let isUnlocked: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            // Badge Icon
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(
                                gradient: Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                isUnlocked ? Color.white.opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isUnlocked ? .purple.opacity(0.5) : .clear,
                        radius: 10,
                        x: 0,
                        y: 5
                    )

                // Icon or lock
                if isUnlocked {
                    Image(systemName: badge.iconName)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                } else {
                    ZStack {
                        Image(systemName: badge.iconName)
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.3))

                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                            .offset(x: 20, y: 20)
                    }
                }
            }

            // Badge name
            Text(badge.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Progress bar for locked badges
            if !isUnlocked {
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(min(progress / 100, 1.0)), height: 6)
                                .animation(.easeInOut, value: progress)
                        }
                    }
                    .frame(height: 6)

                    Text(String(format: "%.0f%%", progress))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isUnlocked ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isUnlocked ? Color.white.opacity(0.2) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Badge Detail View

struct BadgeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let badge: Badge
    let progress: Double
    let currentValue: Int

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Large badge icon
                        ZStack {
                            Circle()
                                .fill(
                                    badge.isUnlocked
                                        ? LinearGradient(
                                            gradient: Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            gradient: Gradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            badge.isUnlocked ? Color.white.opacity(0.3) : Color.white.opacity(0.1),
                                            lineWidth: 3
                                        )
                                )
                                .shadow(
                                    color: badge.isUnlocked ? .purple.opacity(0.6) : .clear,
                                    radius: 20,
                                    x: 0,
                                    y: 10
                                )

                            if badge.isUnlocked {
                                Image(systemName: badge.iconName)
                                    .font(.system(size: 72))
                                    .foregroundColor(.white)
                            } else {
                                ZStack {
                                    Image(systemName: badge.iconName)
                                        .font(.system(size: 72))
                                        .foregroundColor(.white.opacity(0.3))

                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white.opacity(0.6))
                                        .offset(x: 40, y: 40)
                                }
                            }
                        }
                        .padding(.top, 32)

                        // Badge info
                        VStack(spacing: 16) {
                            Text(badge.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(badge.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Progress section (for locked badges)
                        if !badge.isUnlocked {
                            VStack(spacing: 16) {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                    .padding(.horizontal)

                                VStack(spacing: 12) {
                                    Text("İlerleme")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.9))

                                    // Progress bar
                                    GeometryReader { geometry in
                                        VStack(spacing: 8) {
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white.opacity(0.2))
                                                    .frame(height: 12)

                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [.purple, .blue]),
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: geometry.size.width * CGFloat(min(progress / 100, 1.0)), height: 12)
                                                    .animation(.easeInOut, value: progress)
                                            }
                                            .frame(height: 12)

                                            HStack {
                                                Text("\(currentValue) / \(badge.requiredValue)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.8))

                                                Spacer()

                                                Text(String(format: "%.0f%%", progress))
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .frame(height: 36)
                                    .padding(.horizontal)

                                    Text(requirementText)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal)
                            }
                        } else {
                            // Unlocked date
                            if let unlockedDate = badge.unlockedDate {
                                VStack(spacing: 8) {
                                    Divider()
                                        .background(Color.white.opacity(0.2))
                                        .padding(.horizontal)

                                    VStack(spacing: 4) {
                                        Text("Kazanılma Tarihi")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))

                                        Text(unlockedDate, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .zenSecondaryButtonStyle()
                }
            }
        }
    }

    private var requirementText: String {
        switch badge.requirementType {
        case .streak:
            return "Gereken: \(badge.requiredValue) gün ardışık meditasyon"
        case .totalMinutes:
            return "Gereken: \(badge.requiredValue) dakika toplam meditasyon"
        case .focusSessions:
            return "Gereken: \(badge.requiredValue) odaklanma seansı"
        case .focusSessionsDaily:
            return "Gereken: Tek günde \(badge.requiredValue) odaklanma seansı"
        }
    }
}

// MARK: - Preview

#Preview {
    BadgesView()
}
