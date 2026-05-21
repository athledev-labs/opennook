// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Combine

/// Coordinated, arbitrated access to the notch surface for *transient* presenters.
///
/// A transient presenter — e.g. `NookComponents`' activity queue — briefly takes over
/// the expanded surface, then yields it back. It must not fight the user: while the
/// user is engaging the surface (hovering it, or having opened it themselves) a
/// transient presenter pauses.
///
/// `AppCoordinator` is the conformer; it owns the surface and arbitrates. The protocol
/// keeps transient presenters decoupled from `AppCoordinator`/`Nook` internals and lets
/// them be unit-tested against a fake conformer — no real window required.
@MainActor
public protocol NookSurfacePresenting: AnyObject {
    /// `true` while the user is actively engaging the surface — hovering it, or it is
    /// open because they opened it. A transient presenter pauses while this holds.
    var isUserEngaged: Bool { get }

    /// Emits whenever ``isUserEngaged`` changes.
    var userEngagementChanges: AnyPublisher<Bool, Never> { get }

    /// Take over the expanded surface for a transient presentation. The arbiter
    /// snapshots the prior state so ``endTransientPresentation()`` can restore it;
    /// a no-op if a transient presentation is already in progress.
    func beginTransientPresentation() async

    /// End the transient presentation, restoring the state captured at
    /// ``beginTransientPresentation()`` — unless the user has since engaged the
    /// surface, in which case their state is left untouched.
    func endTransientPresentation() async
}
