// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Foundation
import NookSurface

public extension AppCoordinator {
    /// Deterministic expand-then-compact cycle for launch smoke tests
    /// (`OPENNOOK_SMOKE_TEST=1`). Returns `false` if any step times out.
    func runLaunchSmokeTest(timeout: TimeInterval = 20) async -> Bool {
        guard await waitForSurfaceState(.compact, timeout: timeout) else { return false }
        showNook()
        guard await waitForSurfaceState(.expanded, timeout: timeout) else { return false }
        guard appState.isNookVisible else { return false }
        hideNook()
        return await waitForSurfaceState(.compact, timeout: timeout)
    }

    /// Expands the chrome and waits for the expanded state. Used by UI smoke tests
    /// (`OPENNOOK_UI_SMOKE_TEST=1`) so XCUITest can assert on the real panel window.
    func prepareForUISmokeTest(timeout: TimeInterval = 20) async -> Bool {
        guard await waitForSurfaceState(.compact, timeout: timeout) else { return false }
        showNook()
        return await waitForSurfaceState(.expanded, timeout: timeout)
    }

    private func waitForSurfaceState(_ expected: NookState, timeout: TimeInterval) async -> Bool {
        let pollNanoseconds: UInt64 = 50_000_000
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if surface.state == expected { return true }
            try? await Task.sleep(nanoseconds: pollNanoseconds)
        }
        return surface.state == expected
    }
}
