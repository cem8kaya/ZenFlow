//
//  SessionCompleteView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//  Updated by Claude AI on 24.11.2025.
//
//  Session completion modal with:
//  - Success checkmark animation (2 seconds)
//  - Duration summary
//  - Mood check-in feature
//  - Auto-dismiss after animation
//

import SwiftUI

/// Session completion overlay with success animation and mood check-in
struct SessionCompleteView: View {
    let durationMinutes: Int
    let onComplete: (Mood?) -> Void

    @State private var showSuccessAnimation = false
    @State private var showText = false
    @State private var showMoodSelector = false
    @State private var backgroundOpacity: Double = 0.0
    @State private var checkmarkScale: CGFloat = 0.0
    @State private var checkmarkOpacity: Double = 0.0
    @State private var selectedMood: Mood? = nil
    @State private var moodSelectionComplete = false

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            VStack(spacing: 30) {
                // Success Animation
                if showSuccessAnimation {
                    ZStack {
                        // Circle background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(checkmarkScale)

                        // Checkmark
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(checkmarkOpacity)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Session summary text
                if showText {
                    VStack(spacing: 12) {
                        Text(String(localized: "session_complete_title", comment: "Meditation completed title"))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text(String(localized: "session_complete_duration", defaultValue: "\(durationMinutes) dakika", comment: "Session duration"))
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .cyan]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text(String(localized: "session_complete_congratulations", comment: "Congratulations message"))
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Mood Selector
                if showMoodSelector && !moodSelectionComplete {
                    VStack(spacing: 20) {
                        Text(String(localized: "session_complete_mood_question", comment: "How are you feeling?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        // Mood emojis row
                        HStack(spacing: 20) {
                            ForEach(Mood.allCases) { mood in
                                MoodButton(
                                    mood: mood,
                                    isSelected: selectedMood == mood,
                                    otherSelected: selectedMood != nil && selectedMood != mood
                                ) {
                                    selectMood(mood)
                                }
                            }
                        }

                        // Skip button
                        Button(action: {
                            skipMoodSelection()
                        }) {
                            Text(String(localized: "session_complete_skip", comment: "Skip button"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 24)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ZenTheme.deepIndigo.opacity(0.4),
                                        ZenTheme.softPurple.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Step 1: Fade in background (0.2s)
        withAnimation(.easeOut(duration: 0.2)) {
            backgroundOpacity = 1.0
        }

        // Step 2: Show success animation (0.3s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticManager.shared.playNotification(type: .success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccessAnimation = true
                checkmarkScale = 1.0
            }

            // Fade in checkmark
            withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                checkmarkOpacity = 1.0
            }
        }

        // Step 3: Show text (0.8s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showText = true
            }
        }

        // Step 4: Show mood selector (2.5s delay - after success animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showMoodSelector = true
            }
        }
    }

    // MARK: - Mood Selection

    private func selectMood(_ mood: Mood) {
        // Haptic feedback
        HapticManager.shared.playImpact(style: .medium)

        // Set selected mood
        selectedMood = mood

        // Animate selection
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            moodSelectionComplete = true
        }

        // Save mood to LocalDataManager
        LocalDataManager.shared.saveMood(mood)

        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismissView(withMood: mood)
        }
    }

    private func skipMoodSelection() {
        // Haptic feedback
        HapticManager.shared.playImpact(style: .light)

        // Dismiss without saving mood
        dismissView(withMood: nil)
    }

    private func dismissView(withMood mood: Mood?) {
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete(mood)
        }
    }
}

// MARK: - Mood Button

private struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let otherSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mood.emoji)
                .font(.system(size: 44))
                .scaleEffect(isSelected ? 1.3 : 1.0)
                .opacity(otherSelected ? 0.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                .animation(.easeOut(duration: 0.3), value: otherSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    SessionCompleteView(durationMinutes: 5) { mood in
        if let mood = mood {
            print("Session complete with mood: \(mood.displayName)")
        } else {
            print("Session complete without mood")
        }
    }
}
