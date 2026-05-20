// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Kai Azim — DynamicNotchKit (original)
// Copyright (c) 2026 Glendon Chin — OpenNook modifications
//
// Licensed under the MIT License.
// Original kit license: /ThirdPartyLicenses/DynamicNotchKit.txt
// Modifications license: /LICENSE-MIT-NOOKSURFACE

import AppKit

/// Borderless, screen-saver-level panel that hosts the nook chrome above all spaces.
final class NookPanel: NSPanel {
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
        self.hasShadow = false
        self.backgroundColor = .clear
        // `.statusBar + 8` keeps the chrome above ordinary windows (and the menu bar
        // itself) without going so high that AppKit skips us for drag-and-drop
        // delivery — `.screenSaver` is silently undeliverable for system drag sessions.
        self.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 8)
        // `.canJoinAllSpaces` + `.stationary` keep the chrome pinned across Spaces;
        // `.fullScreenAuxiliary` lets it stay visible when another app goes fullscreen
        // (without it the notch UI vanishes the moment any window is fullscreened);
        // `.ignoresCycle` keeps the panel out of Cmd-Tab and the window cycle.
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle,
        ]
    }

    override var canBecomeKey: Bool {
        true
    }
}

/// Transparent overlay view that intercepts AppKit drag-and-drop events and forwards
/// them to a `NookDragDestination`. Sits on top of the SwiftUI hosting view so drag
/// events reach us before `NSHostingView` swallows them — `hitTest(_:)` returns `nil`
/// so mouse events pass through to the SwiftUI surface untouched.
///
/// Drag handling can't live on the panel itself — `NSDraggingDestination` is informal
/// on `NSWindow` in Swift, and `NSHostingView` has its own internal drag-types
/// registration that consumes events before they reach a parent NSView. Routing
/// through this overlay is the standard AppKit pattern that survives both.
final class NookDragInterceptingView: NSView {
    weak var dragDestination: NookDragDestination?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Pass mouse events through to whatever sits below us in the view hierarchy
    /// (the SwiftUI hosting view). Drag-and-drop uses a separate AppKit code path
    /// that doesn't go through `hitTest(_:)`, so this only neutralizes pointer
    /// interactions — drag events still land in `draggingEntered(_:)` etc.
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = readFileURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else { return [] }
        return dragDestination?.nookPanelDraggingEntered(urls) ?? []
    }

    /// Forward updates as `entered` again — `Nook` is idempotent on enter — so the
    /// returned drag operation stays accurate as the cursor moves within the view.
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = readFileURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else { return [] }
        return dragDestination?.nookPanelDraggingEntered(urls) ?? []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        dragDestination?.nookPanelDraggingExited()
    }

    /// Drag session ended without entering us. Mirrors `draggingExited` so the
    /// "stateBeforeDrag" restore path runs even if the user dropped elsewhere.
    override func draggingEnded(_ sender: NSDraggingInfo) {
        dragDestination?.nookPanelDraggingExited()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        !readFileURLs(from: sender.draggingPasteboard).isEmpty
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = readFileURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else { return false }
        return dragDestination?.nookPanelPerformDrop(urls) ?? false
    }

    private func readFileURLs(from pasteboard: NSPasteboard) -> [URL] {
        guard let items = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return []
        }
        return items
    }
}
