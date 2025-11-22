//
//  SplashScreenView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//
//  App launch splash screen with:
//  - Simple zen logo animation (1.5 seconds)
//  - Fade-out transition
//

import SwiftUI

/// Splash screen shown on app launch
struct SplashScreenView: View {
    @Binding var isActive: Bool

    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = 0

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
                // Simple Loading Animation
                ZStack {
                    Circle()
                        .stroke(lineWidth: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))
                }
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

            // Rotation animation
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
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
