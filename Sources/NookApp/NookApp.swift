// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import AppKit
import NookKit
import SwiftUI

/// Library entry point shared by the SPM executable trampoline
/// (`Sources/NookExecutable/main.swift`) and the Xcode app target's
/// `App/main.swift`. Both call into the same boot sequence here so behavior
/// cannot drift between launch surfaces.
public enum NookApp {
    /// Synchronous entry point. The OS calls this from the process's main
    /// thread at startup, so we assert that invariant via
    /// `MainActor.assumeIsolated` and run the actual setup on the main actor.
    public static func main() {
        MainActor.assumeIsolated {
            let app = NSApplication.shared
            let delegate = AppDelegate()
            app.delegate = delegate
            app.setActivationPolicy(.accessory)
            app.run()
            withExtendedLifetime(delegate) {}
        }
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator: AppCoordinator
    private var statusItem: NSStatusItem?

    override init() {
        self.coordinator = AppCoordinator()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.start()
        installMenuBarFallback()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func installMenuBarFallback() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Nook")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Show Nook",
            action: #selector(showNook),
            keyEquivalent: ";"
        ))
        menu.addItem(NSMenuItem(
            title: "Settings…",
            action: #selector(showSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "Toggle Stay Expanded",
            action: #selector(toggleKeepOpen),
            keyEquivalent: "k"
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc private func showNook() {
        coordinator.showNook()
    }

    @objc private func showSettings() {
        coordinator.showSettings()
    }

    @objc private func toggleKeepOpen() {
        coordinator.toggleKeepNookOpen()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
