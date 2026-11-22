//
//  SessionLiveActivityManager.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Starts, updates and ends the Live Activity (lock screen + Dynamic Island)
//  for a running breathing, focus or silent meditation session.
//
//  The real implementation is compiled only when the ZENFLOW_LIVE_ACTIVITIES
//  Swift flag is set. Add it (Build Settings > Active Compilation Conditions)
//  once the widget extension with the Live Activity UI exists; before that
//  every method is a harmless no-op, so the app never shows an empty activity.
//  See ZenFlowWidget/README.md.
//

import Foundation
#if ZENFLOW_LIVE_ACTIVITIES && canImport(ActivityKit)
import ActivityKit
#endif

class SessionLiveActivityManager {

    static let shared = SessionLiveActivityManager()

    private init() {}

#if ZENFLOW_LIVE_ACTIVITIES && canImport(ActivityKit)

    private var activity: Activity<ZenSessionActivityAttributes>?

    /// Start the activity, or move an existing one to a new end date (resume)
    func start(kind: ZenSessionKind, title: String, endDate: Date) {
        let state = ZenSessionActivityAttributes.ContentState(endDate: endDate, isPaused: false, pausedRemaining: 0)

        if let activity {
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        do {
            activity = try Activity.request(
                attributes: ZenSessionActivityAttributes(kind: kind, title: title),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("⚠️ Live Activity could not start: \(error.localizedDescription)")
        }
    }

    /// Freeze the countdown at `remaining` seconds
    func pause(remaining: TimeInterval) {
        guard let activity else { return }
        let state = ZenSessionActivityAttributes.ContentState(
            endDate: Date().addingTimeInterval(remaining),
            isPaused: true,
            pausedRemaining: max(0, remaining)
        )
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    /// Continue counting down to a new end date
    func resume(endDate: Date) {
        guard let activity else { return }
        let state = ZenSessionActivityAttributes.ContentState(endDate: endDate, isPaused: false, pausedRemaining: 0)
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    /// End the activity right away
    func end() {
        guard let current = activity else { return }
        activity = nil
        Task { await current.end(nil, dismissalPolicy: .immediate) }
    }

#else

    func start(kind: ZenSessionKind, title: String, endDate: Date) {}
    func pause(remaining: TimeInterval) {}
    func resume(endDate: Date) {}
    func end() {}

#endif
}
