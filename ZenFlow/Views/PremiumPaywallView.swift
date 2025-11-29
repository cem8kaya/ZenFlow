//
//  PremiumPaywallView.swift
//  ZenFlow
//
//  Created by Claude AI on 29.11.2025.
//
//  Premium paywall view for presenting IAP purchase options.
//  Features bilingual support (Turkish/English) and ZenTheme integration.
//

import SwiftUI

/// Paywall view for premium features
struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared

    var body: some View {
        ZStack {
            // Background
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        // Premium icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            ZenTheme.mysticalViolet.opacity(0.3),
                                            ZenTheme.calmBlue.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [ZenTheme.lightLavender, ZenTheme.mysticalViolet],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 40)

                        // Title
                        Text(String(localized: "premium.title", defaultValue: "ZenFlow Premium", comment: "Premium title"))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(ZenTheme.lightLavender)

                        // Subtitle
                        Text(String(localized: "premium.subtitle", defaultValue: "Tüm özelliklerin kilidini aç", comment: "Premium subtitle"))
                            .font(.system(size: 18))
                            .foregroundColor(ZenTheme.softPurple)
                            .multilineTextAlignment(.center)
                    }

                    // Features list
                    VStack(spacing: 16) {
                        PremiumFeatureRow(
                            icon: "wind",
                            title: String(localized: "premium.features.allExercises", defaultValue: "Tüm Nefes Egzersizleri", comment: "All exercises feature"),
                            description: String(localized: "premium.features.allExercises.desc", defaultValue: "4-7-8, Sakinleştirici ve daha fazlası", comment: "All exercises description")
                        )

                        PremiumFeatureRow(
                            icon: "speaker.wave.2.fill",
                            title: String(localized: "premium.features.allSounds", defaultValue: "Tüm Ambient Sesler", comment: "All sounds feature"),
                            description: String(localized: "premium.features.allSounds.desc", defaultValue: "Okyanus, orman, şömine ve 10+ ses", comment: "All sounds description")
                        )

                        PremiumFeatureRow(
                            icon: "chart.bar.fill",
                            title: String(localized: "premium.features.advancedStats", defaultValue: "Gelişmiş İstatistikler", comment: "Advanced stats feature"),
                            description: String(localized: "premium.features.advancedStats.desc", defaultValue: "Detaylı analiz ve streak takibi", comment: "Advanced stats description")
                        )

                        PremiumFeatureRow(
                            icon: "paintpalette.fill",
                            title: String(localized: "premium.features.premiumThemes", defaultValue: "Premium Temalar", comment: "Premium themes feature"),
                            description: String(localized: "premium.features.premiumThemes.desc", defaultValue: "Özel renk paletleri", comment: "Premium themes description")
                        )
                    }
                    .padding(.horizontal, 24)

                    // Price
                    VStack(spacing: 12) {
                        Text(String(localized: "premium.price.onetime", defaultValue: "Tek Seferlik Ödeme", comment: "One-time payment label"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ZenTheme.softPurple)

                        Text(storeManager.premiumPrice)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(ZenTheme.lightLavender)

                        Text(String(localized: "premium.price.lifetime", defaultValue: "Ömür Boyu Erişim", comment: "Lifetime access label"))
                            .font(.system(size: 16))
                            .foregroundColor(ZenTheme.softPurple)
                    }
                    .padding(.top, 8)

                    // Purchase button
                    Button(action: {
                        Task {
                            await storeManager.purchase()
                        }
                    }) {
                        HStack {
                            if storeManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 20, weight: .bold))
                                Text(String(localized: "premium.purchase", defaultValue: "Premium'a Geç", comment: "Purchase button"))
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [ZenTheme.mysticalViolet, ZenTheme.calmBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: ZenTheme.mysticalViolet.opacity(0.5), radius: 20, x: 0, y: 10)
                    }
                    .disabled(storeManager.isLoading)
                    .padding(.horizontal, 24)
                    .zenPrimaryButtonStyle()

                    // Restore button
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    }) {
                        HStack {
                            if storeManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: ZenTheme.softPurple))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16))
                                Text(String(localized: "premium.restore", defaultValue: "Satın Alımları Geri Yükle", comment: "Restore button"))
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(ZenTheme.softPurple)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .disabled(storeManager.isLoading)
                    .padding(.horizontal, 24)
                    .zenSecondaryButtonStyle()

                    // Error message
                    if let error = storeManager.purchaseError {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Close button
                    Button(action: {
                        HapticManager.shared.playImpact(style: .light)
                        dismiss()
                    }) {
                        Text(String(localized: "premium.close", defaultValue: "Kapat", comment: "Close button"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ZenTheme.softPurple.opacity(0.7))
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Premium Feature Row

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(ZenTheme.mysticalViolet.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(ZenTheme.lightLavender)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(ZenTheme.softPurple.opacity(0.8))
            }

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(ZenTheme.mysticalViolet)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ZenTheme.softPurple.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    PremiumPaywallView()
}
