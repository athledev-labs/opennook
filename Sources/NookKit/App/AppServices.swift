// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Foundation
import SwiftUI

/// A per-module dependency container, threaded into a module's views via the SwiftUI
/// environment (`\.appServices`).
///
/// Each ``NookModule`` gets its own `AppServices` through its ``NookModuleContext``, so
/// two modules in the same host process never share or collide on services. A module
/// registers what it needs by type and its views resolve it back the same way:
///
/// ```swift
/// context.services.register(ClipboardService())
/// // ...in a view:
/// @Environment(\.appServices) private var services
/// let clipboard = services.resolve(ClipboardService.self)
/// ```
///
/// Expected to be used from the main actor: registration happens when a module is
/// constructed, resolution happens during view rendering. It is intentionally not
/// `@MainActor` so SwiftUI's `EnvironmentKey.defaultValue` initializer stays callable
/// from any context.
public final class AppServices {
    private var storage: [ObjectIdentifier: Any] = [:]

    public init() {}

    /// Registers `service`, keyed by its own type. A later registration of the same
    /// type replaces the earlier one.
    public func register<Service>(_ service: Service) {
        storage[ObjectIdentifier(Service.self)] = service
    }

    /// Returns the registered service of the requested type, or `nil` if none was
    /// registered.
    public func resolve<Service>(_ type: Service.Type) -> Service? {
        storage[ObjectIdentifier(type)] as? Service
    }

    /// Subscript form of ``register(_:)`` / ``resolve(_:)``.
    public subscript<Service>(_ type: Service.Type) -> Service? {
        get { storage[ObjectIdentifier(type)] as? Service }
        set { storage[ObjectIdentifier(type)] = newValue }
    }
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
