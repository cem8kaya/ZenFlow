//
//  IntentClassifier.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Intent classification and sentiment analysis using Apple's NaturalLanguage framework.
//  Supports Turkish language with keyword matching and NLP fallback.
//

import Foundation
import NaturalLanguage

// MARK: - Intent Classifier

/// Singleton class for classifying user intent and analyzing sentiment
class IntentClassifier {

    // MARK: - Singleton

    static let shared = IntentClassifier()

    private init() {}

    // MARK: - Intent Classification

    /// Classifies user intent from message text
    /// - Parameter text: User's message text
    /// - Returns: Classified intent (defaults to .general if no match)
    func classifyIntent(from text: String) -> UserIntent {
        let lowercasedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Primary method: Keyword matching
        for intent in UserIntent.allCases {
            for keyword in intent.keywords {
                if lowercasedText.contains(keyword) {
                    print("🎯 Intent classified: \(intent.displayName) (keyword: \(keyword))")
                    return intent
                }
            }
        }

        // Fallback method: NLP-based matching
        let nlpIntent = classifyIntentWithNLP(from: text)
        if nlpIntent != .general {
            print("🎯 Intent classified: \(nlpIntent.displayName) (NLP fallback)")
            return nlpIntent
        }

        print("🎯 Intent classified: General (no match)")
        return .general
    }

    /// NLP-based intent classification using NaturalLanguage framework
    /// - Parameter text: User's message text
    /// - Returns: Classified intent
    private func classifyIntentWithNLP(from text: String) -> UserIntent {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        var extractedTokens: [String] = []

        // Extract nouns and verbs
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag {
                let token = String(text[tokenRange]).lowercased()
                if tag == .noun || tag == .verb {
                    extractedTokens.append(token)
                }
            }
            return true
        }

        // Fuzzy match extracted tokens against intent keywords
        var intentScores: [UserIntent: Int] = [:]

        for token in extractedTokens {
            for intent in UserIntent.allCases where intent != .general {
                for keyword in intent.keywords {
                    if token.contains(keyword) || keyword.contains(token) {
                        intentScores[intent, default: 0] += 1
                    }
                }
            }
        }

        // Return intent with highest score
        if let bestIntent = intentScores.max(by: { $0.value < $1.value }), bestIntent.value > 0 {
            return bestIntent.key
        }

        return .general
    }

    // MARK: - Sentiment Analysis

    /// Analyzes sentiment from message text
    /// - Parameter text: User's message text
    /// - Returns: Sentiment classification
    func analyzeSentiment(from text: String) -> MessageSentiment {
        // Primary method: NaturalLanguage sentiment score
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var sentimentScore: Double = 0.0
        var hasValidScore = false

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                sentimentScore = score
                hasValidScore = true
            }
            return true
        }

        if hasValidScore {
            let sentiment: MessageSentiment
            if sentimentScore > 0.3 {
                sentiment = .positive
            } else if sentimentScore < -0.3 {
                sentiment = .negative
            } else {
                sentiment = .neutral
            }
            print("😊 Sentiment analyzed: \(sentiment.displayName) (score: \(sentimentScore))")
            return sentiment
        }

        // Fallback method: Keyword-based sentiment
        let keywordSentiment = analyzeSentimentWithKeywords(from: text)
        print("😊 Sentiment analyzed: \(keywordSentiment.displayName) (keyword fallback)")
        return keywordSentiment
    }

    /// Keyword-based sentiment analysis fallback
    /// - Parameter text: User's message text
    /// - Returns: Sentiment classification
    private func analyzeSentimentWithKeywords(from text: String) -> MessageSentiment {
        let lowercasedText = text.lowercased()

        var positiveCount = 0
        var negativeCount = 0

        // Count positive keywords
        for keyword in MessageSentiment.positive.keywords {
            if lowercasedText.contains(keyword) {
                positiveCount += 1
            }
        }

        // Count negative keywords
        for keyword in MessageSentiment.negative.keywords {
            if lowercasedText.contains(keyword) {
                negativeCount += 1
            }
        }

        // Determine sentiment based on counts
        if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else {
            return .neutral
        }
    }

    // MARK: - Language Detection

    /// Detects the dominant language in the text
    /// - Parameter text: Input text
    /// - Returns: Language code (e.g., "tr", "en")
    func detectLanguage(from text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        if let language = recognizer.dominantLanguage {
            print("🌍 Language detected: \(language.rawValue)")
            return language.rawValue
        }

        return nil
    }
}
