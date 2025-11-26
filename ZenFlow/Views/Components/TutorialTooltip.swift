//
//  TutorialTooltip.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//
//  Reusable tutorial tooltip component for showing first-time
//  guidance and tips throughout the app.
//

import SwiftUI

/// Tutorial tooltip with arrow and dismiss button
struct TutorialTooltip: View {
    let title: String
    let message: String
    let arrowDirection: ArrowDirection
    let onDismiss: () -> Void

    @State private var isVisible = false

    enum ArrowDirection {
        case up, down, left, right
    }

    var body: some View {
        VStack(spacing: 0) {
            // Arrow pointing up
            if arrowDirection == .up {
                arrowShape
                    .frame(width: 20, height: 10)
                    .offset(y: 1)
            }

            // Tooltip content
            VStack(alignment: .leading, spacing: 12) {
                // Header with title and close button
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ZenTheme.lightLavender)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ZenTheme.softPurple.opacity(0.6))
                    }
                }

                // Message
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ZenTheme.softPurple.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                ZenTheme.mysticalViolet.opacity(0.95),
                                ZenTheme.serenePurple.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ZenTheme.lightLavender.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)

            // Arrow pointing down
            if arrowDirection == .down {
                arrowShape
                    .rotationEffect(.degrees(180))
                    .frame(width: 20, height: 10)
                    .offset(y: -1)
            }
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .offset(y: isVisible ? 0 : -10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
                isVisible = true
            }
        }
    }

    private var arrowShape: some View {
        Triangle()
            .fill(
                LinearGradient(
                    colors: [
                        ZenTheme.mysticalViolet.opacity(0.95),
                        ZenTheme.serenePurple.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

// MARK: - Triangle Shape

/// Triangle shape for tooltip arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Tutorial Tooltip Modifier

/// View modifier for adding tutorial tooltips
struct TutorialTooltipModifier: ViewModifier {
    @ObservedObject var tutorialManager = TutorialManager.shared
    let tutorialStep: TutorialStep
    let title: String
    let message: String
    let arrowDirection: TutorialTooltip.ArrowDirection
    let offset: CGSize

    func body(content: Content) -> some View {
        content
            .overlay(alignment: overlayAlignment) {
                if tutorialManager.activeTutorial == tutorialStep {
                    TutorialTooltip(
                        title: title,
                        message: message,
                        arrowDirection: arrowDirection,
                        onDismiss: {
                            tutorialManager.dismissActiveTutorial()
                        }
                    )
                    .frame(maxWidth: 280)
                    .offset(offset)
                    .zIndex(999)
                }
            }
    }

    private var overlayAlignment: Alignment {
        switch arrowDirection {
        case .up:
            return .bottom
        case .down:
            return .top
        case .left:
            return .trailing
        case .right:
            return .leading
        }
    }
}

// MARK: - View Extension

extension View {
    /// Add a tutorial tooltip to this view
    func tutorialTooltip(
        _ step: TutorialStep,
        title: String,
        message: String,
        arrowDirection: TutorialTooltip.ArrowDirection = .down,
        offset: CGSize = .zero
    ) -> some View {
        self.modifier(
            TutorialTooltipModifier(
                tutorialStep: step,
                title: title,
                message: message,
                arrowDirection: arrowDirection,
                offset: offset
            )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()

        VStack(spacing: 40) {
            // Example with arrow up
            TutorialTooltip(
                title: String(localized: "tutorial_first_breath_exercise", defaultValue: "İlk Nefes Egzersizin", comment: "First breathing exercise tutorial title"),
                message: String(localized: "tutorial_first_breath_exercise_message", defaultValue: "Buradan nefes egzersizlerine başlayabilirsin. Box Breathing ile başlamayı öneririz!", comment: "First breathing exercise tutorial message"),
                arrowDirection: .up,
                onDismiss: {}
            )
            .frame(maxWidth: 280)

            // Example with arrow down
            TutorialTooltip(
                title: String(localized: "tutorial_zen_garden", defaultValue: "Zen Bahçen", comment: "Zen garden tutorial title"),
                message: String(localized: "tutorial_zen_garden_message", defaultValue: "Her meditasyon seansı bahçeni büyütür. İlerlemenizi buradan takip edin!", comment: "Zen garden tutorial message"),
                arrowDirection: .down,
                onDismiss: {}
            )
            .frame(maxWidth: 280)
        }
    }
    .preferredColorScheme(.dark)
}
