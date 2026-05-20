// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import SwiftUI

/// Static header icon (no hover, no action) used by the persistent "Home" cluster.
///
/// Mirrors `HeaderIcon`'s 11pt / 24×24 / `headerInactiveIcon` styling so the home glyph
/// reads at the same minimal weight as the lock / gear / search icons on the right side
/// of the topbar. The deliberately muted tone (vs. `primaryLabel`) keeps it as chrome
/// rather than competing with whatever the user actually came to do.
struct StaticHeaderIcon: View {
    let systemName: String

    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(theme.headerInactiveIcon)
            .frame(width: 24, height: 24)
    }
}

/// Hover-and-tap glyph in the topbar (sidebar toggle, settings, search, etc.). Active state
/// is colored by `activeColor`; idle by the resolved theme.
struct HeaderIcon: View {
    let systemName: String
    let isActive: Bool
    let activeColor: Color
    let help: String
    let action: () -> Void

    @Environment(\.nookResolvedTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isActive ? activeColor : (isHovering ? theme.primaryLabel.opacity(0.92) : theme.headerInactiveIcon))
                .frame(width: 24, height: 24)
                .background(isHovering ? theme.subtleFill : .clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isHovering ? theme.subtleStroke : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovering = $0 }
    }
}
