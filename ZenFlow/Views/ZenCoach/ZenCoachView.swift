//
//  ZenCoachView.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Main Zen Coach chat interface.
//  Provides offline AI-powered mindfulness guidance using NaturalLanguage framework.
//  Enhanced with beautiful Zen wisdom and engaging starter prompts.
//

import SwiftUI

// MARK: - Zen Coach View

/// Main chat interface for Zen Coach feature
struct ZenCoachView: View {

    // MARK: - State

    @StateObject private var manager = ZenCoachManager.shared
    @State private var inputText: String = ""
    @State private var showClearAlert: Bool = false
    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Messages or empty state
                if manager.messages.isEmpty {
                    emptyState
                } else {
                    messagesList
                }

                // Input bar
                inputBar
            }
        }
        .alert("Geçmişi Temizle", isPresented: $showClearAlert) {
            Button("İptal", role: .cancel) {}
            Button("Temizle", role: .destructive) {
                manager.clearHistory()
                HapticManager.shared.playNotification(type: .success)
            }
        } message: {
            Text("Tüm sohbet geçmişi silinecek. Emin misiniz?")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ZenTheme.mysticalViolet, ZenTheme.serenePurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text("🧘")
                    .font(.system(size: 28))
            }

            // Title and status
            VStack(alignment: .leading, spacing: 2) {
                Text("Zen Master")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)

                Text(manager.isProcessing ? "Yazıyor..." : "Çevrimiçi")
                    .font(.system(size: 13))
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
            }

            Spacer()

            // Clear history button
            if !manager.messages.isEmpty {
                Button(action: {
                    showClearAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                        .padding(8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.3)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)

                // Avatar with glow effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ZenTheme.serenePurple.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Text("🧘")
                        .font(.system(size: 80))
                }

                // Title
                Text("Zen Master")
                    .font(ZenTheme.zenTitle)
                    .foregroundColor(ZenTheme.lightLavender)

                // Subtitle with Zen quote
                VStack(spacing: 8) {
                    Text("Mindfulness yolculuğunda rehberin")
                        .font(ZenTheme.zenSubheadline)
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Text("\"Şimdiki an, sahip olduğun tek andır.\"")
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(ZenTheme.softPurple)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Spacer()
                    .frame(height: 20)

                // Suggested prompts
                SuggestedPromptsView(
                    prompts: manager.getSuggestedPrompts(),
                    onPromptTapped: { prompt in
                        // Remove emoji from prompt before sending
                        let cleanPrompt = prompt.replacingOccurrences(of: "🌸 ", with: "")
                            .replacingOccurrences(of: "💭 ", with: "")
                            .replacingOccurrences(of: "⚡ ", with: "")
                            .replacingOccurrences(of: "😴 ", with: "")
                            .replacingOccurrences(of: "🎯 ", with: "")
                            .replacingOccurrences(of: "🫁 ", with: "")
                            .replacingOccurrences(of: "📈 ", with: "")
                            .replacingOccurrences(of: "🧘 ", with: "")
                            .replacingOccurrences(of: "💆 ", with: "")
                            .replacingOccurrences(of: "✨ ", with: "")
                        inputText = cleanPrompt
                        sendMessage()
                    }
                )

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(manager.messages) { message in
                        ChatBubbleView(
                            message: message,
                            action: manager.getAction(for: message.id)
                        )
                        .id(message.id)
                    }

                    // Typing indicator
                    if manager.isProcessing {
                        HStack {
                            TypingIndicatorView()
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .id("typing")
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: manager.messages.count) { _, _ in
                // Auto-scroll to bottom
                if let lastMessage = manager.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: manager.isProcessing) { _, isProcessing in
                // Scroll to typing indicator
                if isProcessing {
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text field
            TextField("Bir şey sor...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundColor(ZenTheme.lightLavender)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(ZenTheme.softPurple.opacity(0.3), lineWidth: 1)
                        )
                )

            // Send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? .gray.opacity(0.5)
                        : ZenTheme.serenePurple
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || manager.isProcessing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.3)
        )
    }

    // MARK: - Actions

    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !manager.isProcessing else { return }

        manager.sendMessage(trimmedText)
        inputText = ""
        isInputFocused = false

        HapticManager.shared.playImpact(style: .light)
    }
}

// MARK: - Preview

#Preview {
    ZenCoachView()
}
