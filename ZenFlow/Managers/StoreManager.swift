//
//  StoreManager.swift
//  ZenFlow
//
//  Created by Claude AI on 29.11.2025.
//
//  Manages in-app purchases using StoreKit 2.
//  Handles premium lifetime unlock with offline persistence via UserDefaults.
//

import SwiftUI
import StoreKit
import Combine

/// Manager for in-app purchases and premium features
@MainActor
class StoreManager: ObservableObject {

    // MARK: - Singleton

    static let shared = StoreManager()

    // MARK: - Product IDs

    private let premiumProductID = "com.oqza.myzenflowapp.premium.lifetime"

    
    // MARK: - Published Properties

    @Published private(set) var isPremiumUnlocked: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var products: [Product] = []
    @Published var purchaseError: String? = nil

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>? = nil
    private let userDefaultsKey = "zenflow_premium_unlocked"

    // MARK: - Initialization

    private init() {
        // Load saved premium status from UserDefaults (offline-first)
        self.isPremiumUnlocked = UserDefaults.standard.bool(forKey: userDefaultsKey)

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products and verify purchases
        Task {
            await loadProducts()
            await verifyPurchases()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load available products from the App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Request products from StoreKit
            let storeProducts = try await Product.products(for: [premiumProductID])

            // Update products on main thread
            await MainActor.run {
                self.products = storeProducts
                print("✅ Loaded \(storeProducts.count) product(s)")
            }
        } catch {
            print("❌ Failed to load products: \(error.localizedDescription)")
            await MainActor.run {
                self.purchaseError = String(localized: "error.products.failed", defaultValue: "Ürünler yüklenemedi", comment: "Products failed to load")
            }
        }
    }

    // MARK: - Purchase

    /// Purchase the premium lifetime product
    func purchase() async {
        guard let product = products.first(where: { $0.id == premiumProductID }) else {
            purchaseError = String(localized: "error.product.notfound", defaultValue: "Ürün bulunamadı", comment: "Product not found")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Attempt purchase
            let result = try await product.purchase()

            // Handle purchase result
            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Transaction verified, unlock premium
                await unlockPremium()

                // Finish the transaction
                await transaction.finish()

                print("✅ Purchase successful and verified")

                // Play success haptic
                HapticManager.shared.playNotification(type: .success)

            case .userCancelled:
                print("ℹ️ User cancelled purchase")
                purchaseError = nil // Clear any previous errors

            case .pending:
                print("⏳ Purchase pending approval")
                purchaseError = String(localized: "error.purchase.pending", defaultValue: "Satın alma onay bekliyor", comment: "Purchase pending")

            @unknown default:
                print("⚠️ Unknown purchase result")
                purchaseError = String(localized: "error.purchase.unknown", defaultValue: "Bilinmeyen hata", comment: "Unknown error")
            }

        } catch StoreKitError.userCancelled {
            print("ℹ️ User cancelled purchase")
            purchaseError = nil

        } catch {
            print("❌ Purchase failed: \(error.localizedDescription)")
            purchaseError = String(localized: "error.purchase.failed", defaultValue: "Satın alma başarısız", comment: "Purchase failed")

            // Play error haptic
            HapticManager.shared.playNotification(type: .error)
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Verify all purchases
            await verifyPurchases()

            if isPremiumUnlocked {
                print("✅ Purchases restored successfully")
                HapticManager.shared.playNotification(type: .success)
            } else {
                print("ℹ️ No purchases found to restore")
                purchaseError = String(localized: "error.restore.notfound", defaultValue: "Geri yüklenecek satın alma bulunamadı", comment: "No purchases to restore")
            }

        } catch {
            print("❌ Failed to restore purchases: \(error.localizedDescription)")
            purchaseError = String(localized: "error.restore.failed", defaultValue: "Geri yükleme başarısız", comment: "Restore failed")

            HapticManager.shared.playNotification(type: .error)
        }
    }

    // MARK: - Transaction Verification

    /// Verify all purchases and update premium status
    private func verifyPurchases() async {
        var hasPremium = false

        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is the premium product
                if transaction.productID == premiumProductID {
                    hasPremium = true
                    print("✅ Premium entitlement verified: \(transaction.productID)")
                }
            } catch {
                print("⚠️ Transaction verification failed: \(error.localizedDescription)")
            }
        }

        // Update premium status
        await MainActor.run {
            if hasPremium && !isPremiumUnlocked {
                unlockPremiumSync()
            }
        }
    }

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Check if this unlocks premium
                    if transaction.productID == self.premiumProductID {
                        await self.unlockPremium()
                    }

                    // Always finish a transaction
                    await transaction.finish()

                } catch {
                    print("❌ Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Verify a transaction is valid
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification
        switch result {
        case .unverified:
            // StoreKit has parsed the JWS but failed verification
            throw StoreError.failedVerification
        case .verified(let safe):
            // The result is verified, return the unwrapped value
            return safe
        }
    }

    // MARK: - Premium Management

    /// Unlock premium features (async version)
    private func unlockPremium() async {
        await MainActor.run {
            unlockPremiumSync()
        }
    }

    /// Unlock premium features (sync version for MainActor)
    private func unlockPremiumSync() {
        isPremiumUnlocked = true
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        print("✅ Premium unlocked")
    }

    // MARK: - Helper Methods

    /// Get formatted price for the premium product
    var premiumPrice: String {
        guard let product = products.first(where: { $0.id == premiumProductID }) else {
            return "$2.99"
        }
        return product.displayPrice
    }

    /// Check if a specific feature is available
    func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .allBreathingExercises, .allAmbientSounds, .advancedStats, .premiumThemes:
            return isPremiumUnlocked
        }
    }
}

// MARK: - Premium Features

/// Available premium features
enum PremiumFeature {
    case allBreathingExercises
    case allAmbientSounds
    case advancedStats
    case premiumThemes
}

// MARK: - Store Error

enum StoreError: Error {
    case failedVerification
}
