// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import AppKit
import CoreGraphics

/// Resolves a ``NookDisplayPreference`` to a concrete `NSScreen`, and enumerates the
/// attached displays for settings UI.
///
/// The tricky part of multi-display support is *stable* identity: `CGDirectDisplayID`
/// and `NSScreen` ordering both shuffle as displays connect and disconnect, so a saved
/// preference can't reference them directly. The display *UUID*
/// (`CGDisplayCreateUUIDFromDisplayID`) is stable across reconnects, so that's what
/// ``NookDisplayPreference/specific(_:)`` persists and what this type matches against.
public enum NookScreenLocator {
    /// A currently-attached display, as surfaced to settings UI.
    public struct DisplayInfo: Identifiable, Equatable, Sendable {
        /// Stable display UUID — the value stored in ``NookDisplayPreference``.
        public let uuid: String
        /// Human-readable name (`NSScreen.localizedName`), e.g. "Built-in Retina Display".
        public let name: String
        /// `true` for the Mac's built-in panel.
        public let isBuiltIn: Bool

        public var id: String { uuid }
    }

    /// The `CGDirectDisplayID` backing a screen. Transient — valid only for the current
    /// display arrangement; never persist it.
    public static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? NSNumber)?.uint32Value
    }

    /// Stable UUID string for a display ID, surviving unplug/replug. `nil` for the rare
    /// display that exposes no UUID (some virtual/streamed displays).
    public static func uuid(for displayID: CGDirectDisplayID) -> String? {
        guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return nil
        }
        return CFUUIDCreateString(nil, cfUUID) as String
    }

    /// Stable UUID string for a screen.
    public static func uuid(for screen: NSScreen) -> String? {
        guard let id = displayID(for: screen) else { return nil }
        return uuid(for: id)
    }

    /// Every currently-attached display, for populating a display picker.
    public static func connectedDisplays() -> [DisplayInfo] {
        NSScreen.screens.compactMap { screen in
            guard let id = displayID(for: screen), let uuid = uuid(for: id) else { return nil }
            return DisplayInfo(
                uuid: uuid,
                name: screen.localizedName,
                isBuiltIn: CGDisplayIsBuiltin(id) != 0
            )
        }
    }

    /// Resolve a preference to a concrete screen.
    ///
    /// The fallback chain keeps the chrome on-screen even when the chosen display is
    /// unplugged: a `.specific` display that isn't attached, or a `.builtIn` request on a
    /// desktop Mac, both degrade to built-in → main → first-attached rather than vanishing.
    /// Returns `nil` only when no display is attached at all.
    public static func screen(matching preference: NookDisplayPreference) -> NSScreen? {
        switch preference.mode {
        case .specific:
            if let uuid = preference.displayUUID,
               let match = NSScreen.screens.first(where: { Self.uuid(for: $0) == uuid }) {
                return match
            }
            return builtInScreen() ?? NSScreen.main ?? NSScreen.screens.first
        case .builtIn:
            return builtInScreen() ?? NSScreen.main ?? NSScreen.screens.first
        case .main:
            return NSScreen.main ?? builtInScreen() ?? NSScreen.screens.first
        }
    }

    /// The Mac's built-in panel, if one is attached.
    public static func builtInScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let id = displayID(for: screen) else { return false }
            return CGDisplayIsBuiltin(id) != 0
        }
    }
}
