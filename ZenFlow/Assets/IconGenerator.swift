//
//  IconGenerator.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//
//  Professional app icon generator for ZenFlow meditation app.
//  Generates three icon concepts: Lotus, Breathing Circles, Zen Stones
//  Exports to 1024x1024 for App Store and all iOS sizes.
//

import SwiftUI

// MARK: - Icon Style

enum IconStyle: String, CaseIterable, Identifiable {
    case lotus = "Lotus Flower"
    case breathingCircles = "Breathing Circles"
    case zenStones = "Zen Stones"

    var id: String { rawValue }
}

// MARK: - Icon Colors

struct IconColors {
    /// Based on ZenTheme palette
    static let calmBlue = Color(red: 0.35, green: 0.45, blue: 0.85)      // #5973D9
    static let serenePurple = Color(red: 0.50, green: 0.35, blue: 0.85)  // #8059D9
    static let softPurple = Color(red: 0.45, green: 0.35, blue: 0.65)    // #7359A6
    static let deepIndigo = Color(red: 0.18, green: 0.15, blue: 0.35)    // #2E2659

    /// Gradient for main icon background
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.25, green: 0.22, blue: 0.42),  // Lighter indigo
            deepIndigo
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Accent gradient for icon elements
    static let accentGradient = LinearGradient(
        colors: [calmBlue, serenePurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Soft glow gradient
    static let glowGradient = RadialGradient(
        colors: [softPurple.opacity(0.6), Color.clear],
        center: .center,
        startRadius: 50,
        endRadius: 200
    )
}

// MARK: - Icon Generator View

struct IconGeneratorView: View {
    @State private var selectedStyle: IconStyle = .breathingCircles
    @State private var iconSize: CGFloat = 1024

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Style Picker
                Picker("Icon Style", selection: $selectedStyle) {
                    ForEach(IconStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Icon Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 300, height: 300)

                    iconView(for: selectedStyle)
                        .frame(width: 256, height: 256)
                        .clipShape(RoundedRectangle(cornerRadius: 55))
                        .shadow(radius: 10)
                }

                // Export Info
                VStack(spacing: 10) {
                    Text("App Icon Preview")
                        .font(.headline)

                    Text("Designed for iOS 17+ • 1024x1024px")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Use Xcode's Image Renderer to export")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .navigationTitle("ZenFlow Icons")
        }
    }

    @ViewBuilder
    private func iconView(for style: IconStyle) -> some View {
        switch style {
        case .lotus:
            LotusIconView()
        case .breathingCircles:
            BreathingCirclesIconView()
        case .zenStones:
            ZenStonesIconView()
        }
    }
}

// MARK: - Lotus Icon

struct LotusIconView: View {
    var body: some View {
        ZStack {
            // Background
            IconColors.backgroundGradient

            // Glow effect
            IconColors.glowGradient

            // Lotus flower
            ZStack {
                // Outer petals (8 petals)
                ForEach(0..<8, id: \.self) { index in
                    LotusPetal(size: .large)
                        .fill(
                            LinearGradient(
                                colors: [
                                    IconColors.softPurple.opacity(0.8),
                                    IconColors.serenePurple.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 120, height: 180)
                        .rotationEffect(.degrees(Double(index) * 45))
                }

                // Middle petals (8 petals)
                ForEach(0..<8, id: \.self) { index in
                    LotusPetal(size: .medium)
                        .fill(
                            LinearGradient(
                                colors: [
                                    IconColors.calmBlue.opacity(0.9),
                                    IconColors.serenePurple.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 90, height: 140)
                        .rotationEffect(.degrees(Double(index) * 45 + 22.5))
                }

                // Inner petals (6 petals)
                ForEach(0..<6, id: \.self) { index in
                    LotusPetal(size: .small)
                        .fill(
                            LinearGradient(
                                colors: [
                                    IconColors.calmBlue,
                                    IconColors.softPurple.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 100)
                        .rotationEffect(.degrees(Double(index) * 60))
                }

                // Center circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                IconColors.calmBlue.opacity(0.7)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 40
                        )
                    )
                    .frame(width: 60, height: 60)

                // Center dots for detail
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(IconColors.serenePurple.opacity(0.4))
                        .frame(width: 4, height: 4)
                        .offset(y: -20)
                        .rotationEffect(.degrees(Double(index) * 30))
                }
            }
        }
    }
}

// MARK: - Lotus Petal Shape

struct LotusPetal: Shape {
    enum Size {
        case small, medium, large
    }

    let size: Size

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Control points based on size
        let curveIntensity: CGFloat = {
            switch size {
            case .small: return 0.4
            case .medium: return 0.5
            case .large: return 0.6
            }
        }()

        // Start at bottom center
        path.move(to: CGPoint(x: width / 2, y: height))

        // Left curve
        path.addQuadCurve(
            to: CGPoint(x: width / 2, y: 0),
            control: CGPoint(x: width * (0.5 - curveIntensity), y: height * 0.5)
        )

        // Right curve
        path.addQuadCurve(
            to: CGPoint(x: width / 2, y: height),
            control: CGPoint(x: width * (0.5 + curveIntensity), y: height * 0.5)
        )

        return path
    }
}

// MARK: - Breathing Circles Icon

struct BreathingCirclesIconView: View {
    var body: some View {
        ZStack {
            // Background
            IconColors.backgroundGradient

            // Concentric circles with breathing effect
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                IconColors.serenePurple.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 100,
                            endRadius: 300
                        )
                    )

                // Circle 1 - Outermost
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                IconColors.softPurple.opacity(0.4),
                                IconColors.serenePurple.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 400, height: 400)

                // Circle 2
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                IconColors.softPurple.opacity(0.5),
                                IconColors.serenePurple.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 330, height: 330)

                // Circle 3
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                IconColors.calmBlue.opacity(0.6),
                                IconColors.serenePurple.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 5
                    )
                    .frame(width: 260, height: 260)

                // Circle 4
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                IconColors.calmBlue.opacity(0.7),
                                IconColors.serenePurple.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 190, height: 190)

                // Circle 5
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                IconColors.calmBlue.opacity(0.8),
                                IconColors.serenePurple.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 7
                    )
                    .frame(width: 120, height: 120)

                // Center filled circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                IconColors.calmBlue.opacity(0.8),
                                IconColors.serenePurple.opacity(0.7)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(IconColors.calmBlue, lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Zen Stones Icon

struct ZenStonesIconView: View {
    var body: some View {
        ZStack {
            // Background
            IconColors.backgroundGradient

            // Subtle glow
            IconColors.glowGradient

            // Stone stack
            VStack(spacing: -20) {
                // Top stone (smallest)
                ZenStone(width: 140, height: 70)
                    .fill(
                        LinearGradient(
                            colors: [
                                IconColors.calmBlue.opacity(0.9),
                                IconColors.calmBlue.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        ZenStone(width: 140, height: 70)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 5, y: 3)

                // Middle stone
                ZenStone(width: 200, height: 90)
                    .fill(
                        LinearGradient(
                            colors: [
                                IconColors.serenePurple.opacity(0.9),
                                IconColors.serenePurple.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        ZenStone(width: 200, height: 90)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 5, y: 3)

                // Bottom stone (largest)
                ZenStone(width: 260, height: 110)
                    .fill(
                        LinearGradient(
                            colors: [
                                IconColors.softPurple.opacity(0.9),
                                IconColors.softPurple.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        ZenStone(width: 260, height: 110)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 8, y: 5)
            }
            .offset(y: 30)

            // Ripple circles at base
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        IconColors.calmBlue.opacity(0.2 - Double(index) * 0.06),
                        lineWidth: 2
                    )
                    .frame(
                        width: CGFloat(320 + index * 60),
                        height: CGFloat(320 + index * 60)
                    )
                    .offset(y: 180)
            }
        }
    }
}

// MARK: - Zen Stone Shape

struct ZenStone: Shape {
    let width: CGFloat
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let centerX = rect.midX
        let centerY = rect.midY

        let w = width / 2
        let h = height / 2

        // Create organic stone shape with curves
        path.move(to: CGPoint(x: centerX - w * 0.9, y: centerY))

        // Top left curve
        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.3, y: centerY - h),
            control: CGPoint(x: centerX - w * 0.8, y: centerY - h * 0.8)
        )

        // Top curve
        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.3, y: centerY - h),
            control: CGPoint(x: centerX, y: centerY - h * 1.1)
        )

        // Top right curve
        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.9, y: centerY),
            control: CGPoint(x: centerX + w * 0.8, y: centerY - h * 0.8)
        )

        // Bottom right curve
        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.4, y: centerY + h),
            control: CGPoint(x: centerX + w * 0.9, y: centerY + h * 0.7)
        )

        // Bottom curve
        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.4, y: centerY + h),
            control: CGPoint(x: centerX, y: centerY + h * 1.05)
        )

        // Bottom left curve
        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.9, y: centerY),
            control: CGPoint(x: centerX - w * 0.9, y: centerY + h * 0.7)
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Export Helper

struct IconExportView: View {
    let style: IconStyle
    let size: CGFloat

    var body: some View {
        Group {
            switch style {
            case .lotus:
                LotusIconView()
            case .breathingCircles:
                BreathingCirclesIconView()
            case .zenStones:
                ZenStonesIconView()
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Icon Generator") {
    IconGeneratorView()
}

#Preview("Lotus - 1024") {
    IconExportView(style: .lotus, size: 1024)
}

#Preview("Breathing Circles - 1024") {
    IconExportView(style: .breathingCircles, size: 1024)
}

#Preview("Zen Stones - 1024") {
    IconExportView(style: .zenStones, size: 1024)
}
