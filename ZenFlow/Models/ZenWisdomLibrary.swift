//
//  ZenWisdomLibrary.swift
//  ZenFlow
//
//  Created by Claude AI on 25.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Zen öğretileri kütüphanesi ve kategori yönetimi
//  Offline çalışan, derin Zen felsefesi içeren hikmet kitaplığı
//

import Foundation

// MARK: - Zen Kategorileri
enum ZenCategory: String, CaseIterable {
    case mindfulness
    case impermanence
    case acceptance
    case simplicity
    case beginner
    case meditation
    case breath
    case nature
    case silence
    case balance

    var displayName: String {
        String(localized: LocalizedStringKey("zen_category_\(rawValue)"), comment: "Zen category")
    }
}

// MARK: - Zen Öğretisi Modeli
struct ZenTeaching: Identifiable, Codable {
    let id: UUID
    let teachingIndex: Int
    let category: String

    // Localized computed properties
    var title: String {
        String(localized: LocalizedStringKey("zen_teaching_\(teachingIndex)_title"), comment: "Teaching title")
    }

    var content: String {
        String(localized: LocalizedStringKey("zen_teaching_\(teachingIndex)_content"), comment: "Teaching content")
    }

    var quote: String? {
        let quoteText = String(localized: LocalizedStringKey("zen_teaching_\(teachingIndex)_quote"), comment: "Teaching quote")
        return quoteText.isEmpty ? nil : quoteText
    }

    var author: String? {
        let authorText = String(localized: LocalizedStringKey("zen_teaching_\(teachingIndex)_author"), comment: "Teaching author")
        return authorText.isEmpty ? nil : authorText
    }

    var practicalAdvice: String {
        String(localized: LocalizedStringKey("zen_teaching_\(teachingIndex)_advice"), comment: "Practical advice")
    }

    init(id: UUID = UUID(), teachingIndex: Int, category: ZenCategory) {
        self.id = id
        self.teachingIndex = teachingIndex
        self.category = category.rawValue
    }
}

// MARK: - Zen Hikmet Kütüphanesi
class ZenWisdomLibrary {
    static let shared = ZenWisdomLibrary()

    private var teachings: [ZenTeaching] = []

    private init() {
        loadTeachings()
    }

    private func loadTeachings() {
        teachings = [
            ZenTeaching(teachingIndex: 0, category: .mindfulness),
            ZenTeaching(teachingIndex: 1, category: .impermanence),
            ZenTeaching(teachingIndex: 2, category: .acceptance),
            ZenTeaching(teachingIndex: 3, category: .simplicity),
            ZenTeaching(teachingIndex: 4, category: .beginner),
            ZenTeaching(teachingIndex: 5, category: .meditation),
            ZenTeaching(teachingIndex: 6, category: .breath),
            ZenTeaching(teachingIndex: 7, category: .nature),
            ZenTeaching(teachingIndex: 8, category: .silence),
            ZenTeaching(teachingIndex: 9, category: .balance)
        ]
    }

    // MARK: - Public Methods

    /// Kategoriye göre rastgele öğreti al
    func getTeaching(for category: ZenCategory) -> ZenTeaching? {
        return teachings.filter { $0.category == category.rawValue }.randomElement()
    }

    /// Tamamen rastgele bir öğreti al
    func getRandomTeaching() -> ZenTeaching {
        return teachings.randomElement() ?? teachings[0]
    }

    /// Kullanıcı bağlamına göre uygun öğreti al
    func getTeachingForContext(sessionCount: Int, lastSessionDate: Date?, currentMood: String?) -> ZenTeaching {
        // Başlangıç kullanıcıları için
        if sessionCount < 5 {
            return getTeaching(for: .beginner) ?? getRandomTeaching()
        }

        // Düzenli kullanıcılar için nefes odaklı
        if let lastDate = lastSessionDate, Calendar.current.isDateInToday(lastDate) {
            return getTeaching(for: .breath) ?? getRandomTeaching()
        }

        // Genel rotasyon
        return getRandomTeaching()
    }

    /// Tüm kategorileri al
    func getAllCategories() -> [ZenCategory] {
        return ZenCategory.allCases
    }

    /// Kategori için ikon adı
    func iconForCategory(_ category: ZenCategory) -> String {
        switch category {
        case .mindfulness: return "brain.head.profile"
        case .impermanence: return "leaf"
        case .acceptance: return "hand.raised.fill"
        case .simplicity: return "circle"
        case .beginner: return "sparkles"
        case .meditation: return "figure.mind.and.body"
        case .breath: return "wind"
        case .nature: return "tree"
        case .silence: return "speaker.slash.fill"
        case .balance: return "scale.3d"
        }
    }

    /// Kategori için renk
    func colorForCategory(_ category: ZenCategory) -> String {
        switch category {
        case .mindfulness: return "purple"
        case .impermanence: return "orange"
        case .acceptance: return "blue"
        case .simplicity: return "gray"
        case .beginner: return "yellow"
        case .meditation: return "indigo"
        case .breath: return "cyan"
        case .nature: return "green"
        case .silence: return "mint"
        case .balance: return "pink"
        }
    }
}
