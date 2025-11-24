//
//  ExerciseSelectionView.swift
//  ZenFlow
//
//  Created by Claude AI on 22.11.2025.
//
//  Horizontal carousel view for selecting breathing exercises.
//  Features smooth scrolling, haptic feedback, and animated selection effects.
//

import SwiftUI

/// Exercise selection view with horizontal carousel
struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var exerciseManager = BreathingExerciseManager.shared
    @State private var selectedExercise: BreathingExercise

    var onExerciseSelected: ((BreathingExercise) -> Void)?

    init(onExerciseSelected: ((BreathingExercise) -> Void)? = nil) {
        self.onExerciseSelected = onExerciseSelected
        _selectedExercise = State(initialValue: BreathingExerciseManager.shared.selectedExercise)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerView

            // Exercise carousel
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 20) {
                    ForEach(exerciseManager.allExercises) { exercise in
                        ExerciseCard(
                            exercise: exercise,
                            isSelected: selectedExercise.id == exercise.id,
                            onTap: {
                                selectExercise(exercise)
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
            }
            .frame(height: 280)

            // Selected exercise details
            selectedExerciseDetailsView

            Spacer()

            // Action buttons
            actionButtonsView
        }
        .padding(.top, 20)
        .background(
            ZenTheme.backgroundGradient
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Nefes Egzersizi Seç")
                .font(ZenTheme.zenTitle)
                .foregroundColor(ZenTheme.lightLavender)

            Text("Size uygun bir egzersiz seçin")
                .font(ZenTheme.zenSubheadline)
                .foregroundColor(ZenTheme.softPurple)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nefes egzersizi seçim ekranı")
    }

    // MARK: - Selected Exercise Details

    private var selectedExerciseDetailsView: some View {
        VStack(spacing: 16) {
            // Exercise name and difficulty
            HStack(spacing: 12) {
                Image(systemName: selectedExercise.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(ZenTheme.lightLavender)

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedExercise.name)
                        .font(ZenTheme.zenHeadline)
                        .foregroundColor(ZenTheme.lightLavender)

                    HStack(spacing: 8) {
                        // Difficulty badge
                        Text(selectedExercise.difficulty.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(selectedExercise.difficulty.color)
                            .cornerRadius(8)

                        // Recommended time
                        HStack(spacing: 4) {
                            Image(systemName: selectedExercise.recommendedTime.icon)
                                .font(.system(size: 12))
                            Text(selectedExercise.recommendedTime.rawValue)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(ZenTheme.softPurple)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 32)

            // Description
            Text(selectedExercise.description)
                .font(ZenTheme.zenBody)
                .foregroundColor(ZenTheme.softPurple.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(.horizontal, 32)

            // Benefits
            VStack(alignment: .leading, spacing: 8) {
                Text("Faydaları:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(selectedExercise.benefits.prefix(3), id: \.self) { benefit in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(ZenTheme.mysticalViolet)
                                .frame(width: 4, height: 4)

                            Text(benefit)
                                .font(.system(size: 13))
                                .foregroundColor(ZenTheme.softPurple.opacity(0.8))
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Cancel button
            Button(action: {
                HapticManager.shared.playImpact(style: .light)
                dismiss()
            }) {
                Text("İptal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ZenTheme.softPurple)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            .zenSecondaryButtonStyle()

            // Confirm button
            Button(action: {
                confirmSelection()
            }) {
                Text("Seç")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [ZenTheme.mysticalViolet, ZenTheme.calmBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .zenPrimaryButtonStyle()
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func selectExercise(_ exercise: BreathingExercise) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedExercise = exercise
        }
        HapticManager.shared.playImpact(style: .medium)
    }

    private func confirmSelection() {
        HapticManager.shared.playImpact(style: .heavy)
        exerciseManager.selectExercise(selectedExercise)
        onExerciseSelected?(selectedExercise)

        // Accessibility announcement
        UIAccessibility.post(
            notification: .announcement,
            argument: "\(selectedExercise.name) egzersizi seçildi"
        )

        dismiss()
    }
}

// MARK: - Exercise Card

/// Individual exercise card for the carousel
struct ExerciseCard: View {
    let exercise: BreathingExercise
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                exercise.difficulty.color.opacity(0.3),
                                exercise.difficulty.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                Image(systemName: exercise.iconName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Name
            Text(exercise.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            // Description
            Text(exercise.description)
                .font(.system(size: 12))
                .foregroundColor(ZenTheme.softPurple.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Difficulty badge
            HStack(spacing: 4) {
                Circle()
                    .fill(exercise.difficulty.color)
                    .frame(width: 8, height: 8)

                Text(exercise.difficulty.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(exercise.difficulty.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(exercise.difficulty.color.opacity(0.2))
            )
        }
        .padding(20)
        .frame(width: 160, height: 240)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            ZenTheme.deepIndigo.opacity(0.6),
                            ZenTheme.softPurple.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isSelected ? ZenTheme.lightLavender : Color.clear,
                    lineWidth: isSelected ? 3 : 0
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .shadow(
            color: isSelected ? ZenTheme.mysticalViolet.opacity(0.5) : Color.black.opacity(0.3),
            radius: isSelected ? 15 : 10,
            x: 0,
            y: isSelected ? 8 : 5
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.difficulty.rawValue) seviye")
        .accessibilityHint(isSelected ? "Seçili" : "Seçmek için dokunun")
    }
}

// MARK: - Preview

#Preview {
    ExerciseSelectionView()
}
