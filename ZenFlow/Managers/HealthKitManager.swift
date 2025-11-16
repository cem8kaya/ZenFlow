//
//  HealthKitManager.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import HealthKit

class HealthKitManager {
    // MARK: - Singleton

    static let shared = HealthKitManager()

    // MARK: - Properties

    private let healthStore = HKHealthStore()
    private(set) var isHealthKitAvailable = false

    // MARK: - Initialization

    private init() {
        checkHealthKitAvailability()
    }

    // MARK: - Availability Check

    /// Check if HealthKit is available on this device
    private func checkHealthKitAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()

        if isHealthKitAvailable {
            print("✅ HealthKit is available on this device")
        } else {
            print("⚠️ HealthKit is not available on this device")
        }
    }

    // MARK: - Authorization

    /// Request authorization to write mindful sessions to HealthKit
    /// - Parameter completion: Completion handler with success status and optional error
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard isHealthKitAvailable else {
            print("⚠️ HealthKit is not available")
            completion(false, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }

        // Define the data types we want to write
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            print("❌ Failed to get mindful session type")
            completion(false, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get mindful session type"]))
            return
        }

        let typesToWrite: Set<HKSampleType> = [mindfulSessionType]

        // Request authorization
        healthStore.requestAuthorization(toShare: typesToWrite, read: nil) { success, error in
            if success {
                print("✅ HealthKit authorization granted")
            } else {
                print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }

            completion(success, error)
        }
    }

    /// Check the current authorization status for mindful sessions
    /// - Returns: The authorization status
    func getAuthorizationStatus() -> HKAuthorizationStatus {
        guard isHealthKitAvailable else {
            return .notDetermined
        }

        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return .notDetermined
        }

        return healthStore.authorizationStatus(for: mindfulSessionType)
    }

    /// Check if we have permission to write mindful sessions
    /// - Returns: True if authorized, false otherwise
    func isAuthorized() -> Bool {
        let status = getAuthorizationStatus()
        return status == .sharingAuthorized
    }

    // MARK: - Save Mindful Session

    /// Save a mindful session to HealthKit
    /// - Parameters:
    ///   - startDate: The start date of the session
    ///   - endDate: The end date of the session
    ///   - completion: Completion handler with success status and optional error
    func saveMindfulSession(startDate: Date, endDate: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard isHealthKitAvailable else {
            print("⚠️ HealthKit is not available")
            completion(false, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }

        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            print("❌ Failed to get mindful session type")
            completion(false, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get mindful session type"]))
            return
        }

        // Create the mindful session sample
        let mindfulSession = HKCategorySample(
            type: mindfulSessionType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )

        // Save to HealthKit
        healthStore.save(mindfulSession) { success, error in
            if success {
                let duration = endDate.timeIntervalSince(startDate)
                print("✅ Mindful session saved to HealthKit (duration: \(duration)s)")
            } else {
                print("❌ Failed to save mindful session: \(error?.localizedDescription ?? "Unknown error")")
            }

            completion(success, error)
        }
    }
}
