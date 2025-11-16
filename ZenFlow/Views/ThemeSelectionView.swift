//
//  ThemeSelectionView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Theme selection interface allowing users to preview and select
//  different visual themes. Premium themes are locked behind subscription.
//

import SwiftUI

/// Main view for theme selection with preview cards
struct ThemeSelectionView: View {

    // MARK: - State

    @StateObject private var featureFlag = FeatureFlag.shared
    @StateObject private var hapticManager = HapticManager.shared
    @State private var showPremiumAlert = false
    @State private var selectedThemeForPreview: ThemeType?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient using current theme
            currentTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Premium status indicator
                    premiumStatusSection

                    // Theme grid
                    themeGridSection

                    // Premium benefits (if not premium)
                    if !featureFlag.isPremium {
                        premiumBenefitsSection
                    }
                }
                .padding()
            }
        }
        .alert("Premium Gerekli", isPresented: $showPremiumAlert) {
            Button("Tamam", role: .cancel) { }
            Button("Premium'a Geç") {
                // TODO: Trigger StoreKit purchase flow
            }
        } message: {
            Text("Bu tema premium üyelik gerektirir. Premium'a geçerek tüm temalara erişim sağlayabilirsiniz.")
        }
    }

    // MARK: - Computed Properties

    private var currentTheme: PremiumTheme {
        featureFlag.selectedThemeType.theme
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Temalar")
                .font(ZenTheme.largeTitle)
                .foregroundColor(currentTheme.textHighlight)

            Text("Meditasyon deneyiminizi kişiselleştirin")
                .font(ZenTheme.body)
                .foregroundColor(currentTheme.textHighlight.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Temalar. Meditasyon deneyiminizi kişiselleştirin")
    }

    // MARK: - Premium Status Section

    private var premiumStatusSection: some View {
        HStack {
            Image(systemName: featureFlag.isPremium ? "crown.fill" : "crown")
                .foregroundColor(featureFlag.isPremium ? .yellow : currentTheme.textHighlight.opacity(0.5))
                .accessibilityHidden(true)

            Text(featureFlag.isPremium ? "Premium Üye" : "Ücretsiz Üye")
                .font(ZenTheme.headline)
                .foregroundColor(currentTheme.textHighlight)

            Spacer()

            // Debug toggle for testing (remove in production)
            #if DEBUG
            Button {
                featureFlag.setPremiumStatus(!featureFlag.isPremium)
                hapticManager.playImpact(style: .medium)
            } label: {
                Text(featureFlag.isPremium ? "Test: Free'ye Geç" : "Test: Premium'a Geç")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(currentTheme.accent.opacity(0.3))
                    .cornerRadius(8)
            }
            .accessibilityLabel(featureFlag.isPremium ? "Test modunda ücretsiz üyeliğe geç" : "Test modunda premium üyeliğe geç")
            #endif
        }
        .padding()
        .background(currentTheme.cardGradient)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Theme Grid Section

    private var themeGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(ThemeType.allCases) { themeType in
                ThemeCard(
                    themeType: themeType,
                    isSelected: featureFlag.selectedThemeType == themeType,
                    isLocked: themeType.isPremium && !featureFlag.isPremium
                ) {
                    selectTheme(themeType)
                }
            }
        }
    }

    // MARK: - Premium Benefits Section

    private var premiumBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Avantajları")
                .font(ZenTheme.headline)
                .foregroundColor(currentTheme.textHighlight)

            VStack(alignment: .leading, spacing: 12) {
                benefitRow(icon: "paintpalette.fill", text: "3 özel premium tema")
                benefitRow(icon: "sparkles", text: "Gelecekte eklenecek yeni temalar")
                benefitRow(icon: "heart.fill", text: "Geliştiricileri destekle")
            }

            Button {
                // TODO: Trigger StoreKit purchase flow
                hapticManager.playImpact(style: .medium)
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Premium'a Geç")
                        .font(ZenTheme.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(currentTheme.progressGradient)
                .cornerRadius(12)
            }
            .accessibilityLabel("Premium üyeliğe geç")
            .accessibilityHint("Premium özelliklerin kilidini açmak için dokunun")
        }
        .padding()
        .background(currentTheme.cardGradient)
        .cornerRadius(16)
    }

    // MARK: - Helper Views

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(currentTheme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(ZenTheme.body)
                .foregroundColor(currentTheme.textHighlight.opacity(0.9))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    private func selectTheme(_ themeType: ThemeType) {
        let success = featureFlag.selectTheme(themeType)

        if success {
            hapticManager.playImpact(style: .medium)
        } else {
            showPremiumAlert = true
            hapticManager.playNotification(type: .warning)
        }
    }
}

// MARK: - Theme Card

/// Individual theme preview card with selection state
struct ThemeCard: View {

    let themeType: ThemeType
    let isSelected: Bool
    let isLocked: Bool
    let onSelect: () -> Void

    private var theme: PremiumTheme {
        themeType.theme
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Theme preview circles
                ZStack {
                    Circle()
                        .fill(theme.breathingOuterGradient)
                        .frame(width: 80, height: 80)
                        .opacity(0.6)

                    Circle()
                        .fill(theme.breathingInnerGradient)
                        .frame(width: 60, height: 60)

                    // Lock icon for premium themes
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .accessibilityLabel("Kilitli")
                    }

                    // Checkmark for selected theme
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 18, height: 18)
                                    )
                                    .accessibilityLabel("Seçili")
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                .frame(height: 100)

                // Theme name
                Text(themeType.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textHighlight)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Premium badge
                if themeType.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                        Text("Premium")
                            .font(.caption)
                    }
                    .foregroundColor(.yellow)
                    .accessibilityLabel("Premium tema")
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 3)
                    )
            )
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(themeType.displayName) teması")
        .accessibilityHint(isLocked ? "Kilitli, premium gerektirir" : isSelected ? "Seçili tema" : "Temayı seçmek için dokunun")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Scale Button Style

/// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ThemeSelectionView()
}
