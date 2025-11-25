//
//  SuggestedPromptsView.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Quick prompt suggestions for Zen Coach with enhanced visual design.
//

import SwiftUI

// MARK: - Suggested Prompts View

/// Displays quick prompt suggestions with beautiful design
struct SuggestedPromptsView: View {

    // MARK: - Properties

    let prompts: [String]
    let onPromptTapped: (String) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Section header
            Text("Başlamak için bir soru seç:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

            ForEach(prompts, id: \.self) { prompt in
                Button(action: {
                    onPromptTapped(prompt)
                    HapticManager.shared.playImpact(style: .light)
                }) {
                    HStack {
                        Text(prompt)
                            .font(.system(size: 16))
                            .foregroundColor(ZenTheme.lightLavender)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(ZenTheme.lightLavender.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        Color.white.opacity(0.08)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
