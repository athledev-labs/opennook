// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import AppKit
import Foundation

enum NookLaunchSmoke {
    static var runsExitSmokeTest: Bool {
        ProcessInfo.processInfo.environment["OPENNOOK_SMOKE_TEST"] == "1"
    }

    static var runsUISmokeTest: Bool {
        ProcessInfo.processInfo.environment["OPENNOOK_UI_SMOKE_TEST"] == "1"
    }

    @MainActor
    static func handleLaunch(coordinator: AppCoordinator) {
        if runsExitSmokeTest {
            Task {
                let ok = await coordinator.runLaunchSmokeTest()
                exit(ok ? EXIT_SUCCESS : EXIT_FAILURE)
            }
            return
        }

        if runsUISmokeTest {
            Task {
                guard await coordinator.prepareForUISmokeTest() else {
                    exit(EXIT_FAILURE)
                }
                guard verifyPanelWindow() else {
                    exit(EXIT_FAILURE)
                }
                exit(EXIT_SUCCESS)
            }
        }
    }

    @MainActor
    private static func verifyPanelWindow() -> Bool {
        NSApplication.shared.windows.contains { window in
            window.accessibilityIdentifier() == "opennook.panel"
                && window.frame.width > 100
                && window.frame.height > 20
        }
    }
}
