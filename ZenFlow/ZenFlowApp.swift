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
internal import HealthKit

@main
struct ZenFlowApp: App {
    @State private var selectedTab: Int = 0
    @State private var showSplash: Bool = true
    @State private var showOnboarding: Bool = false
    @State private var showHealthKitOnboarding: Bool = false
    @State private var showSettings: Bool = false
    @StateObject private var onboardingManager = OnboardingManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                SwipeableTabView(selection: $selectedTab)
                    .preferredColorScheme(.dark)

                // Splash screen overlay
                if showSplash {
                    SplashScreenView(isActive: $showSplash)
                        .transition(.opacity)
                        .zIndex(1)
                }

                // Onboarding overlay
                if showOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                        .zIndex(2)
                }

                // HealthKit onboarding overlay (legacy - now integrated into OnboardingView)
                if showHealthKitOnboarding {
                    HealthKitOnboardingView(isPresented: $showHealthKitOnboarding)
                        .transition(.opacity)
                        .zIndex(3)
                }
            }
            .onChange(of: showSplash) { _, newValue in
                // When splash screen is dismissed, check if onboarding should be shown
                if !newValue {
                    checkOnboardingStatus()
                }
            }
            .onChange(of: onboardingManager.hasCompletedOnboarding) { _, completed in
                // When onboarding is completed, hide it
                if completed {
                    withAnimation {
                        showOnboarding = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: DeepLinkHandler.switchToTabNotification)) { notification in
                // Handle deep link tab switching
                if let tabIndex = notification.userInfo?["tabIndex"] as? Int {
                    withAnimation {
                        selectedTab = tabIndex
                    }
                }
            }
        }
    }

    // MARK: - Onboarding Check

    private func checkOnboardingStatus() {
        // Check if user has completed onboarding
        if onboardingManager.shouldShowOnboarding {
            // Show onboarding for first-time users
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showOnboarding = true
                }
            }
        } else {
            // Onboarding completed, check legacy authorizations
            // (for users who already have the app before onboarding was added)
            checkHealthKitAuthorization()
            checkNotificationAuthorization()
        }
    }

    // MARK: - HealthKit Authorization Check (Legacy)

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

    // MARK: - Notification Authorization Check (Legacy)

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

    var body: some View {
        TabView(selection: $selection) {
            BreathingView()
                .tabItem {
                    Label("Meditasyon", systemImage: "leaf.circle.fill")
                }
                .accessibilityLabel("Meditasyon sekmesi")
                .tag(0)

            FocusTimerView()
                .tabItem {
                    Label("Odaklan", systemImage: "timer")
                }
                .accessibilityLabel("Odaklan sekmesi")
                .tag(1)

            ZenGardenView()
                .tabItem {
                    Label("Zen Bahçem", systemImage: "tree.fill")
                }
                .accessibilityLabel("Zen Bahçem sekmesi")
                .tag(2)

            BadgesView()
                .tabItem {
                    Label("Rozetler", systemImage: "trophy.fill")
                }
                .accessibilityLabel("Rozetler sekmesi")
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
                .accessibilityLabel("Ayarlar sekmesi")
                .tag(4)
        }
    }
}
