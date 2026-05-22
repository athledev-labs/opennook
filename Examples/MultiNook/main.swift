// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

// MultiNook — one host process, several interchangeable notch apps.
//
// A NookHostConfiguration registers a set of modules; the host shows one at a time and
// the user switches between them through the switcher strip at the top of the expanded
// surface, or with the module-cycle shortcut. Run with `swift run MultiNook`.

import NookApp
import SwiftUI

/// A plain home view shared by the example modules.
struct ModuleHome: View {
    let headline: String
    let detail: String
    let symbol: String
    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(theme.secondaryLabel)
            Text(headline)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.primaryLabel)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(theme.tertiaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

/// A module that carries its own product state — a launch counter persisted in the
/// module's isolated `UserDefaults` suite. Shows the full `NookModule` protocol; the
/// simpler modules below register a `NookConfiguration` closure directly.
@MainActor
final class CounterModule: NookModule {
    static let moduleDescriptor = NookModuleDescriptor(
        id: "com.opennook.example.counter",
        displayName: "Counter",
        icon: "number",
        accent: .orange
    )

    let descriptor = CounterModule.moduleDescriptor
    private let context: NookModuleContext
    private let launchCount: Int

    init(context: NookModuleContext) {
        self.context = context
        let previous = context.defaults.integer(forKey: "launchCount")
        self.launchCount = previous + 1
        context.defaults.set(launchCount, forKey: "launchCount")
    }

    func makeConfiguration() -> NookConfiguration {
        let count = launchCount
        var configuration = NookConfiguration()
        configuration.setHome {
            ModuleHome(
                headline: "Counter module",
                detail: "Opened \(count) time\(count == 1 ? "" : "s") — persisted in this module's own suite.",
                symbol: "number"
            )
        }
        configuration.topBarLeadingTitle = { _ in "Counter" }
        configuration.topBarLeadingIcon = "number"
        return configuration
    }
}

func clockConfiguration() -> NookConfiguration {
    var configuration = NookConfiguration()
    configuration.setHome {
        ModuleHome(
            headline: "Clock module",
            detail: "A second notch app sharing the same surface.",
            symbol: "clock"
        )
    }
    configuration.topBarLeadingTitle = { _ in "Clock" }
    configuration.topBarLeadingIcon = "clock"
    return configuration
}

func notesConfiguration() -> NookConfiguration {
    var configuration = NookConfiguration()
    configuration.setHome {
        ModuleHome(
            headline: "Notes module",
            detail: "Switch with the strip above, or press Control-Option-Grave.",
            symbol: "note.text"
        )
    }
    configuration.topBarLeadingTitle = { _ in "Notes" }
    configuration.topBarLeadingIcon = "note.text"
    return configuration
}

var host = NookHostConfiguration()

host.register(CounterModule.moduleDescriptor) { context in
    CounterModule(context: context)
}
host.register(
    NookModuleDescriptor(
        id: "com.opennook.example.clock",
        displayName: "Clock",
        icon: "clock",
        accent: .blue
    ),
    configuration: clockConfiguration
)
host.register(
    NookModuleDescriptor(
        id: "com.opennook.example.notes",
        displayName: "Notes",
        icon: "note.text",
        accent: .green
    ),
    configuration: notesConfiguration
)

// Control-Option-Grave cycles to the next module. (Carbon: controlKey | optionKey.)
host.moduleCycleHotkey = NookHotkey(keyCode: 50, carbonModifiers: 4096 | 2048, keySymbol: "`")
host.defaultModule = CounterModule.moduleDescriptor.id

NookApp.main(host)
