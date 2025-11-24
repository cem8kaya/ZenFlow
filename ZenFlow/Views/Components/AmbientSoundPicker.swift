//
//  AmbientSoundPicker.swift
//  ZenFlow
//
//  Created by Claude AI on 22.11.2025.
//
//  Horizontal sound picker with cards for selecting ambient sounds.
//  Supports multiple selection (max 2 sounds) and displays category badges.
//

import SwiftUI

/// Horizontal picker for selecting ambient sounds during meditation
struct AmbientSoundPicker: View {

    // MARK: - Properties

    @Binding var selectedSounds: [AmbientSound]
    let maxSelections: Int = 2
    var onSoundToggle: ((AmbientSound) -> Void)?

    @State private var selectedCategory: AmbientCategory? = nil

    // MARK: - Available Sounds

    private var availableSounds: [AmbientSound] {
        let sounds = [AmbientSound.none] + AmbientSound.allSounds

        guard let category = selectedCategory else {
            return sounds
        }

        return [AmbientSound.none] + sounds.filter { $0.category == category && !$0.fileName.isEmpty }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Arka Plan Sesi")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)

                Spacer()

                if !selectedSounds.isEmpty && selectedSounds.first?.fileName != "" {
                    Text("\(selectedSounds.count)/\(maxSelections)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ZenTheme.softPurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(ZenTheme.softPurple.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 20)

            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All Categories
                    CategoryChip(
                        title: "Tümü",
                        icon: "music.note.list",
                        color: ZenTheme.lightLavender,
                        isSelected: selectedCategory == nil,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = nil
                            }
                        }
                    )

                    // Individual Categories
                    ForEach(AmbientCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = category
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }

            // Sound Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(availableSounds) { sound in
                        SoundCard(
                            sound: sound,
                            isSelected: isSelected(sound),
                            isDisabled: isDisabled(sound),
                            action: {
                                toggleSound(sound)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helper Methods

    private func isSelected(_ sound: AmbientSound) -> Bool {
        // "Sessiz" is selected when no other sounds are selected
        if sound.fileName.isEmpty {
            return selectedSounds.isEmpty || selectedSounds.allSatisfy { $0.fileName.isEmpty }
        }
        return selectedSounds.contains { $0.id == sound.id }
    }

    private func isDisabled(_ sound: AmbientSound) -> Bool {
        // "Sessiz" is never disabled
        if sound.fileName.isEmpty {
            return false
        }

        // Disable if max selections reached and this sound is not selected
        return selectedSounds.count >= maxSelections && !isSelected(sound)
    }

    private func toggleSound(_ sound: AmbientSound) {
        HapticManager.shared.playImpact(style: .light)

        // Handle "Sessiz" (none) selection
        if sound.fileName.isEmpty {
            selectedSounds.removeAll()
            onSoundToggle?(sound)
            return
        }

        // Toggle regular sound
        if let index = selectedSounds.firstIndex(where: { $0.id == sound.id }) {
            selectedSounds.remove(at: index)
        } else {
            // Remove "Sessiz" if present
            selectedSounds.removeAll { $0.fileName.isEmpty }

            // Add new sound (respect max limit)
            if selectedSounds.count < maxSelections {
                selectedSounds.append(sound)
            } else if selectedSounds.count == maxSelections {
                // Replace first sound
                selectedSounds.removeFirst()
                selectedSounds.append(sound)
            }
        }

        onSoundToggle?(sound)
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .light)
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.8) : color.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(color, lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Sound Card

private struct SoundCard: View {
    let sound: AmbientSound
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon with checkmark overlay
                ZStack(alignment: .topTrailing) {
                    // Sound icon
                    Image(systemName: sound.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(isSelected ? .white : ZenTheme.lightLavender.opacity(0.8))
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(
                                    isSelected ?
                                    sound.category.color.opacity(0.3) :
                                    Color.white.opacity(0.1)
                                )
                        )

                    // Checkmark for selected
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(sound.category.color)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.8))
                                    .frame(width: 18, height: 18)
                            )
                            .offset(x: 4, y: -4)
                    }
                }

                // Sound name
                Text(sound.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : ZenTheme.lightLavender)
                    .lineLimit(1)

                // Category badge (not for "Sessiz")
                if !sound.fileName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: sound.category.icon)
                            .font(.system(size: 10))
                        Text(sound.category.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(sound.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(sound.category.color.opacity(0.2))
                    )
                }
            }
            .frame(width: 100)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        Color.white.opacity(0.15) :
                        Color.white.opacity(0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ?
                        sound.category.color :
                        Color.clear,
                        lineWidth: 2
                    )
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled)
        .accessibilityLabel("\(sound.name) sesi")
        .accessibilityHint(isSelected ? "Seçili, kaldırmak için dokunun" : "Seçmek için dokunun")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()

        VStack {
            Spacer()
            AmbientSoundPicker(
                selectedSounds: .constant([AmbientSound.allSounds[0]])
            )
            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
