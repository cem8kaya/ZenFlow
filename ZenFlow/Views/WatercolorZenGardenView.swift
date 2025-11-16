//
//  WatercolorZenGardenView.swift
//  ZenFlow
//
//  Created by Claude on 2025-11-16.
//  2D Watercolor/Pastel Zen Garden with Japanese Mysticism
//

import SwiftUI

// MARK: - Koi Fish Model
struct KoiFish: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var angle: Double
    var speed: CGFloat
    var size: CGFloat
    var color: Color
    var phase: Double = 0
}

// MARK: - Sakura Petal Model
struct SakuraPetal: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var opacity: Double
    var speed: CGFloat
    var swayAmplitude: CGFloat
}

// MARK: - Bamboo Model
struct BambooStalk: Identifiable {
    let id = UUID()
    var x: CGFloat
    var height: CGFloat
    var sway: Double = 0
    var segments: Int
}

// MARK: - Watercolor Zen Garden View
struct WatercolorZenGardenView: View {
    @ObservedObject var gardenManager: ZenGardenManager

    // Animation states
    @State private var koiFish: [KoiFish] = []
    @State private var sakuraPetals: [SakuraPetal] = []
    @State private var bambooStalks: [BambooStalk] = []
    @State private var waterRipples: [CGFloat] = [0, 0, 0]
    @State private var mistOffset: CGFloat = 0
    @State private var lanternGlow: Double = 0.5

    // Timers
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky gradient background (watercolor style)
                skyGradient

                // Mountain silhouette (far background)
                mountainSilhouette(in: geometry.size)
                    .offset(y: geometry.size.height * 0.3)

                // Mist layer
                mistLayer(in: geometry.size)

                // Torii gate (background)
                toriiGate(in: geometry.size)
                    .offset(y: geometry.size.height * 0.2)

                // Sand garden with rake patterns
                sandGarden(in: geometry.size)
                    .offset(y: geometry.size.height * 0.4)

                // Water pond
                waterPond(in: geometry.size)
                    .offset(x: -geometry.size.width * 0.25, y: geometry.size.height * 0.35)

                // Koi fish in pond
                ForEach(koiFish) { fish in
                    koiFishView(fish: fish)
                        .offset(x: -geometry.size.width * 0.25, y: geometry.size.height * 0.35)
                }

                // Lotus flowers
                lotusFlowers(in: geometry.size)
                    .offset(x: -geometry.size.width * 0.25, y: geometry.size.height * 0.35)

                // Growing tree (center, based on stage)
                growingTree(for: gardenManager.currentStage, in: geometry.size)
                    .offset(y: geometry.size.height * 0.15)

                // Stone lantern
                stoneLantern(in: geometry.size)
                    .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.3)

                // Bamboo forest (left and right)
                ForEach(bambooStalks) { bamboo in
                    bambooStalkView(bamboo: bamboo, in: geometry.size)
                }

                // Falling sakura petals
                ForEach(sakuraPetals) { petal in
                    sakuraPetalView(petal: petal)
                }

                // Foreground mist
                mistLayer(in: geometry.size, isForeground: true)
                    .opacity(0.3)
            }
            .onAppear {
                initializeElements(size: geometry.size)
            }
            .onReceive(timer) { _ in
                animateElements(size: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Sky Gradient (Watercolor)

    private var skyGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.85, blue: 0.90), // Soft pink
                Color(red: 0.85, green: 0.90, blue: 0.95), // Soft blue
                Color(red: 0.90, green: 0.92, blue: 0.88), // Warm beige
                Color(red: 0.78, green: 0.82, blue: 0.88)  // Soft grey-blue
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            // Watercolor texture effect
            Canvas { context, size in
                for _ in 0..<50 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let radius = CGFloat.random(in: 30...100)

                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    let opacity = Double.random(in: 0.02...0.05)

                    context.opacity = opacity
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white)
                    )
                }
            }
        )
    }

    // MARK: - Mountain Silhouette

    private func mountainSilhouette(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: canvasSize.height))

            // Mountain peaks
            path.addLine(to: CGPoint(x: canvasSize.width * 0.15, y: canvasSize.height * 0.6))
            path.addLine(to: CGPoint(x: canvasSize.width * 0.3, y: canvasSize.height * 0.4))
            path.addLine(to: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.2))
            path.addLine(to: CGPoint(x: canvasSize.width * 0.7, y: canvasSize.height * 0.35))
            path.addLine(to: CGPoint(x: canvasSize.width * 0.85, y: canvasSize.height * 0.5))
            path.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.7))
            path.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
            path.closeSubpath()

            // Watercolor effect with gradient
            let gradient = Gradient(colors: [
                Color(red: 0.45, green: 0.50, blue: 0.60, alpha: 0.4),
                Color(red: 0.55, green: 0.60, blue: 0.70, alpha: 0.2)
            ])

            context.fill(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: canvasSize.width * 0.5, y: 0),
                    endPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height)
                )
            )
        }
        .blur(radius: 3)
    }

    // MARK: - Mist Layer

    private func mistLayer(in size: CGSize, isForeground: Bool = false) -> some View {
        Canvas { context, canvasSize in
            let yOffset = isForeground ? canvasSize.height * 0.6 : canvasSize.height * 0.3

            for i in 0..<5 {
                let offset = mistOffset + CGFloat(i * 50)
                let x = offset.truncatingRemainder(dividingBy: canvasSize.width + 200) - 100
                let y = yOffset + CGFloat(i * 20)
                let width = CGFloat.random(in: 150...300)
                let height = CGFloat.random(in: 40...80)

                let rect = CGRect(x: x, y: y, width: width, height: height)
                context.opacity = 0.15
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white)
                )
            }
        }
        .blur(radius: 20)
    }

    // MARK: - Torii Gate

    private func toriiGate(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let centerX = canvasSize.width * 0.5
            let gateWidth: CGFloat = 180
            let gateHeight: CGFloat = 140
            let pillarWidth: CGFloat = 12

            // Torii color (vermillion/red-orange)
            let toriiColor = Color(red: 0.85, green: 0.35, blue: 0.25, alpha: 0.7)

            // Left pillar
            let leftPillar = Path(
                roundedRect: CGRect(
                    x: centerX - gateWidth/2,
                    y: 0,
                    width: pillarWidth,
                    height: gateHeight
                ),
                cornerRadius: 3
            )
            context.fill(leftPillar, with: .color(toriiColor))

            // Right pillar
            let rightPillar = Path(
                roundedRect: CGRect(
                    x: centerX + gateWidth/2 - pillarWidth,
                    y: 0,
                    width: pillarWidth,
                    height: gateHeight
                ),
                cornerRadius: 3
            )
            context.fill(rightPillar, with: .color(toriiColor))

            // Top beam (kasagi)
            let topBeam = Path(
                roundedRect: CGRect(
                    x: centerX - gateWidth/2 - 15,
                    y: 15,
                    width: gateWidth + 30,
                    height: 14
                ),
                cornerRadius: 7
            )
            context.fill(topBeam, with: .color(toriiColor))

            // Middle beam (nuki)
            let middleBeam = Path(
                roundedRect: CGRect(
                    x: centerX - gateWidth/2 - 5,
                    y: 55,
                    width: gateWidth + 10,
                    height: 10
                ),
                cornerRadius: 5
            )
            context.fill(middleBeam, with: .color(toriiColor))
        }
        .blur(radius: 1.5)
    }

    // MARK: - Sand Garden

    private func sandGarden(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            // Sand base
            let sandRect = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height * 0.6)
            let sandGradient = Gradient(colors: [
                Color(red: 0.96, green: 0.94, blue: 0.88),
                Color(red: 0.92, green: 0.90, blue: 0.85)
            ])

            context.fill(
                Path(roundedRect: sandRect, cornerRadius: 0),
                with: .linearGradient(
                    sandGradient,
                    startPoint: CGPoint(x: canvasSize.width * 0.5, y: 0),
                    endPoint: CGPoint(x: canvasSize.width * 0.5, y: sandRect.height)
                )
            )

            // Rake patterns (concentric circles)
            context.opacity = 0.3
            let rakeColor = Color(red: 0.85, green: 0.83, blue: 0.78)

            for radius in stride(from: 30, through: 200, by: 15) {
                let center = CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.3)
                var path = Path()
                path.addEllipse(in: CGRect(
                    x: center.x - CGFloat(radius),
                    y: center.y - CGFloat(radius) * 0.5,
                    width: CGFloat(radius) * 2,
                    height: CGFloat(radius)
                ))

                context.stroke(path, with: .color(rakeColor), lineWidth: 1)
            }
        }
    }

    // MARK: - Water Pond

    private func waterPond(in size: CGSize) -> some View {
        ZStack {
            // Pond shape
            Canvas { context, canvasSize in
                let pondPath = Path { path in
                    // Organic pond shape
                    path.move(to: CGPoint(x: 50, y: 80))
                    path.addQuadCurve(
                        to: CGPoint(x: 200, y: 70),
                        control: CGPoint(x: 125, y: 30)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: 250, y: 150),
                        control: CGPoint(x: 240, y: 100)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: 180, y: 200),
                        control: CGPoint(x: 230, y: 180)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: 60, y: 180),
                        control: CGPoint(x: 120, y: 210)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: 50, y: 80),
                        control: CGPoint(x: 40, y: 130)
                    )
                }

                // Water gradient
                let waterGradient = Gradient(colors: [
                    Color(red: 0.40, green: 0.60, blue: 0.70, alpha: 0.7),
                    Color(red: 0.25, green: 0.45, blue: 0.60, alpha: 0.8)
                ])

                context.fill(
                    pondPath,
                    with: .linearGradient(
                        waterGradient,
                        startPoint: CGPoint(x: 150, y: 50),
                        endPoint: CGPoint(x: 150, y: 200)
                    )
                )
            }
            .blur(radius: 2)

            // Water ripples
            Canvas { context, canvasSize in
                context.opacity = 0.3
                for (index, ripple) in waterRipples.enumerated() {
                    let center = CGPoint(
                        x: 100 + CGFloat(index * 40),
                        y: 120 + CGFloat(index * 20)
                    )

                    for r in stride(from: ripple, through: ripple + 30, by: 10) {
                        var path = Path()
                        path.addEllipse(in: CGRect(
                            x: center.x - r,
                            y: center.y - r * 0.7,
                            width: r * 2,
                            height: r * 1.4
                        ))

                        context.stroke(
                            path,
                            with: .color(.white),
                            lineWidth: 1.5
                        )
                    }
                }
            }
        }
        .frame(width: 300, height: 250)
    }

    // MARK: - Koi Fish

    private func koiFishView(fish: KoiFish) -> some View {
        Canvas { context, size in
            // Fish body (elongated ellipse)
            let bodyLength: CGFloat = fish.size
            let bodyWidth: CGFloat = fish.size * 0.4

            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: fish.x, y: fish.y)
            transform = transform.rotated(by: fish.angle)

            context.transform = transform

            // Body
            let bodyPath = Path(
                ellipseIn: CGRect(
                    x: -bodyLength/2,
                    y: -bodyWidth/2,
                    width: bodyLength,
                    height: bodyWidth
                )
            )

            context.fill(bodyPath, with: .color(fish.color))

            // Tail fin
            var tailPath = Path()
            tailPath.move(to: CGPoint(x: -bodyLength/2, y: 0))
            tailPath.addQuadCurve(
                to: CGPoint(x: -bodyLength/2 - 15, y: 8),
                control: CGPoint(x: -bodyLength/2 - 10, y: 5)
            )
            tailPath.addQuadCurve(
                to: CGPoint(x: -bodyLength/2, y: 0),
                control: CGPoint(x: -bodyLength/2 - 10, y: 3)
            )

            context.fill(tailPath, with: .color(fish.color.opacity(0.8)))

            // Eye
            let eyePath = Path(
                ellipseIn: CGRect(
                    x: bodyLength/4,
                    y: -2,
                    width: 3,
                    height: 3
                )
            )
            context.fill(eyePath, with: .color(.black.opacity(0.6)))
        }
    }

    // MARK: - Lotus Flowers

    private func lotusFlowers(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let lotusPositions: [(x: CGFloat, y: CGFloat)] = [
                (80, 100),
                (180, 140),
                (220, 90)
            ]

            for pos in lotusPositions {
                // Lily pad
                let padPath = Path(
                    ellipseIn: CGRect(
                        x: pos.x - 25,
                        y: pos.y - 20,
                        width: 50,
                        height: 40
                    )
                )
                context.fill(
                    padPath,
                    with: .color(Color(red: 0.3, green: 0.6, blue: 0.4, alpha: 0.7))
                )

                // Lotus flower (simple)
                for i in 0..<5 {
                    let angle = Double(i) * (2 * .pi / 5)
                    let petalX = pos.x + cos(angle) * 8
                    let petalY = pos.y + sin(angle) * 8

                    let petalPath = Path(
                        ellipseIn: CGRect(
                            x: petalX - 6,
                            y: petalY - 8,
                            width: 12,
                            height: 16
                        )
                    )

                    context.fill(
                        petalPath,
                        with: .color(Color(red: 0.98, green: 0.85, blue: 0.90, alpha: 0.9))
                    )
                }

                // Center
                let centerPath = Path(
                    ellipseIn: CGRect(
                        x: pos.x - 5,
                        y: pos.y - 5,
                        width: 10,
                        height: 10
                    )
                )
                context.fill(
                    centerPath,
                    with: .color(Color(red: 0.95, green: 0.85, blue: 0.3, alpha: 0.8))
                )
            }
        }
        .frame(width: 300, height: 250)
    }

    // MARK: - Growing Tree (Based on Stage)

    private func growingTree(for stage: TreeGrowthStage, in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let centerX = canvasSize.width * 0.5
            let baseY = canvasSize.height * 0.6

            switch stage {
            case .seed:
                // Small seed
                let seedPath = Path(
                    ellipseIn: CGRect(
                        x: centerX - 8,
                        y: baseY - 8,
                        width: 16,
                        height: 16
                    )
                )
                context.fill(seedPath, with: .color(Color(red: 0.5, green: 0.35, blue: 0.25)))

            case .sprout:
                // Seed + small stem
                let seedPath = Path(
                    ellipseIn: CGRect(
                        x: centerX - 6,
                        y: baseY - 6,
                        width: 12,
                        height: 12
                    )
                )
                context.fill(seedPath, with: .color(Color(red: 0.5, green: 0.35, blue: 0.25)))

                // Stem
                var stemPath = Path()
                stemPath.move(to: CGPoint(x: centerX, y: baseY))
                stemPath.addLine(to: CGPoint(x: centerX, y: baseY - 40))
                context.stroke(stemPath, with: .color(Color(red: 0.4, green: 0.7, blue: 0.3)), lineWidth: 3)

                // Small leaves
                for i in 0..<2 {
                    let side: CGFloat = i == 0 ? -1 : 1
                    let leafPath = Path(
                        ellipseIn: CGRect(
                            x: centerX + side * 8 - 6,
                            y: baseY - 30 - 6,
                            width: 12,
                            height: 18
                        )
                    )
                    context.fill(leafPath, with: .color(Color(red: 0.5, green: 0.8, blue: 0.4, alpha: 0.8)))
                }

            case .sapling:
                drawSakuraTree(context: &context, centerX: centerX, baseY: baseY, size: 1.0, blossomAmount: 0.0)

            case .youngTree:
                drawSakuraTree(context: &context, centerX: centerX, baseY: baseY, size: 1.5, blossomAmount: 0.3)

            case .matureTree:
                drawSakuraTree(context: &context, centerX: centerX, baseY: baseY, size: 2.0, blossomAmount: 0.7)

            case .ancientTree:
                drawSakuraTree(context: &context, centerX: centerX, baseY: baseY, size: 2.5, blossomAmount: 1.0)
            }
        }
        .blur(radius: 0.5) // Subtle watercolor blur
    }

    private func drawSakuraTree(context: inout GraphicsContext, centerX: CGFloat, baseY: CGFloat, size: CGFloat, blossomAmount: Double) {
        // Trunk
        let trunkWidth = 15 * size
        let trunkHeight = 100 * size

        var trunkPath = Path()
        trunkPath.move(to: CGPoint(x: centerX - trunkWidth/2, y: baseY))
        trunkPath.addLine(to: CGPoint(x: centerX - trunkWidth/3, y: baseY - trunkHeight))
        trunkPath.addLine(to: CGPoint(x: centerX + trunkWidth/3, y: baseY - trunkHeight))
        trunkPath.addLine(to: CGPoint(x: centerX + trunkWidth/2, y: baseY))
        trunkPath.closeSubpath()

        context.fill(trunkPath, with: .color(Color(red: 0.35, green: 0.25, blue: 0.20, alpha: 0.8)))

        // Branches
        let branches: [(angle: Double, length: CGFloat, y: CGFloat)] = [
            (-0.6, 50 * size, trunkHeight * 0.4),
            (0.6, 45 * size, trunkHeight * 0.5),
            (-0.4, 55 * size, trunkHeight * 0.7),
            (0.5, 50 * size, trunkHeight * 0.8),
            (0.0, 40 * size, trunkHeight * 0.95)
        ]

        for branch in branches {
            var branchPath = Path()
            let startX = centerX
            let startY = baseY - branch.y
            let endX = startX + cos(branch.angle) * branch.length
            let endY = startY - sin(branch.angle + 0.5) * branch.length

            branchPath.move(to: CGPoint(x: startX, y: startY))
            branchPath.addLine(to: CGPoint(x: endX, y: endY))

            context.stroke(branchPath, with: .color(Color(red: 0.40, green: 0.30, blue: 0.25, alpha: 0.7)), lineWidth: 4 * size)

            // Blossoms on branch
            if blossomAmount > 0 {
                let blossomCount = Int(Double.random(in: 3...8) * blossomAmount)
                for i in 0..<blossomCount {
                    let t = CGFloat(i) / CGFloat(blossomCount)
                    let blossomX = startX + (endX - startX) * t + CGFloat.random(in: -10...10)
                    let blossomY = startY + (endY - startY) * t + CGFloat.random(in: -10...10)

                    drawSakuraBlossom(context: &context, x: blossomX, y: blossomY, size: 8 * size)
                }
            }
        }

        // Canopy blossoms
        if blossomAmount > 0 {
            let canopyRadius = 60 * size
            let blossomCount = Int(30 * blossomAmount)

            for _ in 0..<blossomCount {
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 0...canopyRadius)
                let blossomX = centerX + cos(angle) * distance
                let blossomY = baseY - trunkHeight + sin(angle) * distance * 0.6

                drawSakuraBlossom(context: &context, x: blossomX, y: blossomY, size: CGFloat.random(in: 6...12) * size)
            }
        }
    }

    private func drawSakuraBlossom(context: inout GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat) {
        // 5 petals
        for i in 0..<5 {
            let angle = Double(i) * (2 * .pi / 5) - .pi / 2
            let petalX = x + cos(angle) * size * 0.4
            let petalY = y + sin(angle) * size * 0.4

            let petalPath = Path(
                ellipseIn: CGRect(
                    x: petalX - size * 0.4,
                    y: petalY - size * 0.5,
                    width: size * 0.8,
                    height: size
                )
            )

            let petalColor = Color(
                red: 1.0,
                green: Double.random(in: 0.75...0.85),
                blue: Double.random(in: 0.80...0.90),
                alpha: 0.8
            )

            context.fill(petalPath, with: .color(petalColor))
        }

        // Center
        let centerPath = Path(
            ellipseIn: CGRect(
                x: x - size * 0.2,
                y: y - size * 0.2,
                width: size * 0.4,
                height: size * 0.4
            )
        )
        context.fill(centerPath, with: .color(Color(red: 0.95, green: 0.85, blue: 0.3, alpha: 0.9)))
    }

    // MARK: - Stone Lantern

    private func stoneLantern(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let x: CGFloat = 100
            let y: CGFloat = 80

            let stoneColor = Color(red: 0.50, green: 0.48, blue: 0.45, alpha: 0.8)

            // Base
            let basePath = Path(
                roundedRect: CGRect(x: x - 20, y: y + 60, width: 40, height: 10),
                cornerRadius: 2
            )
            context.fill(basePath, with: .color(stoneColor))

            // Post
            let postPath = Path(
                roundedRect: CGRect(x: x - 8, y: y + 20, width: 16, height: 40),
                cornerRadius: 2
            )
            context.fill(postPath, with: .color(stoneColor))

            // Light box
            let lightBoxPath = Path(
                roundedRect: CGRect(x: x - 15, y: y, width: 30, height: 25),
                cornerRadius: 3
            )
            context.fill(lightBoxPath, with: .color(Color(red: 0.95, green: 0.93, blue: 0.88, alpha: 0.7)))

            // Glow effect
            context.opacity = lanternGlow
            let glowPath = Path(
                ellipseIn: CGRect(x: x - 20, y: y - 5, width: 40, height: 35)
            )
            context.fill(glowPath, with: .color(Color(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.6)))
            context.opacity = 1.0

            // Roof
            var roofPath = Path()
            roofPath.move(to: CGPoint(x: x - 25, y: y))
            roofPath.addLine(to: CGPoint(x: x, y: y - 15))
            roofPath.addLine(to: CGPoint(x: x + 25, y: y))
            roofPath.closeSubpath()

            context.fill(roofPath, with: .color(Color(red: 0.35, green: 0.33, blue: 0.30, alpha: 0.8)))
        }
        .frame(width: 200, height: 150)
        .blur(radius: 0.8)
    }

    // MARK: - Bamboo Stalk

    private func bambooStalkView(bamboo: BambooStalk, in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let segments = bamboo.segments
            let segmentHeight = bamboo.height / CGFloat(segments)

            for i in 0..<segments {
                let y = CGFloat(i) * segmentHeight
                let sway = sin(bamboo.sway + Double(i) * 0.3) * 3

                // Bamboo segment
                let segmentPath = Path(
                    roundedRect: CGRect(
                        x: bamboo.x + sway,
                        y: size.height - y - segmentHeight,
                        width: 12,
                        height: segmentHeight
                    ),
                    cornerRadius: 4
                )

                let bambooColor = Color(
                    red: 0.45,
                    green: 0.62,
                    blue: 0.35,
                    alpha: 0.7
                )

                context.fill(segmentPath, with: .color(bambooColor))

                // Segment ring
                let ringPath = Path(
                    ellipseIn: CGRect(
                        x: bamboo.x + sway - 2,
                        y: size.height - y - 3,
                        width: 16,
                        height: 6
                    )
                )

                context.fill(ringPath, with: .color(Color(red: 0.35, green: 0.52, blue: 0.25, alpha: 0.8)))
            }

            // Leaves at top
            for i in 0..<3 {
                let angle = Double(i) * 0.8 - 0.8
                let swayOffset = sin(bamboo.sway + Double(i) * 0.5) * 5

                var leafPath = Path()
                leafPath.move(to: CGPoint(x: bamboo.x + 6, y: size.height - bamboo.height))
                leafPath.addQuadCurve(
                    to: CGPoint(
                        x: bamboo.x + 6 + cos(angle) * 25 + swayOffset,
                        y: size.height - bamboo.height - sin(angle) * 40
                    ),
                    control: CGPoint(
                        x: bamboo.x + 6 + cos(angle) * 15,
                        y: size.height - bamboo.height - sin(angle) * 20
                    )
                )

                context.stroke(
                    leafPath,
                    with: .color(Color(red: 0.40, green: 0.70, blue: 0.30, alpha: 0.7)),
                    lineWidth: 3
                )
            }
        }
        .blur(radius: 0.5)
    }

    // MARK: - Sakura Petal

    private func sakuraPetalView(petal: SakuraPetal) -> some View {
        Canvas { context, size in
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: petal.x, y: petal.y)
            transform = transform.rotated(by: petal.rotation)

            context.transform = transform
            context.opacity = petal.opacity

            // Petal shape
            let petalPath = Path(
                ellipseIn: CGRect(x: -4, y: -6, width: 8, height: 12)
            )

            let petalColor = Color(red: 1.0, green: 0.80, blue: 0.85, alpha: 0.9)
            context.fill(petalPath, with: .color(petalColor))
        }
    }

    // MARK: - Initialize Elements

    private func initializeElements(size: CGSize) {
        // Initialize koi fish
        koiFish = (0..<5).map { i in
            KoiFish(
                x: CGFloat.random(in: 60...240),
                y: CGFloat.random(in: 80...180),
                angle: Double.random(in: 0...(2 * .pi)),
                speed: CGFloat.random(in: 0.3...0.8),
                size: CGFloat.random(in: 25...40),
                color: [
                    Color(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.8),
                    Color(red: 1.0, green: 0.95, blue: 0.95, alpha: 0.9),
                    Color(red: 0.9, green: 0.3, blue: 0.2, alpha: 0.85)
                ].randomElement()!,
                phase: Double(i) * 0.5
            )
        }

        // Initialize bamboo
        let leftBamboo = (0..<4).map { i in
            BambooStalk(
                x: CGFloat(20 + i * 25),
                height: CGFloat.random(in: 200...300),
                segments: Int.random(in: 6...10)
            )
        }

        let rightBamboo = (0..<4).map { i in
            BambooStalk(
                x: size.width - CGFloat(120 - i * 25),
                height: CGFloat.random(in: 200...300),
                segments: Int.random(in: 6...10)
            )
        }

        bambooStalks = leftBamboo + rightBamboo

        // Initialize sakura petals (if mature tree)
        if gardenManager.currentStage == .matureTree || gardenManager.currentStage == .ancientTree {
            generateSakuraPetals(size: size)
        }
    }

    // MARK: - Animate Elements

    private func animateElements(size: CGSize) {
        // Animate koi fish
        for i in 0..<koiFish.count {
            koiFish[i].phase += 0.05

            // Swimming motion
            let wave = sin(koiFish[i].phase) * 2
            koiFish[i].x += cos(koiFish[i].angle) * koiFish[i].speed
            koiFish[i].y += sin(koiFish[i].angle) * koiFish[i].speed + wave

            // Boundary check (stay in pond area)
            if koiFish[i].x < 60 || koiFish[i].x > 240 {
                koiFish[i].angle = .pi - koiFish[i].angle
            }
            if koiFish[i].y < 70 || koiFish[i].y > 190 {
                koiFish[i].angle = -koiFish[i].angle
            }

            // Random direction changes
            if Double.random(in: 0...1) < 0.02 {
                koiFish[i].angle += Double.random(in: -0.3...0.3)
            }
        }

        // Animate water ripples
        for i in 0..<waterRipples.count {
            waterRipples[i] += 1.5
            if waterRipples[i] > 40 {
                waterRipples[i] = 0
            }
        }

        // Animate mist
        mistOffset += 0.3
        if mistOffset > size.width + 200 {
            mistOffset = 0
        }

        // Animate lantern glow
        lanternGlow = 0.5 + sin(Date().timeIntervalSince1970 * 2) * 0.2

        // Animate bamboo sway
        for i in 0..<bambooStalks.count {
            bambooStalks[i].sway += 0.02
        }

        // Animate sakura petals
        if !sakuraPetals.isEmpty {
            for i in 0..<sakuraPetals.count {
                sakuraPetals[i].y += sakuraPetals[i].speed
                sakuraPetals[i].x += sin(sakuraPetals[i].y * 0.05) * sakuraPetals[i].swayAmplitude
                sakuraPetals[i].rotation += 2

                // Reset if off screen
                if sakuraPetals[i].y > size.height {
                    sakuraPetals[i].y = -20
                    sakuraPetals[i].x = CGFloat.random(in: 0...size.width)
                }
            }
        } else if gardenManager.currentStage == .matureTree || gardenManager.currentStage == .ancientTree {
            // Generate petals for mature trees
            if Double.random(in: 0...1) < 0.1 {
                generateSakuraPetals(size: size, count: 1)
            }
        }
    }

    private func generateSakuraPetals(size: CGSize, count: Int = 15) {
        for _ in 0..<count {
            let petal = SakuraPetal(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -100...0),
                rotation: Double.random(in: 0...360),
                opacity: Double.random(in: 0.6...0.9),
                speed: CGFloat.random(in: 0.5...1.5),
                swayAmplitude: CGFloat.random(in: 0.5...2.0)
            )
            sakuraPetals.append(petal)
        }

        // Limit petal count
        if sakuraPetals.count > 30 {
            sakuraPetals.removeFirst(sakuraPetals.count - 30)
        }
    }
}

// MARK: - Preview
#Preview {
    WatercolorZenGardenView(gardenManager: ZenGardenManager())
}
