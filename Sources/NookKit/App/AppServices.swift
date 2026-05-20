// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Foundation
import SwiftUI

/// Dependency container threaded into views via the SwiftUI environment.
/// Empty by default — downstream forks add services here (clipboard, link-metadata,
/// transcription, whatever) so each view's init signature stays put.
///
/// Not `@MainActor` so SwiftUI's `EnvironmentKey.defaultValue = AppServices()` initializer
/// stays callable from any context.
public final class AppServices {
    public init() {}
}

private struct AppServicesEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppServices = AppServices()
}

public extension EnvironmentValues {
    var appServices: AppServices {
        get { self[AppServicesEnvironmentKey.self] }
        set { self[AppServicesEnvironmentKey.self] = newValue }
    }
}
