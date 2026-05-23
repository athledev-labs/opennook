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

/// A durable description of a global hotkey that failed to register. Carries the
/// human-facing shortcut name and the combination that was rejected, so Settings can
/// tell the user *which* shortcut is unavailable rather than a single shared string.
public struct HotkeyRegistrationFailure: Equatable, Sendable {
    /// Human-readable name of the shortcut, e.g. `"Show Nook"` or a module's display name.
    public let shortcutName: String
    /// The key combination that failed to register, e.g. `"⌥⌘;"`.
    public let combination: String

    public init(shortcutName: String, combination: String) {
        self.shortcutName = shortcutName
        self.combination = combination
    }

    /// A ready-to-show one-line warning for the Settings UI.
    public var message: String {
        "\(combination) is unavailable — another app may be using it."
    }
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

    /// When on, the expanded nook stays open past hover-exit. Backed by
    /// ``NookAppearancePreferences/keepNookOpen`` so it persists across launches;
    /// reading or writing it goes through `appearancePreferences`.
    public var keepNookOpen: Bool {
        get { appearancePreferences.keepNookOpen }
        set {
            guard newValue != appearancePreferences.keepNookOpen else { return }
            var preferences = appearancePreferences
            preferences.keepNookOpen = newValue
            replaceAppearancePreferences(preferences)
        }
    }

    /// `true` while the nook surface is expanded. This is a read-only mirror of the
    /// surface's own ``NookState`` — the coordinator binds it to `Nook.$state`, so it
    /// stays accurate for hover- and drag-driven transitions too, not just
    /// coordinator-initiated show/hide. Drive visibility through ``AppCoordinator``,
    /// never by writing this.
    ///
    /// This is purely a view-model mirror. It is NOT consulted by the surface arbiter
    /// to decide "is the user engaged" — see ``AppCoordinator/isUserEngaged``, which
    /// reads an explicit user-intent flag to avoid mistaking the arbiter's own expand
    /// for user engagement.
    @Published public internal(set) var isNookVisible = false

    /// Transient status channel — a short-lived message tied to a single nook session.
    /// Cleared by ``resetTransientStatus()`` on every show/toggle. Hotkey-registration
    /// failures must NOT live here: they outlive a nook session and need to stay visible
    /// until the registration is fixed. Those use ``hotkeyRegistrationFailures`` instead.
    @Published public var errorMessage: String?

    /// Durable hotkey-registration failures, keyed by ``HotkeyController`` registration id
    /// (`"toggle"`, `"cycle"`, `"module.<id>"`). Each value is a human-readable failure
    /// for that specific shortcut. Unlike ``errorMessage`` this is NOT cleared by
    /// ``resetTransientStatus()``: a failed registration stays surfaced until that
    /// registration actually succeeds (or the offending hotkey is changed), at which
    /// point the coordinator clears that id's entry. Each entry reflects the CURRENT
    /// outcome of its registration — not a last-writer-wins shared string.
    @Published public internal(set) var hotkeyRegistrationFailures: [String: HotkeyRegistrationFailure] = [:]

    /// Records the outcome of one hotkey registration attempt: `failure` non-nil keeps
    /// the entry, `nil` clears it. Called by the coordinator after every (re-)register.
    func recordHotkeyRegistration(id: String, failure: HotkeyRegistrationFailure?) {
        if let failure {
            hotkeyRegistrationFailures[id] = failure
        } else {
            hotkeyRegistrationFailures.removeValue(forKey: id)
        }
    }

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
