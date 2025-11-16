//
//  Persistence.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//  Updated by Claude AI on 16.11.2025.
//
//  CoreData persistence controller for managing the app's local database.
//  Currently provides boilerplate setup; app uses UserDefaults for data storage.
//  This can be extended for more complex data persistence needs in the future.
//

import CoreData

/// Controller for managing CoreData persistent container and context
struct PersistenceController {

    // MARK: - Shared Instance

    /// Shared singleton instance for production use
    static let shared = PersistenceController()

    // MARK: - Preview Instance

    /// Preview instance with in-memory store for SwiftUI previews and testing
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for previews
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error creating preview data: \(nsError), \(nsError.userInfo)")
            // Note: fatalError acceptable in preview context only
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return result
    }()

    // MARK: - Properties

    /// The NSPersistentContainer managing the CoreData stack
    let container: NSPersistentContainer

    // MARK: - Initialization

    /// Initialize the persistence controller
    /// - Parameter inMemory: If true, uses in-memory store (for testing/previews)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ZenFlow")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                /*
                 Common persistence errors:
                 - Parent directory doesn't exist or isn't writable
                 - Store not accessible due to permissions or data protection
                 - Device out of space
                 - Store migration failed

                 In production, handle errors gracefully:
                 1. Log the error for debugging
                 2. Attempt recovery (delete/recreate store if necessary)
                 3. Notify user if data loss occurred
                 4. Provide fallback behavior
                */

                print("CoreData error: \(error), \(error.userInfo)")
                print("Store description: \(storeDescription)")

                // TODO: Implement production error handling
                // For now, crash in development to catch issues early
                fatalError("Unresolved CoreData error \(error), \(error.userInfo)")
            }
        }

        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
