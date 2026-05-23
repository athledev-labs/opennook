// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import NookSurface
import SwiftUI
import XCTest
@testable import NookKit

/// Pins ``NookBackdropMapping`` to its rendering contract. The mapping is the only
/// producer of ``NookBackdrop`` in the framework; if these change, downstream renders
/// change too — so they're worth pinning explicitly.
final class NookBackdropMappingTests: XCTestCase {
    private func preferences(
        palette: NookChromePalette,
        style: NookSurfaceStyle
    ) -> NookAppearancePreferences {
        NookAppearancePreferences(chromePalette: palette, surfaceStyle: style)
    }

    func testSolidStyleMapsToSolidBlackInDark() {
        let backdrop = NookBackdropMapping.notchBackdrop(
            preferences: preferences(palette: .dark, style: .solid),
            effectiveColorScheme: .dark,
            reduceTransparency: false
        )
        XCTAssertEqual(backdrop, .solid(.black))
    }

    func testSolidStyleMapsToSolidWhiteInLight() {
        let backdrop = NookBackdropMapping.notchBackdrop(
            preferences: preferences(palette: .light, style: .solid),
            effectiveColorScheme: .light,
            reduceTransparency: false
        )
        XCTAssertEqual(backdrop, .solid(.white))
    }

    /// Reduce Transparency overrides the translucent style — the chrome must avoid
    /// `NSVisualEffectView` entirely.
    func testReduceTransparencyForcesSolidEvenWhenTranslucent() {
        let backdrop = NookBackdropMapping.notchBackdrop(
            preferences: preferences(palette: .dark, style: .translucent),
            effectiveColorScheme: .dark,
            reduceTransparency: true
        )
        XCTAssertEqual(backdrop, .solid(.black), "RT forces a solid fill in any style")
    }

    func testFollowSystemPaletteResolvesAgainstEffectiveScheme() {
        let dark = NookBackdropMapping.notchBackdrop(
            preferences: preferences(palette: .followSystem, style: .solid),
            effectiveColorScheme: .dark,
            reduceTransparency: false
        )
        XCTAssertEqual(dark, .solid(.black))

        let light = NookBackdropMapping.notchBackdrop(
            preferences: preferences(palette: .followSystem, style: .solid),
            effectiveColorScheme: .light,
            reduceTransparency: false
        )
        XCTAssertEqual(light, .solid(.white))
    }

    func testTranslucentDarkUsesSidebarVibrancyWithDarkDarken() {
        let backdrop = NookBackdropMapping.notchBackdrop(
            preferences: preferences(palette: .dark, style: .translucent),
            effectiveColorScheme: .dark,
            reduceTransparency: false
        )
        let expected = NookBackdrop.vibrancy(.init(
            material: .sidebar,
            blendingMode: .behindWindow,
            darkenOpacity: 0.52
        ))
        XCTAssertEqual(backdrop, expected)
    }

    func testTranslucentLightUsesSidebarVibrancyWithLightDarken() {
        let backdrop = NookBackdropMapping.notchBackdrop(
            preferences: preferences(palette: .light, style: .translucent),
            effectiveColorScheme: .light,
            reduceTransparency: false
        )
        let expected = NookBackdrop.vibrancy(.init(
            material: .sidebar,
            blendingMode: .behindWindow,
            darkenOpacity: 0.10
        ))
        XCTAssertEqual(backdrop, expected)
    }

    /// The framework default — what every host gets before any mapping runs — must be
    /// the solid-black fill so cold-launch rendering matches the historical chrome.
    func testDefaultBackdropIsSolidBlack() {
        XCTAssertEqual(NookBackdrop.solidBlack, .solid(.black))
    }
}
