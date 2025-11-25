//
//  EnhancedZenCoachView.swift
//  ZenFlow
//
//  Created by Claude AI on 25.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Zen Master ana görünümü - kategori grid, günlük öğreti ve kişiselleştirilmiş tavsiyeler
//  Derin Zen felsefesi ve öğretileri ile zenginleştirilmiş kullanıcı deneyimi
//

import SwiftUI

struct EnhancedZenCoachView: View {
    @StateObject private var viewModel = ZenCoachViewModel()
    @State private var selectedCategory: ZenCategory?
    @State private var currentTeaching: ZenTeaching?
    @State private var showingTeachingDetail = false

    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Başlık Bölümü
                        zenMasterHeader

                        // Günün Zen Öğretisi Kartı
                        dailyTeachingCard

                        // Kategori Grid Bölümü
                        categoriesSection

                        // Kişiselleştirilmiş Tavsiye Kartı
                        personalizedAdviceCard

                        // Zen Alıştırması Kartı
                        zenPracticeCard
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingTeachingDetail) {
                if let teaching = currentTeaching {
                    TeachingDetailView(teaching: teaching)
                }
            }
        }
        .onAppear {
            viewModel.loadDailyTeaching()
        }
    }

    // MARK: - View Components

    private var zenMasterHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.purple)

            Text("Zen Master", comment: "Zen Master header title")
                .font(.system(size: 32, weight: .bold, design: .serif))

            Text("Bilgelik yolculuğuna hoş geldin", comment: "Zen Master welcome message")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }

    private var dailyTeachingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
                Text("Günün Öğretisi", comment: "Daily teaching section title")
                    .font(.headline)
            }

            if let teaching = viewModel.dailyTeaching {
                VStack(alignment: .leading, spacing: 12) {
                    Text(teaching.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(teaching.content)
                        .font(.body)
                        .lineLimit(4)
                        .foregroundColor(.secondary)

                    if let quote = teaching.quote {
                        HStack(alignment: .top, spacing: 8) {
                            Rectangle()
                                .fill(Color.purple)
                                .frame(width: 3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(quote)
                                    .font(.callout)
                                    .italic()

                                if let author = teaching.author {
                                    Text("— \(author)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Button(action: {
                        currentTeaching = teaching
                        showingTeachingDetail = true
                    }) {
                        Text("Devamını Oku", comment: "Read more button")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zen Öğretileri", comment: "Zen teachings section title")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(ZenCategory.allCases, id: \.self) { category in
                    CategoryCard(category: category) {
                        selectedCategory = category
                        currentTeaching = ZenWisdomLibrary.shared.getTeaching(for: category)
                        showingTeachingDetail = true
                    }
                }
            }
        }
    }

    private var personalizedAdviceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text("Sana Özel Tavsiye", comment: "Personalized advice section title")
                    .font(.headline)
            }

            Text(viewModel.personalizedAdvice)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }

    private var zenPracticeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Bugünün Uygulaması", comment: "Today's practice section title")
                    .font(.headline)
            }

            if let teaching = viewModel.dailyTeaching {
                Text(teaching.practicalAdvice)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// MARK: - Category Card Component
struct CategoryCard: View {
    let category: ZenCategory
    let action: () -> Void

    private let library = ZenWisdomLibrary.shared

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: library.iconForCategory(category))
                    .font(.system(size: 30))
                    .foregroundColor(colorForCategory)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var colorForCategory: Color {
        switch category {
        case .mindfulness: return .purple
        case .impermanence: return .orange
        case .acceptance: return .blue
        case .simplicity: return .gray
        case .beginner: return .yellow
        case .meditation: return .indigo
        case .breath: return .cyan
        case .nature: return .green
        case .silence: return .mint
        case .balance: return .pink
        }
    }
}

// MARK: - Teaching Detail View
struct TeachingDetailView: View {
    let teaching: ZenTeaching
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Başlık
                    Text(teaching.title)
                        .font(.system(size: 28, weight: .bold, design: .serif))

                    Divider()

                    // Ana İçerik
                    Text(teaching.content)
                        .font(.body)
                        .lineSpacing(8)

                    // Alıntı Bölümü
                    if let quote = teaching.quote {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()

                            HStack(alignment: .top, spacing: 12) {
                                Rectangle()
                                    .fill(Color.purple)
                                    .frame(width: 4)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(quote)
                                        .font(.title3)
                                        .italic()

                                    if let author = teaching.author {
                                        Text("— \(author)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }

                    Divider()

                    // Pratik Uygulama Bölümü
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Uygulama", comment: "Practice section title")
                                .font(.headline)
                        }

                        Text(teaching.practicalAdvice)
                            .font(.body)
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle(Text("Zen Öğretisi", comment: "Zen teaching detail page title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Kapat", comment: "Close button")
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct EnhancedZenCoachView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedZenCoachView()
    }
}
