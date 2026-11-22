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
            return String(localized: "breathing_phase_inhale", defaultValue: "Nefes Al", comment: "Inhale")
        case .hold:
            return String(localized: "breathing_phase_hold", defaultValue: "Tut", comment: "Hold")
        case .exhale:
            return String(localized: "breathing_phase_exhale", defaultValue: "Nefes Ver", comment: "Exhale")
        case .holdAfterExhale:
            return String(localized: "breathing_phase_hold_after_exhale", defaultValue: "Tut", comment: "Hold after exhale")
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
        // Use the localization key to fetch the instruction
        // Note: We use NSLocalizedString here as instructionKey comes from data/JSON usually
        let localized = NSLocalizedString(instructionKey, comment: "")
        return localized != instructionKey ? localized : instructionKey
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
            return String(localized: "difficulty_beginner", defaultValue: "Başlangıç", comment: "Beginner")
        case .intermediate:
            return String(localized: "difficulty_intermediate", defaultValue: "Orta", comment: "Intermediate")
        case .advanced:
            return String(localized: "difficulty_advanced", defaultValue: "İleri", comment: "Advanced")
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
            return String(localized: "recommended_time_morning", defaultValue: "Sabah", comment: "Morning")
        case .evening:
            return String(localized: "recommended_time_evening", defaultValue: "Akşam", comment: "Evening")
        case .stressful:
            return String(localized: "recommended_time_stressful", defaultValue: "Stres Anı", comment: "Stressful moments")
        case .anytime:
            return String(localized: "recommended_time_anytime", defaultValue: "Her Zaman", comment: "Anytime")
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
    let isPremium: Bool
    /// Name of a user-designed exercise (nil for the built-in ones)
    let customName: String?

    /// Whether this is a user-designed exercise
    var isCustom: Bool { customName != nil }

    // Localized computed properties
    var localizedName: String {
        customName ?? getDefaultName()
    }

    var localizedDescription: String {
        if isCustom {
            return String(localized: "custom_exercise_description", defaultValue: "Kendi tasarladığın nefes ritmi.", comment: "Description of a custom breathing exercise")
        }
        return getDefaultDescription()
    }

    var localizedBenefits: [String] {
        // Custom exercises have no canned benefits; drop empty rows
        (0..<4).map { index in
            getDefaultBenefit(at: index)
        }.filter { !$0.isEmpty }
    }

    // Default values using String(localized:) for automatic extraction and fallback
    private func getDefaultName() -> String {
        switch exerciseType {
        case "box":
            return String(localized: "exercise_box_name", defaultValue: "Kutu Nefesi", comment: "Box Breathing Name")
        case "478":
            return String(localized: "exercise_478_name", defaultValue: "4-7-8 Tekniği", comment: "4-7-8 Technique Name")
        case "calming":
            return String(localized: "exercise_calming_name", defaultValue: "Sakinleştirici Nefes", comment: "Calming Breath Name")
        case "energy":
            return String(localized: "exercise_energy_name", defaultValue: "Enerji Nefesi", comment: "Energy Breath Name")
        case "deep":
            return String(localized: "exercise_deep_name", defaultValue: "Derin Gevşeme", comment: "Deep Relaxation Name")
        case "coherent":
            return String(localized: "exercise_coherent_name", defaultValue: "Tutarlı Nefes 5-5", comment: "Coherent Breathing Name")
        case "sigh":
            return String(localized: "exercise_sigh_name", defaultValue: "Fizyolojik İç Çekiş", comment: "Physiological Sigh Name")
        case "triangle":
            return String(localized: "exercise_triangle_name", defaultValue: "Üçgen Nefes", comment: "Triangle Breathing Name")
        default:
            return exerciseType
        }
    }

    private func getDefaultDescription() -> String {
        switch exerciseType {
        case "box":
            return String(localized: "exercise_box_description", defaultValue: "Dengeli ve düzenli bir nefes egzersizi. Zihinsel netlik ve sakinlik için idealdir.", comment: "Box Breathing Description")
        case "478":
            return String(localized: "exercise_478_description", defaultValue: "Uykuya dalmayı kolaylaştıran ve derin rahatlama sağlayan teknik. Dr. Andrew Weil tarafından geliştirilmiştir.", comment: "4-7-8 Technique Description")
        case "calming":
            return String(localized: "exercise_calming_description", defaultValue: "Basit ve etkili bir sakinleşme tekniği. Uzun nefes vermeler sinir sistemini sakinleştirir.", comment: "Calming Breath Description")
        case "energy":
            return String(localized: "exercise_energy_description", defaultValue: "Enerji ve canlılık kazandıran hızlı tempo nefes egzersizi. Sabah rutini için mükemmeldir.", comment: "Energy Breath Description")
        case "deep":
            return String(localized: "exercise_deep_description", defaultValue: "Yavaş ve derin nefes alıp vermelerle tam bir rahatlama hali. Meditasyon ve yoga sonrası idealdir.", comment: "Deep Relaxation Description")
        case "coherent":
            return String(localized: "exercise_coherent_description", defaultValue: "Dakikada yaklaşık 6 nefesle eşit uzunlukta nefes alıp verme. Kalp ritmini dengeler, gün boyu sakin bir odak sağlar.", comment: "Coherent Breathing Description")
        case "sigh":
            return String(localized: "exercise_sigh_description", defaultValue: "Burundan iki kısa nefes alıp ağızdan uzun nefes verme. Anlık stresi birkaç döngüde azaltmanın en hızlı yollarından biridir.", comment: "Physiological Sigh Description")
        case "triangle":
            return String(localized: "exercise_triangle_description", defaultValue: "Al, tut, ver: üç eşit adım. Kutu nefesine göre daha yumuşak, yeni başlayanlar için ideal bir ritim.", comment: "Triangle Breathing Description")
        default:
            return exerciseType
        }
    }

    private func getDefaultBenefit(at index: Int) -> String {
        // Dictionary values wrapped in String(localized:) to enable key extraction
        let benefits: [String: [String]] = [
            "box": [
                String(localized: "exercise_box_benefit_0", defaultValue: "Stresi azaltır", comment: "Box benefit 1"),
                String(localized: "exercise_box_benefit_1", defaultValue: "Odaklanmayı artırır", comment: "Box benefit 2"),
                String(localized: "exercise_box_benefit_2", defaultValue: "Zihinsel netlik sağlar", comment: "Box benefit 3"),
                String(localized: "exercise_box_benefit_3", defaultValue: "Anksiyeteyi azaltır", comment: "Box benefit 4")
            ],
            "478": [
                String(localized: "exercise_478_benefit_0", defaultValue: "Uykuya dalmayı kolaylaştırır", comment: "478 benefit 1"),
                String(localized: "exercise_478_benefit_1", defaultValue: "Anksiyeteyi azaltır", comment: "478 benefit 2"),
                String(localized: "exercise_478_benefit_2", defaultValue: "Kan basıncını düşürür", comment: "478 benefit 3"),
                String(localized: "exercise_478_benefit_3", defaultValue: "Derin rahatlama sağlar", comment: "478 benefit 4")
            ],
            "calming": [
                String(localized: "exercise_calming_benefit_0", defaultValue: "Hızlı sakinleşme sağlar", comment: "Calming benefit 1"),
                String(localized: "exercise_calming_benefit_1", defaultValue: "Stresi azaltır", comment: "Calming benefit 2"),
                String(localized: "exercise_calming_benefit_2", defaultValue: "Kalp atış hızını düzenler", comment: "Calming benefit 3"),
                String(localized: "exercise_calming_benefit_3", defaultValue: "Kolayca uygulanabilir", comment: "Calming benefit 4")
            ],
            "energy": [
                String(localized: "exercise_energy_benefit_0", defaultValue: "Enerji seviyesini yükseltir", comment: "Energy benefit 1"),
                String(localized: "exercise_energy_benefit_1", defaultValue: "Zihinsel uyanıklığı artırır", comment: "Energy benefit 2"),
                String(localized: "exercise_energy_benefit_2", defaultValue: "Kan dolaşımını hızlandırır", comment: "Energy benefit 3"),
                String(localized: "exercise_energy_benefit_3", defaultValue: "Güne dinç başlamanızı sağlar", comment: "Energy benefit 4")
            ],
            "coherent": [
                String(localized: "exercise_coherent_benefit_0", defaultValue: "Kalp ritmini dengeler", comment: "Coherent benefit 1"),
                String(localized: "exercise_coherent_benefit_1", defaultValue: "Gün boyu sakin odak sağlar", comment: "Coherent benefit 2"),
                String(localized: "exercise_coherent_benefit_2", defaultValue: "Stres tepkisini yumuşatır", comment: "Coherent benefit 3"),
                String(localized: "exercise_coherent_benefit_3", defaultValue: "Uzun seanslar için uygundur", comment: "Coherent benefit 4")
            ],
            "sigh": [
                String(localized: "exercise_sigh_benefit_0", defaultValue: "Anlık stresi hızla düşürür", comment: "Sigh benefit 1"),
                String(localized: "exercise_sigh_benefit_1", defaultValue: "Sadece 1-3 dakikada etkili olur", comment: "Sigh benefit 2"),
                String(localized: "exercise_sigh_benefit_2", defaultValue: "Gergin omuz ve göğsü gevşetir", comment: "Sigh benefit 3"),
                String(localized: "exercise_sigh_benefit_3", defaultValue: "Her yerde sessizce uygulanabilir", comment: "Sigh benefit 4")
            ],
            "triangle": [
                String(localized: "exercise_triangle_benefit_0", defaultValue: "Yeni başlayanlar için kolaydır", comment: "Triangle benefit 1"),
                String(localized: "exercise_triangle_benefit_1", defaultValue: "Zihni sakinleştirir", comment: "Triangle benefit 2"),
                String(localized: "exercise_triangle_benefit_2", defaultValue: "Nefes kontrolünü geliştirir", comment: "Triangle benefit 3"),
                String(localized: "exercise_triangle_benefit_3", defaultValue: "Kısa molalar için uygundur", comment: "Triangle benefit 4")
            ],
            "deep": [
                String(localized: "exercise_deep_benefit_0", defaultValue: "Derin rahatlama sağlar", comment: "Deep benefit 1"),
                String(localized: "exercise_deep_benefit_1", defaultValue: "Meditasyonu derinleştirir", comment: "Deep benefit 2"),
                String(localized: "exercise_deep_benefit_2", defaultValue: "Kalp hızını yavaşlatır", comment: "Deep benefit 3"),
                String(localized: "exercise_deep_benefit_3", defaultValue: "İç huzur verir", comment: "Deep benefit 4")
            ]
        ]
        
        guard let typeBenefits = benefits[exerciseType],
              index >= 0 && index < typeBenefits.count else {
            return ""
        }
        return typeBenefits[index]
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
        recommendedTime: RecommendedTime,
        isPremium: Bool = false,
        customName: String? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.customName = customName
        self.exerciseType = exerciseType
        self.phases = phases
        self.totalCycleDuration = phases.reduce(0) { $0 + $1.duration }
        self.recommendedDuration = recommendedDuration
        self.iconName = iconName
        self.difficulty = difficulty
        self.recommendedTime = recommendedTime
        self.isPremium = isPremium
    }
}

// MARK: - Breathing Exercise Manager

/// Singleton manager for breathing exercises
class BreathingExerciseManager: ObservableObject {
    static let shared = BreathingExerciseManager()

    // UserDefaults keys
    private let selectedExerciseKey = "selectedBreathingExercise"
    private let favoriteExercisesKey = "favoriteBreathingExercises"

    private let customPatternsKey = "customBreathingPatterns"

    @Published var selectedExercise: BreathingExercise
    @Published var favoriteExerciseIDs: Set<UUID> = []

    /// Patterns the user designed (premium)
    @Published private(set) var customPatterns: [CustomBreathingPattern] = []
    /// Playable exercises for `customPatterns`. Rebuilt only when patterns change,
    /// so the exercise ids stay stable between reads.
    @Published private(set) var customExercises: [BreathingExercise] = []

    /// All available breathing exercises (static for performance - created once and shared)
    static let allExercises: [BreathingExercise] = [
        // 1. Box Breathing - FREE
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
            recommendedTime: .anytime,
            isPremium: false // FREE
        ),

        // 2. 4-7-8 Technique - PREMIUM
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
            recommendedTime: .evening,
            isPremium: true // PREMIUM
        ),

        // 3. Calming Breath - PREMIUM
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
            recommendedTime: .stressful,
            isPremium: true // PREMIUM
        ),

        // 4. Energy Breath - PREMIUM
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
            recommendedTime: .morning,
            isPremium: true // PREMIUM
        ),

        // 5. Deep Relaxation - PREMIUM
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
            recommendedTime: .evening,
            isPremium: true // PREMIUM
        ),

        // 6. Coherent Breathing 5-5 - PREMIUM
        BreathingExercise(
            exerciseType: "coherent",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 5,
                    instructionKey: "exercise_coherent_phase_0_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 5,
                    instructionKey: "exercise_coherent_phase_1_instruction"
                )
            ],
            recommendedDuration: 10,
            iconName: "waveform.path",
            difficulty: .beginner,
            recommendedTime: .anytime,
            isPremium: true // PREMIUM
        ),

        // 7. Physiological Sigh (double inhale, long exhale) - PREMIUM
        BreathingExercise(
            exerciseType: "sigh",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 2,
                    instructionKey: "exercise_sigh_phase_0_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 1,
                    instructionKey: "exercise_sigh_phase_1_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 6,
                    instructionKey: "exercise_sigh_phase_2_instruction"
                )
            ],
            recommendedDuration: 3,
            iconName: "lungs.fill",
            difficulty: .beginner,
            recommendedTime: .stressful,
            isPremium: true // PREMIUM
        ),

        // 8. Triangle Breathing 4-4-4 - PREMIUM
        BreathingExercise(
            exerciseType: "triangle",
            phases: [
                BreathingPhaseConfig(
                    phase: .inhale,
                    duration: 4,
                    instructionKey: "exercise_triangle_phase_0_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .hold,
                    duration: 4,
                    instructionKey: "exercise_triangle_phase_1_instruction"
                ),
                BreathingPhaseConfig(
                    phase: .exhale,
                    duration: 4,
                    instructionKey: "exercise_triangle_phase_2_instruction"
                )
            ],
            recommendedDuration: 5,
            iconName: "triangle.fill",
            difficulty: .beginner,
            recommendedTime: .anytime,
            isPremium: true // PREMIUM
        )
    ]

    private init() {
        // Exercise `id`s of the built-in exercises are generated at launch, so
        // selection and favorites are persisted by the stable `exerciseType`.

        // Custom exercises first, so they can be restored as selection/favorites
        var patterns: [CustomBreathingPattern] = []
        if let data = UserDefaults.standard.data(forKey: customPatternsKey),
           let decoded = try? JSONDecoder().decode([CustomBreathingPattern].self, from: data) {
            patterns = decoded.map { $0.sanitized() }
        }
        let customs = patterns.map { $0.makeExercise() }
        self.customPatterns = patterns
        self.customExercises = customs
        let everything = Self.allExercises + customs

        // Load selected exercise from UserDefaults
        if let savedType = UserDefaults.standard.string(forKey: selectedExerciseKey),
           let exercise = everything.first(where: { $0.exerciseType == savedType }) {
            self.selectedExercise = exercise
        } else {
            // Default to Box Breathing
            self.selectedExercise = Self.allExercises[0]
        }

        // Load favorite exercises from UserDefaults
        if let savedFavorites = UserDefaults.standard.array(forKey: favoriteExercisesKey) as? [String] {
            let favoriteTypes = Set(savedFavorites)
            self.favoriteExerciseIDs = Set(
                everything
                    .filter { favoriteTypes.contains($0.exerciseType) }
                    .map { $0.id }
            )
        }
    }

    /// Built-in exercises followed by the user's own
    var allExercises: [BreathingExercise] {
        Self.allExercises + customExercises
    }

    // MARK: - Custom exercises

    var canAddCustomPattern: Bool {
        customPatterns.count < CustomBreathingPattern.maxPatterns
    }

    /// Add a new pattern (or replace one with the same id). Returns false when
    /// the maximum number of patterns is reached.
    @discardableResult
    func saveCustomPattern(_ pattern: CustomBreathingPattern) -> Bool {
        let clean = pattern.sanitized()

        if let index = customPatterns.firstIndex(where: { $0.id == clean.id }) {
            customPatterns[index] = clean
        } else {
            guard canAddCustomPattern else { return false }
            customPatterns.append(clean)
        }
        customPatternsChanged()

        // Keep the selection pointing at the edited exercise
        if selectedExercise.id == clean.id, let updated = customExercises.first(where: { $0.id == clean.id }) {
            selectedExercise = updated
        }
        return true
    }

    func deleteCustomPattern(id: UUID) {
        customPatterns.removeAll { $0.id == id }
        favoriteExerciseIDs.remove(id)
        saveFavorites()
        customPatternsChanged()

        // Falling back to the default if the selected exercise was deleted
        if selectedExercise.id == id {
            selectExercise(Self.allExercises[0])
        }
    }

    /// Replace all patterns (used when restoring a backup)
    func replaceCustomPatterns(_ patterns: [CustomBreathingPattern]) {
        customPatterns = Array(patterns.map { $0.sanitized() }.prefix(CustomBreathingPattern.maxPatterns))
        customPatternsChanged()
        if selectedExercise.isCustom, !customExercises.contains(where: { $0.id == selectedExercise.id }) {
            selectExercise(Self.allExercises[0])
        }
    }

    private func customPatternsChanged() {
        customExercises = customPatterns.map { $0.makeExercise() }
        if let data = try? JSONEncoder().encode(customPatterns) {
            UserDefaults.standard.set(data, forKey: customPatternsKey)
        }
    }

    /// Select an exercise
    func selectExercise(_ exercise: BreathingExercise) {
        selectedExercise = exercise
        UserDefaults.standard.set(exercise.exerciseType, forKey: selectedExerciseKey)
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
        let favoriteTypes = allExercises
            .filter { favoriteExerciseIDs.contains($0.id) }
            .map { $0.exerciseType }
        UserDefaults.standard.set(favoriteTypes, forKey: favoriteExercisesKey)
    }

    /// Select exercise by type identifier from deep link
    /// - Parameter type: Exercise type identifier (e.g., "box", "478", "calming")
    func selectExerciseByType(_ type: String) {
        if let exercise = allExercises.first(where: { $0.exerciseType.lowercased() == type.lowercased() }) {
            selectExercise(exercise)
            print("✅ Selected exercise via deep link: \(exercise.name)")
        } else {
            print("⚠️ Unknown exercise type: \(type), keeping current selection")
        }
    }
}
