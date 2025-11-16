//
//  ZenGarden3DView.swift
//  ZenFlow
//
//  Created by Claude on 2025-11-16.
//  3D Zen Garden with SceneKit
//

import SwiftUI
import SceneKit

struct ZenGarden3DView: UIViewRepresentable {
    @ObservedObject var gardenManager: ZenGardenManager
    @Binding var is3DEnabled: Bool

    // Accessibility
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = context.coordinator.scene
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false // We'll handle gestures manually
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X

        // Enable shadows
        scnView.scene?.rootNode.castsShadow = true

        // Add gesture recognizers
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scnView.addGestureRecognizer(doubleTapGesture)

        // Accessibility
        scnView.isAccessibilityElement = true
        scnView.accessibilityLabel = accessibilityDescription(for: gardenManager.currentStage)
        scnView.accessibilityHint = "Parmağınızı kaydırarak kamera açısını değiştirebilir, iki parmakla yakınlaştırabilir veya sıfırlamak için çift dokunabilirsiniz"
        scnView.accessibilityTraits = .allowsDirectInteraction

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update tree when stage changes
        context.coordinator.updateTree(for: gardenManager.currentStage, shouldCelebrate: gardenManager.shouldCelebrate, reduceMotion: reduceMotion)

        // Update accessibility label
        uiView.accessibilityLabel = accessibilityDescription(for: gardenManager.currentStage)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(gardenManager: gardenManager)
    }

    // MARK: - Accessibility Helper

    private func accessibilityDescription(for stage: TreeGrowthStage) -> String {
        return "Ağaç görünümü, \(stage.title) aşamasında. \(stage.description)"
    }

    // MARK: - Coordinator
    class Coordinator: NSObject {
        let scene: SCNScene
        let gardenManager: ZenGardenManager

        // Scene nodes
        private var cameraNode: SCNNode!
        private var treeNode: SCNNode?
        private var environmentNode: SCNNode!

        // Camera control
        private var cameraOrbit: Float = 0.0
        private var cameraDistance: Float = 8.0
        private let minDistance: Float = 4.0
        private let maxDistance: Float = 15.0

        // Previous stage for animation
        private var previousStage: TreeGrowthStage?

        init(gardenManager: ZenGardenManager) {
            self.gardenManager = gardenManager
            self.scene = SCNScene()

            super.init()

            setupScene()
            setupCamera()
            setupLighting()
            setupEnvironment()

            // Initial tree
            updateTree(for: gardenManager.currentStage, shouldCelebrate: false, reduceMotion: false)
        }

        // MARK: - Scene Setup
        private func setupScene() {
            // Gradient background
            scene.background.contents = createGradientBackground()
        }

        private func createGradientBackground() -> UIImage {
            let size = CGSize(width: 1, height: 500)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                // Natural sky gradient - soft blue to warm horizon
                let colors = [
                    UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0).cgColor, // Sky blue
                    UIColor(red: 0.85, green: 0.92, blue: 0.95, alpha: 1.0).cgColor, // Light blue
                    UIColor(red: 0.98, green: 0.94, blue: 0.88, alpha: 1.0).cgColor  // Warm horizon
                ]

                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors as CFArray,
                                         locations: [0.0, 0.5, 1.0])!

                context.cgContext.drawLinearGradient(gradient,
                                                     start: CGPoint(x: 0, y: 0),
                                                     end: CGPoint(x: 0, y: size.height),
                                                     options: [])
            }
        }

        private func setupCamera() {
            cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.zFar = 100
            cameraNode.camera?.zNear = 0.1
            cameraNode.camera?.fieldOfView = 60

            updateCameraPosition()
            scene.rootNode.addChildNode(cameraNode)
        }

        private func updateCameraPosition() {
            let x = cameraDistance * sin(cameraOrbit)
            let z = cameraDistance * cos(cameraOrbit)
            cameraNode.position = SCNVector3(x: x, y: 3.0, z: z)
            cameraNode.look(at: SCNVector3(x: 0, y: 1.5, z: 0))
        }

        private func setupLighting() {
            // Ambient light - natural daylight
            let ambientLight = SCNNode()
            ambientLight.light = SCNLight()
            ambientLight.light?.type = .ambient
            ambientLight.light?.color = UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0) // Slight cool tint
            ambientLight.light?.intensity = 400
            scene.rootNode.addChildNode(ambientLight)

            // Directional light - warm sunlight with soft shadows
            let directionalLight = SCNNode()
            directionalLight.light = SCNLight()
            directionalLight.light?.type = .directional
            directionalLight.light?.color = UIColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1.0) // Warm sunlight
            directionalLight.light?.intensity = 800
            directionalLight.light?.castsShadow = true
            directionalLight.light?.shadowMode = .deferred
            directionalLight.light?.shadowRadius = 4.0
            directionalLight.light?.shadowSampleCount = 16
            directionalLight.light?.shadowColor = UIColor(white: 0, alpha: 0.25)
            directionalLight.position = SCNVector3(x: 8, y: 12, z: 6)
            directionalLight.look(at: SCNVector3(x: 0, y: 0, z: 0))
            scene.rootNode.addChildNode(directionalLight)

            // Fill light - subtle bounce light from opposite side
            let fillLight = SCNNode()
            fillLight.light = SCNLight()
            fillLight.light?.type = .omni
            fillLight.light?.color = UIColor(red: 0.85, green: 0.90, blue: 0.95, alpha: 1.0) // Cool fill
            fillLight.light?.intensity = 150
            fillLight.position = SCNVector3(x: -5, y: 3, z: -5)
            scene.rootNode.addChildNode(fillLight)
        }

        private func setupEnvironment() {
            environmentNode = SCNNode()

            // Ground plane with white sand texture
            let ground = SCNPlane(width: 20, height: 20)
            let groundMaterial = SCNMaterial()
            // Natural white/beige sand color
            groundMaterial.diffuse.contents = createSandTexture()
            groundMaterial.roughness.contents = 0.95
            groundMaterial.normal.contents = createSandNormalMap()
            groundMaterial.normal.intensity = 0.3
            ground.materials = [groundMaterial]

            let groundNode = SCNNode(geometry: ground)
            groundNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
            groundNode.position = SCNVector3(0, 0, 0)
            environmentNode.addChildNode(groundNode)

            // Sand rake patterns
            addRakePatterns()

            // Scattered rocks
            addRocks()

            // Bamboo elements
            addBamboo()

            // Japanese stone lantern
            addStoneLantern()

            // Water element
            addWater()

            // Particle system (subtle ambient particles)
            addParticleSystem()

            scene.rootNode.addChildNode(environmentNode)
        }

        private func addRocks() {
            // Natural rock colors - mix of grey and brown tones
            let rockColors = [
                UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0), // Medium grey
                UIColor(red: 0.55, green: 0.50, blue: 0.45, alpha: 1.0), // Warm grey
                UIColor(red: 0.40, green: 0.38, blue: 0.35, alpha: 1.0), // Dark grey-brown
                UIColor(red: 0.60, green: 0.55, blue: 0.50, alpha: 1.0), // Light grey-brown
                UIColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1.0)  // Cool grey
            ]

            let rockPositions: [(x: Float, z: Float, size: Float)] = [
                (-3.0, 2.0, 0.4),
                (2.5, -2.5, 0.3),
                (-2.0, -3.0, 0.5),
                (3.5, 1.5, 0.35),
                (0.5, 3.5, 0.25)
            ]

            for (index, (x, z, size)) in rockPositions.enumerated() {
                let rock = SCNSphere(radius: CGFloat(size))
                let rockMaterial = SCNMaterial()
                rockMaterial.diffuse.contents = rockColors[index % rockColors.count]
                rockMaterial.roughness.contents = 0.85
                rockMaterial.metalness.contents = 0.1
                rock.materials = [rockMaterial]

                let rockNode = SCNNode(geometry: rock)
                rockNode.position = SCNVector3(x: x, y: size * 0.6, z: z)
                // Random variations for natural look
                rockNode.scale = SCNVector3(
                    1.0 + Float.random(in: -0.15...0.15),
                    0.7 + Float.random(in: -0.1...0.1),
                    1.0 + Float.random(in: -0.15...0.15)
                )
                rockNode.rotation = SCNVector4(0, 1, 0, Float.random(in: 0...(2 * .pi)))
                environmentNode.addChildNode(rockNode)
            }
        }

        // MARK: - Sand Texture Helpers

        private func createSandTexture() -> UIImage {
            let size: CGFloat = 512
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

            return renderer.image { context in
                // Base sand color - natural beige/white
                let baseColor = UIColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1.0)
                baseColor.setFill()
                context.fill(CGRect(x: 0, y: 0, width: size, height: size))

                // Add subtle noise for texture
                for _ in 0..<1000 {
                    let x = CGFloat.random(in: 0...size)
                    let y = CGFloat.random(in: 0...size)
                    let brightness = CGFloat.random(in: 0.85...0.98)
                    UIColor(white: brightness, alpha: 0.3).setFill()
                    context.cgContext.fillEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                }
            }
        }

        private func createSandNormalMap() -> UIImage {
            let size: CGFloat = 256
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

            return renderer.image { context in
                // Neutral normal (pointing up)
                UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0).setFill()
                context.fill(CGRect(x: 0, y: 0, width: size, height: size))

                // Add subtle bumps
                for _ in 0..<100 {
                    let x = CGFloat.random(in: 0...size)
                    let y = CGFloat.random(in: 0...size)
                    let radius = CGFloat.random(in: 2...8)

                    let colors = [
                        UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0).cgColor,
                        UIColor(red: 0.48, green: 0.52, blue: 1.0, alpha: 1.0).cgColor
                    ]

                    let gradient = CGGradient(
                        colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: colors as CFArray,
                        locations: [0.0, 1.0]
                    )!

                    context.cgContext.drawRadialGradient(
                        gradient,
                        startCenter: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endCenter: CGPoint(x: x, y: y),
                        endRadius: radius,
                        options: []
                    )
                }
            }
        }

        private func addRakePatterns() {
            // Create zen rake patterns in the sand
            let patternPositions: [(centerX: Float, centerZ: Float, radius: Float, rings: Int)] = [
                (0.0, 0.0, 2.5, 8),    // Center pattern around tree
                (-4.0, -3.0, 1.5, 5),  // Small pattern
                (3.0, 4.0, 1.8, 6)     // Another pattern
            ]

            for pattern in patternPositions {
                for ring in 0..<pattern.rings {
                    let radius = Float(ring) * (pattern.radius / Float(pattern.rings))
                    let segments = max(12, ring * 8)

                    for segment in 0..<segments {
                        let angle = Float(segment) * (2 * .pi / Float(segments))
                        let x = pattern.centerX + radius * cos(angle)
                        let z = pattern.centerZ + radius * sin(angle)

                        // Small cylinder to represent rake line
                        let line = SCNCylinder(radius: 0.01, height: 0.005)
                        let lineMaterial = SCNMaterial()
                        lineMaterial.diffuse.contents = UIColor(red: 0.88, green: 0.86, blue: 0.80, alpha: 1.0)
                        line.materials = [lineMaterial]

                        let lineNode = SCNNode(geometry: line)
                        lineNode.position = SCNVector3(x: x, y: 0.002, z: z)
                        lineNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
                        environmentNode.addChildNode(lineNode)
                    }
                }
            }
        }

        private func addBamboo() {
            // Add bamboo stalks near the edges
            let bambooPositions: [(x: Float, z: Float, height: Float)] = [
                (-5.5, 5.0, 3.0),
                (-5.0, 4.5, 2.8),
                (-5.8, 5.3, 3.2),
                (5.5, -5.0, 2.9),
                (5.3, -5.5, 3.1)
            ]

            for (x, z, height) in bambooPositions {
                let bamboo = SCNCylinder(radius: 0.08, height: CGFloat(height))
                let bambooMaterial = SCNMaterial()
                bambooMaterial.diffuse.contents = UIColor(red: 0.45, green: 0.62, blue: 0.35, alpha: 1.0)
                bambooMaterial.roughness.contents = 0.6
                bamboo.materials = [bambooMaterial]

                let bambooNode = SCNNode(geometry: bamboo)
                bambooNode.position = SCNVector3(x: x, y: height / 2, z: z)

                // Add bamboo segments (rings)
                for i in 0..<Int(height * 3) {
                    let segment = SCNTorus(ringRadius: 0.09, pipeRadius: 0.015)
                    let segmentMaterial = SCNMaterial()
                    segmentMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.52, blue: 0.25, alpha: 1.0)
                    segment.materials = [segmentMaterial]

                    let segmentNode = SCNNode(geometry: segment)
                    segmentNode.position = SCNVector3(0, Float(i) * 0.35 - height / 2 + 0.2, 0)
                    bambooNode.addChildNode(segmentNode)
                }

                environmentNode.addChildNode(bambooNode)
            }
        }

        private func addStoneLantern() {
            // Traditional Japanese stone lantern (simplified)
            let lanternX: Float = -4.5
            let lanternZ: Float = 1.5

            // Base
            let base = SCNBox(width: 0.5, height: 0.15, length: 0.5, chamferRadius: 0.02)
            let baseMaterial = SCNMaterial()
            baseMaterial.diffuse.contents = UIColor(red: 0.50, green: 0.48, blue: 0.45, alpha: 1.0)
            baseMaterial.roughness.contents = 0.9
            base.materials = [baseMaterial]

            let baseNode = SCNNode(geometry: base)
            baseNode.position = SCNVector3(x: lanternX, y: 0.075, z: lanternZ)
            environmentNode.addChildNode(baseNode)

            // Post
            let post = SCNCylinder(radius: 0.1, height: 1.0)
            let postMaterial = SCNMaterial()
            postMaterial.diffuse.contents = UIColor(red: 0.48, green: 0.46, blue: 0.43, alpha: 1.0)
            postMaterial.roughness.contents = 0.85
            post.materials = [postMaterial]

            let postNode = SCNNode(geometry: post)
            postNode.position = SCNVector3(x: lanternX, y: 0.65, z: lanternZ)
            environmentNode.addChildNode(postNode)

            // Light box
            let lightBox = SCNBox(width: 0.4, height: 0.4, length: 0.4, chamferRadius: 0.02)
            let lightBoxMaterial = SCNMaterial()
            lightBoxMaterial.diffuse.contents = UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 0.8)
            lightBoxMaterial.emission.contents = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.3)
            lightBoxMaterial.roughness.contents = 0.3
            lightBox.materials = [lightBoxMaterial]

            let lightBoxNode = SCNNode(geometry: lightBox)
            lightBoxNode.position = SCNVector3(x: lanternX, y: 1.35, z: lanternZ)
            environmentNode.addChildNode(lightBoxNode)

            // Roof (pyramid)
            let roof = SCNPyramid(width: 0.6, height: 0.4, length: 0.6)
            let roofMaterial = SCNMaterial()
            roofMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.33, blue: 0.30, alpha: 1.0)
            roofMaterial.roughness.contents = 0.95
            roof.materials = [roofMaterial]

            let roofNode = SCNNode(geometry: roof)
            roofNode.position = SCNVector3(x: lanternX, y: 1.75, z: lanternZ)
            environmentNode.addChildNode(roofNode)
        }

        private func addWater() {
            let water = SCNPlane(width: 3.0, height: 2.0)
            let waterMaterial = SCNMaterial()
            // More natural water color
            waterMaterial.diffuse.contents = UIColor(red: 0.25, green: 0.35, blue: 0.45, alpha: 0.7)
            waterMaterial.metalness.contents = 0.7
            waterMaterial.roughness.contents = 0.3
            water.materials = [waterMaterial]

            let waterNode = SCNNode(geometry: water)
            waterNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
            waterNode.position = SCNVector3(4.0, 0.01, -4.0)
            environmentNode.addChildNode(waterNode)
        }

        private func addParticleSystem() {
            // Subtle floating particles - like dust motes in sunlight or petals
            let particleSystem = SCNParticleSystem()
            particleSystem.birthRate = 1.5
            particleSystem.particleLifeSpan = 10
            particleSystem.particleSize = 0.08
            // Natural soft white/cream color for subtle ambiance
            particleSystem.particleColor = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 0.6)
            particleSystem.emitterShape = SCNBox(width: 12, height: 6, length: 12, chamferRadius: 0)
            particleSystem.particleVelocity = 0.15
            particleSystem.particleVelocityVariation = 0.2
            particleSystem.acceleration = SCNVector3(0, 0.05, 0)

            // Create a soft glowing particle image
            particleSystem.particleImage = createParticleImage()

            // Blend mode for soft glow effect
            particleSystem.blendMode = .alpha

            // Subtle size variation for more organic feel
            particleSystem.particleSizeVariation = 0.04

            let particleNode = SCNNode()
            particleNode.position = SCNVector3(0, 0, 0)
            particleNode.addParticleSystem(particleSystem)
            environmentNode.addChildNode(particleNode)
        }

        // MARK: - Particle Image Helper

        private func createParticleImage() -> UIImage {
            let size: CGFloat = 64
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

            return renderer.image { context in
                let center = CGPoint(x: size / 2, y: size / 2)
                let radius = size / 2

                // Create radial gradient for soft glow effect
                let colors = [
                    UIColor.white.withAlphaComponent(1.0).cgColor,
                    UIColor.white.withAlphaComponent(0.6).cgColor,
                    UIColor.white.withAlphaComponent(0.2).cgColor,
                    UIColor.clear.cgColor
                ]

                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors as CFArray,
                    locations: [0.0, 0.3, 0.6, 1.0]
                )!

                context.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }

        // MARK: - Tree Updates
        func updateTree(for stage: TreeGrowthStage, shouldCelebrate: Bool, reduceMotion: Bool) {
            let oldTree = treeNode

            // Create new tree
            let newTree = createTree(for: stage)
            scene.rootNode.addChildNode(newTree)

            // Animation
            if let oldTree = oldTree, previousStage != nil {
                if reduceMotion {
                    // Instant transition for Reduce Motion
                    oldTree.removeFromParentNode()
                    newTree.opacity = 1.0
                } else {
                    animateTreeTransition(from: oldTree, to: newTree, shouldCelebrate: shouldCelebrate)
                }
            } else {
                // First load - no animation
                newTree.opacity = 1.0
            }

            treeNode = newTree
            previousStage = stage
        }

        private func createTree(for stage: TreeGrowthStage) -> SCNNode {
            let treeBuilder = TreeBuilder()
            return treeBuilder.buildTree(for: stage)
        }

        private func animateTreeTransition(from oldTree: SCNNode, to newTree: SCNNode, shouldCelebrate: Bool) {
            // Set initial state for new tree
            newTree.opacity = 0.0
            newTree.scale = SCNVector3(0.0, 0.0, 0.0)

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 2.0
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            SCNTransaction.completionBlock = {
                oldTree.removeFromParentNode()

                if shouldCelebrate {
                    self.playCelebrationEffect()
                }
            }

            // Fade out old tree
            oldTree.opacity = 0.0
            oldTree.scale = SCNVector3(0.8, 0.8, 0.8)

            // Fade in new tree
            newTree.opacity = 1.0
            newTree.scale = SCNVector3(1.0, 1.0, 1.0)

            SCNTransaction.commit()
        }

        private func playCelebrationEffect() {
            // Particle burst
            let celebrationParticles = SCNParticleSystem()
            celebrationParticles.birthRate = 100
            celebrationParticles.particleLifeSpan = 2.0
            celebrationParticles.particleSize = 0.1
            celebrationParticles.particleColor = UIColor(red: 0.95, green: 0.85, blue: 0.3, alpha: 1.0)
            celebrationParticles.emissionDuration = 0.5
            celebrationParticles.spreadingAngle = 180
            celebrationParticles.particleVelocity = 3.0
            celebrationParticles.particleVelocityVariation = 1.5

            let burstNode = SCNNode()
            burstNode.position = SCNVector3(0, 2.0, 0)
            burstNode.addParticleSystem(celebrationParticles)
            scene.rootNode.addChildNode(burstNode)

            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                burstNode.removeFromParentNode()
            }

            // Camera shake
            let originalPosition = cameraNode.position
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.1
            cameraNode.position = SCNVector3(originalPosition.x + 0.1, originalPosition.y, originalPosition.z)
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.1
                self.cameraNode.position = originalPosition
                SCNTransaction.commit()
            }
            SCNTransaction.commit()
        }

        // MARK: - Gesture Handlers
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)

            // Rotate camera orbit
            cameraOrbit += Float(translation.x) * 0.005

            gesture.setTranslation(.zero, in: gesture.view)

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.1
            updateCameraPosition()
            SCNTransaction.commit()
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed {
                let scale = Float(gesture.scale)
                cameraDistance = max(minDistance, min(maxDistance, cameraDistance / scale))
                gesture.scale = 1.0

                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.1
                updateCameraPosition()
                SCNTransaction.commit()
            }
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            // Reset camera to default position
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            cameraOrbit = 0.0
            cameraDistance = 8.0
            updateCameraPosition()

            SCNTransaction.commit()
        }
    }
}

// MARK: - Tree Builder Helper
class TreeBuilder {
    func buildTree(for stage: TreeGrowthStage) -> SCNNode {
        let treeNode = SCNNode()
        treeNode.position = SCNVector3(0, 0, 0)

        switch stage {
        case .seed:
            treeNode.addChildNode(createSeed())
        case .sprout:
            treeNode.addChildNode(createSprout())
        case .sapling:
            treeNode.addChildNode(createSapling())
        case .youngTree:
            treeNode.addChildNode(createYoungTree())
        case .matureTree:
            treeNode.addChildNode(createMatureTree())
        case .ancientTree:
            treeNode.addChildNode(createAncientTree())
        }

        return treeNode
    }

    // MARK: - Stage Geometries

    private func createSeed() -> SCNNode {
        let seed = SCNSphere(radius: 0.15)
        let material = createMaterial(color: UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0))
        seed.materials = [material]

        let seedNode = SCNNode(geometry: seed)
        seedNode.position = SCNVector3(0, 0.15, 0)
        return seedNode
    }

    private func createSprout() -> SCNNode {
        let container = SCNNode()

        // Seed base
        let seed = SCNSphere(radius: 0.12)
        let seedMaterial = createMaterial(color: UIColor(red: 0.5, green: 0.3, blue: 0.15, alpha: 1.0))
        seed.materials = [seedMaterial]
        let seedNode = SCNNode(geometry: seed)
        seedNode.position = SCNVector3(0, 0.12, 0)
        container.addChildNode(seedNode)

        // Small stem
        let stem = SCNCylinder(radius: 0.02, height: 0.3)
        let stemMaterial = createMaterial(color: UIColor(red: 0.5, green: 0.8, blue: 0.3, alpha: 1.0))
        stem.materials = [stemMaterial]
        let stemNode = SCNNode(geometry: stem)
        stemNode.position = SCNVector3(0, 0.35, 0)
        container.addChildNode(stemNode)

        return container
    }

    private func createSapling() -> SCNNode {
        let container = SCNNode()

        // Trunk
        let trunk = SCNCylinder(radius: 0.05, height: 0.8)
        let trunkMaterial = createMaterial(color: UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0))
        trunk.materials = [trunkMaterial]
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position = SCNVector3(0, 0.4, 0)
        container.addChildNode(trunkNode)

        // Foliage (cone)
        let foliage = SCNCone(topRadius: 0.0, bottomRadius: 0.4, height: 0.8)
        let foliageMaterial = createMaterial(color: UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0))
        foliage.materials = [foliageMaterial]
        let foliageNode = SCNNode(geometry: foliage)
        foliageNode.position = SCNVector3(0, 1.2, 0)
        container.addChildNode(foliageNode)

        return container
    }

    private func createYoungTree() -> SCNNode {
        let container = SCNNode()

        // Main trunk
        let trunk = SCNCylinder(radius: 0.08, height: 1.5)
        let trunkMaterial = createMaterial(color: UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0))
        trunk.materials = [trunkMaterial]
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position = SCNVector3(0, 0.75, 0)
        container.addChildNode(trunkNode)

        // Multiple branch levels
        let branchPositions: [(y: Float, angle: Float, length: Float)] = [
            (0.8, 0.0, 0.4),
            (1.0, Float.pi / 2, 0.35),
            (1.2, Float.pi, 0.3),
            (1.4, 3 * Float.pi / 2, 0.35)
        ]

        for (y, angle, length) in branchPositions {
            let branch = createBranch(length: CGFloat(length), angle: angle)
            branch.position = SCNVector3(0, y, 0)
            container.addChildNode(branch)
        }

        // Top foliage
        let foliage = SCNSphere(radius: 0.6)
        let foliageMaterial = createMaterial(color: UIColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0))
        foliage.materials = [foliageMaterial]
        let foliageNode = SCNNode(geometry: foliage)
        foliageNode.position = SCNVector3(0, 2.0, 0)
        container.addChildNode(foliageNode)

        return container
    }

    private func createMatureTree() -> SCNNode {
        let container = SCNNode()

        // Thick trunk
        let trunk = SCNCylinder(radius: 0.12, height: 2.0)
        let trunkMaterial = createMaterial(color: UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0))
        trunk.materials = [trunkMaterial]
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position = SCNVector3(0, 1.0, 0)
        container.addChildNode(trunkNode)

        // 5 main branches with sub-branches
        let branchAngles: [Float] = [0, Float.pi * 0.4, Float.pi * 0.8, Float.pi * 1.2, Float.pi * 1.6]

        for (index, angle) in branchAngles.enumerated() {
            let yPos: Float = 1.2 + Float(index) * 0.2
            let branch = createDetailedBranch(angle: angle)
            branch.position = SCNVector3(0, yPos, 0)
            container.addChildNode(branch)
        }

        // Lush canopy
        let canopy = SCNSphere(radius: 1.0)
        let canopyMaterial = createMaterial(color: UIColor(red: 0.45, green: 0.35, blue: 0.65, alpha: 1.0)) // mysticalViolet
        canopy.materials = [canopyMaterial]
        let canopyNode = SCNNode(geometry: canopy)
        canopyNode.position = SCNVector3(0, 2.8, 0)
        container.addChildNode(canopyNode)

        return container
    }

    private func createAncientTree() -> SCNNode {
        let container = SCNNode()

        // Massive gnarled trunk
        let trunk = SCNCylinder(radius: 0.18, height: 2.5)
        let trunkMaterial = createMaterial(color: UIColor(red: 0.25, green: 0.15, blue: 0.05, alpha: 1.0))
        trunk.materials = [trunkMaterial]
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position = SCNVector3(0, 1.25, 0)
        container.addChildNode(trunkNode)

        // Complex branch system
        let branchConfigs: [(y: Float, angle: Float, tilt: Float)] = [
            (1.5, 0.0, 0.3),
            (1.7, Float.pi / 3, 0.4),
            (1.9, 2 * Float.pi / 3, 0.35),
            (2.1, Float.pi, 0.4),
            (2.3, 4 * Float.pi / 3, 0.3),
            (2.5, 5 * Float.pi / 3, 0.35)
        ]

        for config in branchConfigs {
            let branch = createAncientBranch(angle: config.angle, tilt: config.tilt)
            branch.position = SCNVector3(0, config.y, 0)
            container.addChildNode(branch)
        }

        // Magical golden canopy
        let canopy = SCNSphere(radius: 1.3)
        let canopyMaterial = createMaterial(color: UIColor(red: 0.95, green: 0.85, blue: 0.3, alpha: 1.0))
        canopyMaterial.emission.contents = UIColor(red: 0.6, green: 0.5, blue: 0.1, alpha: 1.0)
        canopy.materials = [canopyMaterial]
        let canopyNode = SCNNode(geometry: canopy)
        canopyNode.position = SCNVector3(0, 3.5, 0)
        container.addChildNode(canopyNode)

        // Add glow particles
        let glowParticles = SCNParticleSystem()
        glowParticles.birthRate = 5
        glowParticles.particleLifeSpan = 3
        glowParticles.particleSize = 0.08
        glowParticles.particleColor = UIColor(red: 0.95, green: 0.85, blue: 0.3, alpha: 0.6)
        glowParticles.emitterShape = SCNSphere(radius: 1.5)
        glowParticles.particleVelocity = 0.3

        canopyNode.addParticleSystem(glowParticles)

        return container
    }

    // MARK: - Helper Methods

    private func createBranch(length: CGFloat, angle: Float) -> SCNNode {
        let branch = SCNCylinder(radius: 0.03, height: length)
        let branchMaterial = createMaterial(color: UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0))
        branch.materials = [branchMaterial]

        let branchNode = SCNNode(geometry: branch)
        branchNode.rotation = SCNVector4(0, 1, 0, angle)
        branchNode.eulerAngles.z = Float.pi / 4 // Tilt upward

        // Add small foliage
        let foliage = SCNSphere(radius: length * 0.4)
        let foliageMaterial = createMaterial(color: UIColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0))
        foliage.materials = [foliageMaterial]
        let foliageNode = SCNNode(geometry: foliage)
        foliageNode.position = SCNVector3(0, Float(length * 0.6), 0)
        branchNode.addChildNode(foliageNode)

        return branchNode
    }

    private func createDetailedBranch(angle: Float) -> SCNNode {
        let container = SCNNode()

        // Main branch
        let mainBranch = SCNCylinder(radius: 0.06, height: 0.6)
        let material = createMaterial(color: UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0))
        mainBranch.materials = [material]

        let branchNode = SCNNode(geometry: mainBranch)
        branchNode.rotation = SCNVector4(0, 1, 0, angle)
        branchNode.eulerAngles.z = Float.pi / 3

        // Sub-branches
        let subBranch1 = createSubBranch(length: 0.3, angle: 0.5)
        subBranch1.position = SCNVector3(0, 0.2, 0)
        branchNode.addChildNode(subBranch1)

        let subBranch2 = createSubBranch(length: 0.25, angle: -0.5)
        subBranch2.position = SCNVector3(0, 0.1, 0)
        branchNode.addChildNode(subBranch2)

        container.addChildNode(branchNode)
        return container
    }

    private func createAncientBranch(angle: Float, tilt: Float) -> SCNNode {
        let container = SCNNode()

        let branch = SCNCylinder(radius: 0.08, height: 0.8)
        let material = createMaterial(color: UIColor(red: 0.25, green: 0.15, blue: 0.05, alpha: 1.0))
        branch.materials = [material]

        let branchNode = SCNNode(geometry: branch)
        branchNode.rotation = SCNVector4(0, 1, 0, angle)
        branchNode.eulerAngles.z = tilt

        // Add mystical leaves
        let leaves = SCNSphere(radius: 0.4)
        let leavesMaterial = createMaterial(color: UIColor(red: 0.85, green: 0.80, blue: 0.95, alpha: 1.0))
        leaves.materials = [leavesMaterial]
        let leavesNode = SCNNode(geometry: leaves)
        leavesNode.position = SCNVector3(0, 0.5, 0)
        branchNode.addChildNode(leavesNode)

        container.addChildNode(branchNode)
        return container
    }

    private func createSubBranch(length: CGFloat, angle: Float) -> SCNNode {
        let subBranch = SCNCylinder(radius: 0.03, height: length)
        let material = createMaterial(color: UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0))
        subBranch.materials = [material]

        let subBranchNode = SCNNode(geometry: subBranch)
        subBranchNode.eulerAngles.z = angle

        return subBranchNode
    }

    private func createMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.roughness.contents = 0.7
        material.metalness.contents = 0.1
        material.lightingModel = .physicallyBased
        return material
    }
}
