// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import SwiftUI

/// The host-app registration seam — everything a notch app customizes without forking
/// the framework.
///
/// Pass one to `NookApp.main(_:)`. The default value reproduces the demo exactly, so
/// `NookApp.main()` is unchanged. The common case is a single registered view:
///
/// ```swift
/// NookApp.main { MyHomeView() }
/// ```
///
/// The fuller form reaches every knob:
///
/// ```swift
/// var configuration = NookConfiguration()
/// configuration.setHome { MyHomeView() }
/// configuration.setCompactTrailing { MyGlyph() }
/// configuration.theme = { appState in MyPalette.resolve(appState) }
/// configuration.onExpand = { print("nook expanded") }
/// NookApp.main(configuration)
/// ```
///
/// > Note: This is a *registration* entry point, distinct from the `NookSurface`-level
/// > customization types (`NookStyle`, `NookHoverBehavior`, …). It exists so a host can
/// > depend on the package and customize through public API only.
public struct NookConfiguration {
    /// The expanded home surface, shown between the framework top bar and Settings.
    /// Use ``setHome(_:)`` to set it from a `@ViewBuilder`.
    public var home: () -> AnyView

    /// Content for the compact slot to the **left** of the notch. Use
    /// ``setCompactLeading(_:)`` to set it from a `@ViewBuilder`.
    public var compactLeading: () -> AnyView

    /// Content for the compact slot to the **right** of the notch. Use
    /// ``setCompactTrailing(_:)`` to set it from a `@ViewBuilder`.
    public var compactTrailing: () -> AnyView

    /// Resolves the chrome palette. Defaults to ``NookResolvedTheme/live(appState:)``;
    /// supply a closure returning a host-built ``NookResolvedTheme`` to theme the chrome.
    public var theme: (AppState) -> NookResolvedTheme

    /// Called when the chrome transitions into the expanded surface (from any source).
    public var onExpand: (() -> Void)?

    /// Called when the chrome transitions into the compact pill.
    public var onCompact: (() -> Void)?

    /// Called when the chrome transitions into the hidden state.
    public var onHide: (() -> Void)?

    /// Creates a configuration matching the framework demo: the placeholder home view,
    /// the default compact glyphs, the live system theme, and no lifecycle callbacks.
    public init() {
        home = { AnyView(NookPlaceholderHomeView()) }
        compactLeading = { AnyView(NookCompactLeadingView()) }
        compactTrailing = { AnyView(NookCompactTrailingView()) }
        theme = NookResolvedTheme.live
    }

    /// Registers the expanded home surface from a `@ViewBuilder` closure.
    public mutating func setHome<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        home = { AnyView(content()) }
    }

    /// Registers the left compact-slot content from a `@ViewBuilder` closure.
    public mutating func setCompactLeading<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        compactLeading = { AnyView(content()) }
    }

    /// Registers the right compact-slot content from a `@ViewBuilder` closure.
    public mutating func setCompactTrailing<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        compactTrailing = { AnyView(content()) }
    }
}
