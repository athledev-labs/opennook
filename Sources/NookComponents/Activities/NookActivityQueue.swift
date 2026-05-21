// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Combine
import Foundation
import NookKit

/// A priority queue of transient notch activities.
///
/// Enqueue ``NookActivity`` values; the queue drains them one at a time, highest
/// ``NookActivityPriority/high`` first, collapsing any that share a `coalescingKey`.
/// Presenting an activity briefly takes over the expanded surface through a
/// ``NookSurfacePresenting`` — typically `AppCoordinator`, supplied via
/// `NookConfiguration.onReady`:
///
/// ```swift
/// let queue = NookActivityQueue()
/// configuration.onReady = { queue.bind(to: $0) }
/// // …later, from anywhere on the main actor:
/// queue.enqueue(NookActivity(title: "Build finished", systemImage: "hammer"))
/// ```
///
/// The queue **yields to the user**: while the user is hovering or has opened the nook
/// themselves it pauses, resuming once they disengage. It does not preempt an activity
/// that is already on screen — priority orders only what is still pending.
@MainActor
public final class NookActivityQueue: ObservableObject {
    /// The activity currently on screen, or `nil`. A host view (see ``NookActivityHost``)
    /// renders this.
    @Published public private(set) var current: NookActivity?

    /// Activities waiting to be presented, in enqueue order.
    @Published public private(set) var pending: [NookActivity] = []

    /// `true` while draining is suspended via ``suspend()``.
    @Published public private(set) var isSuspended: Bool = false

    private weak var presenter: (any NookSurfacePresenting)?

    /// The running drain loop, or `nil` when idle. Internal so tests can await it.
    var drainTask: Task<Void, Never>?

    /// Injectable sleep — real time in production, instant in tests.
    private let sleep: @Sendable (Duration) async -> Void

    /// - Parameter sleep: how the queue waits out an activity's `dwell`. Defaults to a
    ///   real `Task.sleep`; tests pass an instant closure to drive timing deterministically.
    public init(sleep: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.sleep = sleep
    }

    /// Connects the queue to the surface it presents through, and starts draining any
    /// already-queued activities. Call once — `NookConfiguration.onReady` is the seam.
    public func bind(to presenter: any NookSurfacePresenting) {
        self.presenter = presenter
        startDrainingIfNeeded()
    }

    /// Adds an activity. If it carries a `coalescingKey`, any pending peer with the same
    /// key is dropped first (keep-latest).
    public func enqueue(_ activity: NookActivity) {
        if let key = activity.coalescingKey {
            pending.removeAll { $0.coalescingKey == key }
        }
        pending.append(activity)
        startDrainingIfNeeded()
    }

    /// Removes a still-pending activity. No effect once it is on screen.
    public func cancel(_ id: NookActivity.ID) {
        pending.removeAll { $0.id == id }
    }

    /// Removes all pending activities with the given coalescing key.
    public func cancelAll(coalescingKey: String) {
        pending.removeAll { $0.coalescingKey == coalescingKey }
    }

    /// Pauses draining. An activity already on screen finishes its dwell; nothing new is
    /// presented until ``resume()``.
    public func suspend() {
        guard !isSuspended else { return }
        isSuspended = true
        drainTask?.cancel()
        drainTask = nil
    }

    /// Resumes draining after ``suspend()``.
    public func resume() {
        guard isSuspended else { return }
        isSuspended = false
        startDrainingIfNeeded()
    }

    // MARK: - Drain loop

    private func startDrainingIfNeeded() {
        guard !isSuspended, drainTask == nil, presenter != nil, !pending.isEmpty else { return }
        drainTask = Task { [weak self] in
            await self?.drain()
            self?.drainTask = nil
        }
    }

    private func drain() async {
        while !isSuspended, !Task.isCancelled, let presenter, let activity = dequeue() {
            // Don't fight the user for the surface.
            await waitWhileUserEngaged(presenter)
            if isSuspended || Task.isCancelled { break }

            await presenter.beginTransientPresentation()
            current = activity
            await sleep(activity.dwell)
            current = nil
            await presenter.endTransientPresentation()
        }
    }

    /// Removes and returns the highest-priority pending activity, FIFO within a priority.
    private func dequeue() -> NookActivity? {
        guard let maxPriority = pending.map(\.priority).max(),
              let index = pending.firstIndex(where: { $0.priority == maxPriority }) else {
            return nil
        }
        return pending.remove(at: index)
    }

    /// Suspends the drain loop while the user is engaging the surface, returning once
    /// they disengage (or the queue is suspended/cancelled).
    private func waitWhileUserEngaged(_ presenter: any NookSurfacePresenting) async {
        guard presenter.isUserEngaged else { return }
        for await engaged in presenter.userEngagementChanges.values {
            if !engaged || isSuspended || Task.isCancelled { return }
        }
    }
}
