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

    // MARK: - Environment Objects (Performance Optimization)
    @EnvironmentObject var exerciseManager: BreathingExerciseManager
    @State private var selectedExercise: BreathingExercise
    @State private var showPaywall = false
    @StateObject private var storeManager = StoreManager.shared

    var onExerciseSelected: ((BreathingExercise) -> Void)?

    init(onExerciseSelected: ((BreathingExercise) -> Void)? = nil) {
        self.onExerciseSelected = onExerciseSelected
        _selectedExercise = State(initialValue: BreathingExerciseManager.shared.selectedExercise)
    }

    var body: some View {
        ZStack {
            // 1. Arka Plan (Tüm ekranı kaplar)
            ZenTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 2. Kaydırılabilir İçerik Alanı (Scrollable Content)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Başlık (Sheet tutamacından kurtarmak için üst boşluk artırıldı)
                        headerView
                            .padding(.top, 32)
                        
                        // Exercise carousel
                        ScrollView(.horizontal, showsIndicators: false) {
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
                            .padding(.vertical, 20) // Gölge kesilmemesi için dikey boşluk
                        }
                        .frame(height: 280)
                        
                        // Selected exercise details
                        selectedExerciseDetailsView
                    }
                    .padding(.bottom, 100) // Footer'ın altında kalmaması için ekstra boşluk
                }
                
                // 3. Sabit Alt Butonlar (Sticky Footer)
                // ScrollView'ın dışında tutarak her zaman görünür olmasını sağlıyoruz
                VStack {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    actionButtonsView
                        .padding(.top, 16)
                        .padding(.bottom, 16) // Alt güvenli alan için biraz boşluk
                }
                .background(
                    ZenTheme.backgroundGradient // Butonların arkasının okunabilir olması için
                        .opacity(0.98)
                )
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(String(localized: "exercise_selection_title", defaultValue: "Nefes Egzersizi Seç", comment: "Exercise selection page title"))
                .font(ZenTheme.zenTitle)
                .foregroundColor(ZenTheme.lightLavender)

            Text(String(localized: "exercise_selection_subtitle", defaultValue: "Size uygun bir egzersiz seçin", comment: "Exercise selection page subtitle"))
                .font(ZenTheme.zenSubheadline)
                .foregroundColor(ZenTheme.softPurple)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(localized: "exercise_selection_accessibility", defaultValue: "Nefes egzersizi seçim ekranı", comment: "Exercise selection screen accessibility label")))
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
                        Text(selectedExercise.difficulty.displayName)
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
                Text(String(localized: "exercise_selection_benefits", defaultValue: "Faydaları:", comment: "Exercise benefits section title"))
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
                Text(String(localized: "exercise_selection_cancel", defaultValue: "İptal", comment: "Cancel button"))
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
                Text(String(localized: "exercise_selection_select", defaultValue: "Seç", comment: "Select exercise button"))
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
        // Not: Padding buradan kaldırıldı, dışarıdaki VStack'e eklendi
    }

    // MARK: - Actions

    private func selectExercise(_ exercise: BreathingExercise) {
        // Check premium status for premium exercises
        if exercise.isPremium && !storeManager.isPremiumUnlocked {
            HapticManager.shared.playNotification(type: .warning)
            showPaywall = true
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedExercise = exercise
        }
        HapticManager.shared.playImpact(style: .medium)
    }

    private func confirmSelection() {
        // Double-check premium status before confirming
        if selectedExercise.isPremium && !storeManager.isPremiumUnlocked {
            HapticManager.shared.playNotification(type: .warning)
            showPaywall = true
            return
        }

        HapticManager.shared.playImpact(style: .heavy)
        exerciseManager.selectExercise(selectedExercise)
        onExerciseSelected?(selectedExercise)

        // Accessibility announcement
        UIAccessibility.post(
            notification: .announcement,
            argument: String(localized: "exercise_selected_announcement", defaultValue: "Egzersiz seçildi: \(selectedExercise.name)", comment: "Exercise selected announcement")
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

    @StateObject private var storeManager = StoreManager.shared

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack(alignment: .topTrailing) {
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

                // Premium lock indicator
                if exercise.isPremium && !storeManager.isPremiumUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(ZenTheme.mysticalViolet)
                        )
                        .offset(x: 8, y: -8)
                }
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

                Text(exercise.difficulty.displayName)
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
        .accessibilityLabel(Text(String(localized: "exercise_card_accessibility", defaultValue: "\(exercise.name), \(exercise.difficulty.displayName) seviye", comment: "Exercise card accessibility label")))
        .accessibilityHint(isSelected ? String(localized: "exercise_card_selected", defaultValue: "Seçili", comment: "Selected hint") : String(localized: "exercise_card_tap_to_select", defaultValue: "Seçmek için dokunun", comment: "Tap to select hint"))
    }
}

// MARK: - Preview

#Preview {
    ExerciseSelectionView()
}
