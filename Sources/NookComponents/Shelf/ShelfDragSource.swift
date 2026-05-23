// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import AppKit
import UniformTypeIdentifiers

/// Drag-OUT plumbing for one shelf item. Provides a `NSItemProvider` whose file
/// representation is a *promise*: the actual file copy runs only when the receiver
/// requests data, with security scope held around it.
///
/// This shape solves three problems that `NSItemProvider(contentsOf:)` did not:
///
/// 1. The shelf lives on a `.nonactivatingPanel`. Drags originated from a SwiftUI
///    hosting view inside such a panel often fail when the pasteboard item is bound
///    to the view's window lifetime — a deferred file representation registers
///    cheaply at drag-start and runs the file write only when the receiver accepts.
/// 2. Receivers that demand file *promises* (Mail compose, web upload widgets, many
///    sandboxed apps) reject contents-of providers but accept a promise.
/// 3. Under the App Sandbox, the bookmark must be resolved *with* security scope at
///    the moment of read. The write closure brackets `withResolvedURL`, so the
///    receiver always gets a readable file regardless of who reads it later.
///
/// Equivalent to `NSFilePromiseProvider` in spirit; uses `NSItemProvider`'s native
/// promise API so it composes directly with SwiftUI's `.onDrag`.

/// Errors a shelf drag can produce. Surfaced to the receiver via the
/// `NSItemProvider` file-representation completion handler; AppKit shows the standard
/// "couldn't be moved" alert.
enum ShelfDragError: LocalizedError {
    case unresolvable
    case temporaryDirectoryFailed

    var errorDescription: String? {
        switch self {
        case .unresolvable:
            return "The shelved file could not be located."
        case .temporaryDirectoryFailed:
            return "The shelf could not stage the file for drag-out."
        }
    }
}

/// Copies `item`'s contents to `destination`, holding security-scoped access around
/// the copy. Returns the error to forward to the file-representation completion
/// handler, or `nil` on success.
///
/// Synchronous on purpose: called from `NSItemProvider`'s file-representation closure
/// which AppKit dispatches off-main. `ShelfItem` is `Sendable` so it's safe to pass
/// across threads.
func writeShelfItem(_ item: ShelfItem, to destination: URL) -> Error? {
    let result: Result<Void, Error>? = item.withResolvedURL { source in
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    switch result {
    case .success: return nil
    case .failure(let error): return error
    case .none: return ShelfDragError.unresolvable
    }
}

/// Builds the drag-out item provider for `item`, registered with a promise-style file
/// representation. SwiftUI's `.onDrag` returns this.
///
/// The write closure runs off-main when the receiver requests data. It stages the
/// file into a fresh per-drag temporary directory (so concurrent drags can't collide
/// on the destination name), copies the contents under scope, and hands the URL to
/// the system. macOS clears temp directories on its usual schedule.
@MainActor
func makeShelfDragItemProvider(for item: ShelfItem) -> NSItemProvider {
    let utType = UTType(item.typeIdentifier) ?? .data
    let provider = NSItemProvider()
    provider.suggestedName = item.displayName

    // Capture by value — `ShelfItem` is `Sendable`. The closure must not capture the
    // host SwiftUI view or any actor-isolated state.
    let captured = item

    provider.registerFileRepresentation(
        forTypeIdentifier: utType.identifier,
        fileOptions: [],
        visibility: .all
    ) { completionHandler in
        let ext = captured.fileExtension.isEmpty ? "" : ".\(captured.fileExtension)"
        let stage = FileManager.default.temporaryDirectory
            .appendingPathComponent("nook-shelf-out-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: stage, withIntermediateDirectories: true)
        } catch {
            completionHandler(nil, false, ShelfDragError.temporaryDirectoryFailed)
            return nil
        }
        let destination = stage.appendingPathComponent(captured.displayName + ext)
        if let error = writeShelfItem(captured, to: destination) {
            completionHandler(nil, false, error)
        } else {
            // `coordinated: false` — the temp file we just minted needs no
            // NSFileCoordinator brokering for the receiver to read it.
            completionHandler(destination, false, nil)
        }
        return nil  // optional Progress; AppKit handles UI progress itself
    }
    return provider
}
