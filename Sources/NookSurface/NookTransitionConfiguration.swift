// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Kai Azim — DynamicNotchKit (original)
// Copyright (c) 2026 Glendon Chin — OpenNook modifications
//
// Licensed under the MIT License.
// Original kit license: /ThirdPartyLicenses/DynamicNotchKit.txt
// Modifications license: /LICENSE-MIT-NOOKSURFACE

import SwiftUI

/// Per-instance overrides for the surface's animation curves. Nil values fall back to ``NookStyle`` defaults.
public struct NookTransitionConfiguration: Sendable {
    /// Hidden → expanded / hidden → compact.
    public var openingAnimation: Animation?
    /// Expanded → hidden / compact → hidden.
    public var closingAnimation: Animation?
    /// Compact ↔ expanded.
    public var conversionAnimation: Animation?
    /// When `true`, compact↔expanded skips the intermediate hide-and-show.
    public var skipIntermediateHides: Bool

    public init(
        openingAnimation: Animation? = nil,
        closingAnimation: Animation? = nil,
        conversionAnimation: Animation? = nil,
        skipIntermediateHides: Bool = false
    ) {
        self.openingAnimation = openingAnimation
        self.closingAnimation = closingAnimation
        self.conversionAnimation = conversionAnimation
        self.skipIntermediateHides = skipIntermediateHides
    }
}
