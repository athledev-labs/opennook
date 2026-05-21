// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import NookSurface
import XCTest

final class NookPresentationTests: XCTestCase {
    /// `.auto` is the whole point of the non-notch fallback: notch layout on a notched
    /// display, floating layout everywhere else.
    func testAutoFollowsTheDisplay() {
        XCTAssertFalse(NookPresentation.auto.isFloating(screenHasNotch: true))
        XCTAssertTrue(NookPresentation.auto.isFloating(screenHasNotch: false))
    }

    /// Forced modes ignore the display entirely.
    func testForcedModesIgnoreTheDisplay() {
        XCTAssertFalse(NookPresentation.notch.isFloating(screenHasNotch: true))
        XCTAssertFalse(NookPresentation.notch.isFloating(screenHasNotch: false))
        XCTAssertTrue(NookPresentation.floating.isFloating(screenHasNotch: true))
        XCTAssertTrue(NookPresentation.floating.isFloating(screenHasNotch: false))
    }

    func testRoundTripThroughJSON() throws {
        for original in NookPresentation.allCases {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(NookPresentation.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }
}
