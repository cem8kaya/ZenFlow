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

    // MARK: - Environment Objects (Performance Optimization)
    @EnvironmentObject var manager: ZenCoachManager

    // MARK: - State
    @State private var inputText: String = ""
    @State private var showClearAlert: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?

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
        .alert(String(localized: "zen_coach_clear_history_title", defaultValue: "Geçmişi Temizle", comment: "Clear history alert title"), isPresented: $showClearAlert) {
                    Button(String(localized: "zen_coach_cancel", defaultValue: "İptal", comment: "Cancel button"), role: .cancel) {}
                    Button(String(localized: "zen_coach_clear", defaultValue: "Temizle", comment: "Clear button"), role: .destructive) {
                        manager.clearHistory()
                        HapticManager.shared.playNotification(type: .success)
                    }
                } message: {
                    Text(String(localized: "zen_coach_clear_history_message", defaultValue: "Tüm sohbet geçmişi silinecek. Emin misiniz?", comment: "Clear history confirmation message"))
                }
            }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Close/Dismiss keyboard button - dismisses keyboard and scrolls to top
            Button(action: {
                // Dismiss keyboard
                isInputFocused = false

                // Scroll to top of messages if available
                if let firstMessage = manager.messages.first, let proxy = scrollProxy {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(firstMessage.id, anchor: .top)
                    }
                }

                // Haptic feedback
                HapticManager.shared.playImpact(style: .light)
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }

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
                            Text(String(localized: "zen_coach_title", defaultValue: "Zen Master", comment: "Zen Master title"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(ZenTheme.lightLavender)

                            Group {
                                if manager.isProcessing {
                                    Text(String(localized: "zen_coach_typing", defaultValue: "Yazıyor...", comment: "Typing indicator"))
                                } else {
                                    Text(String(localized: "zen_coach_online", defaultValue: "Çevrimiçi", comment: "Online status"))
                                }
                            }
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
                Text(String(localized: "zen_coach_title", defaultValue: "Zen Master", comment: "Zen Master title"))
                    .font(ZenTheme.zenTitle)
                    .foregroundColor(ZenTheme.lightLavender)

                // Subtitle with Zen quote
                VStack(spacing: 8) {
                    Text(String(localized: "zen_coach_subtitle", defaultValue: "Mindfulness yolculuğunda rehberin", comment: "Your guide in mindfulness journey"))
                        .font(ZenTheme.zenSubheadline)
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Text(String(localized: "zen_coach_quote", defaultValue: "\"Şimdiki an, sahip olduğun tek andır.\"", comment: "Zen wisdom quote"))
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
            if #available(iOS 17.0, *) {
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
                        
                        // Suggested prompts after messages (if not processing)
                        if !manager.isProcessing {
                            VStack(spacing: 12) {
                                Divider()
                                    .background(ZenTheme.softPurple.opacity(0.3))
                                    .padding(.vertical, 8)
                                
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
                            }
                            .padding(.top, 8)
                            .id("prompts")
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
                    // Scroll to typing indicator or last message
                    if isProcessing {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    } else {
                        // Keep focus on the last message (coach response)
                        if let lastMessage = manager.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    // Store proxy for use in header button
                    scrollProxy = proxy
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text field
            TextField(String(localized: "zen_coach_input_placeholder", defaultValue: "Bir şey sor...", comment: "Ask something..."), text: $inputText, axis: .vertical)
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
