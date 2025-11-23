//
//  ZenFlowApp.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//  Updated by Claude AI on 16.11.2025.
//
//  Main application entry point defining the tab-based navigation
//  structure with meditation, garden, badges, and theme selection views.
//

import SwiftUI
import CoreData
internal import HealthKit

@main
struct ZenFlowApp: App {
    let persistenceController = PersistenceController.shared
    @State private var selectedTab: Int = 0
    @State private var showSplash: Bool = true
    @State private var showHealthKitOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                SwipeableTabView(selection: $selectedTab, persistenceController: persistenceController)
                    .preferredColorScheme(.dark)

                // Splash screen overlay
                if showSplash {
                    SplashScreenView(isActive: $showSplash)
                        .transition(.opacity)
                        .zIndex(1)
                }

                // HealthKit onboarding overlay
                if showHealthKitOnboarding {
                    HealthKitOnboardingView(isPresented: $showHealthKitOnboarding)
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .onChange(of: showSplash) { _, newValue in
                // When splash screen is dismissed, check HealthKit authorization
                if !newValue {
                    checkHealthKitAuthorization()
                }
            }
        }
    }

    // MARK: - HealthKit Authorization Check

    private func checkHealthKitAuthorization() {
        // Only check if HealthKit is available
        guard HealthKitManager.shared.isHealthKitAvailable else {
            return
        }

        let authStatus = HealthKitManager.shared.getAuthorizationStatus()

        // Show onboarding if authorization not determined
        if authStatus == .notDetermined {
            // Delay to allow splash screen animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showHealthKitOnboarding = true
                }
            }
        }
    }
}

/// Kaydırma destekli tab view wrapper
struct SwipeableTabView: View {
    @Binding var selection: Int
    let persistenceController: PersistenceController
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        TabView(selection: $selection) {
            BreathingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Meditasyon", systemImage: "leaf.circle.fill")
                }
                .accessibilityLabel("Meditasyon sekmesi")
                .tag(0)
                .gesture(swipeGesture)

            FocusTimerView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Odaklan", systemImage: "timer")
                }
                .accessibilityLabel("Odaklan sekmesi")
                .tag(1)
                .gesture(swipeGesture)

            ZenGardenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Zen Bahçem", systemImage: "tree.fill")
                }
                .accessibilityLabel("Zen Bahçem sekmesi")
                .tag(2)
                .gesture(swipeGesture)

            BadgesView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Rozetler", systemImage: "trophy.fill")
                }
                .accessibilityLabel("Rozetler sekmesi")
                .tag(3)
                .gesture(swipeGesture)
        }
    }

    /// Enhanced swipe gesture with velocity-based animations and haptic feedback
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .local)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                // Calculate velocity for dynamic animation
                let velocity = value.predictedEndTranslation.width - value.translation.width

                // Yatay kaydırma dikey kaydırmadan fazlaysa (gerçek bir swipe)
                if abs(horizontalAmount) > abs(verticalAmount) {
                    // Determine animation speed based on velocity
                    let animationSpeed = min(abs(velocity) / 1000, 0.5)
                    let springResponse = max(0.3 - animationSpeed, 0.15)

                    if horizontalAmount < 0 && selection < 3 {
                        // Sola kaydırma - sonraki tab
                        HapticManager.shared.playImpact(style: .light)
                        withAnimation(.spring(response: springResponse, dampingFraction: 0.75)) {
                            selection = min(selection + 1, 3)
                        }
                    } else if horizontalAmount > 0 && selection > 0 {
                        // Sağa kaydırma - önceki tab
                        HapticManager.shared.playImpact(style: .light)
                        withAnimation(.spring(response: springResponse, dampingFraction: 0.75)) {
                            selection = max(selection - 1, 0)
                        }
                    }
                }
            }
    }
}
