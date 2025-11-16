//
//  ZenLoadingView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//
//  Custom loading indicators:
//  - ZenLoadingView: Rotating mandala pattern
//  - ZenProgressView: Circular progress with gradient stroke
//  - ShimmerView: Loading placeholder effect
//

import SwiftUI

// MARK: - Zen Loading View (Rotating Mandala)

/// Custom loading view with rotating mandala pattern
struct ZenLoadingView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8

    var size: CGFloat = 60
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            // Outer rotating circle
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))

            // Middle pulsing circle
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: lineWidth - 1
                )
                .frame(width: size * 0.7, height: size * 0.7)
                .rotationEffect(.degrees(-rotation * 1.5))
                .scaleEffect(scale)

            // Inner dot
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.2, height: size * 0.2)
                .opacity(opacity)

            // Mandala petals
            ForEach(0..<8) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.6), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 0.4, height: lineWidth)
                    .offset(x: size * 0.2)
                    .rotationEffect(.degrees(Double(index) * 45 + rotation))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.2
            }

            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                opacity = 0.3
            }
        }
    }
}

// MARK: - Zen Progress View (Circular with Gradient)

/// Custom circular progress indicator with gradient stroke
struct ZenProgressView: View {
    var progress: Double // 0.0 to 1.0
    var size: CGFloat = 80
    var lineWidth: CGFloat = 8

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color.white.opacity(0.2),
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)

            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue, .cyan]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Percentage text
            Text("\(Int(animatedProgress * 100))%")
                .font(.system(size: size * 0.25, weight: .semibold))
                .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Shimmer Effect (Loading Placeholder)

/// Shimmer loading effect for skeleton views
struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color
                Color.white.opacity(0.1)

                // Shimmer gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.3), location: 0.5),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

/// Shimmer modifier for easy application
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.4), location: 0.5),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Skeleton Loading View

/// Skeleton view for loading states
struct SkeletonView: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.1))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ShimmerView())
            )
            .clipped()
    }
}

// MARK: - View Extension

extension View {
    /// Apply shimmer effect to view
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Preview

#Preview("Zen Loading View") {
    ZStack {
        Color.black
        VStack(spacing: 40) {
            ZenLoadingView()
            ZenLoadingView(size: 80, lineWidth: 4)
            ZenProgressView(progress: 0.65)
        }
    }
}

#Preview("Shimmer Effect") {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            SkeletonView(height: 60)
            SkeletonView(height: 40)
            SkeletonView(height: 40)
        }
        .padding()
    }
}
