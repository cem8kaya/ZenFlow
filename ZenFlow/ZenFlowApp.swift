//
//  ZenFlowApp.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
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

                ZenGardenView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Zen Bahçem", systemImage: "tree.fill")
                    }

                BadgesView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Rozetler", systemImage: "trophy.fill")
                    }
            }
            .preferredColorScheme(.dark)
        }
    }
}
