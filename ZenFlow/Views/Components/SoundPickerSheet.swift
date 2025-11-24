//
//  SoundPickerSheet.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Bottom sheet for selecting ambient sounds and adjusting volume.
//  Used in BreathingView and FocusTimerView.
//

import SwiftUI

/// Bottom sheet for selecting ambient sounds and adjusting volume
struct SoundPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var soundManager = AmbientSoundManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ZenTheme.backgroundGradient
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                ScrollView {
                    VStack(spacing: 24) {
                        // Sound Picker
                        AmbientSoundPicker(
                            selectedSounds: $soundManager.activeSounds,
                            onSoundToggle: { sound in
                                // Auto-play on selection if enabled
                                if soundManager.isEnabled && !sound.fileName.isEmpty {
                                    // Check if sound should be played or stopped
                                    if soundManager.activeSounds.contains(where: { $0.id == sound.id }) {
                                        soundManager.playSound(sound)
                                    } else {
                                        soundManager.stopSound(sound)
                                    }
                                }
                            }
                        )
                        .padding(.top, 8)

                        // Volume Slider (only show if sounds are selected)
                        if !soundManager.activeSounds.isEmpty && soundManager.activeSounds.first?.fileName != "" {
                            VolumeSliderView(volume: $soundManager.volume)
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .scale))
                        }

                        // Enable/Disable Toggle
                        Toggle(isOn: $soundManager.isEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: soundManager.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(soundManager.isEnabled ? ZenTheme.calmBlue : ZenTheme.softPurple)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Arka Plan Sesleri")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ZenTheme.lightLavender)

                                    Text(soundManager.isEnabled ? "Etkin" : "Devre Dışı")
                                        .font(.system(size: 14))
                                        .foregroundColor(ZenTheme.softPurple)
                                }

                                Spacer()
                            }
                        }
                        .tint(ZenTheme.calmBlue)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        // Info text
                        Text("Seçili sesler meditasyon sırasında arka planda çalacak. En fazla 2 ses aynı anda seçebilirsiniz.")
                            .font(.system(size: 14))
                            .foregroundColor(ZenTheme.softPurple.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Ses Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                    .foregroundColor(ZenTheme.lightLavender)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    SoundPickerSheet()
}
