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
                let colors = [
                    UIColor(red: 0.18, green: 0.15, blue: 0.35, alpha: 1.0).cgColor, // deepIndigo
                    UIColor(red: 0.45, green: 0.35, blue: 0.65, alpha: 1.0).cgColor  // softPurple
                ]

                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors as CFArray,
                                         locations: [0.0, 1.0])!

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
            // Ambient light - soft overall illumination
            let ambientLight = SCNNode()
            ambientLight.light = SCNLight()
            ambientLight.light?.type = .ambient
            ambientLight.light?.color = UIColor(white: 0.4, alpha: 1.0)
            scene.rootNode.addChildNode(ambientLight)

            // Directional light - sun-like with soft shadows
            let directionalLight = SCNNode()
            directionalLight.light = SCNLight()
            directionalLight.light?.type = .directional
            directionalLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
            directionalLight.light?.castsShadow = true
            directionalLight.light?.shadowMode = .deferred
            directionalLight.light?.shadowRadius = 3.0
            directionalLight.light?.shadowSampleCount = 16
            directionalLight.light?.shadowColor = UIColor(white: 0, alpha: 0.3)
            directionalLight.position = SCNVector3(x: 5, y: 10, z: 5)
            directionalLight.look(at: SCNVector3(x: 0, y: 0, z: 0))
            scene.rootNode.addChildNode(directionalLight)

            // Accent light - subtle highlight from opposite side
            let accentLight = SCNNode()
            accentLight.light = SCNLight()
            accentLight.light?.type = .omni
            accentLight.light?.color = UIColor(red: 0.55, green: 0.40, blue: 0.75, alpha: 1.0) // mysticalViolet
            accentLight.light?.intensity = 200
            accentLight.position = SCNVector3(x: -3, y: 2, z: -3)
            scene.rootNode.addChildNode(accentLight)
        }

        private func setupEnvironment() {
            environmentNode = SCNNode()

            // Ground plane with stone texture
            let ground = SCNPlane(width: 20, height: 20)
            let groundMaterial = SCNMaterial()
            groundMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0) // Sand color
            groundMaterial.roughness.contents = 0.9
            ground.materials = [groundMaterial]

            let groundNode = SCNNode(geometry: ground)
            groundNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
            groundNode.position = SCNVector3(0, 0, 0)
            environmentNode.addChildNode(groundNode)

            // Scattered rocks
            addRocks()

            // Water element
            addWater()

            // Particle system (fireflies)
            addParticleSystem()

            scene.rootNode.addChildNode(environmentNode)
        }

        private func addRocks() {
            let rockPositions: [(x: Float, z: Float, size: Float)] = [
                (-3.0, 2.0, 0.4),
                (2.5, -2.5, 0.3),
                (-2.0, -3.0, 0.5),
                (3.5, 1.5, 0.35),
                (0.5, 3.5, 0.25)
            ]

            for (x, z, size) in rockPositions {
                let rock = SCNSphere(radius: CGFloat(size))
                let rockMaterial = SCNMaterial()
                rockMaterial.diffuse.contents = UIColor(white: 0.3, alpha: 1.0)
                rockMaterial.roughness.contents = 0.95
                rock.materials = [rockMaterial]

                let rockNode = SCNNode(geometry: rock)
                rockNode.position = SCNVector3(x: x, y: size * 0.7, z: z)
                rockNode.scale = SCNVector3(1.0, 0.8, 1.0) // Slightly flatten
                environmentNode.addChildNode(rockNode)
            }
        }

        private func addWater() {
            let water = SCNPlane(width: 3.0, height: 2.0)
            let waterMaterial = SCNMaterial()
            waterMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.6)
            waterMaterial.metalness.contents = 0.8
            waterMaterial.roughness.contents = 0.2
            water.materials = [waterMaterial]

            let waterNode = SCNNode(geometry: water)
            waterNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
            waterNode.position = SCNVector3(4.0, 0.01, -4.0)
            environmentNode.addChildNode(waterNode)
        }

        private func addParticleSystem() {
            let particleSystem = SCNParticleSystem()
            particleSystem.birthRate = 2
            particleSystem.particleLifeSpan = 8
            particleSystem.particleSize = 0.05
            particleSystem.particleColor = UIColor(red: 0.85, green: 0.80, blue: 0.95, alpha: 0.6)
            particleSystem.emitterShape = SCNBox(width: 10, height: 5, length: 10, chamferRadius: 0)
            particleSystem.particleVelocity = 0.2
            particleSystem.particleVelocityVariation = 0.3
            particleSystem.acceleration = SCNVector3(0, 0.1, 0)

            let particleNode = SCNNode()
            particleNode.position = SCNVector3(0, 0, 0)
            particleNode.addParticleSystem(particleSystem)
            environmentNode.addChildNode(particleNode)
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
