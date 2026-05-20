// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Foundation
import SwiftUI

/// Persistent personalization for the Nook chrome. Values map to Apple-style materials
/// and system accessibility behavior.
public struct NookAppearancePreferences: Equatable, Codable, Sendable {
    /// Follow the macOS appearance, or pin the chrome to dark / light.
    public var chromePalette: NookChromePalette

    /// Solid (opaque, matches the notch) or translucent (frosted, shows the wallpaper).
    public var surfaceStyle: NookSurfaceStyle

    /// When on, completion-style events play a one-shot trackpad haptic via
    /// `NSHapticFeedbackManager`. Off by default — macOS haptics only fire when the user's
    /// hand is on a Force Touch trackpad with system haptics enabled, so this is a bonus
    /// completion signal, never the primary feedback channel.
    public var hapticFeedbackEnabled: Bool

    public init(
        chromePalette: NookChromePalette = .followSystem,
        surfaceStyle: NookSurfaceStyle = .solid,
        hapticFeedbackEnabled: Bool = false
    ) {
        self.chromePalette = chromePalette
        self.surfaceStyle = surfaceStyle
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
    }

    public static let `default` = NookAppearancePreferences()

    private enum CodingKeys: String, CodingKey {
        case chromePalette
        case surfaceStyle
        case hapticFeedbackEnabled
    }

    // Custom decode so JSON written by an older build (missing a later-added field)
    // round-trips to the current defaults instead of failing the whole record back to
    // `.default` and wiping the user's saved preferences. To add a field: give it a
    // default in the initializer and a matching `decodeIfPresent` line here.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.chromePalette = try container.decodeIfPresent(NookChromePalette.self, forKey: .chromePalette) ?? .followSystem
        self.surfaceStyle = try container.decodeIfPresent(NookSurfaceStyle.self, forKey: .surfaceStyle) ?? .solid
        self.hapticFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticFeedbackEnabled) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chromePalette, forKey: .chromePalette)
        try container.encode(surfaceStyle, forKey: .surfaceStyle)
        try container.encode(hapticFeedbackEnabled, forKey: .hapticFeedbackEnabled)
    }
}

public enum NookChromePalette: String, Codable, Sendable, CaseIterable {
    case followSystem
    case dark
    case light
}

/// `.solid` paints the chrome the same opaque color as the menu-bar notch — true black on
/// dark, true white on light — so the expanded panel reads as one continuous surface.
/// `.translucent` shows the wallpaper through a frosted material instead.
public enum NookSurfaceStyle: String, Codable, Sendable, CaseIterable {
    case solid
    case translucent
}

// MARK: - Persistence

enum NookAppearanceStore {
    private static let defaultsKey = "opennook.appearance.v1"

    static func load() -> NookAppearancePreferences {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(NookAppearancePreferences.self, from: data)
        } catch {
            return .default
        }
    }

    static func save(_ preferences: NookAppearancePreferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            // Best-effort persistence; ignore encode failures.
        }
    }
}
