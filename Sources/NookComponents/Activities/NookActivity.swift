// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import SwiftUI

/// Relative urgency of a queued activity. The queue drains higher priorities first;
/// ties keep enqueue (FIFO) order.
public enum NookActivityPriority: Int, Comparable, Sendable {
    case low, normal, high

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// One transient activity to surface in the notch — a "download finished", a "build
/// succeeded", a "message arrived".
///
/// Hand activities to a ``NookActivityQueue``; it orders them by ``priority``, collapses
/// duplicates that share a ``coalescingKey``, and presents each one in turn by briefly
/// taking over the expanded surface for ``dwell``.
public struct NookActivity: Identifiable, Sendable {
    public let id: UUID

    /// Activities sharing a non-`nil` key collapse: enqueuing one drops any pending
    /// peer with the same key (keep-latest). `nil` means "never coalesce".
    public var coalescingKey: String?

    public var priority: NookActivityPriority
    public var title: String
    public var subtitle: String?
    /// SF Symbol name shown on the activity card.
    public var systemImage: String?
    public var tint: Color
    /// How long the activity holds the expanded surface before yielding it back.
    public var dwell: Duration

    public init(
        id: UUID = UUID(),
        coalescingKey: String? = nil,
        priority: NookActivityPriority = .normal,
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        tint: Color = .accentColor,
        dwell: Duration = .seconds(2.4)
    ) {
        self.id = id
        self.coalescingKey = coalescingKey
        self.priority = priority
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.dwell = dwell
    }
}
