//
//  CustomDurationSheet.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Small sheet with a wheel to pick any session length (1-120 minutes).
//

import SwiftUI

struct CustomDurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var minutes: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(String(localized: "custom_duration_title", defaultValue: "Özel Süre", comment: "Custom duration sheet title"))
                .font(.headline)
                .foregroundColor(ZenTheme.lightLavender)
                .padding(.top, 20)

            Picker("", selection: $minutes) {
                ForEach(Array(SilentMeditationPlan.minuteRange), id: \.self) { value in
                    Text(String(localized: "sleep_mode_minutes_short", defaultValue: "\(value) dk", comment: "Minutes, short")).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)

            Button {
                HapticManager.shared.playImpact(style: .light)
                dismiss()
            } label: {
                Text(String(localized: "daily_zen_done", defaultValue: "Tamam", comment: "Done button"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(ZenTheme.mysticalViolet.opacity(0.8)))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(ZenTheme.backgroundGradient.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
