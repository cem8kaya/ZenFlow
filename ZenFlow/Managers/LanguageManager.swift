//
//  LanguageManager.swift
//  ZenFlow
//
//  Created by Claude AI on 25.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Manages app language preferences
//

import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case turkish = "tr"
    case english = "en"

    var displayName: String {
        switch self {
        case .turkish:
            return "Türkçe"
        case .english:
            return "English"
        }
    }

    var localizedDisplayName: LocalizedStringKey {
        switch self {
        case .turkish:
            return "Türkçe"
        case .english:
            return "İngilizce"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage("appLanguage") private var languageCode: String = "tr"

    @Published var currentLanguage: AppLanguage {
        didSet {
            languageCode = currentLanguage.rawValue
            // Post notification for language change
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    private init() {
        // Initialize from stored preference
        if let language = AppLanguage(rawValue: languageCode) {
            currentLanguage = language
        } else {
            currentLanguage = .turkish
        }
    }

    /// Sets the app language
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
