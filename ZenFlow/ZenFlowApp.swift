//
//  ZenFlowApp.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//  Updated by Claude AI on 16.11.2025.
//
//  Main application entry point defining the tab-based navigation
//  structure with meditation, garden, badges, and theme selection views.
//

import SwiftUI
import CoreData

@main
struct ZenFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                BreathingView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Meditasyon", systemImage: "leaf.circle.fill")
                    }
                    .accessibilityLabel("Meditasyon sekmesi")

                ZenGardenView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Zen Bahçem", systemImage: "tree.fill")
                    }
                    .accessibilityLabel("Zen Bahçem sekmesi")

                BadgesView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Rozetler", systemImage: "trophy.fill")
                    }
                    .accessibilityLabel("Rozetler sekmesi")

                ThemeSelectionView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Temalar", systemImage: "paintpalette.fill")
                    }
                    .accessibilityLabel("Temalar sekmesi")
            }
            .preferredColorScheme(.dark)
        }
    }
}
