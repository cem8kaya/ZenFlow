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
    @State private var showSettings: Bool = false

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
                // When splash screen is dismissed, check authorizations
                if !newValue {
                    checkHealthKitAuthorization()
                    checkNotificationAuthorization()
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

    // MARK: - Notification Authorization Check

    private func checkNotificationAuthorization() {
        // Request notification authorization on first launch or when not determined
        NotificationManager.shared.checkAuthorizationStatus()

        // If notifications are not authorized, request permission
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !NotificationManager.shared.isAuthorized {
                NotificationManager.shared.requestAuthorization { _ in }
            }
        }
    }
}

/// Tab view wrapper
struct SwipeableTabView: View {
    @Binding var selection: Int
    let persistenceController: PersistenceController

    var body: some View {
        TabView(selection: $selection) {
            BreathingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Meditasyon", systemImage: "leaf.circle.fill")
                }
                .accessibilityLabel("Meditasyon sekmesi")
                .tag(0)

            FocusTimerView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Odaklan", systemImage: "timer")
                }
                .accessibilityLabel("Odaklan sekmesi")
                .tag(1)

            ZenGardenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Zen Bahçem", systemImage: "tree.fill")
                }
                .accessibilityLabel("Zen Bahçem sekmesi")
                .tag(2)

            BadgesView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Rozetler", systemImage: "trophy.fill")
                }
                .accessibilityLabel("Rozetler sekmesi")
                .tag(3)

            SettingsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
                .accessibilityLabel("Ayarlar sekmesi")
                .tag(4)
        }
    }
}
