//
//  CoachIntentScorer.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Scores a message against every intent's keywords. Compared with "first
//  keyword that appears anywhere wins" it:
//   - folds case and diacritics, so "UYUYAMIYORUM" and "uyuyamıyorum" match
//     (Turkish dotted/dotless i included)
//   - matches whole words by prefix, so "kaygılarımı" hits "kaygı" but
//     "interest" does not hit "rest"
//   - gives generic words ("help", "nasıl", "start") a low weight
//   - counts every matching keyword and picks the best-scoring intent
//

import Foundation

enum CoachIntentScorer {

    // MARK: - Normalization

    /// Lowercase, strip diacritics and map the Turkish dotless i, so text typed
    /// with or without Turkish characters compares equal.
    static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .replacingOccurrences(of: "ı", with: "i")
    }

    /// Words of a normalized text (letters and digits only)
    static func tokens(of normalizedText: String) -> [String] {
        normalizedText
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    // MARK: - Weights

    /// Generic words that appear in many sentences; they only nudge the score
    private static let weakKeywords: Set<String> = [
        "help", "start", "how", "learn", "rest", "night", "exercise", "technique", "work", "energy", "power",
        "status", "tired", "exhausted", "dream", "stats",
        "nasil", "ogren", "basla", "guc", "gece", "egzersiz", "teknik", "calis", "enerji", "durum",
        "yorgun", "bitkin", "dinlen", "yat", "baslangic", "huzur", "sakinles", "calisma", "dikkat"
    ].reduce(into: Set<String>()) { $0.insert(normalize($1)) }

    private static let weakWeight = 0.4
    private static let phraseWeight = 2.0

    /// Keywords per intent, normalized once
    private static let normalizedKeywords: [UserIntent: [String]] = {
        var result: [UserIntent: [String]] = [:]
        for intent in UserIntent.allCases {
            result[intent] = Array(Set(intent.keywords.map(normalize)))
        }
        return result
    }()

    // MARK: - Scoring

    /// Score of each intent for `text` (intents without any match are omitted)
    static func scores(for text: String) -> [UserIntent: Double] {
        let normalized = normalize(text)
        let words = tokens(of: normalized)
        var result: [UserIntent: Double] = [:]

        for intent in UserIntent.allCases where intent != .general {
            var total = 0.0

            for keyword in normalizedKeywords[intent] ?? [] {
                let isPhrase = keyword.contains(" ") || keyword.contains("-")

                if isPhrase {
                    if normalized.contains(keyword) {
                        total += phraseWeight
                    }
                } else if matchesWord(keyword, in: words) {
                    total += weakKeywords.contains(keyword) ? weakWeight : 1.0
                }
            }

            if total > 0 {
                result[intent] = total
            }
        }
        return result
    }

    /// Best intent, or nil without any keyword match. Ties go to the intent
    /// declared first in `UserIntent`.
    static func bestIntent(for text: String) -> UserIntent? {
        let all = scores(for: text)
        guard !all.isEmpty else { return nil }

        let order = UserIntent.allCases
        return all.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            // Equal score: the earlier case wins, so it must compare as "greater"
            return order.firstIndex(of: lhs.key)! > order.firstIndex(of: rhs.key)!
        }?.key
    }

    /// Whole-word match by prefix (short keywords must match exactly)
    private static func matchesWord(_ keyword: String, in words: [String]) -> Bool {
        if keyword.count < 4 {
            return words.contains(keyword)
        }
        return words.contains { $0.hasPrefix(keyword) }
    }
}
