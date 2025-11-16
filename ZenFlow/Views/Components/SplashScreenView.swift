//
//  SplashScreenView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//
//  App launch splash screen with:
//  - Lottie zen logo animation (1.5 seconds)
//  - Fade-out transition
//

import SwiftUI

/// Splash screen shown on app launch
struct SplashScreenView: View {
    @Binding var isActive: Bool

    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.1, blue: 0.3),
                    Color(red: 0.08, green: 0.05, blue: 0.15),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Lottie Loading Animation
                LoadingLottieView()
                    .scaleEffect(scale)

                // App Name
                Text("ZenFlow")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Huzurlu bir yolculuk...")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            .opacity(opacity)
        }
        .onAppear {
            // Scale animation
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
            }

            // Auto-dismiss after animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isActive = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView(isActive: .constant(true))
}
