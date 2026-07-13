//
//  ZenMixPicker.swift
//  ZenFlow
//
//  Created by Claude AI on 13.07.2026.
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Horizontal picker of curated soundscape presets ("Zen Mixes").
//  Applies a two-sound atmosphere with a single tap.
//  Used inside SoundPickerSheet above the individual sound picker.
//

import SwiftUI

/// Horizontally scrolling cards of curated ambient soundscape presets
struct ZenMixPicker: View {
    @ObservedObject private var soundManager = AmbientSoundManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @State private var showPaywall = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(ZenTheme.lightLavender)

                Text(String(localized: "zen_mixes_title", defaultValue: "Zen Karışımları", comment: "Zen Mixes section title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)

                Spacer()
            }
            .padding(.horizontal, 20)

            Text(String(localized: "zen_mixes_subtitle", defaultValue: "Tek dokunuşla hazır atmosferler", comment: "Zen Mixes section subtitle"))
                .font(.system(size: 13))
                .foregroundColor(ZenTheme.softPurple)
                .padding(.horizontal, 20)

            // Mix cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ZenMix.allMixes) { mix in
                        mixCard(for: mix)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }

    // MARK: - Mix Card

    private func mixCard(for mix: ZenMix) -> some View {
        let isActive = soundManager.isMixActive(mix)
        let isLocked = mix.isPremium && !storeManager.isPremiumUnlocked

        return Button(action: {
            handleTap(on: mix, isActive: isActive, isLocked: isLocked)
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(mix.accentColor.opacity(isActive ? 0.4 : 0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: mix.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(isActive ? .white : mix.accentColor)
                    }

                    Spacer()

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(ZenTheme.softPurple)
                    } else if isActive {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(mix.accentColor)
                    }
                }

                Spacer(minLength: 0)

                Text(mix.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)
                    .lineLimit(1)

                Text(mix.description)
                    .font(.system(size: 12))
                    .foregroundColor(ZenTheme.softPurple)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(width: 160, height: 130, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? mix.accentColor.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isActive ? mix.accentColor.opacity(0.8) : ZenTheme.softPurple.opacity(0.3),
                        lineWidth: isActive ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mix.name)
        .accessibilityHint(mix.description)
    }

    // MARK: - Actions

    private func handleTap(on mix: ZenMix, isActive: Bool, isLocked: Bool) {
        if isLocked {
            HapticManager.shared.playImpact(style: .light)
            showPaywall = true
            return
        }

        HapticManager.shared.playImpact(style: .medium)

        if isActive {
            soundManager.stopMix(mix)
        } else {
            soundManager.playMix(mix)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()
        ZenMixPicker()
    }
    .preferredColorScheme(.dark)
}
