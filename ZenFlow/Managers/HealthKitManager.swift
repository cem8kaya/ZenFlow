//
//  HealthKitManager.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

internal import HealthKit
import Combine

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

    /// Custom error types for HealthKit operations
    enum HealthKitError: LocalizedError {
        case healthKitNotAvailable
        case mindfulSessionTypeNotAvailable
        case invalidDateRange
        case saveFailed(Error)
        case notAuthorized

        var errorDescription: String? {
            switch self {
            case .healthKitNotAvailable:
                return String(localized: "error_healthkit_not_available", defaultValue: "HealthKit bu cihazda kullanılamıyor", comment: "HealthKit not available error message")
            case .mindfulSessionTypeNotAvailable:
                return String(localized: "error_mindful_session_type_not_available", defaultValue: "Mindful Session veri tipi alınamadı", comment: "Mindful session type not available error message")
            case .invalidDateRange:
                return String(localized: "error_invalid_date_range", defaultValue: "Geçersiz tarih aralığı: Başlangıç zamanı bitiş zamanından sonra olamaz", comment: "Invalid date range error message")
            case .saveFailed(let error):
                return String(localized: "error_save_failed", defaultValue: "Veri kaydedilemedi: \(error.localizedDescription)", comment: "Save failed error message")
            case .notAuthorized:
                return String(localized: "error_not_authorized", defaultValue: "HealthKit izni verilmedi. Lütfen Ayarlar'dan izin verin", comment: "HealthKit not authorized error message")
            }
        }
    }

    /// Save a mindful session to HealthKit (async/await version)
    /// - Parameters:
    ///   - startDate: The start date of the session
    ///   - endDate: The end date of the session
    /// - Throws: HealthKitError if the operation fails
    func saveMindfulSession(startDate: Date, endDate: Date) async throws {
        // Validate HealthKit availability
        guard isHealthKitAvailable else {
            print("⚠️ HealthKit is not available")
            throw HealthKitError.healthKitNotAvailable
        }

        // Validate authorization
        guard isAuthorized() else {
            print("⚠️ HealthKit authorization not granted")
            throw HealthKitError.notAuthorized
        }

        // Validate date range
        guard startDate < endDate else {
            print("⚠️ Invalid date range: start(\(startDate)) >= end(\(endDate))")
            throw HealthKitError.invalidDateRange
        }

        // Get mindful session type
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            print("❌ Failed to get mindful session type")
            throw HealthKitError.mindfulSessionTypeNotAvailable
        }

        // Create the mindful session sample
        let mindfulSession = HKCategorySample(
            type: mindfulSessionType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )

        // Save to HealthKit using async/await
        do {
            try await healthStore.save(mindfulSession)
            let duration = endDate.timeIntervalSince(startDate)
            let minutes = Int(duration / 60)
            print("✅ Mindful session saved to HealthKit (duration: \(minutes) dakika)")
        } catch {
            print("❌ Failed to save mindful session: \(error.localizedDescription)")
            throw HealthKitError.saveFailed(error)
        }
    }

    /// Save a mindful session to HealthKit (completion handler version for backward compatibility)
    /// - Parameters:
    ///   - startDate: The start date of the session
    ///   - endDate: The end date of the session
    ///   - completion: Completion handler with success status and optional error
    func saveMindfulSession(startDate: Date, endDate: Date, completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                try await saveMindfulSession(startDate: startDate, endDate: endDate)
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
    }
}
