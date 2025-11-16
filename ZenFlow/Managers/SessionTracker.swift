//
//  SessionTracker.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import Foundation
import Combine

class SessionTracker: ObservableObject {
    // MARK: - Singleton

    static let shared = SessionTracker()

    // MARK: - Published Properties

    @Published private(set) var isActive: Bool = false
    @Published private(set) var startDate: Date?
    @Published private(set) var endDate: Date?
    @Published private(set) var duration: TimeInterval = 0

    // MARK: - Private Properties

    private var timer: Timer?

    // MARK: - Initialization

    private init() {
        print("✅ SessionTracker initialized")
    }

    // MARK: - Session Management

    /// Start a new meditation session
    func startSession() {
        guard !isActive else {
            print("⚠️ Session already active")
            return
        }

        // Reset previous session data
        endDate = nil
        duration = 0

        // Start new session
        startDate = Date()
        isActive = true

        // Start duration timer
        startDurationTimer()

        print("▶️ Session started at \(startDate!)")
    }

    /// End the current meditation session
    /// - Parameter completion: Optional completion handler with session duration
    func endSession(completion: ((TimeInterval) -> Void)? = nil) {
        guard isActive, let sessionStartDate = startDate else {
            print("⚠️ No active session to end")
            return
        }

        // Stop timer
        stopDurationTimer()

        // Record end time
        endDate = Date()
        isActive = false

        // Calculate final duration
        if let sessionEndDate = endDate {
            duration = sessionEndDate.timeIntervalSince(sessionStartDate)
            print("⏹️ Session ended (duration: \(duration)s)")

            // Save to HealthKit
            saveToHealthKit(startDate: sessionStartDate, endDate: sessionEndDate)

            // Save to LocalDataManager
            saveToLocalStorage(startDate: sessionStartDate, endDate: sessionEndDate, duration: duration)

            // Call completion handler
            completion?(duration)
        }
    }

    /// Cancel the current session without saving
    func cancelSession() {
        guard isActive else {
            print("⚠️ No active session to cancel")
            return
        }

        stopDurationTimer()

        startDate = nil
        endDate = nil
        duration = 0
        isActive = false

        print("❌ Session cancelled")
    }

    // MARK: - Duration Tracking

    /// Start a timer to update duration in real-time
    private func startDurationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
    }

    /// Stop the duration timer
    private func stopDurationTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Update the current session duration
    private func updateDuration() {
        guard isActive, let sessionStartDate = startDate else {
            return
        }

        duration = Date().timeIntervalSince(sessionStartDate)
    }

    // MARK: - HealthKit Integration

    /// Save the session to HealthKit
    /// - Parameters:
    ///   - startDate: Session start date
    ///   - endDate: Session end date
    private func saveToHealthKit(startDate: Date, endDate: Date) {
        // Check if authorized
        guard HealthKitManager.shared.isAuthorized() else {
            print("⚠️ HealthKit not authorized - requesting authorization")

            // Request authorization and then save
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    self.performHealthKitSave(startDate: startDate, endDate: endDate)
                } else {
                    print("❌ Failed to get HealthKit authorization: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            return
        }

        // Already authorized, save directly
        performHealthKitSave(startDate: startDate, endDate: endDate)
    }

    /// Perform the actual HealthKit save operation
    /// - Parameters:
    ///   - startDate: Session start date
    ///   - endDate: Session end date
    private func performHealthKitSave(startDate: Date, endDate: Date) {
        HealthKitManager.shared.saveMindfulSession(startDate: startDate, endDate: endDate) { success, error in
            if success {
                print("✅ Session saved to HealthKit")
            } else {
                print("❌ Failed to save session to HealthKit: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    // MARK: - LocalDataManager Integration

    /// Save the session to local storage
    /// - Parameters:
    ///   - startDate: Session start date
    ///   - endDate: Session end date
    ///   - duration: Session duration in seconds
    private func saveToLocalStorage(startDate: Date, endDate: Date, duration: TimeInterval) {
        let durationMinutes = Int(duration / 60)

        // Only save sessions that are at least 1 minute long
        guard durationMinutes >= 1 else {
            print("⚠️ Session too short to save (\(Int(duration))s)")
            return
        }

        LocalDataManager.shared.saveSession(durationMinutes: durationMinutes, date: endDate)
        print("✅ Session saved to local storage (\(durationMinutes) minutes)")
    }

    // MARK: - Helper Methods

    /// Get formatted duration string (MM:SS)
    /// - Returns: Formatted duration string
    func getFormattedDuration() -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Get session summary
    /// - Returns: Dictionary with session details
    func getSessionSummary() -> [String: Any] {
        return [
            "isActive": isActive,
            "startDate": startDate as Any,
            "endDate": endDate as Any,
            "duration": duration,
            "formattedDuration": getFormattedDuration()
        ]
    }
}
