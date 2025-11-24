//
//  OnboardingInteractiveElements.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//
//  Interactive components for onboarding pages including pulsing circles,
//  breathing demos, tree growth animations, and timer previews.
//

import SwiftUI

// MARK: - Pulsing Circle

/// Animated pulsing zen circle for welcome page
struct PulsingCircleView: View {
    @State private var isPulsing = false
    let accentColor: Color

    var body: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .stroke(accentColor.opacity(0.3), lineWidth: 2)
                .frame(width: 180, height: 180)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.8)

            // Middle pulsing ring
            Circle()
                .stroke(accentColor.opacity(0.5), lineWidth: 3)
                .frame(width: 140, height: 140)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.0 : 1.0)

            // Inner glowing circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.8),
                            accentColor.opacity(0.4),
                            accentColor.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(isPulsing ? 1.1 : 1.0)

            // Center icon
            Image(systemName: "circle.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Breathing Demo

/// Interactive breathing animation demo
struct BreathingDemoView: View {
    @State private var isBreathing = false
    @State private var phase: BreathingPhase = .inhale
    @State private var instructionText = "Dokun ve nefes al"
    let accentColor: Color

    enum BreathingPhase {
        case inhale, hold, exhale, rest
    }

    var body: some View {
        VStack(spacing: 24) {
            // Breathing circle
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.4),
                                accentColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(isBreathing ? 1.3 : 1.0)
                    .blur(radius: 20)

                // Main breathing circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isBreathing ? 140 : 100, height: isBreathing ? 140 : 100)

                // Lungs icon
                Image(systemName: "lungs.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.9))
            }
            .onTapGesture {
                if !isBreathing {
                    startBreathingCycle()
                }
            }

            // Instruction text
            Text(instructionText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ZenTheme.lightLavender)
                .multilineTextAlignment(.center)
                .frame(height: 40)
                .animation(.easeInOut, value: instructionText)
        }
    }

    private func startBreathingCycle() {
        // Inhale phase
        phase = .inhale
        instructionText = "İç çek... 4"
        withAnimation(.easeInOut(duration: 4.0)) {
            isBreathing = true
        }

        // Hold phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            phase = .hold
            instructionText = "Tut... 4"
        }

        // Exhale phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            phase = .exhale
            instructionText = "Ver... 4"
            withAnimation(.easeInOut(duration: 4.0)) {
                isBreathing = false
            }
        }

        // Rest phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
            phase = .rest
            instructionText = "Harika! Tekrar dene"
        }

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 14.0) {
            instructionText = "Dokun ve nefes al"
        }
    }
}

// MARK: - Tree Growth

/// Animated tree growth visualization
struct TreeGrowthView: View {
    @State private var growthStage = 0
    @State private var stageText = "Kaydır ve büyümeyi izle"
    let accentColor: Color

    private let stages = [
        ("Tohum", "🌱", 0.6),
        ("Fidan", "🌿", 0.8),
        ("Genç Ağaç", "🌳", 1.0),
        ("Olgun Ağaç", "🌲", 1.2)
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Tree visualization
            ZStack {
                // Growth rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(accentColor.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                        .scaleEffect(stages[growthStage].2)
                }

                // Tree emoji/icon
                Text(stages[growthStage].1)
                    .font(.system(size: 80))
                    .scaleEffect(stages[growthStage].2)
            }
            .frame(height: 200)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: growthStage)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.width < -50 {
                            // Swipe left - next stage
                            growthStage = min(growthStage + 1, stages.count - 1)
                            stageText = stages[growthStage].0
                        } else if value.translation.width > 50 {
                            // Swipe right - previous stage
                            growthStage = max(growthStage - 1, 0)
                            stageText = stages[growthStage].0
                        }
                    }
            )

            // Stage indicator
            VStack(spacing: 8) {
                Text(stageText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)

                // Stage dots
                HStack(spacing: 8) {
                    ForEach(0..<stages.count, id: \.self) { index in
                        Circle()
                            .fill(growthStage == index ? accentColor : accentColor.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .animation(.easeInOut, value: growthStage)
        }
        .onAppear {
            // Auto-cycle through stages
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                growthStage = (growthStage + 1) % stages.count
                stageText = stages[growthStage].0
            }
        }
    }
}

// MARK: - Timer Demo

/// Interactive timer preview
struct TimerDemoView: View {
    @State private var isRunning = false
    @State private var timeRemaining = 30
    @State private var progress: CGFloat = 1.0
    let accentColor: Color

    var body: some View {
        VStack(spacing: 24) {
            // Timer circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 150, height: 150)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: progress)

                // Timer text
                VStack(spacing: 4) {
                    Text("\(timeRemaining)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(ZenTheme.lightLavender)

                    Text("saniye")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ZenTheme.softPurple)
                }
            }
            .onTapGesture {
                if !isRunning {
                    startTimer()
                }
            }

            // Instruction
            Text(isRunning ? "Odaklan..." : "Dene - 30 saniye")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ZenTheme.lightLavender)
                .frame(height: 40)
        }
    }

    private func startTimer() {
        isRunning = true
        timeRemaining = 30

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
                progress = CGFloat(timeRemaining) / 30.0
            } else {
                timer.invalidate()
                isRunning = false
                progress = 1.0
                timeRemaining = 30
            }
        }
    }
}

// MARK: - Preview

#Preview("Pulsing Circle") {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()

        PulsingCircleView(accentColor: ZenTheme.mysticalViolet)
    }
    .preferredColorScheme(.dark)
}

#Preview("Breathing Demo") {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()

        BreathingDemoView(accentColor: ZenTheme.calmBlue)
    }
    .preferredColorScheme(.dark)
}

#Preview("Tree Growth") {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()

        TreeGrowthView(accentColor: ZenTheme.sageGreen)
    }
    .preferredColorScheme(.dark)
}

#Preview("Timer Demo") {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()

        TimerDemoView(accentColor: ZenTheme.softPurple)
    }
    .preferredColorScheme(.dark)
}
