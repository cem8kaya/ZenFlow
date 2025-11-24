//
//  OnboardingPageView.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//
//  Individual onboarding page component displaying icon,
//  title, and description with smooth animations and zen styling.
//

import SwiftUI

/// Single page view for onboarding
struct OnboardingPageView: View {

    // MARK: - Properties

    let page: OnboardingPage
    @State private var isAnimating = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Interactive element or static icon
            Group {
                switch page.interactiveType {
                case .pulsingCircle:
                    PulsingCircleView(accentColor: page.accentColor)
                        .frame(height: 240)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)

                case .breathingDemo:
                    BreathingDemoView(accentColor: page.accentColor)
                        .frame(height: 240)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)

                case .treeGrowth:
                    TreeGrowthView(accentColor: page.accentColor)
                        .frame(height: 240)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)

                case .timerDemo:
                    TimerDemoView(accentColor: page.accentColor)
                        .frame(height: 240)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)

                case .none:
                    // Static icon with animated appearance
                    ZStack {
                        // Glow effect background
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        page.accentColor.opacity(0.3),
                                        page.accentColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)
                            .blur(radius: 20)
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                            .opacity(isAnimating ? 1.0 : 0.0)

                        // Main icon
                        Image(systemName: page.iconName)
                            .font(.system(size: 100, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [page.accentColor, page.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .rotationEffect(.degrees(isAnimating ? 0 : -10))
                    }
                    .frame(height: 240)
                }
            }
            .padding(.bottom, 60)

            // Title
            Text(page.title)
                .font(ZenTheme.zenTitle)
                .fontWeight(.semibold)
                .foregroundColor(ZenTheme.lightLavender)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)

            // Description
            Text(page.description)
                .font(ZenTheme.zenBody)
                .foregroundColor(ZenTheme.softPurple.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 40)
                .padding(.top, 24)
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(page.accessibilityLabel)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ZenTheme.backgroundGradient
            .ignoresSafeArea()

        OnboardingPageView(page: OnboardingData.pages[0])
    }
    .preferredColorScheme(.dark)
}
