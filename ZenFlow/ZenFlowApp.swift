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
    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            SwipeableTabView(selection: $selectedTab, persistenceController: persistenceController)
                .preferredColorScheme(.dark)
        }
    }
}

/// Kaydırma destekli tab view wrapper
struct SwipeableTabView: View {
    @Binding var selection: Int
    let persistenceController: PersistenceController
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        TabView(selection: $selection) {
            BreathingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Meditasyon", systemImage: "leaf.circle.fill")
                }
                .accessibilityLabel("Meditasyon sekmesi")
                .tag(0)
                .gesture(swipeGesture)

            ZenGardenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Zen Bahçem", systemImage: "tree.fill")
                }
                .accessibilityLabel("Zen Bahçem sekmesi")
                .tag(1)
                .gesture(swipeGesture)

            BadgesView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Rozetler", systemImage: "trophy.fill")
                }
                .accessibilityLabel("Rozetler sekmesi")
                .tag(2)
                .gesture(swipeGesture)

            ThemeSelectionView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tabItem {
                    Label("Temalar", systemImage: "paintpalette.fill")
                }
                .accessibilityLabel("Temalar sekmesi")
                .tag(3)
                .gesture(swipeGesture)
        }
    }

    /// Kaydırma gesture'ı
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .local)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                // Yatay kaydırma dikey kaydırmadan fazlaysa (gerçek bir swipe)
                if abs(horizontalAmount) > abs(verticalAmount) {
                    if horizontalAmount < 0 {
                        // Sola kaydırma - sonraki tab
                        withAnimation {
                            selection = min(selection + 1, 3)
                        }
                    } else {
                        // Sağa kaydırma - önceki tab
                        withAnimation {
                            selection = max(selection - 1, 0)
                        }
                    }
                }
            }
    }
}
