// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

// ClockNook — a home surface plus a custom compact slot.
//
// Shows two registration knobs: `setHome` for the expanded surface and
// `setCompactTrailing` for the glyph flanking the notch when collapsed.
// Run with `swift run ClockNook`.

import NookApp
import SwiftUI

/// A live clock for the expanded surface.
struct ClockHomeView: View {
    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 4) {
                Text(context.date, format: .dateTime.hour().minute().second())
                    .font(.system(size: 34, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(theme.primaryLabel)
                Text(context.date, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 11))
                    .foregroundStyle(theme.tertiaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

/// The compact-slot glyph shown to the right of the notch when collapsed.
struct ClockGlyph: View {
    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        Image(systemName: "clock")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(theme.primaryLabel.opacity(0.82))
            .frame(width: 24, height: 24)
    }
}

var configuration = NookConfiguration()
configuration.setHome { ClockHomeView() }
configuration.setCompactTrailing { ClockGlyph() }
NookApp.main(configuration)
