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
            return "Nefes Al"
        case .hold:
            return "Tut"
        case .exhale:
            return "Nefes Ver"
        case .holdAfterExhale:
            return "Tut"
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
    let instruction: String

    init(phase: BreathingPhaseType, duration: TimeInterval, instruction: String) {
        self.id = UUID()
        self.phase = phase
        self.duration = duration
        self.instruction = instruction
    }
}

// MARK: - Exercise Difficulty

/// Difficulty level for breathing exercises
enum ExerciseDifficulty: String, Codable {
    case beginner = "Başlangıç"
    case intermediate = "Orta"
    case advanced = "İleri"

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
    case morning = "Sabah"
    case evening = "Akşam"
    case stressful = "Stres Anı"
    case anytime = "Her Zaman"

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
    let name: String
    let description: String
    let phases: [BreathingPhaseConfig]
    let totalCycleDuration: TimeInterval
    let recommendedDuration: Int // in minutes
    let iconName: String
    let difficulty: ExerciseDifficulty
    let recommendedTime: RecommendedTime
    let benefits: [String]

    init(
        name: String,
        description: String,
        phases: [BreathingPhaseConfig],
        recommendedDuration: Int = 5,
        iconName: String,
        difficulty: ExerciseDifficulty,
        recommendedTime: RecommendedTime,
        benefits: [String]
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.phases = phases
        self.totalCycleDuration = phases.reduce(0) { $0 + $1.duration }
        self.recommendedDuration = recommendedDuration
        self.iconName = iconName
        self.difficulty = difficulty
        self.recommendedTime = recommendedTime
        self.benefits = benefits
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
        // 1. Box Breathing (Kutu Nefesi)
        BreathingExercise(
            name: "Kutu Nefesi",
            description: "Dengeli ve düzenli bir nefes egzersizi. Zihinsel netlik ve sakinlik için idealdir.",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 4,
                    instruction: "Dört sayarak burnunuzdan yavaşça nefes alın"
                ),
                BreathingPhaseConfig(
                    phase: .hold,
                    duration: 4,
                    instruction: "Dört sayarak nefesinizi tutun"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 4,
                    instruction: "Dört sayarak ağzınızdan yavaşça nefes verin"
                ),
                BreathingPhaseConfig(
                    phase: .holdAfterExhale,
                    duration: 4,
                    instruction: "Dört sayarak nefesinizi tutun"
                )
            ],
            recommendedDuration: 5,
            iconName: "square.fill",
            difficulty: .beginner,
            recommendedTime: .anytime,
            benefits: [
                "Stresi azaltır",
                "Odaklanmayı artırır",
                "Zihinsel netlik sağlar",
                "Anksiyeteyi azaltır"
            ]
        ),

        // 2. 4-7-8 Tekniği
        BreathingExercise(
            name: "4-7-8 Tekniği",
            description: "Uykuya dalmayı kolaylaştıran ve derin rahatlama sağlayan teknik. Dr. Andrew Weil tarafından geliştirilmiştir.",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 4,
                    instruction: "Burnunuzdan dört sayarak sessizce nefes alın"
                ),
                BreathingPhaseConfig(
                    phase: .hold,
                    duration: 7,
                    instruction: "Yedi sayarak nefesinizi tutun"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 8,
                    instruction: "Ağzınızdan sekiz sayarak sesli bir şekilde nefes verin"
                )
            ],
            recommendedDuration: 5,
            iconName: "bed.double.fill",
            difficulty: .intermediate,
            recommendedTime: .evening,
            benefits: [
                "Uykuya dalmayı kolaylaştırır",
                "Anksiyeteyi azaltır",
                "Kan basıncını düşürür",
                "Derin rahatlama sağlar"
            ]
        ),

        // 3. Sakinleştirici Nefes
        BreathingExercise(
            name: "Sakinleştirici Nefes",
            description: "Basit ve etkili bir sakinleşme tekniği. Uzun nefes vermeler sinir sistemini sakinleştirir.",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 4,
                    instruction: "Burnunuzdan dört sayarak nefes alın"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 6,
                    instruction: "Ağzınızdan altı sayarak yavaşça nefes verin"
                )
            ],
            recommendedDuration: 5,
            iconName: "leaf.fill",
            difficulty: .beginner,
            recommendedTime: .stressful,
            benefits: [
                "Hızlı sakinleşme sağlar",
                "Stresi azaltır",
                "Kalp atış hızını düzenler",
                "Kolayca uygulanabilir"
            ]
        ),

        // 4. Enerji Nefesi
        BreathingExercise(
            name: "Enerji Nefesi",
            description: "Enerji ve canlılık kazandıran hızlı tempo nefes egzersizi. Sabah rutini için mükemmeldir.",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 2,
                    instruction: "Burnunuzdan hızlıca iki sayarak nefes alın"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 2,
                    instruction: "Ağzınızdan hızlıca iki sayarak nefes verin"
                )
            ],
            recommendedDuration: 3,
            iconName: "bolt.fill",
            difficulty: .intermediate,
            recommendedTime: .morning,
            benefits: [
                "Enerji seviyesini yükseltir",
                "Zihinsel uyanıklığı artırır",
                "Kan dolaşımını hızlandırır",
                "Güne dinç başlamanızı sağlar"
            ]
        ),

        // 5. Derin Gevşeme
        BreathingExercise(
            name: "Derin Gevşeme",
            description: "Yavaş ve derin nefes alıp vermelerle tam bir rahatlama hali. Meditasyon ve yoga sonrası idealdir.",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 6,
                    instruction: "Burnunuzdan çok yavaş ve derin bir şekilde altı sayarak nefes alın"
                ),
                BreathingPhaseConfig(
                    phase: .hold,
                    duration: 2,
                    instruction: "İki sayarak nefesinizi nazikçe tutun"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 8,
                    instruction: "Ağzınızdan çok yavaş sekiz sayarak nefesinizi tamamen boşaltın"
                )
            ],
            recommendedDuration: 10,
            iconName: "wind",
            difficulty: .advanced,
            recommendedTime: .evening,
            benefits: [
                "Derin rahatlama sağlar",
                "Meditasyonu derinleştirir",
                "Kalp hızını yavaşlatır",
                "İç huzur verir"
            ]
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
}
