// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the MIT License.
// See /LICENSE-MIT-NOOKSURFACE for the modifications license.

import AppKit
import SwiftUI

/// What the chrome paints behind compact and expanded nook content.
///
/// Two intentionally disjoint cases:
///
/// - ``vibrancy(_:)`` paints an `NSVisualEffectView` material with an optional darken
///   pass on top — the default frosted look, used when translucency is allowed.
/// - ``solid(_:)`` paints a flat opaque fill — used for `.solid` chrome styles and
///   whenever Reduce Transparency is on, where `NSVisualEffectView` is avoided.
///
/// These are *modes*, not flags. A caller picks one and supplies only the parameters
/// that mode needs — no more eleven-field configuration struct where half the fields
/// are dead per branch.
///
/// Extending to e.g. `.gradient(Gradient)` or `.material(Material)` later is one new
/// case and one new view branch; existing callers keep compiling.
public enum NookBackdrop: Equatable, Sendable {
    /// Frosted vibrancy: a system material with an optional black overlay for
    /// legibility on bright wallpapers.
    case vibrancy(Vibrancy)

    /// Flat opaque fill. Use this for `.solid` chrome styles and when Reduce
    /// Transparency is on — it avoids `NSVisualEffectView` entirely.
    case solid(Color)

    /// Vibrancy parameters: which material to render, how to blend it against the
    /// content below the window, and how much darken to composite over it.
    public struct Vibrancy: Equatable, Sendable {
        /// The `NSVisualEffectView.Material` to render. `.sidebar` is the
        /// framework default; it matches Apple's translucent chrome conventions.
        public var material: NSVisualEffectView.Material

        /// `.behindWindow` (the default) samples the desktop wallpaper through the
        /// nook window. `.withinWindow` samples sibling content within the window.
        public var blendingMode: NSVisualEffectView.BlendingMode

        /// 0...1 black overlay composited on top of the material for legibility.
        /// 0 disables the darken pass entirely.
        public var darkenOpacity: CGFloat

        public init(
            material: NSVisualEffectView.Material = .sidebar,
            blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
            darkenOpacity: CGFloat = 0
        ) {
            self.material = material
            self.blendingMode = blendingMode
            self.darkenOpacity = darkenOpacity
        }
    }

    /// The default backdrop — a pure black solid, matching the menu-bar notch chrome
    /// when no other treatment is wanted. Equivalent to the historical
    /// `NookBackdropConfiguration.solidBlack`; rendering is byte-identical.
    public static let solidBlack = NookBackdrop.solid(.black)
}
