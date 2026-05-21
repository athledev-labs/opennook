// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

// ActivityNook — the live-activity queue from the NookComponents add-on.
//
// A NookActivityQueue collects transient activities and presents them one at a time,
// briefly taking over the expanded surface for each. This demo enqueues a sample
// activity on a timer so the takeover is visible. Run with `swift run ActivityNook`.

import NookApp
import NookComponents
import SwiftUI

/// Shown when the queue is idle — the host's normal home content.
struct ActivityNookHome: View {
    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bell")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(theme.secondaryLabel)
            Text("Activity queue idle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.primaryLabel)
            Text("A sample activity surfaces every few seconds.")
                .font(.system(size: 11))
                .foregroundStyle(theme.tertiaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// `NookApp.main { … }` builds the configuration on the main actor, so the
// main-actor-isolated NookActivityQueue can be constructed here.
NookApp.main {
    let queue = NookActivityQueue()

    var configuration = NookConfiguration()
    configuration.setHome {
        NookActivityHost(queue: queue) { ActivityNookHome() }
    }
    configuration.onReady = { coordinator in
        queue.bind(to: coordinator)

        // Demo only: enqueue a rotating sample activity on a timer so the
        // takeover is visible. A real app enqueues in response to its own events.
        let samples = [
            NookActivity(priority: .normal, title: "Build finished",
                         subtitle: "Debug · 12.4s", systemImage: "hammer", tint: .green),
            NookActivity(priority: .high, title: "Backup complete",
                         subtitle: "3,204 files", systemImage: "externaldrive.badge.checkmark", tint: .blue),
            NookActivity(priority: .low, title: "New message",
                         subtitle: "from the notch", systemImage: "message", tint: .orange),
        ]
        Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
            // Timer fires on the main run loop; hop to the main actor to enqueue.
            MainActor.assumeIsolated {
                let index = Int(Date.now.timeIntervalSince1970 / 6) % samples.count
                queue.enqueue(samples[index])
            }
        }
    }
    return configuration
}
