//
//  TypingIndicatorView.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Animated typing indicator for Zen Coach.
//

import SwiftUI

// MARK: - Typing Indicator View

/// Displays animated typing dots
struct TypingIndicatorView: View {

    // MARK: - State

    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0]

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(ZenTheme.lightLavender.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScales[index])
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: dotScales[index]
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.white.opacity(0.15)
        )
        .cornerRadius(20)
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                dotScales[index] = 1.5
            }
        }
    }
}
