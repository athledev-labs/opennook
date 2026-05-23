// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import UniformTypeIdentifiers
import XCTest
@testable import NookComponents

/// Pins the file-promise drag-out plumbing — the bookmark-resolve + scoped-copy path
/// the receiver eventually triggers. The receiver-side trigger itself (AppKit calling
/// the registered `NSItemProvider` representation) is an integration concern out of
/// unit-test reach; what we CAN test deterministically is the write closure.
@MainActor
final class ShelfDragSourceTests: XCTestCase {
    private func makeTempFile(contents: String = "nook drag-out") throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("nook-drag-src-\(UUID().uuidString)")
            .appendingPathExtension("txt")
        try Data(contents.utf8).write(to: url)
        return url
    }

    private func makeTempStage() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nook-drag-dst-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// The write closure copies the source file's contents to the destination URL.
    func testWriteShelfItemCopiesContentsToDestination() throws {
        let source = try makeTempFile(contents: "OPENNOOK")
        defer { try? FileManager.default.removeItem(at: source) }
        let stage = try makeTempStage()
        defer { try? FileManager.default.removeItem(at: stage) }
        let item = ShelfItem.make(from: source)!

        let destination = stage.appendingPathComponent("out.txt")
        let error = writeShelfItem(item, to: destination)
        XCTAssertNil(error)

        let written = try Data(contentsOf: destination)
        XCTAssertEqual(written, Data("OPENNOOK".utf8))
    }

    /// An unresolvable bookmark produces `ShelfDragError.unresolvable` — the receiver
    /// gets a meaningful error rather than a silent failure or a crash.
    func testWriteShelfItemReportsErrorWhenSourceUnresolvable() throws {
        let stage = try makeTempStage()
        defer { try? FileManager.default.removeItem(at: stage) }

        // Synthesise a ShelfItem with a deliberately broken bookmark.
        let broken = ShelfItem(
            id: UUID(),
            displayName: "ghost",
            fileExtension: "txt",
            addedAt: Date(),
            bookmark: Data(repeating: 0xff, count: 32),
            typeIdentifier: UTType.plainText.identifier,
            bookmarkKind: .nonScoped
        )
        let destination = stage.appendingPathComponent("ghost.txt")
        let error = writeShelfItem(broken, to: destination)
        XCTAssertNotNil(error)
        XCTAssertTrue(error is ShelfDragError)
        XCTAssertEqual(error as? ShelfDragError, .unresolvable)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    /// If the destination already exists (a retry, or AppKit's at-least-once delivery),
    /// the write overwrites it cleanly instead of throwing on the second attempt.
    func testWriteShelfItemOverwritesExistingDestination() throws {
        let source = try makeTempFile(contents: "FRESH")
        defer { try? FileManager.default.removeItem(at: source) }
        let stage = try makeTempStage()
        defer { try? FileManager.default.removeItem(at: stage) }
        let item = ShelfItem.make(from: source)!

        let destination = stage.appendingPathComponent("dup.txt")
        try Data("STALE".utf8).write(to: destination)

        let error = writeShelfItem(item, to: destination)
        XCTAssertNil(error)
        let written = try Data(contentsOf: destination)
        XCTAssertEqual(written, Data("FRESH".utf8), "the new write replaces the prior contents")
    }

    /// The drag NSItemProvider registers itself for the item's UTI so receivers can
    /// decide whether to accept the drag before committing.
    func testDragItemProviderRegistersFileRepresentationForTypeIdentifier() throws {
        let source = try makeTempFile()
        defer { try? FileManager.default.removeItem(at: source) }
        let item = ShelfItem.make(from: source)!

        let provider = makeShelfDragItemProvider(for: item)
        XCTAssertEqual(provider.suggestedName, item.displayName)
        XCTAssertTrue(
            provider.registeredTypeIdentifiers.contains(item.typeIdentifier),
            "provider must advertise the item's UTI so receivers can match the drag"
        )
    }
}
