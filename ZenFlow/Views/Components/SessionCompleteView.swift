//
//  SessionCompleteView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//
//  Session completion modal with:
//  - Lottie success checkmark animation (2 seconds)
//  - Duration summary
//  - Auto-dismiss after animation
//

import SwiftUI

/// Session completion overlay with Lottie success animation
struct SessionCompleteView: View {
    let durationMinutes: Int
    let onComplete: () -> Void

    @State private var showSuccessAnimation = false
    @State private var showText = false
    @State private var backgroundOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            VStack(spacing: 30) {
                // Success Lottie Animation
                if showSuccessAnimation {
                    SuccessLottieView {
                        // Animation completed (2 seconds)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                backgroundOpacity = 0.0
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onComplete()
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Session summary text
                if showText {
                    VStack(spacing: 12) {
                        Text("Meditasyon Tamamlandı!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("\(durationMinutes) dakika")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .cyan]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Harika bir seans! 🧘‍♀️")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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
            }
        }

        // Step 3: Show text (0.8s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showText = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SessionCompleteView(durationMinutes: 5) {
        print("Session complete dismissed")
    }
}
