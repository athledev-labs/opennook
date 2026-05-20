// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import AppKit
import SwiftUI

/// Resolved palette for one layout pass: respects the chrome palette, system appearance,
/// and Reduce Transparency.
///
/// Every color is built **explicitly** from black or white at a fixed opacity — never from
/// system-adaptive colors like `Color.primary`. A nook lives on a non-activating panel
/// whose SwiftUI `colorScheme` environment is unreliable, so an adaptive color could resolve
/// for the wrong appearance (e.g. white text on the white light-mode panel). Resolving the
/// appearance once, here, and emitting concrete colors keeps light and dark both correct.
public struct NookResolvedTheme: Sendable {
    public var primaryLabel: Color
    public var secondaryLabel: Color
    public var tertiaryLabel: Color
    public var quaternaryLabel: Color

    public var subtleFill: Color
    public var subtleStroke: Color

    public var headerInactiveIcon: Color

    public static func resolve(
        preferences: NookAppearancePreferences,
        effectiveColorScheme: ColorScheme,
        reduceTransparency: Bool
    ) -> NookResolvedTheme {
        let isDark: Bool = switch preferences.chromePalette {
        case .followSystem:
            effectiveColorScheme == .dark
        case .dark:
            true
        case .light:
            false
        }

        // `trueSolid` = the user picked the solid surface. `isSolid` = we're painting solid
        // either way (solid surface, or Reduce Transparency forcing it). Inner fills need a
        // touch more contrast on a true-solid black/white panel than on a frosted one.
        let trueSolid = preferences.surfaceStyle == .solid
        let isSolid = trueSolid || reduceTransparency

        if isDark {
            return NookResolvedTheme(
                primaryLabel: Color.white.opacity(0.95),
                secondaryLabel: Color.white.opacity(0.62),
                tertiaryLabel: Color.white.opacity(0.46),
                quaternaryLabel: Color.white.opacity(0.34),
                subtleFill: Color.white.opacity(isSolid ? (trueSolid ? 0.07 : 0.12) : 0.055),
                subtleStroke: Color.white.opacity(0.14),
                headerInactiveIcon: Color.white.opacity(0.42)
            )
        }

        return NookResolvedTheme(
            primaryLabel: Color.black.opacity(0.88),
            secondaryLabel: Color.black.opacity(0.55),
            tertiaryLabel: Color.black.opacity(0.42),
            quaternaryLabel: Color.black.opacity(0.32),
            subtleFill: Color.black.opacity(isSolid ? (trueSolid ? 0.045 : 0.055) : 0.030),
            subtleStroke: Color.black.opacity(0.09),
            headerInactiveIcon: Color.black.opacity(0.38)
        )
    }
}

// MARK: - SwiftUI environment

private struct NookResolvedThemeKey: EnvironmentKey {
    static let defaultValue = NookResolvedTheme.resolve(
        preferences: .default,
        effectiveColorScheme: .dark,
        reduceTransparency: false
    )
}

public extension EnvironmentValues {
    var nookResolvedTheme: NookResolvedTheme {
        get { self[NookResolvedThemeKey.self] }
        set { self[NookResolvedThemeKey.self] = newValue }
    }
}

public extension NookResolvedTheme {
    /// Resolves chrome using saved prefs, **`NSApp.effectiveAppearance`** for “Match Mac”
    /// (SwiftUI’s `colorScheme` is unreliable on menu-bar panels), and Reduce Transparency.
    static func live(appState: AppState) -> NookResolvedTheme {
        let systemScheme: ColorScheme =
            NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
        let scheme = appState.appearancePreferences.effectiveColorScheme(systemScheme: systemScheme)
        return resolve(
            preferences: appState.appearancePreferences,
            effectiveColorScheme: scheme,
            reduceTransparency: NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        )
    }
}

public extension NookAppearancePreferences {
    /// When non-nil, apply as SwiftUI `preferredColorScheme` so Dark/Light chrome overrides stick on panel-hosted UI.
    var chromeColorSchemeOverride: ColorScheme? {
        switch chromePalette {
        case .followSystem:
            nil
        case .dark:
            .dark
        case .light:
            .light
        }
    }

    func effectiveColorScheme(systemScheme: ColorScheme) -> ColorScheme {
        switch chromePalette {
        case .followSystem:
            systemScheme
        case .dark:
            .dark
        case .light:
            .light
        }
    }

    /// The `NSAppearance` to pin on the chrome window, or `nil` to follow the system.
    /// Drives the backdrop's `NSVisualEffectView` material so a forced theme renders right.
    var chromeAppearanceOverride: NSAppearance? {
        switch chromePalette {
        case .followSystem:
            nil
        case .dark:
            NSAppearance(named: .darkAqua)
        case .light:
            NSAppearance(named: .aqua)
        }
    }
}
