//
//  GardenDecorationsView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Draws the unlocked garden decorations with simple shapes around the sand
//  circle. It must be placed with the same frame and offset as the sand circle
//  so both share the same center. Static (no animation) to stay light.
//

import SwiftUI

struct GardenDecorationsView: View {
    let unlocked: Set<GardenDecoration>

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            let cy = size.height * 0.5

            // Back to front so nearer objects overlap farther ones
            if unlocked.contains(.bamboo) {
                drawBamboo(context, base: CGPoint(x: cx + 105, y: cy - 20))
            }
            if unlocked.contains(.lantern) {
                drawLantern(context, base: CGPoint(x: cx + 118, y: cy + 62))
            }
            if unlocked.contains(.pond) {
                drawPond(context, center: CGPoint(x: cx - 78, y: cy + 112))
            }
            if unlocked.contains(.stones) {
                drawStones(context, at: CGPoint(x: cx - 112, y: cy + 52))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Stones

    private func drawStones(_ context: GraphicsContext, at point: CGPoint) {
        let stones: [(dx: CGFloat, dy: CGFloat, w: CGFloat, h: CGFloat, shade: Double)] = [
            (0, 0, 34, 22, 0.50),
            (26, 7, 22, 15, 0.58),
            (-22, 9, 18, 12, 0.44)
        ]

        for stone in stones {
            let rect = CGRect(
                x: point.x + stone.dx - stone.w / 2,
                y: point.y + stone.dy - stone.h / 2,
                width: stone.w,
                height: stone.h
            )

            // Soft shadow
            context.fill(
                Path(ellipseIn: rect.offsetBy(dx: 2, dy: 4).insetBy(dx: -1, dy: 0)),
                with: .color(.black.opacity(0.12))
            )
            context.fill(Path(ellipseIn: rect), with: .color(Color(white: stone.shade)))

            // Highlight
            let highlight = CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.15, width: rect.width * 0.35, height: rect.height * 0.25)
            context.fill(Path(ellipseIn: highlight), with: .color(.white.opacity(0.25)))
        }
    }

    // MARK: - Bamboo

    private func drawBamboo(_ context: GraphicsContext, base: CGPoint) {
        let stems: [(dx: CGFloat, height: CGFloat, shade: Double)] = [
            (-12, 84, 0.42),
            (0, 108, 0.48),
            (13, 74, 0.40)
        ]

        for stem in stems {
            let x = base.x + stem.dx
            let green = Color(red: 0.36 * (1 + (stem.shade - 0.4)), green: 0.55, blue: 0.30)

            let stemRect = CGRect(x: x - 3, y: base.y - stem.height, width: 6, height: stem.height)
            context.fill(Path(roundedRect: stemRect, cornerRadius: 3), with: .color(green))

            // Nodes
            var y = base.y - 14
            while y > base.y - stem.height + 6 {
                var node = Path()
                node.move(to: CGPoint(x: x - 3.5, y: y))
                node.addLine(to: CGPoint(x: x + 3.5, y: y))
                context.stroke(node, with: .color(green.opacity(0.55).mix(with: .black, by: 0.3)), lineWidth: 1.2)
                y -= 18
            }

            // A leaf pair near the top
            let leafY = base.y - stem.height + 10
            context.fill(
                Path(ellipseIn: CGRect(x: x + 2, y: leafY, width: 16, height: 5)),
                with: .color(green.opacity(0.85))
            )
            context.fill(
                Path(ellipseIn: CGRect(x: x - 18, y: leafY + 8, width: 16, height: 5)),
                with: .color(green.opacity(0.85))
            )
        }
    }

    // MARK: - Lantern

    private func drawLantern(_ context: GraphicsContext, base: CGPoint) {
        let stone = Color(white: 0.52)
        let darkStone = Color(white: 0.42)

        // Warm glow behind the lamp
        let lampCenter = CGPoint(x: base.x, y: base.y - 36)
        context.fill(
            Path(ellipseIn: CGRect(x: lampCenter.x - 28, y: lampCenter.y - 28, width: 56, height: 56)),
            with: .radialGradient(
                Gradient(colors: [Color.orange.opacity(0.35), Color.orange.opacity(0)]),
                center: lampCenter,
                startRadius: 2,
                endRadius: 28
            )
        )

        // Base, pillar
        context.fill(Path(roundedRect: CGRect(x: base.x - 14, y: base.y - 8, width: 28, height: 8), cornerRadius: 2), with: .color(darkStone))
        context.fill(Path(roundedRect: CGRect(x: base.x - 5, y: base.y - 30, width: 10, height: 24), cornerRadius: 2), with: .color(stone))

        // Lamp box with a lit window
        context.fill(Path(roundedRect: CGRect(x: base.x - 13, y: base.y - 50, width: 26, height: 22), cornerRadius: 3), with: .color(stone))
        context.fill(Path(roundedRect: CGRect(x: base.x - 7, y: base.y - 46, width: 14, height: 14), cornerRadius: 2), with: .color(Color(red: 1.0, green: 0.78, blue: 0.40)))

        // Roof
        var roof = Path()
        roof.move(to: CGPoint(x: base.x - 20, y: base.y - 50))
        roof.addLine(to: CGPoint(x: base.x, y: base.y - 66))
        roof.addLine(to: CGPoint(x: base.x + 20, y: base.y - 50))
        roof.closeSubpath()
        context.fill(roof, with: .color(darkStone))

        // Finial
        context.fill(Path(ellipseIn: CGRect(x: base.x - 3, y: base.y - 71, width: 6, height: 6)), with: .color(stone))
    }

    // MARK: - Pond

    private func drawPond(_ context: GraphicsContext, center: CGPoint) {
        let width: CGFloat = 112
        let height: CGFloat = 46
        let rect = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)

        // Rim stones and water
        context.fill(Path(ellipseIn: rect.insetBy(dx: -5, dy: -4)), with: .color(Color(white: 0.58)))
        context.fill(
            Path(ellipseIn: rect),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.42, green: 0.70, blue: 0.78),
                    Color(red: 0.25, green: 0.50, blue: 0.62)
                ]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)
            )
        )

        // Ripples
        for inset in [14.0, 28.0] {
            context.stroke(
                Path(ellipseIn: rect.insetBy(dx: inset, dy: inset * 0.4)),
                with: .color(.white.opacity(0.25)),
                lineWidth: 1
            )
        }

        // Two koi
        drawKoi(context, at: CGPoint(x: center.x - 18, y: center.y + 2), body: Color.orange, facingRight: true)
        drawKoi(context, at: CGPoint(x: center.x + 20, y: center.y - 6), body: Color(white: 0.96), facingRight: false)
    }

    private func drawKoi(_ context: GraphicsContext, at point: CGPoint, body: Color, facingRight: Bool) {
        let direction: CGFloat = facingRight ? 1 : -1

        context.fill(
            Path(ellipseIn: CGRect(x: point.x - 8, y: point.y - 3.5, width: 16, height: 7)),
            with: .color(body)
        )

        var tail = Path()
        tail.move(to: CGPoint(x: point.x - 7 * direction, y: point.y))
        tail.addLine(to: CGPoint(x: point.x - 14 * direction, y: point.y - 4))
        tail.addLine(to: CGPoint(x: point.x - 14 * direction, y: point.y + 4))
        tail.closeSubpath()
        context.fill(tail, with: .color(body.opacity(0.85)))
    }
}

private extension Color {
    /// Blend toward another color (used only for small shading tweaks)
    func mix(with other: Color, by amount: CGFloat) -> Color {
        lerp(to: other, progress: amount)
    }
}
