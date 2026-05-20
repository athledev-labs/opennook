// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Kai Azim — DynamicNotchKit (original)
// Copyright (c) 2026 Glendon Chin — OpenNook modifications
//
// Licensed under the MIT License.
// Original kit license: /ThirdPartyLicenses/DynamicNotchKit.txt
// Modifications license: /LICENSE-MIT-NOOKSURFACE

import AppKit
import SwiftUI

/// Layered backdrop spec the chrome paints behind nook content.
///
/// One layer for vibrancy material when translucency is allowed, plus tint and darken layers
/// composed on top; one solid fill for accessibility (Reduce Transparency) or pure-color packs.
public struct NookBackdropConfiguration: Equatable, Sendable {
    public var usesVisualEffect: Bool
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var darkenOpacity: CGFloat
    public var tintRed: CGFloat
    public var tintGreen: CGFloat
    public var tintBlue: CGFloat
    public var tintOpacity: CGFloat
    public var opaqueRed: CGFloat
    public var opaqueGreen: CGFloat
    public var opaqueBlue: CGFloat

    public init(
        usesVisualEffect: Bool,
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode,
        darkenOpacity: CGFloat,
        tintRed: CGFloat,
        tintGreen: CGFloat,
        tintBlue: CGFloat,
        tintOpacity: CGFloat,
        opaqueRed: CGFloat,
        opaqueGreen: CGFloat,
        opaqueBlue: CGFloat
    ) {
        self.usesVisualEffect = usesVisualEffect
        self.material = material
        self.blendingMode = blendingMode
        self.darkenOpacity = darkenOpacity
        self.tintRed = tintRed
        self.tintGreen = tintGreen
        self.tintBlue = tintBlue
        self.tintOpacity = tintOpacity
        self.opaqueRed = opaqueRed
        self.opaqueGreen = opaqueGreen
        self.opaqueBlue = opaqueBlue
    }

    /// Solid black backing — matches the menu-bar notch chrome when no other treatment is wanted.
    public static let solidBlack = NookBackdropConfiguration(
        usesVisualEffect: false,
        material: .contentBackground,
        blendingMode: .behindWindow,
        darkenOpacity: 0,
        tintRed: 0,
        tintGreen: 0,
        tintBlue: 0,
        tintOpacity: 0,
        opaqueRed: 0,
        opaqueGreen: 0,
        opaqueBlue: 0
    )
}
