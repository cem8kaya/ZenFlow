//
//  ZenGardenView.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import SwiftUI

// MARK: - Particle Models

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
    var color: Color
}

struct StardustParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var velocity: CGPoint
    var color: Color
}

struct FallingPetal: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var opacity: Double
    var swayPhase: Double
}

struct WaterDroplet: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
}

struct Cloud: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var speed: CGFloat
}

struct Star: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var twinklePhase: Double
    var brightness: Double
}

// MARK: - ZenGardenView

struct ZenGardenView: View {
    // MARK: - State

    @StateObject private var gardenManager = ZenGardenManager()
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isViewActive = false

    @State private var treeScale: CGFloat = 1.0
    @State private var treeRotation: Double = 0.0
    @State private var treeOpacity: Double = 1.0
    @State private var glowOpacity: Double = 0.3

    @State private var particles: [Particle] = []
    @State private var showCelebrationText: Bool = false
    @State private var viewSize: CGSize = .zero
    @State private var sparkleOpacity: Double = 0.0
    @State private var sparkleScale: CGFloat = 0.0

    // Enhanced particle systems
    @State private var stardustParticles: [StardustParticle] = []
    @State private var fallingPetals: [FallingPetal] = []
    @State private var waterDroplets: [WaterDroplet] = []

    // Dynamic background
    @State private var clouds: [Cloud] = []
    @State private var stars: [Star] = []
    @State private var timeOfDay: Double = 0.2 // 0 = night, 1 = day (darker default for consistency)
    @State private var cloudAnimationPhase: Double = 0
    @State private var starTwinklePhase: Double = 0

    // Interactive states
    @State private var tapLocation: CGPoint?
    @State private var showWaterEffect: Bool = false
    @State private var lastTapTime: Date = Date()

    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)

    // Timers for cleanup
    @State private var cloudAnimationTimer: Timer?
    @State private var starTwinkleTimer: Timer?


    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            if #available(iOS 17.0, *) {
                ZStack {
                    // Dynamic Background with time-of-day
                    dynamicBackground
                    
                    // Stars (night only)
                    if timeOfDay < 0.3 {
                        starsLayer
                    }
                    
                    // Clouds
                    cloudsLayer
                    
                    // 2D Watercolor View
                    ZStack {
                        WatercolorZenGardenView(gardenManager: gardenManager)
                        
                        // Falling Petals (Ancient Tree only)
                        if gardenManager.currentStage == .ancientTree {
                            fallingPetalsLayer
                        }
                        
                        // Stardust particles (level-up)
                        stardustParticlesLayer
                        
                        // Water droplets (interactive)
                        waterDropletsLayer
                        
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
                                .onTapGesture { location in
                                    handleTreeTap(at: location, in: geometry.size)
                                }
                            
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
                    isViewActive = true
                    viewSize = geometry.size
                    setupBackground()
                    startBackgroundAnimations()
                    impactFeedback.prepare()
                    lightFeedback.prepare()
                }
                .onDisappear {
                    // PERFORMANCE OPTIMIZATION: Clean up when view disappears
                    isViewActive = false
                    stopAllAnimations()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // PERFORMANCE OPTIMIZATION: Handle app backgrounding
                    switch newPhase {
                    case .active:
                        if isViewActive {
                            startBackgroundAnimations()
                        }
                    case .background, .inactive:
                        stopAllAnimations()
                    @unknown default:
                        break
                    }
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
            } else {
                // Fallback on earlier versions
            }
        }
        .drawingGroup() // Performance optimization
    }

    // MARK: - Background

    private var dynamicBackground: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0, paused: reduceMotion)) { context in
            let dayColors = [
                Color(red: 0.25, green: 0.30, blue: 0.45), // Muted zen blue
                Color(red: 0.30, green: 0.30, blue: 0.50), // Soft zen violet
                Color(red: 0.25, green: 0.25, blue: 0.40)  // Deep zen indigo
            ]

            let nightColors = [
                Color(red: 0.05, green: 0.05, blue: 0.20), // Deep night blue
                Color(red: 0.10, green: 0.10, blue: 0.30), // Night sky
                Color(red: 0.15, green: 0.15, blue: 0.25)  // Horizon purple
            ]

            let currentColors = dayColors.enumerated().map { index, dayColor in
                let nightColor = nightColors[index]
                return Color(
                    red: nightColor.components.red * (1 - timeOfDay) + dayColor.components.red * timeOfDay,
                    green: nightColor.components.green * (1 - timeOfDay) + dayColor.components.green * timeOfDay,
                    blue: nightColor.components.blue * (1 - timeOfDay) + dayColor.components.blue * timeOfDay
                )
            }

            LinearGradient(
                colors: currentColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var starsLayer: some View {
        ZStack {
            ForEach(stars) { star in
                Circle()
                    .fill(Color.white)
                    .frame(width: 2, height: 2)
                    .opacity(star.brightness * (0.3 + 0.7 * sin(starTwinklePhase + star.twinklePhase)))
                    .position(x: star.x, y: star.y)
            }
        }
        .allowsHitTesting(false)
    }

    private var cloudsLayer: some View {
        ZStack {
            ForEach(clouds) { cloud in
                CloudShape()
                    .fill(Color.white.opacity(0.6 * timeOfDay))
                    .frame(width: 80 * cloud.scale, height: 40 * cloud.scale)
                    .position(x: cloud.x, y: cloud.y)
            }
        }
        .allowsHitTesting(false)
    }

    private var fallingPetalsLayer: some View {
        ZStack {
            ForEach(fallingPetals) { petal in
                PetalShape()
                    .fill(Color(red: 1.0, green: 0.75, blue: 0.8))
                    .frame(width: 8, height: 12)
                    .rotationEffect(.degrees(petal.rotation))
                    .opacity(petal.opacity)
                    .position(
                        x: petal.x + sin(petal.swayPhase) * 30,
                        y: petal.y
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private var stardustParticlesLayer: some View {
        ZStack {
            ForEach(stardustParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: 4, height: 4)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .blur(radius: 1)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .allowsHitTesting(false)
    }

    private var waterDropletsLayer: some View {
        ZStack {
            ForEach(waterDroplets) { droplet in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.4),
                                Color.cyan.opacity(0.2)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 30, height: 30)
                    .scaleEffect(droplet.scale)
                    .opacity(droplet.opacity)
                    .position(x: droplet.x, y: droplet.y)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(String(localized: "zen_garden_title", defaultValue: "Zen Bahçem", comment: "Zen Garden title"))
                .font(ZenTheme.zenTitle)
                .foregroundColor(ZenTheme.earthBrown)

            Text(String(localized: "zen_garden_total_minutes", defaultValue: "Toplam: \(gardenManager.totalMinutes) dk", comment: "Total minutes"))
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
                    Text(String(localized: "zen_garden_next_stage", defaultValue: "Sonraki Aşamaya", comment: "Next stage label"))
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

            Text(String(localized: "zen_garden_max_level", defaultValue: "Maksimum Seviye!", comment: "Maximum level reached"))
                .font(ZenTheme.zenHeadline)
                .foregroundColor(ZenTheme.earthBrown)

            Text(String(localized: "zen_garden_legendary_journey", defaultValue: "Efsanevi bir yolculuk tamamladın!", comment: "Legendary journey completed"))
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

                    Text(String(localized: "zen_garden_new_stage", defaultValue: "Yeni Aşama!", comment: "New stage celebration"))
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
        // Haptic feedback - strong impact for celebration
        impactFeedback.impactOccurred()

        // Use simpler animations if Reduce Motion is enabled
        if reduceMotion {
            // Simple fade in/out for sparkles
            withAnimation(.easeInOut(duration: 0.2)) {
                sparkleOpacity = 1.0
                sparkleScale = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    sparkleOpacity = 0.0
                    sparkleScale = 0.5
                }
            }

            // Subtle scale only, no rotation
            withAnimation(.easeInOut(duration: 0.3)) {
                treeScale = 1.05
                glowOpacity = 0.4
            }

            withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
                treeScale = 1.0
                glowOpacity = 0.2
            }

            // Show celebration text
            showCelebrationText = true

            // Hide celebration text
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showCelebrationText = false
                }
            }
        } else {
            // Full animations
            // Generate stardust particles
            generateStardustParticles()

            // Show sparkle animation
            withAnimation(.easeInOut(duration: 0.3)) {
                sparkleOpacity = 1.0
                sparkleScale = 1.0
            }

            // Hide sparkles
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
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

            // Start falling petals if reached ancient tree
            if gardenManager.currentStage == .ancientTree {
                startFallingPetals()
            }
        }
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
            withAnimation(.easeInOut(duration: 2.0)) {
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

    // MARK: - Enhanced Particle Systems

    private func generateStardustParticles() {
        stardustParticles.removeAll()

        let screenWidth = viewSize.width
        let screenHeight = viewSize.height
        let colors = gardenManager.currentStage.colors

        // Generate 50 stardust particles
        for _ in 0..<50 {
            let startX = screenWidth / 2 + CGFloat.random(in: -50...50)
            let startY = screenHeight / 2 + CGFloat.random(in: -50...50)

            let particle = StardustParticle(
                x: startX,
                y: startY,
                scale: CGFloat.random(in: 0.5...1.2),
                opacity: 1.0,
                velocity: CGPoint(
                    x: CGFloat.random(in: -2...2),
                    y: CGFloat.random(in: -4...(-1))
                ),
                color: colors.randomElement() ?? .yellow
            )

            stardustParticles.append(particle)
        }

        // Animate stardust particles upward
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            guard !stardustParticles.isEmpty else {
                timer.invalidate()
                return
            }

            for i in stardustParticles.indices {
                stardustParticles[i].x += stardustParticles[i].velocity.x
                stardustParticles[i].y += stardustParticles[i].velocity.y
                stardustParticles[i].opacity -= 0.01
                stardustParticles[i].scale *= 0.995

                // Remove if too far or invisible
                if stardustParticles[i].y < -50 || stardustParticles[i].opacity <= 0 {
                    stardustParticles.remove(at: i)
                    break
                }
            }
        }
    }

    private func startFallingPetals() {
        guard gardenManager.currentStage == .ancientTree else { return }

        // Generate initial petals
        for _ in 0..<15 {
            let petal = FallingPetal(
                x: CGFloat.random(in: 0...viewSize.width),
                y: -20,
                rotation: Double.random(in: 0...360),
                opacity: Double.random(in: 0.6...1.0),
                swayPhase: Double.random(in: 0...(2 * .pi))
            )
            fallingPetals.append(petal)
        }

        // Continuous petal animation
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            guard gardenManager.currentStage == .ancientTree else {
                timer.invalidate()
                fallingPetals.removeAll()
                return
            }

            // Update existing petals
            for i in fallingPetals.indices {
                fallingPetals[i].y += 1.5
                fallingPetals[i].rotation += 2
                fallingPetals[i].swayPhase += 0.05

                // Remove if off screen
                if fallingPetals[i].y > viewSize.height + 50 {
                    fallingPetals[i] = FallingPetal(
                        x: CGFloat.random(in: 0...viewSize.width),
                        y: -20,
                        rotation: Double.random(in: 0...360),
                        opacity: Double.random(in: 0.6...1.0),
                        swayPhase: Double.random(in: 0...(2 * .pi))
                    )
                }
            }
        }
    }

    // MARK: - Interactive Functions

    private func handleTreeTap(at location: CGPoint, in size: CGSize) {
        // Haptic feedback
        lightFeedback.impactOccurred()

        // Store tap location
        tapLocation = location

        // Generate water droplets
        for _ in 0..<5 {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...60)

            let droplet = WaterDroplet(
                x: size.width / 2 + cos(angle) * distance,
                y: size.height / 2 + sin(angle) * distance,
                scale: 0.0,
                opacity: 0.8
            )
            waterDroplets.append(droplet)
        }

        // Animate water droplets
        withAnimation(.easeOut(duration: 0.6)) {
            for i in waterDroplets.indices {
                waterDroplets[i].scale = 1.5
                waterDroplets[i].opacity = 0.0
            }
        }

        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            waterDroplets.removeAll()
        }

        // Brief tree animation (gentle sway)
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) {
                treeScale = 1.05
            }
            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                treeScale = 1.0
            }
        }
    }

    // MARK: - Background Setup & Animation

    private func setupBackground() {
        // Calculate time of day (0-1) based on current hour
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 18 {
            // Daytime (6 AM - 6 PM)
            timeOfDay = 1.0
        } else if hour >= 18 && hour < 20 {
            // Sunset transition
            let progress = Double(hour - 18) / 2.0
            timeOfDay = 1.0 - progress
        } else if hour >= 4 && hour < 6 {
            // Sunrise transition
            let progress = Double(hour - 4) / 2.0
            timeOfDay = progress
        } else {
            // Nighttime
            timeOfDay = 0.0
        }

        // Generate stars
        if timeOfDay < 0.5 {
            for _ in 0..<80 {
                let star = Star(
                    x: CGFloat.random(in: 0...viewSize.width),
                    y: CGFloat.random(in: 0...(viewSize.height * 0.5)),
                    twinklePhase: Double.random(in: 0...(2 * .pi)),
                    brightness: Double.random(in: 0.3...1.0)
                )
                stars.append(star)
            }
        }

        // Generate clouds
        for i in 0..<5 {
            let cloud = Cloud(
                x: CGFloat(i) * (viewSize.width / 4) + CGFloat.random(in: -50...50),
                y: CGFloat.random(in: 50...200),
                scale: CGFloat.random(in: 0.8...1.5),
                speed: CGFloat.random(in: 0.5...1.5)
            )
            clouds.append(cloud)
        }
    }

    private func startBackgroundAnimations() {
        // Stop any existing timers first
        stopBackgroundAnimations()

        // Cloud movement
        cloudAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard !self.reduceMotion else { return }

            self.cloudAnimationPhase += 0.01

            for i in self.clouds.indices {
                self.clouds[i].x += self.clouds[i].speed * 0.3

                // Wrap around
                if self.clouds[i].x > self.viewSize.width + 100 {
                    self.clouds[i].x = -100
                }
            }
        }

        // Star twinkling
        starTwinkleTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard !self.reduceMotion else { return }
            self.starTwinklePhase += 0.05
        }

        // Start falling petals if ancient tree
        if gardenManager.currentStage == .ancientTree {
            startFallingPetals()
        }
    }

    private func stopBackgroundAnimations() {
        cloudAnimationTimer?.invalidate()
        cloudAnimationTimer = nil
        starTwinkleTimer?.invalidate()
        starTwinkleTimer = nil
    }

    // MARK: - Performance Optimization

    /// Stop all animations and clean up resources when view is not active
    private func stopAllAnimations() {
        // Stop all timers
        stopBackgroundAnimations()

        // Clear particle arrays to free memory
        particles.removeAll()
        stardustParticles.removeAll()
        fallingPetals.removeAll()
        waterDroplets.removeAll()
    }
}

// MARK: - Custom Shapes

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        // Simple cloud shape with 3 circles
        path.addEllipse(in: CGRect(x: w * 0.0, y: h * 0.4, width: w * 0.4, height: h * 0.6))
        path.addEllipse(in: CGRect(x: w * 0.25, y: h * 0.0, width: w * 0.5, height: h * 0.8))
        path.addEllipse(in: CGRect(x: w * 0.6, y: h * 0.4, width: w * 0.4, height: h * 0.6))

        return path
    }
}

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        // Petal shape (teardrop)
        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w / 2, y: h),
            control: CGPoint(x: 0, y: h * 0.6)
        )
        path.addQuadCurve(
            to: CGPoint(x: w / 2, y: 0),
            control: CGPoint(x: w, y: h * 0.6)
        )

        return path
    }
}

// MARK: - Color Extension for Components

extension Color {
    var components: (red: Double, green: Double, blue: Double, alpha: Double) {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return (0, 0, 0, 1)
        }

        return (Double(r), Double(g), Double(b), Double(a))
    }
}

// MARK: - Preview

#Preview {
    ZenGardenView()
}
