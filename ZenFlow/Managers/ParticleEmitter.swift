//
//  ParticleEmitter.swift
//  ZenFlow
//
//  Manages particle emission and lifecycle
//

import SwiftUI
import Combine

/// Manages particle emission, updates, and lifecycle
class ParticleEmitter: ObservableObject {
    @Published private(set) var particles: [ParticleModel] = []

    // Settings
    var intensity: ParticleIntensity = .medium
    var colorTheme: ParticleColorTheme = .zen
    var emissionAngle: Double = .pi / 2 // Default: upward (90 degrees)
    var emissionSpread: Double = .pi / 3 // 60 degree spread
    var gravity: CGVector = CGVector(dx: 0, dy: -50) // Light upward movement

    // Emission control
    private var spawnAccumulator: TimeInterval = 0
    private var lastUpdateTime: Date?
    private var maxParticles: Int { intensity.maxParticles }
    private var spawnRate: Double { intensity.spawnRate }

    // Screen bounds for recycling
    var screenBounds: CGRect = .zero

    // Current breathing phase
    var currentPhase: BreathingPhase = .exhale

    // MARK: - Initialization

    init() {
        // Automatically adjust particle count based on device performance
        adjustForDevicePerformance()
    }

    /// Update all particles and spawn new ones
    func update(deltaTime: TimeInterval) {
        // Update existing particles
        for index in particles.indices {
            particles[index].update(deltaTime: deltaTime, gravity: gravity)
        }

        // Remove dead particles and particles outside screen bounds
        particles.removeAll { particle in
            !particle.isAlive || isParticleOutOfBounds(particle)
        }

        // Spawn new particles
        spawnAccumulator += deltaTime
        let spawnInterval = 1.0 / spawnRate
        while spawnAccumulator >= spawnInterval && particles.count < maxParticles {
            spawnParticle()
            spawnAccumulator -= spawnInterval
        }
    }

    /// Spawn a single particle based on current phase
    private func spawnParticle() {
        let position = getSpawnPosition()
        let velocity = getSpawnVelocity()
        let color = colorTheme.colors.randomElement() ?? .white
        let size = CGFloat.random(in: 3...8)
        let lifetime = TimeInterval.random(in: 2.0...4.0)

        let particle = ParticleModel(
            position: position,
            velocity: velocity,
            opacity: 1.0,
            size: size,
            color: color,
            lifetime: lifetime
        )

        particles.append(particle)
    }

    /// Get spawn position based on breathing phase
    private func getSpawnPosition() -> CGPoint {
        let width = screenBounds.width
        let height = screenBounds.height

        switch currentPhase {
        case .inhale:
            // Spawn from bottom, spread across width
            let x = CGFloat.random(in: width * 0.2...width * 0.8)
            let y = height * 0.9 // Near bottom
            return CGPoint(x: x, y: y)

        case .hold, .holdAfterExhale:
            // Spawn in circular pattern around center
            let centerX = width / 2
            let centerY = height / 2
            let angle = Double.random(in: 0...2 * .pi)
            let radius = CGFloat.random(in: 80...120)
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            return CGPoint(x: x, y: y)

        case .exhale:
            // Spawn from center
            let centerX = width / 2
            let centerY = height / 2
            let offset = CGFloat.random(in: -30...30)
            return CGPoint(x: centerX + offset, y: centerY + offset)
        }
    }

    /// Get spawn velocity based on breathing phase
    private func getSpawnVelocity() -> CGVector {
        switch currentPhase {
        case .inhale:
            // Particles rise upward with slight horizontal spread
            let angle = emissionAngle + Double.random(in: -emissionSpread/2...emissionSpread/2)
            let speed = Double.random(in: 50...100)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            return CGVector(dx: dx, dy: dy)

        case .hold, .holdAfterExhale:
            // Particles slowly orbit around center with minimal movement
            let angle = Double.random(in: 0...2 * .pi)
            let speed = Double.random(in: 15...30) // Much slower for hold
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            return CGVector(dx: dx, dy: dy)

        case .exhale:
            // Particles spread outward from center in all directions
            let angle = Double.random(in: 0...2 * .pi)
            let speed = Double.random(in: 40...80)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            return CGVector(dx: dx, dy: dy)
        }
    }

    /// Check if particle is outside screen bounds with margin
    private func isParticleOutOfBounds(_ particle: ParticleModel) -> Bool {
        let margin: CGFloat = 50
        return particle.position.x < -margin ||
               particle.position.x > screenBounds.width + margin ||
               particle.position.y < -margin ||
               particle.position.y > screenBounds.height + margin
    }

    /// Clear all particles
    func clearParticles() {
        particles.removeAll()
        spawnAccumulator = 0
    }

    /// Set breathing phase
    func setPhase(_ phase: BreathingPhase) {
        currentPhase = phase

        // Adjust emission parameters based on phase
        switch phase {
        case .inhale:
            emissionAngle = .pi / 2 // Upward
            emissionSpread = .pi / 4 // 45 degree spread
            gravity = CGVector(dx: 0, dy: -30) // Gentle upward drift

        case .hold, .holdAfterExhale:
            emissionAngle = 0 // Circular pattern
            emissionSpread = 2 * .pi // Full circle
            gravity = CGVector(dx: 0, dy: 0) // No gravity - particles float

        case .exhale:
            emissionAngle = 0 // Radial (handled in getSpawnVelocity)
            emissionSpread = 2 * .pi // Full circle
            gravity = CGVector(dx: 0, dy: 10) // Slight downward drift
        }
    }

    /// Adjust particle count based on device performance
    func adjustForDevicePerformance() {
            // Removed #if os(iOS) check as it is redundant in this scope
            let processInfo = ProcessInfo.processInfo
            let physicalMemory = processInfo.physicalMemory

            // Reduce particle count on devices with less than 4GB RAM
            if physicalMemory < 4_000_000_000 {
                switch intensity {
                case .high:
                    intensity = .medium
                case .medium:
                    intensity = .low
                case .low:
                    break
                }
            }
        }
}
