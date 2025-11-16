//
//  Constants.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Application-wide constants for configuration, timing, sizing,
//  and other magic numbers. Centralizing these values improves
//  maintainability and reduces errors.
//

import Foundation
import SwiftUI
import Combine

// MARK: - App Constants

enum AppConstants {

    // MARK: - Animation Durations

    enum Animation {
        /// Standard breathing cycle duration in seconds
        static let breathingCycleDuration: Double = 4.0

        /// Button press animation duration
        static let buttonPressDuration: Double = 0.2

        /// View transition animation duration
        static let transitionDuration: Double = 0.3

        /// Celebration animation duration
        static let celebrationDuration: Double = 2.5

        /// Fade animation duration
        static let fadeDuration: Double = 0.5
    }

    // MARK: - Breathing Animation

    enum Breathing {
        /// Scale factor for inhale animation
        static let inhaleScale: CGFloat = 1.5

        /// Scale factor for exhale animation
        static let exhaleScale: CGFloat = 1.0

        /// Inner circle base size
        static let innerCircleSize: CGFloat = 120

        /// Outer circle base size
        static let outerCircleSize: CGFloat = 200

        /// Circle blur radius
        static let circleBlurRadius: CGFloat = 20

        /// Haptic feedback delay from inhale start (seconds)
        static let hapticDelay: Double = 0.5
    }

    // MARK: - Session Tracking

    enum Session {
        /// Minimum session duration to save (seconds)
        static let minimumDurationToSave: Double = 10.0

        /// Timer update interval (seconds)
        static let timerUpdateInterval: Double = 1.0
    }

    // MARK: - Tree Growth Stages

    enum TreeGrowth {
        /// Minutes required for each stage
        static let seedMinutes: Double = 0
        static let sproutMinutes: Double = 30
        static let saplingMinutes: Double = 120
        static let youngTreeMinutes: Double = 300
        static let matureTreeMinutes: Double = 600
        static let ancientTreeMinutes: Double = 1200

        /// Icon sizes for each stage
        static let seedSize: CGFloat = 50
        static let sproutSize: CGFloat = 90
        static let saplingSize: CGFloat = 140
        static let youngTreeSize: CGFloat = 190
        static let matureTreeSize: CGFloat = 240
        static let ancientTreeSize: CGFloat = 280

        /// Glow radius for each stage
        static let seedGlow: CGFloat = 60
        static let sproutGlow: CGFloat = 100
        static let saplingGlow: CGFloat = 150
        static let youngTreeGlow: CGFloat = 200
        static let matureTreeGlow: CGFloat = 260
        static let ancientTreeGlow: CGFloat = 320
    }

    // MARK: - Badge Requirements

    enum Badges {
        /// Days required for 7-day streak badge
        static let weekStreakDays = 7

        /// Days required for 30-day streak badge
        static let monthStreakDays = 30

        /// Minutes required for first hour badge
        static let firstHourMinutes = 60

        /// Minutes required for mastery badge
        static let masteryMinutes = 300

        /// Minutes required for zen master badge
        static let zenMasterMinutes = 1000
    }

    // MARK: - UI Layout

    enum Layout {
        /// Standard padding
        static let standardPadding: CGFloat = 16

        /// Large padding
        static let largePadding: CGFloat = 24

        /// Small padding
        static let smallPadding: CGFloat = 8

        /// Corner radius for cards
        static let cardCornerRadius: CGFloat = 16

        /// Corner radius for buttons
        static let buttonCornerRadius: CGFloat = 12

        /// Corner radius for small elements
        static let smallCornerRadius: CGFloat = 8

        /// Grid spacing
        static let gridSpacing: CGFloat = 16

        /// Progress bar height
        static let progressBarHeight: CGFloat = 8

        /// Icon frame size
        static let iconSize: CGFloat = 24
    }

    // MARK: - Progress Tracking

    enum Progress {
        /// Number of items to show in session history
        static let historyLimit = 30

        /// Days to consider for streak calculation
        static let streakLookbackDays = 365

        /// Percentage multiplier (for converting 0-1 to 0-100)
        static let percentageMultiplier: Double = 100
    }

    // MARK: - Haptic Feedback

    enum Haptics {
        /// Haptic intensity for inhale
        static let inhaleIntensity: Float = 1.0

        /// Haptic intensity for button press
        static let buttonIntensity: Float = 0.7

        /// Haptic intensity for celebration
        static let celebrationIntensity: Float = 1.0

        /// Haptic sharpness for button
        static let buttonSharpness: Float = 0.5
    }

    // MARK: - Theme Selection

    enum Theme {
        /// Theme preview circle outer size
        static let previewOuterSize: CGFloat = 80

        /// Theme preview circle inner size
        static let previewInnerSize: CGFloat = 60

        /// Theme card height
        static let cardHeight: CGFloat = 100

        /// Selection indicator size
        static let selectionIndicatorSize: CGFloat = 18

        /// Lock icon size
        static let lockIconSize: CGFloat = 24
    }

    // MARK: - Accessibility

    enum Accessibility {
        /// Minimum touch target size (Apple HIG recommendation)
        static let minimumTouchTarget: CGFloat = 44

        /// Announcement delay (seconds)
        static let announcementDelay: Double = 0.5
    }

    // MARK: - Time Formatting

    enum TimeFormat {
        /// Seconds per minute
        static let secondsPerMinute = 60

        /// Minutes per hour
        static let minutesPerHour = 60

        /// Hours per day
        static let hoursPerDay = 24
    }

    // MARK: - Opacity Values

    enum Opacity {
        /// Disabled state opacity
        static let disabled: Double = 0.3

        /// Secondary content opacity
        static let secondary: Double = 0.6

        /// Tertiary content opacity
        static let tertiary: Double = 0.4

        /// Full opacity
        static let full: Double = 1.0

        /// Background overlay
        static let overlay: Double = 0.8
    }

    // MARK: - Limits

    enum Limits {
        /// Maximum session duration in minutes (for safety)
        static let maxSessionMinutes = 180

        /// Maximum streak to display (prevents UI issues)
        static let maxStreakDisplay = 999

        /// Maximum badges to show
        static let maxBadgeCount = 100
    }
}
