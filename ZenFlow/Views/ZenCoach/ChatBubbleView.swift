//
//  ChatBubbleView.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Chat bubble component for Zen Coach messages.
//

import SwiftUI

// MARK: - Chat Bubble View

/// Displays a single chat message bubble
struct ChatBubbleView: View {

    // MARK: - Properties

    let message: ZenCoachMessage
    let action: (text: String, url: String)?

    // MARK: - Environment

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                userBubble
            } else {
                coachBubble
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - User Bubble

    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.text)
                .font(ZenTheme.zenBody)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    ZenTheme.softPurple.opacity(0.6)
                )
                .cornerRadius(20)
                .cornerRadius(4, corners: [.bottomRight])

            Text(message.formattedTime)
                .font(.caption2)
                .foregroundColor(ZenTheme.lightLavender.opacity(0.5))
                .padding(.trailing, 4)
        }
    }

    // MARK: - Coach Bubble

    private var coachBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 12) {
                Text(message.text)
                    .font(ZenTheme.zenBody)
                    .foregroundColor(ZenTheme.lightLavender)

                // Action button if available
                if let action = action {
                    Button(action: {
                        handleAction(url: action.url)
                    }) {
                        HStack {
                            Text(action.text)
                                .font(.system(size: 15, weight: .medium))
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundColor(ZenTheme.serenePurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            ZenTheme.softPurple.opacity(0.3)
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color.white.opacity(0.15)
            )
            .cornerRadius(20)
            .cornerRadius(4, corners: [.bottomLeft])

            Text(message.formattedTime)
                .font(.caption2)
                .foregroundColor(ZenTheme.lightLavender.opacity(0.5))
                .padding(.leading, 4)
        }
    }

    // MARK: - Actions

    private func handleAction(url: String) {
        DeepLinkHandler.shared.handle(url)
        HapticManager.shared.playImpact(style: .medium)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
