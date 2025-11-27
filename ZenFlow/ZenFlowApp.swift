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
import UserNotifications

@main
struct ZenFlowApp: App {
    @State private var selectedTab: Int = 0
    @State private var showSplash: Bool = true
    @State private var showOnboarding: Bool = false
    @State private var showHealthKitOnboarding: Bool = false
    @State private var showSettings: Bool = false
    @StateObject private var onboardingManager = OnboardingManager.shared
    private let notificationDelegate = NotificationDelegate()

    // MARK: - Singleton Managers (Performance Optimization)
    // Initialize singleton managers once at app level and inject via EnvironmentObject
    @StateObject private var sessionTracker = SessionTracker.shared
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = AmbientSoundManager.shared
    @StateObject private var exerciseManager = BreathingExerciseManager.shared
    @StateObject private var featureFlag = FeatureFlag.shared
    @StateObject private var dataManager = LocalDataManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @StateObject private var zenCoachManager = ZenCoachManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                SwipeableTabView(selection: $selectedTab)
                    .preferredColorScheme(.dark)
                    // Inject singleton managers into view hierarchy
                    .environmentObject(sessionTracker)
                    .environmentObject(hapticManager)
                    .environmentObject(soundManager)
                    .environmentObject(exerciseManager)
                    .environmentObject(featureFlag)
                    .environmentObject(dataManager)
                    .environmentObject(gamificationManager)
                    .environmentObject(zenCoachManager)
                    .environmentObject(notificationManager)

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
            .onAppear {
                // Set notification delegate
                UNUserNotificationCenter.current().delegate = notificationDelegate
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

/// Tab view wrapper with lazy loading for performance optimization
struct SwipeableTabView: View {
    @Binding var selection: Int

    // MARK: - Lazy Loading State (Performance Optimization)
    // Track which tabs have been loaded to prevent unnecessary initialization
    @State private var loadedTabs: Set<Int> = [0] // Tab 0 (ZenCoach) preloaded

    var body: some View {
        TabView(selection: $selection) {
            // Tab 0: ZenCoach - Always loaded (first tab)
            ZenCoachView()
                .tabItem {
                    Label(String(localized: "tab_zen_coach", defaultValue: "Zen Coach", comment: "Zen Coach tab"), systemImage: "person.crop.circle.fill")
                }
                .accessibilityLabel(String(localized: "tab_zen_coach_accessibility", defaultValue: "Zen Coach sekmesi", comment: "Zen Coach tab accessibility"))
                .tag(0)

            // Tab 1: Breathing - Lazy loaded
            Group {
                if loadedTabs.contains(1) {
                    BreathingView()
                } else {
                    Color.clear.onAppear {
                        loadedTabs.insert(1)
                    }
                }
            }
            .tabItem {
                Label(String(localized: "tab_meditation", defaultValue: "Meditasyon", comment: "Meditation tab"), systemImage: "leaf.circle.fill")
            }
            .accessibilityLabel(String(localized: "tab_meditation_accessibility", defaultValue: "Meditasyon sekmesi", comment: "Meditation tab accessibility"))
            .tag(1)

            // Tab 2: Focus Timer - Lazy loaded
            Group {
                if loadedTabs.contains(2) {
                    FocusTimerView()
                } else {
                    Color.clear.onAppear {
                        loadedTabs.insert(2)
                    }
                }
            }
            .tabItem {
                Label(String(localized: "tab_focus", defaultValue: "Odaklan", comment: "Focus tab"), systemImage: "timer")
            }
            .accessibilityLabel(String(localized: "tab_focus_accessibility", defaultValue: "Odaklan sekmesi", comment: "Focus tab accessibility"))
            .tag(2)

            // Tab 3: Zen Garden - Lazy loaded
            Group {
                if loadedTabs.contains(3) {
                    ZenGardenView()
                } else {
                    Color.clear.onAppear {
                        loadedTabs.insert(3)
                    }
                }
            }
            .tabItem {
                Label(String(localized: "tab_zen_garden", defaultValue: "Zen Bahçem", comment: "Zen Garden tab"), systemImage: "tree.fill")
            }
            .accessibilityLabel(String(localized: "tab_zen_garden_accessibility", defaultValue: "Zen Bahçem sekmesi", comment: "Zen Garden tab accessibility"))
            .tag(3)

            // Tab 4: Settings - Lazy loaded
            Group {
                if loadedTabs.contains(4) {
                    SettingsView()
                } else {
                    Color.clear.onAppear {
                        loadedTabs.insert(4)
                    }
                }
            }
            .tabItem {
                Label(String(localized: "tab_settings", defaultValue: "Ayarlar", comment: "Settings tab"), systemImage: "gear")
            }
            .accessibilityLabel(String(localized: "tab_settings_accessibility", defaultValue: "Ayarlar sekmesi", comment: "Settings tab accessibility"))
            .tag(4)
        }
        .onChange(of: selection) { oldValue, newValue in
            // Preload the selected tab
            loadedTabs.insert(newValue)
        }
    }
}

// MARK: - Notification Delegate

/// Handles notification responses and foreground notifications
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    override init() {
        super.init()
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        print("📱 Notification presented in foreground")
    }

    // Handle notification tap or action button
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 Notification response received: \(response.actionIdentifier)")

        // Handle the response using DeepLinkHandler
        DeepLinkHandler.shared.handleNotificationResponse(response)

        completionHandler()
    }
}
