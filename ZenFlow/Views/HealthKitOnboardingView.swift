//
//  HealthKitOnboardingView.swift
//  ZenFlow
//
//  Created by Claude AI on 22.11.2025.
//
//  Onboarding view for requesting HealthKit authorization to save
//  meditation sessions to Apple Health.
//

import SwiftUI

struct HealthKitOnboardingView: View {
    @Binding var isPresented: Bool
    @State private var isRequesting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background gradient
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ZenTheme.lightLavender, ZenTheme.softPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: ZenTheme.lightLavender.opacity(0.3), radius: 20)

                // Title
                Text(String(localized: "healthkit_onboarding_title", defaultValue: "Apple Sağlık Entegrasyonu", comment: "HealthKit onboarding title"))
                    .font(ZenTheme.zenTitle)
                    .foregroundColor(ZenTheme.lightLavender)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Description
                Text(String(localized: "healthkit_onboarding_description", defaultValue: "Meditasyon sürenizi Apple Sağlık uygulamasına kaydetmek istiyor musunuz?", comment: "HealthKit onboarding description"))
                    .font(ZenTheme.zenBody)
                    .foregroundColor(ZenTheme.softPurple)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    benefitRow(icon: "chart.line.uptrend.xyaxis", text: String(localized: "healthkit_benefit_track_progress", defaultValue: "İlerlemenizi takip edin", comment: "HealthKit benefit: track progress"))
                    benefitRow(icon: "clock.fill", text: String(localized: "healthkit_benefit_view_hours", defaultValue: "Meditasyon saatlerinizi görün", comment: "HealthKit benefit: view hours"))
                    benefitRow(icon: "lock.shield.fill", text: String(localized: "healthkit_benefit_data_secure", defaultValue: "Verileriniz güvende", comment: "HealthKit benefit: data is secure"))
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)

                Spacer()

                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }

                // Buttons
                VStack(spacing: 16) {
                    // Allow button
                    Button(action: requestAuthorization) {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isRequesting ? String(localized: "healthkit_requesting", defaultValue: "İzin İsteniyor...", comment: "HealthKit requesting permission") : String(localized: "healthkit_allow", defaultValue: "İzin Ver", comment: "HealthKit allow button"))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [ZenTheme.lightLavender, ZenTheme.softPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(isRequesting)
                    .padding(.horizontal, 40)

                    // Skip button
                    Button(action: {
                        HapticManager.shared.playImpact(style: .light)
                        isPresented = false
                    }) {
                        Text(String(localized: "button_not_now", defaultValue: "Şimdi Değil", comment: "Not now button"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ZenTheme.softPurple)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .disabled(isRequesting)
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Benefit Row

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(ZenTheme.lightLavender)
                .frame(width: 28)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ZenTheme.softPurple.opacity(0.9))
        }
    }

    // MARK: - Request Authorization

    private func requestAuthorization() {
        isRequesting = true
        showError = false
        HapticManager.shared.playImpact(style: .medium)

        HealthKitManager.shared.requestAuthorization { success, error in
            DispatchQueue.main.async {
                isRequesting = false

                if success {
                    // Success - dismiss the view
                    HapticManager.shared.playNotification(type: .success)
                    UIAccessibility.post(notification: .announcement, argument: String(localized: "healthkit_permission_granted", defaultValue: "HealthKit izni verildi", comment: "HealthKit permission granted announcement"))

                    // Delay to show success state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPresented = false
                    }
                } else {
                    // Error - show error message
                    HapticManager.shared.playNotification(type: .error)
                    showError = true
                    errorMessage = error?.localizedDescription ?? String(localized: "healthkit_permission_failed", defaultValue: "İzin verilemedi. Lütfen tekrar deneyin.", comment: "HealthKit permission failed message")
                    UIAccessibility.post(notification: .announcement, argument: errorMessage)

                    // Auto-hide error after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showError = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HealthKitOnboardingView(isPresented: .constant(true))
}
