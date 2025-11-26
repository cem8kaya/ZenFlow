//
//  LanguageManager.swift
//  ZenFlow
//
//  Created by Claude AI on 25.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Manages app language preferences with runtime Bundle swap
//

import Foundation
import SwiftUI
import Combine

// MARK: - AppLanguage Enum

enum AppLanguage: String, CaseIterable {
    case turkish = "tr"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
    
    var localizedDisplayName: LocalizedStringKey {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "İngilizce"
        }
    }
    
    var localeIdentifier: String {
        switch self {
        case .turkish: return "tr_TR"
        case .english: return "en_US"
        }
    }
}

// MARK: - LanguageManager

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    // UserDefaults keys
    private let kAppLanguageKey = "appLanguage"
    private let kAppleLanguagesKey = "AppleLanguages"
    
    // Published properties for SwiftUI
    @Published var currentLanguage: AppLanguage {
        didSet {
            applyLanguageChange()
        }
    }
    
    @Published var locale: Locale
    @Published var languageRefreshID = UUID()
    
    // Runtime bundle for localization
    private var localizedBundle: Bundle?
    
    private init() {
        // 1. Önce kaydedilen dili yerel bir değişkene alıyoruz (self kullanmadan)
        let savedCode = UserDefaults.standard.string(forKey: "appLanguage") ?? "tr"
        let initialLanguage = AppLanguage(rawValue: savedCode) ?? .turkish
        
        // 2. Property'leri bu yerel değişkeni kullanarak başlatıyoruz
        self.currentLanguage = initialLanguage
        self.locale = Locale(identifier: initialLanguage.localeIdentifier)
        
        // 3. Tüm property'ler atandığına göre artık 'self' kullanabilir ve fonksiyon çağırabiliriz
        setupLocalizedBundle(for: initialLanguage)
    }
    
    /// Sets the app language and applies changes
    func setLanguage(_ language: AppLanguage) {
        guard currentLanguage != language else { return }
        currentLanguage = language
    }
    
    // MARK: - Private Methods
    
    private func applyLanguageChange() {
        // 1. Save to UserDefaults
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: kAppLanguageKey)
        
        // 2. Update AppleLanguages (required for system-level language change)
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: kAppleLanguagesKey)
        UserDefaults.standard.synchronize()
        
        // 3. Setup localized bundle
        setupLocalizedBundle(for: currentLanguage)
        
        // 4. Update locale for SwiftUI environment
        locale = Locale(identifier: currentLanguage.localeIdentifier)
        
        // 5. Trigger full app refresh
        languageRefreshID = UUID()
        
        // 6. Send notification for observers
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
        
        print("🌍 Language changed to: \(currentLanguage.displayName)")
    }
    
    private func setupLocalizedBundle(for language: AppLanguage) {
        // Find the localized bundle path
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.localizedBundle = bundle
            
            // Override main bundle's localization (advanced technique)
            object_setClass(Bundle.main, LocalizedBundle.self)
            LocalizedBundle.currentLanguage = language.rawValue
        }
    }
    
    /// Get localized string with current language
    func localized(_ key: String, comment: String = "") -> String {
        if let bundle = localizedBundle {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return NSLocalizedString(key, comment: comment)
    }
}

// MARK: - LocalizedBundle (Runtime Bundle Swap)

private class LocalizedBundle: Bundle, @unchecked Sendable {
    static var currentLanguage: String = "tr"
    
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // Get the bundle for the current language
        guard let path = Bundle.main.path(forResource: LocalizedBundle.currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

// MARK: - String Extension

extension String {
    /// Get localized string using LanguageManager
    func localized(comment: String = "") -> String {
        return LanguageManager.shared.localized(self, comment: comment)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
