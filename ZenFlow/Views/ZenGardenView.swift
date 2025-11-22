//
//  ZenGardenView.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import SwiftUI

// MARK: - Particle Model

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
    var color: Color
}

// MARK: - ZenGardenView

struct ZenGardenView: View {
    // MARK: - State

    @StateObject private var gardenManager = ZenGardenManager()

    @State private var treeScale: CGFloat = 1.0
    @State private var treeRotation: Double = 0.0
    @State private var treeOpacity: Double = 1.0
    @State private var glowOpacity: Double = 0.3

    @State private var particles: [Particle] = []
    @State private var showCelebrationText: Bool = false
    @State private var viewSize: CGSize = .zero
    @State private var sparkleOpacity: Double = 0.0
    @State private var sparkleScale: CGFloat = 0.0


    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundGradient

                // 2D Watercolor View
                ZStack {
                    WatercolorZenGardenView(gardenManager: gardenManager)

                    // Sparkle Growth Animation Overlay
                    ZStack {
                        ForEach(0..<8, id: \.self) { index in
                            Image(systemName: "sparkle")
                                .font(.system(size: 30))
                                .foregroundColor(gardenManager.currentStage.colors.randomElement() ?? .white)
                                .opacity(sparkleOpacity)
                                .scaleEffect(sparkleScale)
                                .offset(
                                    x: cos(Double(index) * .pi / 4) * 100,
                                    y: sin(Double(index) * .pi / 4) * 100
                                )
                        }
                    }
                    .allowsHitTesting(false)

                    // Overlay UI
                    VStack(spacing: 0) {
                        // Başlık
                        headerView
                            .shadow(color: .black.opacity(0.3), radius: 5)

                        Spacer()

                        // Ağaç görsel alanı (merkez)
                        treeDisplayArea
                            .scaleEffect(treeScale)
                            .rotationEffect(.degrees(treeRotation))
                            .opacity(treeOpacity)

                        Spacer()

                        // İlerleme göstergesi (alt kısma yakın)
                        progressSection
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.1))
                                    .blur(radius: 10)
                            )
                            .padding(.bottom, 40)
                    }
                }
            }
            .onAppear {
                viewSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
            }
            .preferredColorScheme(.light)
            .onChange(of: gardenManager.shouldCelebrate) { _, shouldCelebrate in
                if shouldCelebrate {
                    startCelebrationAnimation()
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.97, blue: 0.92), // Very soft cream
                Color(red: 0.96, green: 0.94, blue: 0.88), // Warm beige
                Color(red: 0.94, green: 0.92, blue: 0.86)  // Soft earth
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Zen Bahçem")
                .font(ZenTheme.zenTitle)
                .foregroundColor(ZenTheme.earthBrown)

            Text("Toplam: \(gardenManager.totalMinutes) dk")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ZenTheme.sageGreen.opacity(0.9))
        }
        .padding(.top, 60)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 20) {
            if let timeRemaining = gardenManager.formattedTimeUntilNextStage() {
                // Sonraki aşama bilgisi
                VStack(spacing: 8) {
                    Text("Sonraki Aşamaya")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ZenTheme.sageGreen)

                    Text(timeRemaining)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(ZenTheme.earthBrown)
                }

                // İlerleme çubuğu
                progressBar

            } else {
                // Maksimum seviyeye ulaşıldı
                maximumLevelView
            }
        }
        .padding(.bottom, 30)
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Arka plan
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    // İlerleme
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: gardenManager.currentStage.colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * gardenManager.stageProgress,
                            height: 12
                        )
                        .animation(.easeInOut(duration: 0.5), value: gardenManager.stageProgress)
                }
            }
            .frame(height: 12)

            // Yüzde göstergesi
            Text(gardenManager.formattedProgress())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ZenTheme.sageGreen.opacity(0.8))
        }
        .padding(.horizontal, 40)
    }

    private var maximumLevelView: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))

            Text("Maksimum Seviye!")
                .font(ZenTheme.zenHeadline)
                .foregroundColor(ZenTheme.earthBrown)

            Text("Efsanevi bir yolculuk tamamladın!")
                .font(ZenTheme.zenBody)
                .foregroundColor(ZenTheme.sageGreen)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Tree Display Area

    private var treeDisplayArea: some View {
        ZStack {
            // Subtle glow effect (very minimal for natural look)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            gardenManager.currentStage.glowColor.opacity(glowOpacity * 0.3),
                            gardenManager.currentStage.glowColor.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: gardenManager.currentStage.glowRadius * 0.6
                    )
                )
                .frame(
                    width: gardenManager.currentStage.glowRadius * 1.2,
                    height: gardenManager.currentStage.glowRadius * 1.2
                )

            // Celebration text overlay (if celebrating)
            if showCelebrationText {
                VStack(spacing: 12) {
                    Text("🌱")
                        .font(.system(size: 40))

                    Text(gardenManager.currentStage.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ZenTheme.earthBrown)
                }
                .offset(y: 60)
                .scaleEffect(showCelebrationText ? 1.0 : 0.5)
                .opacity(showCelebrationText ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showCelebrationText)
            }
        }
    }

    // MARK: - Celebration Overlay

    private var celebrationOverlay: some View {
        ZStack {
            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
            }

            // Celebration text
            if showCelebrationText {
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 60))

                    Text("Yeni Aşama!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text(gardenManager.currentStage.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gardenManager.currentStage.colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.7))
                        .shadow(color: gardenManager.currentStage.glowColor.opacity(0.5), radius: 20)
                )
                .scaleEffect(showCelebrationText ? 1.0 : 0.5)
                .opacity(showCelebrationText ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showCelebrationText)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Celebration Animation

    private func startCelebrationAnimation() {
        // Show sparkle animation
        withAnimation(.easeOut(duration: 0.3)) {
            sparkleOpacity = 1.0
            sparkleScale = 1.0
        }

        // Hide sparkles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                sparkleOpacity = 0.0
                sparkleScale = 0.5
            }
        }

        // Tree scale animation (more subtle)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            treeScale = 1.15
            glowOpacity = 0.5
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
            treeScale = 1.0
            glowOpacity = 0.2
        }

        // Rotation animation
        withAnimation(.easeInOut(duration: 0.4)) {
            treeRotation = 10
        }

        withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
            treeRotation = -10
        }

        withAnimation(.easeInOut(duration: 0.4).delay(0.4)) {
            treeRotation = 0
        }

        // Show celebration text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showCelebrationText = true
        }

        // Hide celebration text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCelebrationText = false
            }
        }

        // Generate particles
        generateParticles()
    }

    private func generateParticles() {
        particles.removeAll()

        let screenWidth = viewSize.width
        let screenHeight = viewSize.height
        let colors = gardenManager.currentStage.colors

        // 30 particle oluştur
        for _ in 0..<30 {
            let startX = screenWidth / 2
            let startY = screenHeight / 2

            let particle = Particle(
                x: startX,
                y: startY,
                scale: Double.random(in: 0.5...1.5),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                color: colors.randomElement() ?? .white
            )

            particles.append(particle)
        }

        // Animate particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 2.0)) {
                for i in 0..<particles.count {
                    let angle = Double.random(in: 0...(2 * .pi))
                    let distance = CGFloat.random(in: 100...300)

                    particles[i].x += cos(angle) * distance
                    particles[i].y += sin(angle) * distance
                    particles[i].opacity = 0.0
                    particles[i].scale *= 0.5
                }
            }
        }

        // Clean up particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            particles.removeAll()
        }
    }
}

// MARK: - Preview

#Preview {
    ZenGardenView()
}
