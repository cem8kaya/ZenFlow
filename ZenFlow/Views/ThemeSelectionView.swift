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

                    // Particle effects settings
                    particleEffectsSection

                    // Breathing gradient settings
                    breathingGradientSection

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

    // MARK: - Breathing Gradient Section

    private var breathingGradientSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Nefes Gradyanı")
                    .font(ZenTheme.headline)
                    .foregroundColor(currentTheme.textHighlight)

                Spacer()

                Toggle("", isOn: $featureFlag.breathingGradientEnabled)
                    .labelsHidden()
                    .tint(currentTheme.accent)
                    .onChange(of: featureFlag.breathingGradientEnabled) { _ in
                        hapticManager.playImpact(style: .light)
                    }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Nefes gradyanı arka plan")
            .accessibilityValue(featureFlag.breathingGradientEnabled ? "Açık" : "Kapalı")

            if featureFlag.breathingGradientEnabled {
                VStack(spacing: 16) {
                    // Color palette picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Renk Paleti")
                            .font(ZenTheme.subheadline)
                            .foregroundColor(currentTheme.textHighlight.opacity(0.8))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ZenColorPalette.allCases) { palette in
                                    gradientPaletteButton(palette)
                                }
                            }
                        }
                    }

                    // Opacity slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Opaklık")
                                .font(ZenTheme.subheadline)
                                .foregroundColor(currentTheme.textHighlight.opacity(0.8))

                            Spacer()

                            Text("\(Int(featureFlag.breathingGradientOpacity * 100))%")
                                .font(ZenTheme.subheadline)
                                .foregroundColor(currentTheme.accent)
                        }

                        Slider(value: $featureFlag.breathingGradientOpacity, in: 0.3...0.8, step: 0.05)
                            .tint(currentTheme.accent)
                            .onChange(of: featureFlag.breathingGradientOpacity) { _ in
                                hapticManager.playImpact(style: .light)
                            }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(currentTheme.cardGradient)
        .cornerRadius(16)
    }

    // MARK: - Particle Effects Section

    private var particleEffectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Parçacık Efektleri")
                    .font(ZenTheme.headline)
                    .foregroundColor(currentTheme.textHighlight)

                Spacer()

                Toggle("", isOn: $featureFlag.particleEffectsEnabled)
                    .labelsHidden()
                    .tint(currentTheme.accent)
                    .onChange(of: featureFlag.particleEffectsEnabled) { _ in
                        hapticManager.playImpact(style: .light)
                    }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Parçacık efektleri")
            .accessibilityValue(featureFlag.particleEffectsEnabled ? "Açık" : "Kapalı")

            if featureFlag.particleEffectsEnabled {
                VStack(spacing: 16) {
                    // Intensity picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yoğunluk")
                            .font(ZenTheme.subheadline)
                            .foregroundColor(currentTheme.textHighlight.opacity(0.8))

                        Picker("Yoğunluk", selection: $featureFlag.particleIntensity) {
                            ForEach(ParticleIntensity.allCases, id: \.self) { intensity in
                                Text(intensity.displayName).tag(intensity)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: featureFlag.particleIntensity) { _ in
                            hapticManager.playImpact(style: .light)
                        }
                    }

                    // Color theme picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Renk Teması")
                            .font(ZenTheme.subheadline)
                            .foregroundColor(currentTheme.textHighlight.opacity(0.8))

                        Picker("Renk Teması", selection: $featureFlag.particleColorTheme) {
                            ForEach(ParticleColorTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: featureFlag.particleColorTheme) { _ in
                            hapticManager.playImpact(style: .light)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(currentTheme.cardGradient)
        .cornerRadius(16)
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

    private func gradientPaletteButton(_ palette: ZenColorPalette) -> some View {
        Button {
            featureFlag.breathingGradientPalette = palette
            hapticManager.playImpact(style: .medium)
        } label: {
            VStack(spacing: 8) {
                // Gradient preview
                ZStack {
                    LinearGradient(
                        colors: palette.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                featureFlag.breathingGradientPalette == palette ? currentTheme.accent : Color.clear,
                                lineWidth: 3
                            )
                    )

                    // Checkmark for selected palette
                    if featureFlag.breathingGradientPalette == palette {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(currentTheme.accent)
                                    .frame(width: 32, height: 32)
                            )
                    }
                }

                // Palette name
                Text(palette.displayName)
                    .font(.caption)
                    .foregroundColor(currentTheme.textHighlight)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(palette.displayName)
        .accessibilityHint(featureFlag.breathingGradientPalette == palette ? "Seçili palet" : "Paleti seçmek için dokunun")
        .accessibilityAddTraits(featureFlag.breathingGradientPalette == palette ? [.isSelected] : [])
    }

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
