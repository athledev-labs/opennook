// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import AppKit
import NookSurface
import SwiftUI

/// Maps appearance preferences into a nook backdrop layer.
///
/// Two outcomes: a solid opaque fill (the `.solid` surface style, or any time Reduce
/// Transparency is on), or a frosted visual-effect material with a slight darken on top.
public enum NookBackdropMapping {
    public static func notchBackdrop(
        preferences: NookAppearancePreferences,
        effectiveColorScheme: ColorScheme,
        reduceTransparency: Bool
    ) -> NookBackdropConfiguration {
        let isDark: Bool = switch preferences.chromePalette {
        case .followSystem:
            effectiveColorScheme == .dark
        case .dark:
            true
        case .light:
            false
        }

        // `.solid` and Reduce Transparency both want the same answer: a real opaque color,
        // no visual-effect view. For `.solid` we go all the way to pure black / white so the
        // chrome reads as the same surface as the physical notch.
        let wantsSolid = preferences.surfaceStyle == .solid || reduceTransparency

        if wantsSolid {
            let base: CGFloat = isDark ? 0 : 1
            return NookBackdropConfiguration(
                usesVisualEffect: false,
                material: .contentBackground,
                blendingMode: .behindWindow,
                darkenOpacity: 0,
                tintRed: 0,
                tintGreen: 0,
                tintBlue: 0,
                tintOpacity: 0,
                opaqueRed: base,
                opaqueGreen: base,
                opaqueBlue: base
            )
        }

        // Translucent: one frosted material per appearance, with a darken pass so chrome
        // content stays legible over a bright wallpaper.
        return NookBackdropConfiguration(
            usesVisualEffect: true,
            material: .sidebar,
            blendingMode: .behindWindow,
            darkenOpacity: isDark ? 0.52 : 0.10,
            tintRed: 0,
            tintGreen: 0,
            tintBlue: 0,
            tintOpacity: 0,
            opaqueRed: 0,
            opaqueGreen: 0,
            opaqueBlue: 0
        )
    }
}
