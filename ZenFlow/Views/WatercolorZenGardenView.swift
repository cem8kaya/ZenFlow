//
//  WatercolorZenGardenView.swift
//  ZenFlow
//
//  Created by Claude on 2025-11-16.
//  Minimal Zen Garden with Natural Tree Growth
//

import SwiftUI
import Combine

// MARK: - Minimal Zen Garden View
struct WatercolorZenGardenView: View {
    @ObservedObject var gardenManager: ZenGardenManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Animation states
    @State private var windPhase: Double = 0
    @State private var treeGrowthScale: CGFloat = 1.0
    @State private var leafSway: Double = 0

    // Timers - using .default RunLoop for better performance
    let timer = Timer.publish(every: 0.05, on: .main, in: .default).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Natural background gradient (soft beige/cream)
                naturalBackgroundGradient

                // Minimal zen sand circle with rake pattern
                zenSandCircle(in: geometry.size)
                    .offset(y: geometry.size.height * 0.15)

                // Tree (drawn with Canvas based on growth stage)
                treeView(in: geometry.size)
                    .offset(y: geometry.size.height * 0.1)
                    .scaleEffect(treeGrowthScale)
            }
            .onReceive(timer) { _ in
                // Skip animations if Reduce Motion is enabled
                if !reduceMotion {
                    animateElements()
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: gardenManager.currentStage) { _, _ in
            animateGrowth()
        }
    }

    // MARK: - Natural Background

    private var naturalBackgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.97, blue: 0.92), // Very soft cream
                Color(red: 0.96, green: 0.94, blue: 0.88), // Warm beige
                Color(red: 0.94, green: 0.92, blue: 0.86)  // Soft earth
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            // Subtle texture - optimized: use simple overlay instead of Canvas redraw
            ZenTheme.earthBrown
                .opacity(0.02)
                .blur(radius: 40)
        )
    }

    // MARK: - Zen Sand Circle

    private func zenSandCircle(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let centerX = canvasSize.width * 0.5
            let centerY = canvasSize.height * 0.5
            let radius: CGFloat = 160

            // Sand circle base
            let circlePath = Path(ellipseIn: CGRect(
                x: centerX - radius,
                y: centerY - radius,
                width: radius * 2,
                height: radius * 2
            ))

            let sandGradient = Gradient(colors: [
                ZenTheme.sandTan.opacity(0.4),
                ZenTheme.sandTan.opacity(0.25)
            ])

            context.fill(
                circlePath,
                with: .radialGradient(
                    sandGradient,
                    center: CGPoint(x: centerX, y: centerY),
                    startRadius: 0,
                    endRadius: radius
                )
            )

            // Concentric rake patterns
            context.opacity = 0.25
            let rakeColor = ZenTheme.earthBrown

            for r in stride(from: 30, through: radius - 10, by: 15) {
                var rakePath = Path()
                rakePath.addEllipse(in: CGRect(
                    x: centerX - r,
                    y: centerY - r,
                    width: r * 2,
                    height: r * 2
                ))

                context.stroke(rakePath, with: .color(rakeColor), lineWidth: 1.5)
            }
        }
    }

    // MARK: - Tree View (Canvas Drawing)

    private func treeView(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let centerX = canvasSize.width * 0.5
            let centerY = canvasSize.height * 0.5

            switch gardenManager.currentStage {
            case .seed:
                drawSeed(context: context, centerX: centerX, centerY: centerY)
            case .sprout:
                drawSprout(context: context, centerX: centerX, centerY: centerY, sway: leafSway)
            case .sapling:
                drawSapling(context: context, centerX: centerX, centerY: centerY, sway: leafSway)
            case .youngTree:
                drawYoungTree(context: context, centerX: centerX, centerY: centerY, sway: leafSway)
            case .matureTree:
                drawMatureTree(context: context, centerX: centerX, centerY: centerY, sway: leafSway)
            case .ancientTree:
                drawAncientTree(context: context, centerX: centerX, centerY: centerY, sway: leafSway)
            }

            // Subtle shadow
            context.opacity = 0.15
            let shadowPath = Path(ellipseIn: CGRect(
                x: centerX - 30,
                y: centerY + getTreeHeight(for: gardenManager.currentStage) - 5,
                width: 60,
                height: 15
            ))
            context.fill(shadowPath, with: .color(.black))
        }
    }

    // MARK: - Tree Drawing Functions

    private func drawSeed(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat) {
        var context = context
        // Small brown seed
        let seedPath = Path(ellipseIn: CGRect(
            x: centerX - 8,
            y: centerY - 8,
            width: 16,
            height: 16
        ))
        context.fill(seedPath, with: .color(ZenTheme.earthBrown))

        // Highlight
        context.opacity = 0.3
        let highlightPath = Path(ellipseIn: CGRect(
            x: centerX - 4,
            y: centerY - 6,
            width: 6,
            height: 6
        ))
        context.fill(highlightPath, with: .color(.white))
    }

    private func drawSprout(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, sway: Double) {
        let swayOffset = sin(sway) * 2

        // Thin stem
        var stemPath = Path()
        stemPath.move(to: CGPoint(x: centerX + swayOffset, y: centerY))
        stemPath.addLine(to: CGPoint(x: centerX + swayOffset, y: centerY - 30))
        context.stroke(stemPath, with: .color(Color(red: 0.5, green: 0.7, blue: 0.3)), lineWidth: 2)

        // 2-3 small leaves
        for i in 0..<2 {
            let yPos = centerY - CGFloat(15 + i * 10)
            let side = i % 2 == 0 ? -1.0 : 1.0
            let leafSway = sin(sway + Double(i) * 0.5) * 1.5

            var leafPath = Path()
            leafPath.move(to: CGPoint(x: centerX + swayOffset, y: yPos))
            leafPath.addQuadCurve(
                to: CGPoint(x: centerX + swayOffset + side * (8 + leafSway), y: yPos - 6),
                control: CGPoint(x: centerX + swayOffset + side * 6, y: yPos - 3)
            )

            context.stroke(leafPath, with: .color(Color(red: 0.5, green: 0.8, blue: 0.3)), lineWidth: 2)
        }
    }

    private func drawSapling(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, sway: Double) {
        let swayOffset = sin(sway) * 3

        // Thin trunk
        var trunkPath = Path()
        trunkPath.move(to: CGPoint(x: centerX, y: centerY))
        trunkPath.addLine(to: CGPoint(x: centerX + swayOffset, y: centerY - 60))
        context.stroke(trunkPath, with: .color(ZenTheme.earthBrown), lineWidth: 4)

        // A few branches with leaves
        for i in 0..<3 {
            let yPos = centerY - CGFloat(30 + i * 15)
            let side = i % 2 == 0 ? -1.0 : 1.0
            let branchSway = sin(sway + Double(i) * 0.3) * 2

            // Branch
            var branchPath = Path()
            branchPath.move(to: CGPoint(x: centerX + swayOffset, y: yPos))
            branchPath.addLine(to: CGPoint(x: centerX + swayOffset + side * (15 + branchSway), y: yPos - 10))
            context.stroke(branchPath, with: .color(ZenTheme.earthBrown.opacity(0.8)), lineWidth: 2)

            // Leaves cluster
            let leafX = centerX + swayOffset + side * (15 + branchSway)
            let leafY = yPos - 10

            for j in 0..<3 {
                let angle = Double(j) * 0.5 - 0.5
                let leafPath = Path(ellipseIn: CGRect(
                    x: leafX + cos(angle) * 6 - 3,
                    y: leafY + sin(angle) * 6 - 4,
                    width: 6,
                    height: 8
                ))
                context.fill(leafPath, with: .color(Color(red: 0.4, green: 0.7, blue: 0.25)))
            }
        }
    }

    private func drawYoungTree(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, sway: Double) {
        let swayOffset = sin(sway) * 4

        // Medium trunk
        var trunkPath = Path()
        trunkPath.move(to: CGPoint(x: centerX, y: centerY))
        trunkPath.addQuadCurve(
            to: CGPoint(x: centerX + swayOffset, y: centerY - 90),
            control: CGPoint(x: centerX + swayOffset * 0.5, y: centerY - 45)
        )
        context.stroke(trunkPath, with: .color(ZenTheme.earthBrown), lineWidth: 8)

        // Multiple branches with fuller foliage
        for i in 0..<5 {
            let yPos = centerY - CGFloat(40 + i * 12)
            let side = i % 2 == 0 ? -1.0 : 1.0
            let branchSway = sin(sway + Double(i) * 0.3) * 3

            var branchPath = Path()
            branchPath.move(to: CGPoint(x: centerX + swayOffset, y: yPos))
            branchPath.addQuadCurve(
                to: CGPoint(x: centerX + swayOffset + side * (25 + branchSway), y: yPos - 15),
                control: CGPoint(x: centerX + swayOffset + side * 15, y: yPos - 7)
            )
            context.stroke(branchPath, with: .color(ZenTheme.earthBrown.opacity(0.8)), lineWidth: 3)

            // Leaf cluster
            let leafX = centerX + swayOffset + side * (25 + branchSway)
            let leafY = yPos - 15

            for j in 0..<5 {
                let angle = Double(j) * 0.6 - 1.2
                let leafPath = Path(ellipseIn: CGRect(
                    x: leafX + cos(angle) * 8 - 4,
                    y: leafY + sin(angle) * 8 - 5,
                    width: 8,
                    height: 10
                ))
                context.fill(leafPath, with: .color(ZenTheme.sageGreen))
            }
        }
    }

    private func drawMatureTree(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, sway: Double) {
        let swayOffset = sin(sway) * 5

        // Thick trunk
        var trunkPath = Path()
        trunkPath.move(to: CGPoint(x: centerX - 6, y: centerY))
        trunkPath.addQuadCurve(
            to: CGPoint(x: centerX + swayOffset - 6, y: centerY - 120),
            control: CGPoint(x: centerX + swayOffset * 0.5 - 6, y: centerY - 60)
        )
        trunkPath.addLine(to: CGPoint(x: centerX + swayOffset + 6, y: centerY - 120))
        trunkPath.addQuadCurve(
            to: CGPoint(x: centerX + 6, y: centerY),
            control: CGPoint(x: centerX + swayOffset * 0.5 + 6, y: centerY - 60)
        )
        trunkPath.closeSubpath()
        context.fill(trunkPath, with: .color(ZenTheme.earthBrown))

        // Wide canopy with many branches
        for i in 0..<8 {
            let yPos = centerY - CGFloat(50 + i * 10)
            let side = i % 2 == 0 ? -1.0 : 1.0
            let branchSway = sin(sway + Double(i) * 0.25) * 4

            var branchPath = Path()
            branchPath.move(to: CGPoint(x: centerX + swayOffset, y: yPos))
            branchPath.addQuadCurve(
                to: CGPoint(x: centerX + swayOffset + side * (35 + branchSway), y: yPos - 20),
                control: CGPoint(x: centerX + swayOffset + side * 20, y: yPos - 10)
            )
            context.stroke(branchPath, with: .color(ZenTheme.earthBrown.opacity(0.7)), lineWidth: 4)

            // Dense foliage
            let leafX = centerX + swayOffset + side * (35 + branchSway)
            let leafY = yPos - 20

            for j in 0..<8 {
                let angle = Double(j) * 0.8 - 2.8
                let distance = CGFloat.random(in: 5...12)
                let leafPath = Path(ellipseIn: CGRect(
                    x: leafX + CGFloat(cos(angle)) * distance - 5,
                    y: leafY + CGFloat(sin(angle)) * distance - 6,
                    width: 10,
                    height: 12
                ))
                context.fill(leafPath, with: .color(ZenTheme.deepSage))
            }
        }
    }

    private func drawAncientTree(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, sway: Double) {
        var context = context
        let swayOffset = sin(sway) * 6

        // Very thick, majestic trunk
        var trunkPath = Path()
        trunkPath.move(to: CGPoint(x: centerX - 10, y: centerY))
        trunkPath.addQuadCurve(
            to: CGPoint(x: centerX + swayOffset - 8, y: centerY - 150),
            control: CGPoint(x: centerX + swayOffset * 0.5 - 9, y: centerY - 75)
        )
        trunkPath.addLine(to: CGPoint(x: centerX + swayOffset + 8, y: centerY - 150))
        trunkPath.addQuadCurve(
            to: CGPoint(x: centerX + 10, y: centerY),
            control: CGPoint(x: centerX + swayOffset * 0.5 + 9, y: centerY - 75)
        )
        trunkPath.closeSubpath()
        context.fill(trunkPath, with: .color(ZenTheme.earthBrown))

        // Trunk texture (bark)
        context.opacity = 0.2
        for i in 0..<5 {
            let yPos = centerY - CGFloat(i * 30)
            var barkPath = Path()
            barkPath.move(to: CGPoint(x: centerX - 8, y: yPos))
            barkPath.addLine(to: CGPoint(x: centerX + 8, y: yPos))
            context.stroke(barkPath, with: .color(.black), lineWidth: 1)
        }
        context.opacity = 1.0

        // Magnificent canopy with sakura-style blossoms
        for i in 0..<12 {
            let yPos = centerY - CGFloat(60 + i * 10)
            let side = i % 2 == 0 ? -1.0 : 1.0
            let branchSway = sin(sway + Double(i) * 0.2) * 5

            var branchPath = Path()
            branchPath.move(to: CGPoint(x: centerX + swayOffset, y: yPos))
            branchPath.addQuadCurve(
                to: CGPoint(x: centerX + swayOffset + side * (45 + branchSway), y: yPos - 25),
                control: CGPoint(x: centerX + swayOffset + side * 25, y: yPos - 12)
            )
            context.stroke(branchPath, with: .color(ZenTheme.earthBrown.opacity(0.6)), lineWidth: 5)

            // Dense foliage with blossoms
            let leafX = centerX + swayOffset + side * (45 + branchSway)
            let leafY = yPos - 25

            // Green leaves
            for j in 0..<10 {
                let angle = Double(j) * 0.7 - 3.5
                let distance = CGFloat.random(in: 8...15)
                let leafPath = Path(ellipseIn: CGRect(
                    x: leafX + CGFloat(cos(angle)) * distance - 6,
                    y: leafY + CGFloat(sin(angle)) * distance - 7,
                    width: 12,
                    height: 14
                ))
                context.fill(leafPath, with: .color(ZenTheme.deepSage))
            }

            // Pink blossoms (sakura style)
            for j in 0..<5 {
                let angle = Double(j) * 0.8 - 2.0
                let distance = CGFloat.random(in: 10...18)
                let blossomX = leafX + cos(angle) * distance
                let blossomY = leafY + sin(angle) * distance

                // 5 petals
                for k in 0..<5 {
                    let petalAngle = Double(k) * (2 * .pi / 5)
                    let petalPath = Path(ellipseIn: CGRect(
                        x: blossomX + cos(petalAngle) * 3 - 2,
                        y: blossomY + sin(petalAngle) * 3 - 3,
                        width: 4,
                        height: 6
                    ))
                    context.fill(petalPath, with: .color(Color(red: 1.0, green: 0.75, blue: 0.8)))
                }

                // Center
                let centerPath = Path(ellipseIn: CGRect(
                    x: blossomX - 1.5,
                    y: blossomY - 1.5,
                    width: 3,
                    height: 3
                ))
                context.fill(centerPath, with: .color(Color(red: 1.0, green: 0.85, blue: 0.4)))
            }
        }

        // Subtle glow effect for ancient tree
        context.opacity = 0.1
        let glowPath = Path(ellipseIn: CGRect(
            x: centerX - 80,
            y: centerY - 160,
            width: 160,
            height: 180
        ))
        context.fill(glowPath, with: .color(Color(red: 1.0, green: 0.9, blue: 0.7)))
    }

    // MARK: - Helper Functions

    private func getTreeHeight(for stage: TreeGrowthStage) -> CGFloat {
        switch stage {
        case .seed: return 10
        case .sprout: return 35
        case .sapling: return 65
        case .youngTree: return 95
        case .matureTree: return 125
        case .ancientTree: return 155
        }
    }

    // MARK: - Animations

    private func animateElements() {
        // Wind effect (leaf sway)
        leafSway += 0.03
    }

    private func animateGrowth() {
        // Use simpler animation if Reduce Motion is enabled
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) {
                treeGrowthScale = 1.05
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    treeGrowthScale = 1.0
                }
            }
        } else {
            // Smooth growth animation
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) {
                treeGrowthScale = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    treeGrowthScale = 1.0
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    WatercolorZenGardenView(gardenManager: ZenGardenManager())
}
