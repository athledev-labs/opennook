// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import XCTest
@testable import NookKit

final class AppStateTests: XCTestCase {
    func testViewModeHelpersKeepHomeAndSettingsExclusive() {
        let state = AppState()

        XCTAssertTrue(state.isHomeView)
        XCTAssertFalse(state.isSettingsView)

        state.showSettings()
        XCTAssertEqual(state.viewMode, .settings)
        XCTAssertFalse(state.isHomeView)
        XCTAssertTrue(state.isSettingsView)

        state.showHome()
        XCTAssertEqual(state.viewMode, .home)
        XCTAssertTrue(state.isHomeView)
        XCTAssertFalse(state.isSettingsView)
    }

    func testResetTransientStatusClearsError() {
        let state = AppState()
        state.errorMessage = "Something broke"

        state.resetTransientStatus()

        XCTAssertNil(state.errorMessage)
    }
}
