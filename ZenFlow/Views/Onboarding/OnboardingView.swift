//
//  OnboardingView.swift
//  ZenFlow
//
//  Created by Claude AI on 23.11.2025.
//
//  Main onboarding flow view with swipeable pages, progress indicators,
//  and navigation controls. Integrates with OnboardingManager to track
//  completion state and supports HealthKit/Notification permission requests.
//

import SwiftUI
internal import HealthKit

/// Main onboarding view with page navigation
struct OnboardingView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var currentPage = 0
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var hapticManager = HapticManager.shared
    @State private var showHealthKitPermission = false
    @State private var showNotificationPermission = false
    @State private var showCompletionCelebration = false

    // MARK: - Constants

    private let pages = OnboardingData.pages
    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button (only show if not on last page)
                if !isLastPage {
                    HStack {
                        Spacer()
                        Button(action: skipOnboarding) {
                            Text("Atla", comment: "Skip onboarding button")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ZenTheme.softPurple)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                        .accessibilityLabel(Text("Tanıtımı atla", comment: "Skip onboarding accessibility label"))
                        .accessibilityHint(Text("Doğrudan uygulamaya git", comment: "Skip onboarding accessibility hint"))
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { oldValue, newValue in
                    // Haptic feedback on page change
                    hapticManager.playImpact(style: .light)

                    // Accessibility announcement
                    let page = pages[newValue]
                    UIAccessibility.post(
                        notification: .screenChanged,
                        argument: String(localized: "Sayfa \(newValue + 1) / \(pages.count). \(page.title)", comment: "Page announcement")
                    )
                }

                // Progress dots
                HStack(spacing: 12) {
                    ForEach(pages) { page in
                        Circle()
                            .fill(currentPage == page.id ?
                                  ZenTheme.lightLavender :
                                  ZenTheme.softPurple.opacity(0.3))
                            .frame(width: currentPage == page.id ? 10 : 8,
                                   height: currentPage == page.id ? 10 : 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.vertical, 24)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Sayfa \(currentPage + 1) / \(pages.count)", comment: "Page indicator accessibility"))

                // Navigation buttons
                HStack(spacing: 20) {
                    // Back button (only show if not on first page)
                    if currentPage > 0 {
                        Button(action: previousPage) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Geri", comment: "Back button")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(ZenTheme.softPurple)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1.5)
                            )
                        }
                        .accessibilityLabel(Text("Önceki sayfa", comment: "Previous page accessibility"))
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Next/Start button
                    Button(action: nextPageOrFinish) {
                        HStack(spacing: 8) {
                            Text(isLastPage ? Text("Başla", comment: "Start button") : Text("İleri", comment: "Next button"))
                                .font(.system(size: 17, weight: .semibold))
                            if !isLastPage {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            ZenTheme.calmBlue,
                                            ZenTheme.mysticalViolet
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(
                            color: ZenTheme.calmBlue.opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }
                    .accessibilityLabel(isLastPage ? Text("Başla", comment: "Start button accessibility") : Text("Sonraki sayfa", comment: "Next page accessibility"))
                    .accessibilityHint(isLastPage ?
                        Text("Onboarding'i tamamla ve uygulamaya geç", comment: "Complete onboarding hint") :
                        Text("Sonraki sayfaya git", comment: "Go to next page hint"))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showHealthKitPermission) {
            HealthKitPermissionView(
                isPresented: $showHealthKitPermission,
                onComplete: {
                    // After HealthKit, show notification permission
                    showNotificationPermission = true
                }
            )
        }
        .sheet(isPresented: $showNotificationPermission) {
            NotificationPermissionView(
                isPresented: $showNotificationPermission,
                onComplete: {
                    // After all permissions, complete onboarding
                    completeOnboarding()
                }
            )
        }
        .fullScreenCover(isPresented: $showCompletionCelebration) {
            OnboardingCompletionView(
                isPresented: $showCompletionCelebration,
                onStartFirstSession: {
                    // Navigate to breathing tab and suggest first session
                    dismiss()
                    // TODO: Show first-time tutorial tooltip
                }
            )
        }
    }

    // MARK: - Actions

    private func nextPageOrFinish() {
        hapticManager.playImpact(style: .medium)

        if isLastPage {
            // Last page - request permissions
            requestPermissions()
        } else {
            // Move to next page
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
            }
        }
    }

    private func previousPage() {
        hapticManager.playImpact(style: .light)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage = max(0, currentPage - 1)
        }
    }

    private func skipOnboarding() {
        hapticManager.playImpact(style: .light)

        // Skip directly to permissions
        requestPermissions()
    }

    private func requestPermissions() {
        // Check if HealthKit is available
        if HealthKitManager.shared.isHealthKitAvailable {
            let authStatus = HealthKitManager.shared.getAuthorizationStatus()
            if authStatus == .notDetermined {
                showHealthKitPermission = true
                return
            }
        }

        // If HealthKit is not needed, check notifications
        checkNotificationPermission()
    }

    private func checkNotificationPermission() {
        NotificationManager.shared.checkAuthorizationStatus()

        if !NotificationManager.shared.isAuthorized {
            showNotificationPermission = true
        } else {
            // All permissions already granted, complete onboarding
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        // Mark onboarding as completed
        onboardingManager.completeOnboarding()

        // Show completion celebration
        showCompletionCelebration = true
    }
}

// MARK: - HealthKit Permission View

/// Dedicated view for HealthKit permission request
private struct HealthKitPermissionView: View {
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ZenTheme.calmBlue, ZenTheme.mysticalViolet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 16) {
                    Text("HealthKit Entegrasyonu", comment: "HealthKit integration title")
                        .font(ZenTheme.zenTitle)
                        .foregroundColor(ZenTheme.lightLavender)
                        .multilineTextAlignment(.center)

                    Text("Meditasyon seanslarını Apple Health'e kaydetmek için izin verin. Verileriniz güvende ve yalnızca sizin kontrolünüzde.", comment: "HealthKit permission description")
                        .font(ZenTheme.zenBody)
                        .foregroundColor(ZenTheme.softPurple.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 16) {
                    // Allow button
                    Button(action: {
                        HealthKitManager.shared.requestAuthorization { _,_  in
                            isPresented = false
                            onComplete()
                        }
                    }) {
                        Text("İzin Ver", comment: "Allow HealthKit permission button")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [ZenTheme.calmBlue, ZenTheme.mysticalViolet],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    // Skip button
                    Button(action: {
                        isPresented = false
                        onComplete()
                    }) {
                        Text("Şimdi Değil", comment: "Not now button")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ZenTheme.softPurple)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Notification Permission View

/// Dedicated view for notification permission request
private struct NotificationPermissionView: View {
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ZenTheme.mysticalViolet, ZenTheme.serenePurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 16) {
                    Text("Günlük Hatırlatmalar", comment: "Daily reminders title")
                        .font(ZenTheme.zenTitle)
                        .foregroundColor(ZenTheme.lightLavender)
                        .multilineTextAlignment(.center)

                    Text("Düzenli meditasyon alışkanlığı kazanmak için günlük hatırlatmalar almak ister misiniz?", comment: "Notification permission description")
                        .font(ZenTheme.zenBody)
                        .foregroundColor(ZenTheme.softPurple.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 16) {
                    // Allow button
                    Button(action: {
                        NotificationManager.shared.requestAuthorization { _ in
                            isPresented = false
                            onComplete()
                        }
                    }) {
                        Text("İzin Ver", comment: "Allow notification permission button")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [ZenTheme.mysticalViolet, ZenTheme.serenePurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    // Skip button
                    Button(action: {
                        isPresented = false
                        onComplete()
                    }) {
                        Text("Şimdi Değil", comment: "Not now notification button")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ZenTheme.softPurple)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
