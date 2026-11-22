//
//  ZenSessionActivityAttributes.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Data model of the Live Activity / Dynamic Island shown while a breathing,
//  focus or silent meditation session runs.
//
//  SHARED FILE: add it to BOTH the app target and the widget extension target
//  (File inspector > Target Membership). See ZenFlowWidget/README.md.
//

import Foundation

/// What kind of session the Live Activity represents
enum ZenSessionKind: String, Codable, Hashable {
    case breathing
    case focus
    case meditation

    var iconName: String {
        switch self {
        case .breathing: return "wind"
        case .focus: return "timer"
        case .meditation: return "figure.mind.and.body"
        }
    }

    /// Deep link opened when the activity is tapped
    var deepLink: String {
        switch self {
        case .breathing, .meditation: return "zenflow://breathing"
        case .focus: return "zenflow://focus"
        }
    }
}

#if canImport(ActivityKit)
import ActivityKit

struct ZenSessionActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// When the session ends (drives the live countdown)
        var endDate: Date
        var isPaused: Bool
        /// Seconds left while paused (the countdown cannot tick then)
        var pausedRemaining: TimeInterval
    }

    var kind: ZenSessionKind
    /// Exercise or mode name, already localized by the app
    var title: String
}
#endif
