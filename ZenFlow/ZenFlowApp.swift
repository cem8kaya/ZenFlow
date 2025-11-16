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
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
