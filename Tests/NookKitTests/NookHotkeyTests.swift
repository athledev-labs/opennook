// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Carbon
import XCTest
@testable import NookKit

final class NookHotkeyTests: XCTestCase {
    func testDefaultHotkeyDisplaysCanonicalGlyphs() {
        // The default is Command-Option-Semicolon. macOS renders modifiers in canonical
        // order (⌃⌥⇧⌘) — Command is always last, so this shows as "⌥⌘;".
        XCTAssertEqual(NookHotkey.default.displaySymbols, ["⌥", "⌘", ";"])
        XCTAssertEqual(NookHotkey.default.display, "⌥⌘;")
    }

    func testModifierSymbolsAreInCanonicalOrder() {
        let hotkey = NookHotkey(
            keyCode: 0,
            carbonModifiers: UInt32(cmdKey | optionKey | controlKey | shiftKey),
            keySymbol: "A"
        )
        XCTAssertEqual(hotkey.modifierSymbols, ["⌃", "⌥", "⇧", "⌘"])
        XCTAssertEqual(hotkey.display, "⌃⌥⇧⌘A")
    }

    func testRoundTripThroughJSON() throws {
        let original = NookHotkey(
            keyCode: 49,
            carbonModifiers: UInt32(cmdKey | controlKey),
            keySymbol: "Space"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NookHotkey.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
