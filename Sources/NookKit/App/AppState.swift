// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Combine
import Foundation

public enum NookViewMode: Equatable, Sendable {
    case home
    case settings
}

/// Mutable, observable state shared between the coordinator and views.
/// Holds chrome-level concerns (view mode, appearance, keep-open, visibility) — product
/// data lives in whatever model layer a downstream fork adds on top.
public final class AppState: ObservableObject {
    @Published public private(set) var viewMode: NookViewMode = .home
    @Published public var appearancePreferences = NookAppearancePreferences.default
    @Published public var hotkey = NookHotkey.default

    /// Which display the Nook chrome appears on. The coordinator projects this onto
    /// the surface (`Nook.screenProvider`) and re-places the chrome when it changes.
    @Published public var displayPreference = NookDisplayPreference.default
    @Published public var keepNookOpen = false
    @Published public var isNookVisible = false
    @Published public var errorMessage: String?

    /// `true` while the user is recording a new global hotkey in Settings. The coordinator
    /// watches this and suspends the live hotkey registration so the old shortcut can't
    /// fire mid-capture.
    @Published public var isRecordingHotkey = false

    /// Mirrors `Nook.isDragInFlight`. `true` while a system file-drag session is over the
    /// panel — kept as a hook-point for downstream consumers that want drop targets.
    @Published public var isDragInFlight: Bool = false

    public init() {
        appearancePreferences = NookAppearanceStore.load()
        hotkey = NookHotkeyStore.load()
        displayPreference = NookDisplayStore.load()
    }

    public func replaceAppearancePreferences(_ preferences: NookAppearancePreferences) {
        guard preferences != appearancePreferences else {
            return
        }
        appearancePreferences = preferences
        NookAppearanceStore.save(preferences)
    }

    public func replaceHotkey(_ hotkey: NookHotkey) {
        guard hotkey != self.hotkey else {
            return
        }
        self.hotkey = hotkey
        NookHotkeyStore.save(hotkey)
    }

    public func replaceDisplayPreference(_ preference: NookDisplayPreference) {
        guard preference != displayPreference else {
            return
        }
        displayPreference = preference
        NookDisplayStore.save(preference)
    }

    public var isHomeView: Bool {
        viewMode == .home
    }

    public var isSettingsView: Bool {
        viewMode == .settings
    }

    public func showHome() {
        viewMode = .home
        resetTransientStatus()
    }

    public func showSettings() {
        viewMode = .settings
        resetTransientStatus()
    }

    public func resetTransientStatus() {
        errorMessage = nil
    }
}
