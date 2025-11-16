//
//  AnimatedGradientView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Animated gradient background synchronized with breathing phases.
//  Features iOS 18 MeshGradient support with fallback to LinearGradient.
//

import SwiftUI

/// Animated gradient background that syncs with breathing rhythm
struct AnimatedGradientView: View {

    // MARK: - Properties

    /// Current breathing phase (inhale/exhale)
    @Binding var breathingPhase: AnimationPhase

    /// Selected color palette
    let palette: ZenColorPalette

    /// Background opacity (0.0 to 1.0)
    let opacity: Double

    /// Animation state for continuous updates
    @State private var animationPhase: CGFloat = 0
    @State private var colorShiftIndex: Int = 0
    @State private var saturationMultiplier: CGFloat = 0.7

    // MARK: - Initialization

    init(breathingPhase: Binding<AnimationPhase>,
         palette: ZenColorPalette = .serene,
         opacity: Double = 0.5) {
        self._breathingPhase = breathingPhase
        self.palette = palette
        self.opacity = opacity
    }

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            if #available(iOS 18.0, *) {
                meshGradientView
            } else {
                linearGradientView
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .opacity(opacity)
        .onChange(of: breathingPhase) { oldPhase, newPhase in
            handlePhaseChange(from: oldPhase, to: newPhase)
        }
    }

    // MARK: - iOS 18 Mesh Gradient

    @available(iOS 18.0, *)
    private var meshGradientView: some View {
        let time = Date.now.timeIntervalSince1970

        // Create 4x4 mesh grid with sinusoidal movement
        let gridSize = 4
        let colors = generateMeshColors(gridSize: gridSize)
        let points = generateMeshPoints(gridSize: gridSize, time: time)

        return MeshGradient(
            width: gridSize,
            height: gridSize,
            points: points,
            colors: colors,
            background: palette.colors[0].adjustSaturation(0.3)
        )
    }

    // MARK: - iOS 17 Fallback: Linear Gradient

    private var linearGradientView: some View {
        let currentColors = generateCurrentColors()

        return LinearGradient(
            colors: currentColors,
            startPoint: breathingPhase == .inhale ? .topLeading : .bottomTrailing,
            endPoint: breathingPhase == .inhale ? .bottomTrailing : .topLeading
        )
        .animation(.easeInOut(duration: AppConstants.Animation.breathingCycleDuration), value: breathingPhase)
    }

    // MARK: - Helper Methods

    /// Generate current gradient colors based on breathing phase
    private func generateCurrentColors() -> [Color] {
        let paletteColors = palette.colors
        let colorCount = paletteColors.count

        // Shift colors during breathing cycle
        var colors: [Color] = []
        for i in 0..<colorCount {
            let index = (i + colorShiftIndex) % colorCount
            let color = paletteColors[index].adjustSaturation(saturationMultiplier)
            colors.append(color)
        }

        return colors
    }

    /// Generate mesh gradient colors for 4x4 grid
    @available(iOS 18.0, *)
    private func generateMeshColors(gridSize: Int) -> [Color] {
        var colors: [Color] = []
        let paletteColors = palette.colors

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                // Determine color based on position in grid
                let colorIndex = (row + col + colorShiftIndex) % paletteColors.count
                let baseColor = paletteColors[colorIndex]

                // Apply saturation based on breathing phase
                let color = baseColor.adjustSaturation(saturationMultiplier)
                colors.append(color)
            }
        }

        return colors
    }

    /// Generate mesh gradient points with sinusoidal movement
    @available(iOS 18.0, *)
    private func generateMeshPoints(gridSize: Int, time: TimeInterval) -> [SIMD2<Float>] {
        var points: [SIMD2<Float>] = []

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                // Base position in normalized coordinates (0.0 to 1.0)
                let baseX = Float(col) / Float(gridSize - 1)
                let baseY = Float(row) / Float(gridSize - 1)

                // Sinusoidal movement
                let frequency: Float = 0.3
                let amplitude: Float = breathingPhase == .inhale ? 0.08 : 0.04

                let offsetX = amplitude * sin(frequency * Float(time) + Float(row + col) * 0.5)
                let offsetY = amplitude * cos(frequency * Float(time) + Float(row - col) * 0.5)

                // Apply offset and clamp to valid range
                let x = min(1.0, max(0.0, baseX + offsetX))
                let y = min(1.0, max(0.0, baseY + offsetY))

                points.append(SIMD2(x, y))
            }
        }

        return points
    }

    /// Handle breathing phase changes
    private func handlePhaseChange(from oldPhase: AnimationPhase, to newPhase: AnimationPhase) {
        // Animate color transition
        withAnimation(.easeInOut(duration: AppConstants.Animation.breathingCycleDuration)) {
            // Shift colors
            if newPhase == .inhale {
                // Inhale: shift colors forward
                colorShiftIndex = (colorShiftIndex + 1) % palette.colors.count
                saturationMultiplier = 1.0 // Maximum saturation at peak
            } else {
                // Exhale: shift colors backward or desaturate
                colorShiftIndex = (colorShiftIndex - 1 + palette.colors.count) % palette.colors.count
                saturationMultiplier = 0.7 // Desaturated during exhale
            }
        }
    }
}

// MARK: - Preview

#Preview("Serene Palette") {
    struct PreviewWrapper: View {
        @State private var phase: AnimationPhase = .exhale
        @State private var isAnimating = false

        var body: some View {
            ZStack {
                AnimatedGradientView(
                    breathingPhase: $phase,
                    palette: .serene,
                    opacity: 0.6
                )

                VStack {
                    Text(phase.text)
                        .font(.largeTitle)
                        .foregroundColor(.white)

                    Button(isAnimating ? "Stop" : "Start") {
                        isAnimating.toggle()
                        if isAnimating {
                            startAnimation()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }

        func startAnimation() {
            Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                guard isAnimating else { return }
                phase = phase == .inhale ? .exhale : .inhale
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Forest Palette") {
    AnimatedGradientView(
        breathingPhase: .constant(.inhale),
        palette: .forest,
        opacity: 0.7
    )
}

#Preview("Sunset Palette") {
    AnimatedGradientView(
        breathingPhase: .constant(.exhale),
        palette: .sunset,
        opacity: 0.5
    )
}

#Preview("Midnight Palette") {
    AnimatedGradientView(
        breathingPhase: .constant(.inhale),
        palette: .midnight,
        opacity: 0.8
    )
}
