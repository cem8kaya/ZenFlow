//
//  BreathingExercise.swift
//  ZenFlow
//
//  Created by Claude AI on 22.11.2025.
//
//  Defines different breathing exercise types with their phases and configurations.
//  Supports various breathing techniques from beginner to advanced levels.
//

import SwiftUI
import Combine

// MARK: - Breathing Phase Type

/// Breathing phase types
enum BreathingPhaseType: String, Codable {
    case inhale = "inhale"
    case hold = "hold"
    case exhale = "exhale"
    case holdAfterExhale = "holdAfterExhale"

    /// Display text for the phase
    var displayText: String {
        switch self {
        case .inhale:
            return String(localized: "breathing_phase_inhale", comment: "Inhale")
        case .hold:
            return String(localized: "breathing_phase_hold", comment: "Hold")
        case .exhale:
            return String(localized: "breathing_phase_exhale", comment: "Exhale")
        case .holdAfterExhale:
            return String(localized: "breathing_phase_hold_after_exhale", comment: "Hold after exhale")
        }
    }

    /// Scale factor for animations
    var scale: CGFloat {
        switch self {
        case .inhale:
            return AppConstants.Breathing.inhaleScale
        case .hold:
            return AppConstants.Breathing.inhaleScale // Keep expanded
        case .exhale:
            return AppConstants.Breathing.exhaleScale
        case .holdAfterExhale:
            return AppConstants.Breathing.exhaleScale // Keep contracted
        }
    }
}

// MARK: - Breathing Phase Configuration

/// Configuration for a single phase in a breathing exercise
struct BreathingPhaseConfig: Identifiable, Codable {
    let id: UUID
    let phase: BreathingPhaseType
    let duration: TimeInterval // in seconds
    let instructionKey: String // Localization key for instruction

    var instruction: String {
            // DÜZELTME 1: LocalizedStringKey yerine NSLocalizedString kullanıldı
            NSLocalizedString(instructionKey, comment: "Breathing phase instruction")
        }

    init(phase: BreathingPhaseType, duration: TimeInterval, instructionKey: String) {
        self.id = UUID()
        self.phase = phase
        self.duration = duration
        self.instructionKey = instructionKey
    }
}

// MARK: - Exercise Difficulty

/// Difficulty level for breathing exercises
enum ExerciseDifficulty: String, Codable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner:
            return String(localized: "difficulty_beginner", comment: "Beginner")
        case .intermediate:
            return String(localized: "difficulty_intermediate", comment: "Intermediate")
        case .advanced:
            return String(localized: "difficulty_advanced", comment: "Advanced")
        }
    }

    var color: Color {
        switch self {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        }
    }
}

// MARK: - Recommended Time

/// Recommended time of day for an exercise
enum RecommendedTime: String, Codable {
    case morning
    case evening
    case stressful
    case anytime

    var displayName: String {
        switch self {
        case .morning:
            return String(localized: "recommended_time_morning", comment: "Morning")
        case .evening:
            return String(localized: "recommended_time_evening", comment: "Evening")
        case .stressful:
            return String(localized: "recommended_time_stressful", comment: "Stressful moments")
        case .anytime:
            return String(localized: "recommended_time_anytime", comment: "Anytime")
        }
    }

    var icon: String {
        switch self {
        case .morning:
            return "sunrise.fill"
        case .evening:
            return "moon.stars.fill"
        case .stressful:
            return "heart.circle.fill"
        case .anytime:
            return "clock.fill"
        }
    }
}

// MARK: - Breathing Exercise

/// A complete breathing exercise with all its phases and metadata
struct BreathingExercise: Identifiable, Codable {
    let id: UUID
    let exerciseType: String // Identifier for localization (e.g., "box", "478", etc.)
    let phases: [BreathingPhaseConfig]
    let totalCycleDuration: TimeInterval
    let recommendedDuration: Int // in minutes
    let iconName: String
    let difficulty: ExerciseDifficulty
    let recommendedTime: RecommendedTime

    // Localized computed properties
    var localizedName: String {
            // DÜZELTME 2: Dinamik anahtarlar için NSLocalizedString kullanıldı
            NSLocalizedString("exercise_\(exerciseType)_name", comment: "Exercise name")
        }
        
    var localizedDescription: String {
        // DÜZELTME 3: Dinamik anahtarlar için NSLocalizedString kullanıldı
        NSLocalizedString("exercise_\(exerciseType)_description", comment: "Exercise description")
    }
    
    var localizedBenefits: [String] {
        (0..<4).map { index in
            // DÜZELTME 4: Dinamik anahtarlar için NSLocalizedString kullanıldı
            NSLocalizedString("exercise_\(exerciseType)_benefit_\(index)", comment: "Exercise benefit")
        }
    }

    // Legacy compatibility
    var name: String { localizedName }
    var description: String { localizedDescription }
    var benefits: [String] { localizedBenefits }

    init(
        exerciseType: String,
        phases: [BreathingPhaseConfig],
        recommendedDuration: Int = 5,
        iconName: String,
        difficulty: ExerciseDifficulty,
        recommendedTime: RecommendedTime
    ) {
        self.id = UUID()
        self.exerciseType = exerciseType
        self.phases = phases
        self.totalCycleDuration = phases.reduce(0) { $0 + $1.duration }
        self.recommendedDuration = recommendedDuration
        self.iconName = iconName
        self.difficulty = difficulty
        self.recommendedTime = recommendedTime
    }
}

// MARK: - Breathing Exercise Manager

/// Singleton manager for breathing exercises
class BreathingExerciseManager: ObservableObject {
    static let shared = BreathingExerciseManager()

    // UserDefaults keys
    private let selectedExerciseKey = "selectedBreathingExercise"
    private let favoriteExercisesKey = "favoriteBreathingExercises"

    @Published var selectedExercise: BreathingExercise
    @Published var favoriteExerciseIDs: Set<UUID> = []

    /// All available breathing exercises
    let allExercises: [BreathingExercise] = [
        // 1. Box Breathing
        BreathingExercise(
            exerciseType: "box",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 4,
                    instructionKey: "exercise_box_phase_0_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .hold,
                    duration: 4,
                    instructionKey: "exercise_box_phase_1_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 4,
                    instructionKey: "exercise_box_phase_2_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .holdAfterExhale,
                    duration: 4,
                    instructionKey: "exercise_box_phase_3_instruction"
                )
            ],
            recommendedDuration: 5,
            iconName: "square.fill",
            difficulty: .beginner,
            recommendedTime: .anytime
        ),

        // 2. 4-7-8 Technique
        BreathingExercise(
            exerciseType: "478",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 4,
                    instructionKey: "exercise_478_phase_0_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .hold,
                    duration: 7,
                    instructionKey: "exercise_478_phase_1_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 8,
                    instructionKey: "exercise_478_phase_2_instruction"
                )
            ],
            recommendedDuration: 5,
            iconName: "bed.double.fill",
            difficulty: .intermediate,
            recommendedTime: .evening
        ),

        // 3. Calming Breath
        BreathingExercise(
            exerciseType: "calming",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 4,
                    instructionKey: "exercise_calming_phase_0_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 6,
                    instructionKey: "exercise_calming_phase_1_instruction"
                )
            ],
            recommendedDuration: 5,
            iconName: "leaf.fill",
            difficulty: .beginner,
            recommendedTime: .stressful
        ),

        // 4. Energy Breath
        BreathingExercise(
            exerciseType: "energy",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 2,
                    instructionKey: "exercise_energy_phase_0_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 2,
                    instructionKey: "exercise_energy_phase_1_instruction"
                )
            ],
            recommendedDuration: 3,
            iconName: "bolt.fill",
            difficulty: .intermediate,
            recommendedTime: .morning
        ),

        // 5. Deep Relaxation
        BreathingExercise(
            exerciseType: "deep",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 6,
                    instructionKey: "exercise_deep_phase_0_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .hold,
                    duration: 2,
                    instructionKey: "exercise_deep_phase_1_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 8,
                    instructionKey: "exercise_deep_phase_2_instruction"
                )
            ],
            recommendedDuration: 10,
            iconName: "wind",
            difficulty: .advanced,
            recommendedTime: .evening
        )
    ]

    private init() {
        // Load selected exercise from UserDefaults
        if let savedExerciseID = UserDefaults.standard.string(forKey: selectedExerciseKey),
           let uuid = UUID(uuidString: savedExerciseID),
           let exercise = allExercises.first(where: { $0.id == uuid }) {
            self.selectedExercise = exercise
        } else {
            // Default to Box Breathing
            self.selectedExercise = allExercises[0]
        }

        // Load favorite exercises from UserDefaults
        if let savedFavorites = UserDefaults.standard.array(forKey: favoriteExercisesKey) as? [String] {
            self.favoriteExerciseIDs = Set(savedFavorites.compactMap { UUID(uuidString: $0) })
        }
    }

    /// Select an exercise
    func selectExercise(_ exercise: BreathingExercise) {
        selectedExercise = exercise
        UserDefaults.standard.set(exercise.id.uuidString, forKey: selectedExerciseKey)
    }

    /// Toggle favorite status for an exercise
    func toggleFavorite(_ exercise: BreathingExercise) {
        if favoriteExerciseIDs.contains(exercise.id) {
            favoriteExerciseIDs.remove(exercise.id)
        } else {
            favoriteExerciseIDs.insert(exercise.id)
        }
        saveFavorites()
    }

    /// Check if an exercise is favorited
    func isFavorite(_ exercise: BreathingExercise) -> Bool {
        return favoriteExerciseIDs.contains(exercise.id)
    }

    /// Get favorite exercises
    var favoriteExercises: [BreathingExercise] {
        return allExercises.filter { favoriteExerciseIDs.contains($0.id) }
    }

    /// Save favorites to UserDefaults
    private func saveFavorites() {
        let favoriteStrings = favoriteExerciseIDs.map { $0.uuidString }
        UserDefaults.standard.set(favoriteStrings, forKey: favoriteExercisesKey)
    }

    /// Select exercise by type identifier from deep link
    /// - Parameter type: Exercise type identifier (e.g., "box", "478", "calming")
    func selectExerciseByType(_ type: String) {
        let typeMap: [String: Int] = [
            "box": 0,           // Kutu Nefesi (Box Breathing)
            "478": 1,           // 4-7-8 Tekniği
            "calming": 2,       // Sakinleştirici Nefes
            "energy": 3,        // Enerji Nefesi
            "deep": 4           // Derin Gevşeme
        ]

        if let index = typeMap[type.lowercased()], index < allExercises.count {
            selectExercise(allExercises[index])
            print("✅ Selected exercise via deep link: \(allExercises[index].name)")
        } else {
            print("⚠️ Unknown exercise type: \(type), keeping current selection")
        }
    }
}
