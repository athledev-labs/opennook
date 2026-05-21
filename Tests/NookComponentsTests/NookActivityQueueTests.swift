// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Combine
import XCTest
@testable import NookComponents
import NookKit

/// A `NookSurfacePresenting` stand-in — no real window, fully controllable engagement.
@MainActor
private final class FakePresenter: NookSurfacePresenting {
    private let engagement = CurrentValueSubject<Bool, Never>(false)

    private(set) var beginCount = 0
    private(set) var endCount = 0

    var isUserEngaged: Bool { engagement.value }

    var userEngagementChanges: AnyPublisher<Bool, Never> {
        engagement.eraseToAnyPublisher()
    }

    func beginTransientPresentation() async { beginCount += 1 }
    func endTransientPresentation() async { endCount += 1 }

    func setEngaged(_ value: Bool) { engagement.send(value) }
}

final class NookActivityQueueTests: XCTestCase {
    /// A queue whose `dwell` waits resolve instantly, for deterministic draining.
    @MainActor
    private func instantQueue() -> NookActivityQueue {
        NookActivityQueue(sleep: { _ in })
    }

    @MainActor
    func testDrainsEveryEnqueuedActivity() async {
        let queue = instantQueue()
        let presenter = FakePresenter()
        queue.bind(to: presenter)

        queue.enqueue(NookActivity(title: "A"))
        queue.enqueue(NookActivity(title: "B"))
        queue.enqueue(NookActivity(title: "C"))
        await queue.drainTask?.value

        XCTAssertEqual(presenter.beginCount, 3)
        XCTAssertEqual(presenter.endCount, 3)
        XCTAssertNil(queue.current)
        XCTAssertTrue(queue.pending.isEmpty)
    }

    @MainActor
    func testPresentsHighestPriorityFirst() async {
        let queue = instantQueue()
        let presenter = FakePresenter()
        queue.bind(to: presenter)

        var presented: [String] = []
        let cancellable = queue.$current
            .compactMap { $0?.title }
            .sink { presented.append($0) }

        queue.enqueue(NookActivity(priority: .low, title: "Low"))
        queue.enqueue(NookActivity(priority: .high, title: "High"))
        queue.enqueue(NookActivity(priority: .normal, title: "Normal"))
        await queue.drainTask?.value
        cancellable.cancel()

        XCTAssertEqual(presented, ["High", "Normal", "Low"])
    }

    @MainActor
    func testCoalescingKeyKeepsLatest() {
        // No presenter bound — the queue holds activities without draining.
        let queue = instantQueue()

        queue.enqueue(NookActivity(coalescingKey: "sync", title: "First"))
        queue.enqueue(NookActivity(coalescingKey: "sync", title: "Second"))

        XCTAssertEqual(queue.pending.count, 1)
        XCTAssertEqual(queue.pending.first?.title, "Second")
    }

    @MainActor
    func testSuspendStopsDrainingAndResumeContinues() async {
        let queue = instantQueue()
        let presenter = FakePresenter()

        queue.suspend()
        queue.bind(to: presenter)
        queue.enqueue(NookActivity(title: "A"))
        XCTAssertEqual(presenter.beginCount, 0, "a suspended queue presents nothing")

        queue.resume()
        await queue.drainTask?.value
        XCTAssertEqual(presenter.beginCount, 1)
    }

    @MainActor
    func testYieldsWhileUserEngaged() async throws {
        let queue = instantQueue()
        let presenter = FakePresenter()
        presenter.setEngaged(true)
        queue.bind(to: presenter)

        queue.enqueue(NookActivity(title: "A"))
        // Give the drain loop time to reach its yield point.
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(presenter.beginCount, 0, "must not present while the user is engaged")

        presenter.setEngaged(false)
        await queue.drainTask?.value
        XCTAssertEqual(presenter.beginCount, 1, "presents once the user disengages")
    }
}
