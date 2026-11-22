//
//  ZenShareCardView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  A square-ish card with the teaching of the day, rendered to an image
//  (ImageRenderer) so it can be shared from the Daily Zen Moment sheet.
//

import SwiftUI

struct ZenShareCardView: View {
    let teaching: ZenTeaching
    let category: ZenCategory

    /// Logical size of the card; the renderer scales it up for sharing
    static let size = CGSize(width: 360, height: 450)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ZenTheme.deepIndigo,
                    Color(red: 0.10, green: 0.08, blue: 0.22),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(ZenTheme.mysticalViolet.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 110, y: -150)

            VStack(spacing: 22) {
                HStack(spacing: 8) {
                    Image(systemName: ZenWisdomLibrary.shared.iconForCategory(category))
                        .font(.system(size: 14))
                    Text(category.displayName)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(ZenTheme.lightLavender)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(ZenTheme.mysticalViolet.opacity(0.35)))

                Spacer(minLength: 0)

                Text(teaching.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(ZenTheme.lightLavender)
                    .multilineTextAlignment(.center)

                if let quote = teaching.quote, !quote.isEmpty {
                    Text("\u{201C}\(quote)\u{201D}")
                        .font(.system(size: 19, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .minimumScaleFactor(0.8)

                    if let author = teaching.author, !author.isEmpty {
                        Text("— \(author)")
                            .font(.system(size: 14))
                            .foregroundColor(ZenTheme.softPurple)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                    Text("MyZenFlow")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(ZenTheme.lightLavender.opacity(0.7))
            }
            .padding(28)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }
}
