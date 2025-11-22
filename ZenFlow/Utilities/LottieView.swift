//
//  LottieView.swift
//  ZenFlow
//
//  Created by Claude AI on 16.11.2025.
//
//  Lottie animation wrapper for SwiftUI with:
//  - Automatic caching and preloading
//  - Reduce Motion accessibility support
//  - Performance optimizations
//  - Memory management
//

import SwiftUI
import Lottie
import Combine

// MARK: - LottieView

/// SwiftUI wrapper for Lottie animations with accessibility support
struct LottieView: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .playOnce
    var animationSpeed: CGFloat = 1.0
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var completion: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.contentMode = contentMode
        animationView.backgroundBehavior = .pauseAndRestore

        // Load animation from cache or bundle
        if let animation = LottieAnimationCache.shared.animation(named: animationName) {
            animationView.animation = animation
        }

        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        // Check Reduce Motion accessibility setting
        if reduceMotion || !UserDefaults.standard.bool(forKey: "lottieAnimationsEnabled") {
            // Show static fallback (last frame)
            if let animation = uiView.animation {
                uiView.currentProgress = 1.0
            }
            return
        }

        // Configure and play animation
        uiView.loopMode = loopMode
        uiView.animationSpeed = animationSpeed

        // Only play if not already playing
        if !uiView.isAnimationPlaying {
            uiView.play { finished in
                if finished {
                    completion?()
                }
            }
        }
    }

    static func dismantleUIView(_ uiView: LottieAnimationView, coordinator: ()) {
        uiView.stop()
    }
}

// MARK: - LottieAnimationCache

/// Singleton cache for Lottie animations to optimize memory usage
class LottieAnimationCache {
    static let shared = LottieAnimationCache()

    private var cache: [String: LottieAnimation] = [:]
    private let maxCacheSize = 5
    private var cacheOrder: [String] = []

    private init() {
        // Enable default animations setting
        if UserDefaults.standard.object(forKey: "lottieAnimationsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "lottieAnimationsEnabled")
        }
    }

    /// Get animation from cache or load from bundle
    func animation(named name: String) -> LottieAnimation? {
        // Check cache first
        if let cached = cache[name] {
            updateCacheOrder(for: name)
            return cached
        }

        // Load from bundle
        guard let animation = LottieAnimation.named(name, bundle: .main) else {
            print("⚠️ Lottie animation '\(name)' not found in bundle")
            return nil
        }

        // Add to cache
        addToCache(animation, named: name)
        return animation
    }

    /// Preload animations into cache
    func preload(animations: [String]) {
        for name in animations {
            _ = animation(named: name)
        }
    }

    /// Clear all cached animations
    func clearCache() {
        cache.removeAll()
        cacheOrder.removeAll()
    }

    // MARK: - Private Methods

    private func addToCache(_ animation: LottieAnimation, named name: String) {
        // Enforce cache size limit (LRU eviction)
        if cache.count >= maxCacheSize {
            if let oldestKey = cacheOrder.first {
                cache.removeValue(forKey: oldestKey)
                cacheOrder.removeFirst()
            }
        }

        cache[name] = animation
        cacheOrder.append(name)
    }

    private func updateCacheOrder(for name: String) {
        // Move to end (most recently used)
        if let index = cacheOrder.firstIndex(of: name) {
            cacheOrder.remove(at: index)
            cacheOrder.append(name)
        }
    }
}

// MARK: - LottieAnimationManager

/// Manages Lottie animations lifecycle and preloading
class LottieAnimationManager: ObservableObject {
    static let shared = LottieAnimationManager()

    @Published var isAnimationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAnimationEnabled, forKey: "lottieAnimationsEnabled")
        }
    }

    private init() {
        self.isAnimationEnabled = UserDefaults.standard.bool(forKey: "lottieAnimationsEnabled")

        // Preload common animations on app launch
        preloadCommonAnimations()

        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    /// Preload frequently used animations
    private func preloadCommonAnimations() {
        DispatchQueue.global(qos: .userInitiated).async {
            LottieAnimationCache.shared.preload(animations: [
                "success",
                "confetti",
                "sparkle",
                "loading"
            ])
        }
    }

    @objc private func appDidEnterBackground() {
        // Clear cache when app goes to background to free memory
        LottieAnimationCache.shared.clearCache()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Predefined Lottie Views

/// Success checkmark animation (2 seconds)
struct SuccessLottieView: View {
    var completion: (() -> Void)? = nil

    var body: some View {
        LottieView(
            animationName: "success",
            loopMode: .playOnce,
            animationSpeed: 1.0,
            completion: completion
        )
        .frame(width: 200, height: 200)
    }
}

/// Confetti burst animation (3 seconds)
struct ConfettiLottieView: View {
    var completion: (() -> Void)? = nil

    var body: some View {
        LottieView(
            animationName: "confetti",
            loopMode: .playOnce,
            animationSpeed: 1.0,
            completion: completion
        )
        .frame(width: 400, height: 400)
    }
}

/// Sparkle glow animation (2.5 seconds)
struct SparkleLottieView: View {
    var completion: (() -> Void)? = nil

    var body: some View {
        LottieView(
            animationName: "sparkle",
            loopMode: .playOnce,
            animationSpeed: 1.0,
            completion: completion
        )
        .frame(width: 300, height: 300)
    }
}

/// Zen loading animation (looping)
struct LoadingLottieView: View {
    var body: some View {
        LottieView(
            animationName: "loading",
            loopMode: .loop,
            animationSpeed: 1.0
        )
        .frame(width: 200, height: 200)
    }
}

// MARK: - Accessibility Extension

extension View {
    /// Apply Lottie animation with reduce motion fallback
    func lottieAnimation(
        _ animationName: String,
        loopMode: LottieLoopMode = .playOnce,
        completion: (() -> Void)? = nil
    ) -> some View {
        self.overlay(
            LottieView(
                animationName: animationName,
                loopMode: loopMode,
                completion: completion
            )
            .allowsHitTesting(false)
        )
    }
}
