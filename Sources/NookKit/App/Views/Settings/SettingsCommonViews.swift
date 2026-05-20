// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import SwiftUI

/// Common chrome shared across settings groupings: section label, grouped panel container,
/// inset divider, and shortcut squircle. Local to the settings layer so the picker model
/// isn't leaked into preferences storage.
public struct SettingsGroupedPanel<Content: View>: View {
    @Environment(\.nookResolvedTheme) private var theme
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.subtleFill.opacity(0.38), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(theme.subtleStroke.opacity(0.22), lineWidth: 1)
            )
    }
}

public struct SettingsInsetDivider: View {
    @Environment(\.nookResolvedTheme) private var theme

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(theme.subtleStroke.opacity(0.35))
            .frame(height: 1)
            .padding(.vertical, 6)
    }
}

struct ShortcutKeySquircle: View {
    let symbol: String

    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        Text(symbol)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(theme.primaryLabel.opacity(0.92))
            .frame(minWidth: 24, minHeight: 22)
            .background(theme.subtleFill.opacity(0.55), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(theme.subtleStroke.opacity(0.35), lineWidth: 1)
            )
    }
}

public struct SettingsSectionLabel: View {
    let title: String

    @Environment(\.nookResolvedTheme) private var theme

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(theme.quaternaryLabel)
            .tracking(0.42)
    }
}
