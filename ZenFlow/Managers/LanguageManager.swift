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
    
    // UserDefaults anahtarını sabit olarak tanımlamak hatayı azaltır
    private let kAppLanguageKey = "appLanguage"
    
    @AppStorage("appLanguage") private var languageCode: String = "tr"
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            // Dil değiştiğinde AppStorage'ı güncelle
            languageCode = currentLanguage.rawValue
            // Notification gönder
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    private init() {
        // ÇÖZÜM: @AppStorage (self.languageCode) yerine UserDefaults.standard kullanıyoruz.
        // Böylece 'self' tam olarak başlatılmadan önce veriyi okuyabiliyoruz.
        let savedCode = UserDefaults.standard.string(forKey: "appLanguage") ?? "tr"
        
        // Değeri atayarak initialization sürecini tamamlıyoruz
        self.currentLanguage = AppLanguage(rawValue: savedCode) ?? .turkish
    }
    
    /// Sets the app language
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
