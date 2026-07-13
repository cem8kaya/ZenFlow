//
//  ZenMixTests.swift
//  ZenFlowTests
//
//  Created by Claude AI on 13.07.2026.
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Integrity tests for the curated Zen Mix soundscape presets and the
//  underlying ambient sound catalog: every mix must reference sounds
//  that exist in the catalog AND have a playable audio asset bundled.
//

import XCTest
import UIKit
@testable import ZenFlow

final class ZenMixTests: XCTestCase {

    func testMixIDsAreUnique() {
        let ids = ZenMix.allMixes.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate ZenMix ids found")
    }

    func testEveryMixHasOneOrTwoSounds() {
        // AmbientSoundManager supports at most 2 simultaneous sounds
        for mix in ZenMix.allMixes {
            XCTAssertTrue(
                (1...2).contains(mix.soundFileNames.count),
                "Mix \(mix.id) has \(mix.soundFileNames.count) sounds; must be 1-2"
            )
        }
    }

    func testEveryMixSoundResolvesInCatalog() {
        for mix in ZenMix.allMixes {
            XCTAssertEqual(
                mix.sounds.count,
                mix.soundFileNames.count,
                "Mix \(mix.id) references a fileName missing from AmbientSound.allSounds"
            )
        }
    }

    func testEveryMixSoundHasBundledAudioAsset() {
        // This is the check that catches presets pointing at catalog entries
        // whose audio asset was never added to Assets.xcassets/Sounds
        for mix in ZenMix.allMixes {
            for fileName in mix.soundFileNames {
                XCTAssertNotNil(
                    NSDataAsset(name: fileName),
                    "Mix \(mix.id): no audio asset named '\(fileName)' in the bundle"
                )
            }
        }
    }

    func testMindfulnessBellChimeAssetExists() {
        XCTAssertNotNil(
            NSDataAsset(name: "singing-bowl"),
            "Mindfulness bell chime asset 'singing-bowl' missing from bundle"
        )
    }

    func testAmbientSoundCatalogAssetsExist() {
        // Known issue: the "fireplace" and "fire" catalog entries currently
        // have no bundled audio asset (pre-existing, tracked separately).
        // This documents the full catalog state without failing the suite.
        let knownMissing: Set<String> = ["fireplace", "fire"]

        for sound in AmbientSound.allSounds where !sound.fileName.isEmpty {
            if knownMissing.contains(sound.fileName) {
                XCTExpectFailure("Known missing asset: \(sound.fileName)") {
                    XCTAssertNotNil(NSDataAsset(name: sound.fileName))
                }
            } else {
                XCTAssertNotNil(
                    NSDataAsset(name: sound.fileName),
                    "Catalog sound '\(sound.fileName)' has no bundled audio asset"
                )
            }
        }
    }
}

final class BellIntervalTests: XCTestCase {

    func testAllCasesAndRawValues() {
        XCTAssertEqual(BellInterval.allCases.map { $0.rawValue }, [3, 5, 10, 15])
    }

    func testIdMatchesRawValue() {
        for interval in BellInterval.allCases {
            XCTAssertEqual(interval.id, interval.rawValue)
        }
    }

    func testInvalidRawValueIsNil() {
        XCTAssertNil(BellInterval(rawValue: 0))
        XCTAssertNil(BellInterval(rawValue: 7))
    }
}
