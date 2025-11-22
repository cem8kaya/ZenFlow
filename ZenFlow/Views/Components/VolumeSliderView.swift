//
//  VolumeSliderView.swift
//  ZenFlow
//
//  Created by Claude AI on 22.11.2025.
//
//  Minimal volume slider with speaker icons and haptic feedback.
//  Features smooth animations and ZenTheme styling.
//

import SwiftUI

/// Volume slider with speaker icons and haptic feedback
struct VolumeSliderView: View {

    // MARK: - Properties

    @Binding var volume: Float
    @State private var isDragging: Bool = false
    @State private var lastHapticValue: Float = 0

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Ses Seviyesi")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)

                Spacer()

                Text("\(Int(volume * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ZenTheme.softPurple)
                    .monospacedDigit()
            }

            // Slider with icons
            HStack(spacing: 16) {
                // Low volume icon
                Image(systemName: "speaker.fill")
                    .font(.system(size: 18))
                    .foregroundColor(volume < 0.3 ? ZenTheme.lightLavender : ZenTheme.softPurple.opacity(0.6))
                    .frame(width: 24)

                // Custom Slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        // Active track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ZenTheme.calmBlue,
                                        ZenTheme.mysticalViolet
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(volume), height: 8)

                        // Thumb
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ZenTheme.lightLavender,
                                        ZenTheme.softPurple
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: isDragging ? 24 : 20, height: isDragging ? 24 : 20)
                            .shadow(color: ZenTheme.mysticalViolet.opacity(0.5), radius: isDragging ? 8 : 4)
                            .offset(x: geometry.size.width * CGFloat(volume) - (isDragging ? 12 : 10))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    HapticManager.shared.playImpact(style: .light)
                                }

                                // Calculate new volume
                                let newVolume = Float(max(0, min(1, value.location.x / geometry.size.width)))

                                // Haptic feedback on significant change (every 10%)
                                if abs(newVolume - lastHapticValue) >= 0.1 {
                                    HapticManager.shared.playImpact(style: .soft)
                                    lastHapticValue = newVolume
                                }

                                volume = newVolume
                            }
                            .onEnded { _ in
                                isDragging = false
                                HapticManager.shared.playImpact(style: .light)
                            }
                    )
                }
                .frame(height: 24)

                // High volume icon
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 18))
                    .foregroundColor(volume > 0.7 ? ZenTheme.lightLavender : ZenTheme.softPurple.opacity(0.6))
                    .frame(width: 24)
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ses seviyesi")
        .accessibilityValue("\(Int(volume * 100)) yüzde")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                volume = min(1.0, volume + 0.1)
                HapticManager.shared.playImpact(style: .light)
            case .decrement:
                volume = max(0.0, volume - 0.1)
                HapticManager.shared.playImpact(style: .light)
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()

        VStack(spacing: 40) {
            Spacer()

            VolumeSliderView(volume: .constant(0.5))
                .padding(.horizontal, 20)

            VolumeSliderView(volume: .constant(0.8))
                .padding(.horizontal, 20)

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
