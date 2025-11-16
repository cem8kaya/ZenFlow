//
//  ParticleModel.swift
//  ZenFlow
//
//  Particle system for breathing meditation effects
//

import SwiftUI

/// Breathing phases for particle emission
enum BreathingPhase {
    case inhale
    case exhale
}

/// Represents a single particle in the particle system
struct ParticleModel: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var opacity: Double
    var size: CGFloat
    var color: Color
    var lifetime: TimeInterval
    var age: TimeInterval = 0

    /// Initial lifetime when particle is spawned
    let initialLifetime: TimeInterval

    init(position: CGPoint, velocity: CGVector, opacity: Double = 1.0, size: CGFloat, color: Color, lifetime: TimeInterval) {
        self.position = position
        self.velocity = velocity
        self.opacity = opacity
        self.size = size
        self.color = color
        self.lifetime = lifetime
        self.initialLifetime = lifetime
    }

    /// Check if particle is still alive
    var isAlive: Bool {
        return age < lifetime
    }

    /// Get normalized age (0.0 to 1.0)
    var normalizedAge: Double {
        return min(age / lifetime, 1.0)
    }

    /// Update particle state based on delta time
    mutating func update(deltaTime: TimeInterval, gravity: CGVector = CGVector(dx: 0, dy: -50)) {
        // Update age
        age += deltaTime

        // Apply gravity to velocity
        velocity.dx += gravity.dx * deltaTime
        velocity.dy += gravity.dy * deltaTime

        // Update position based on velocity
        position.x += velocity.dx * deltaTime
        position.y += velocity.dy * deltaTime

        // Fade out over lifetime
        opacity = 1.0 - normalizedAge
    }
}

/// Particle intensity levels
enum ParticleIntensity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    /// Number of particles spawned per second
    var spawnRate: Double {
        switch self {
        case .low: return 10
        case .medium: return 20
        case .high: return 30
        }
    }

    /// Maximum number of particles allowed
    var maxParticles: Int {
        switch self {
        case .low: return 100
        case .medium: return 150
        case .high: return 200
        }
    }

    var displayName: String {
        switch self {
        case .low: return "Düşük"
        case .medium: return "Orta"
        case .high: return "Yüksek"
        }
    }
}

/// Color themes for particles
enum ParticleColorTheme: String, CaseIterable {
    case zen = "zen"
    case golden = "golden"
    case ocean = "ocean"
    case sunset = "sunset"

    /// Get color palette for the theme
    var colors: [Color] {
        switch self {
        case .zen:
            return [
                Color(red: 0.45, green: 0.35, blue: 0.65), // softPurple
                Color(red: 0.50, green: 0.35, blue: 0.85), // serenePurple
                Color(red: 0.35, green: 0.45, blue: 0.85)  // calmBlue
            ]
        case .golden:
            return [
                Color(red: 1.0, green: 0.84, blue: 0.0),   // gold
                Color(red: 1.0, green: 0.65, blue: 0.0),   // orange
                Color(red: 1.0, green: 0.92, blue: 0.6)    // lightGold
            ]
        case .ocean:
            return [
                Color(red: 0.0, green: 0.5, blue: 0.8),    // oceanBlue
                Color(red: 0.2, green: 0.7, blue: 0.9),    // skyBlue
                Color(red: 0.4, green: 0.8, blue: 0.85)    // aqua
            ]
        case .sunset:
            return [
                Color(red: 1.0, green: 0.4, blue: 0.5),    // coral
                Color(red: 1.0, green: 0.5, blue: 0.3),    // peach
                Color(red: 0.9, green: 0.3, blue: 0.6)     // pink
            ]
        }
    }

    var displayName: String {
        switch self {
        case .zen: return "Zen"
        case .golden: return "Altın"
        case .ocean: return "Okyanus"
        case .sunset: return "Gün Batımı"
        }
    }
}
