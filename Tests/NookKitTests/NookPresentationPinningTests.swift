// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Combine
import NookSurface
import XCTest
@testable import NookKit

@MainActor
final class NookPresentationPinningTests: XCTestCase {
    // MARK: - Broker ref-counting

    func testFirstPinTransitionsIsPinned() {
        let broker = NookPresentationPinning()
        XCTAssertFalse(broker.isPinned)

        let handle = broker.pin()
        XCTAssertTrue(broker.isPinned)
        _ = handle  // keep alive
    }

    func testTwoPinsBothMustReleaseBeforeUnpin() {
        let broker = NookPresentationPinning()
        let a = broker.pin()
        let b = broker.pin()
        XCTAssertTrue(broker.isPinned)

        a.release()
        XCTAssertTrue(broker.isPinned, "still one pin outstanding")

        b.release()
        XCTAssertFalse(broker.isPinned, "last release unpins")
    }

    func testReleaseIsIdempotent() {
        let broker = NookPresentationPinning()
        let handle = broker.pin()
        handle.release()
        handle.release()
        XCTAssertFalse(broker.isPinned)
    }

    func testHandleDeinitFallbackReleasesPin() async {
        let broker = NookPresentationPinning()
        do {
            _ = broker.pin()
            // Handle goes out of scope here; `deinit` dispatches release to main.
        }
        // Yield so the deinit-spawned `Task { @MainActor in ... }` runs.
        await Task.yield()
        await Task.yield()
        XCTAssertFalse(broker.isPinned, "deinit fallback releases the pin")
    }

    // MARK: - pinChanges publisher edges

    func testPinChangesEmitsTrueOnZeroToOneOnly() {
        let broker = NookPresentationPinning()
        var observed: [Bool] = []
        var cancellables: Set<AnyCancellable> = []
        broker.pinChanges
            .dropFirst()  // drop the CurrentValueSubject's initial `false`
            .sink { observed.append($0) }
            .store(in: &cancellables)

        let a = broker.pin()
        let b = broker.pin()  // N stays >= 1; no new edge

        XCTAssertEqual(observed, [true], "only the 0->1 edge emits")
        _ = (a, b)
    }

    func testPinChangesEmitsFalseOnLastReleaseOnly() {
        let broker = NookPresentationPinning()
        var observed: [Bool] = []
        var cancellables: Set<AnyCancellable> = []

        let a = broker.pin()
        let b = broker.pin()

        broker.pinChanges
            .dropFirst()  // drop the initial replay (`true`)
            .sink { observed.append($0) }
            .store(in: &cancellables)

        a.release()
        XCTAssertEqual(observed, [], "intermediate release does not emit")

        b.release()
        XCTAssertEqual(observed, [false], "N->0 edge emits exactly once")
    }

    // MARK: - Diagnostics

    func testActiveReasonsListsRecordedReasonsOnly() {
        let broker = NookPresentationPinning()
        let a = broker.pin(reason: "time-picker")
        let b = broker.pin()  // no reason
        let c = broker.pin(reason: "uploading")

        XCTAssertEqual(broker.activeReasons.map { String(describing: $0) }, ["time-picker", "uploading"])
        _ = (a, b, c)
    }

    // MARK: - Service-key resolution

    func testServiceKeyResolvesFromAppServices() {
        let services = AppServices()
        let broker = NookPresentationPinning()
        services.register(NookPresentationPinningKey.self, broker)

        let resolved = services.resolve(NookPresentationPinningKey.self)
        XCTAssertTrue(resolved === broker, "the registered broker is what resolve returns")
    }

    func testServiceKeyDefaultValueIsAStableInstance() {
        // A test or a context that never went through the registry resolves the
        // key to the static default - verify that resolve returns a usable
        // (non-trapping) broker.
        let services = AppServices()
        let resolved = services.resolve(NookPresentationPinningKey.self)
        let handle = resolved.pin()
        XCTAssertTrue(resolved.isPinned)
        handle.release()
    }
}
