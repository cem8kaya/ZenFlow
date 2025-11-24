//
//  SoundCreditsView.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Displays attribution for ambient sounds (if using CC BY licensed sounds).
//

import SwiftUI

/// View displaying sound attribution information
struct SoundCreditsView: View {

    // MARK: - Attribution Data

    /// List of sound attributions
    /// Update this list when adding CC BY licensed sounds
    private let attributions: [SoundAttribution] = [
        // Example entries - update with actual attributions when sounds are added
        // SoundAttribution(
        //     soundName: "Thunderstorm",
        //     author: "John Smith",
        //     source: "Freesound.org",
        //     license: "CC BY 4.0",
        //     url: "https://freesound.org/..."
        // )
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            ZenTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ses Kredileri")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("ZenFlow'da kullanılan ortam seslerinin kaynakları ve lisans bilgileri")
                            .font(.system(size: 16))
                            .foregroundColor(ZenTheme.lightLavender.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Attribution List
                    if attributions.isEmpty {
                        // No attributions required (all CC0/Pixabay License)
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(ZenTheme.sageGreen)

                            Text("Tüm sesler ücretsiz kullanım lisansına sahip")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("ZenFlow'da kullanılan tüm ortam sesleri CC0 (Public Domain) veya Pixabay Lisansı ile lisanslanmıştır ve atıf gerektirmez.")
                                .font(.system(size: 14))
                                .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Show attributions
                        VStack(spacing: 16) {
                            ForEach(attributions) { attribution in
                                AttributionCard(attribution: attribution)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Sound Sources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ses Kaynakları")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        VStack(spacing: 12) {
                            SourceLink(
                                icon: "waveform.circle.fill",
                                name: "Freesound.org",
                                description: "Topluluk destekli ses kütüphanesi",
                                url: "https://freesound.org"
                            )

                            SourceLink(
                                icon: "music.note.list",
                                name: "Pixabay",
                                description: "Ücretsiz ses efektleri",
                                url: "https://pixabay.com/sound-effects/"
                            )

                            SourceLink(
                                icon: "speaker.wave.3.fill",
                                name: "Mixkit",
                                description: "Ücretsiz müzik ve ses efektleri",
                                url: "https://mixkit.co/free-sound-effects/"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Attribution Model

struct SoundAttribution: Identifiable {
    let id = UUID()
    let soundName: String
    let author: String
    let source: String
    let license: String
    let url: String?
}

// MARK: - Attribution Card

private struct AttributionCard: View {
    let attribution: SoundAttribution

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sound name
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(ZenTheme.softPurple)
                Text(attribution.soundName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Author
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.6))
                Text(attribution.author)
                    .font(.system(size: 14))
                    .foregroundColor(ZenTheme.lightLavender)
            }

            // Source & License
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.6))
                Text("\(attribution.source) • \(attribution.license)")
                    .font(.system(size: 14))
                    .foregroundColor(ZenTheme.lightLavender)
            }

            // URL (if available)
            if let url = attribution.url {
                Link(destination: URL(string: url)!) {
                    HStack(spacing: 6) {
                        Text("Kaynağı Görüntüle")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(ZenTheme.calmBlue)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Source Link

private struct SourceLink: View {
    let icon: String
    let name: String
    let description: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(ZenTheme.softPurple)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(ZenTheme.softPurple.opacity(0.2))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundColor(ZenTheme.lightLavender.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SoundCreditsView()
    }
    .preferredColorScheme(.dark)
}
