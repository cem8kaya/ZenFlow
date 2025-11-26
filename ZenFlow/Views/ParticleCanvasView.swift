//
//  ParticleCanvasView.swift
//  ZenFlow
//
//  Canvas-based particle renderer with 60 FPS update loop
//

import SwiftUI

/// High-performance particle renderer using Canvas API
struct ParticleCanvasView: View {
    @StateObject private var emitter = ParticleEmitter()
    @State private var lastUpdate = Date()

    let isAnimating: Bool
    let currentPhase: AnimationPhase
    let intensity: ParticleIntensity
    let colorTheme: ParticleColorTheme

    init(
        isAnimating: Bool,
        currentPhase: AnimationPhase,
        intensity: ParticleIntensity = .medium,
        colorTheme: ParticleColorTheme = .zen
    ) {
        self.isAnimating = isAnimating
        self.currentPhase = currentPhase
        self.intensity = intensity
        self.colorTheme = colorTheme
    }

    /// Convert AnimationPhase to BreathingPhase
    private var breathingPhase: BreathingPhase {
        switch currentPhase {
        case .inhale:
            return .inhale
        case .hold:
            return .hold
        case .exhale:
            return .exhale
        case .holdAfterExhale:
            return .holdAfterExhale
        }
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0/60.0, paused: !isAnimating)) { timeline in
                Canvas { context, size in
                    // Update emitter screen bounds
                    if emitter.screenBounds != CGRect(origin: .zero, size: size) {
                        emitter.screenBounds = CGRect(origin: .zero, size: size)
                    }

                    // Draw all particles
                    for particle in emitter.particles {
                        drawParticle(particle, in: context, size: size)
                    }
                }
                .onChange(of: timeline.date) { _, newDate in
                    // Update particles with delta time
                    let deltaTime = newDate.timeIntervalSince(lastUpdate)
                    lastUpdate = newDate

                    if isAnimating {
                        emitter.update(deltaTime: deltaTime)
                    }
                }
            }
            .onAppear {
                // Initialize emitter settings
                emitter.intensity = intensity
                emitter.colorTheme = colorTheme
                emitter.setPhase(breathingPhase)
                emitter.adjustForDevicePerformance()
                lastUpdate = Date()
            }
            .onChange(of: currentPhase) { _, _ in
                emitter.setPhase(breathingPhase)
            }
            .onChange(of: intensity) { _, newIntensity in
                emitter.intensity = newIntensity
            }
            .onChange(of: colorTheme) { _, newTheme in
                emitter.colorTheme = newTheme
            }
            .onChange(of: isAnimating) { _, animating in
                if !animating {
                    emitter.clearParticles()
                }
            }
        }
    }

    /// Draw a single particle on the canvas
    private func drawParticle(_ particle: ParticleModel, in context: GraphicsContext, size: CGSize) {
        // Create circle path
        let circle = Circle()
            .path(in: CGRect(
                x: particle.position.x - particle.size / 2,
                y: particle.position.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            ))

        // Apply opacity based on particle lifetime
        var particleContext = context
        particleContext.opacity = particle.opacity

        // Draw particle with blur for glow effect
        particleContext.fill(circle, with: .color(particle.color))

        // Add subtle glow effect
        if particle.size > 4 {
            var glowContext = context
            glowContext.opacity = particle.opacity * 0.3
            glowContext.addFilter(.blur(radius: 2))
            glowContext.fill(circle, with: .color(particle.color))
        }
    }
}

/// Preview version with controls
struct ParticleCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        ParticlePreviewContainer()
    }
}

/// Container for preview with state management
private struct ParticlePreviewContainer: View {
    @State private var isAnimating = true
    @State private var currentPhase: AnimationPhase = .inhale
    @State private var intensity: ParticleIntensity = .medium
    @State private var colorTheme: ParticleColorTheme = .zen

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Particle canvas
            ParticleCanvasView(
                isAnimating: isAnimating,
                currentPhase: currentPhase,
                intensity: intensity,
                colorTheme: colorTheme
            )

            // Controls
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    // Phase toggle
                    Button(action: {
                        currentPhase = currentPhase == .inhale ? .exhale : .inhale
                    }) {
                        Text(currentPhase == .inhale ? String(localized: "particle_breathe_in", defaultValue: "Nefes Al", comment: "Breathe in button") : String(localized: "particle_breathe_out", defaultValue: "Nefes Ver", comment: "Breathe out button"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.purple.opacity(0.7))
                            .cornerRadius(10)
                    }

                    // Animation toggle
                    Button(action: {
                        isAnimating.toggle()
                    }) {
                        Text(isAnimating ? String(localized: "particle_stop", defaultValue: "Durdur", comment: "Stop animation button") : String(localized: "particle_start", defaultValue: "Başlat", comment: "Start animation button"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(10)
                    }

                    // Intensity picker
                    Picker(String(localized: "particle_intensity", defaultValue: "Yoğunluk", comment: "Particle intensity picker label"), selection: $intensity) {
                        ForEach(ParticleIntensity.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Color theme picker
                    Picker(String(localized: "particle_color_theme", defaultValue: "Renk Teması", comment: "Color theme picker label"), selection: $colorTheme) {
                        ForEach(ParticleColorTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                .padding()
            }
        }
    }
}
