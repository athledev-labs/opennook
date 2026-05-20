// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import SwiftUI

/// Compact, icon-only right-rail button. No wide pill chrome — hover background only.
/// Destructive variant tints the icon red on hover so delete reads like delete without a label.
struct IconActionButton: View {
    let systemName: String
    let help: String
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void

    @Environment(\.nookResolvedTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(foregroundColor)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            isHovering = isEnabled && hovering
        }
        .help(help)
        .accessibilityLabel(help)
    }

    private var foregroundColor: Color {
        guard isEnabled else { return theme.quaternaryLabel.opacity(0.7) }
        if isDestructive {
            return isHovering ? Color.red.opacity(0.95) : theme.secondaryLabel
        }
        return isHovering ? theme.primaryLabel : theme.secondaryLabel
    }

    private var backgroundColor: Color {
        guard isEnabled, isHovering else { return Color.clear }
        if isDestructive {
            return Color.red.opacity(0.12)
        }
        return theme.subtleFill
    }

    private var strokeColor: Color {
        guard isEnabled, isHovering else { return Color.clear }
        if isDestructive {
            return Color.red.opacity(0.32)
        }
        return theme.subtleStroke.opacity(0.55)
    }
}
