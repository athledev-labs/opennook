// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import SwiftUI

/// The module switcher — a strip of chips, one per registered module, shown at the top
/// of the expanded surface when a host has more than one module.
///
/// Tapping a chip switches the foreground module. The active chip is tinted with the
/// module's accent; a chip for a backgrounded module that asked for attention carries a
/// small badge.
struct ModuleSwitcherBar: View {
    @ObservedObject var moduleHost: ModuleHost
    let switchModule: (String) -> Void

    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(moduleHost.descriptors) { descriptor in
                ModuleSwitcherChip(
                    descriptor: descriptor,
                    isActive: descriptor.id == moduleHost.activeModuleID,
                    wantsAttention: moduleHost.attentionModuleIDs.contains(descriptor.id),
                    theme: theme,
                    action: { switchModule(descriptor.id) }
                )
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, NookLayout.edgePadding)
        .padding(.top, NookLayout.edgePadding)
        .frame(width: NookLayout.width, alignment: .leading)
    }
}

private struct ModuleSwitcherChip: View {
    let descriptor: NookModuleDescriptor
    let isActive: Bool
    let wantsAttention: Bool
    let theme: NookResolvedTheme
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: descriptor.icon)
                    .font(.system(size: 9, weight: .semibold))
                Text(descriptor.displayName)
                    .font(.system(size: 10.5, weight: .medium))
            }
            .foregroundStyle(isActive ? theme.primaryLabel : theme.secondaryLabel)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(
                Capsule().fill(background)
            )
            .overlay(
                Capsule().stroke(isActive ? descriptor.accent.opacity(0.5) : .clear, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if wantsAttention {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 5, height: 5)
                        .offset(x: 1, y: -1)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(descriptor.displayName)
    }

    private var background: Color {
        if isActive {
            return descriptor.accent.opacity(0.22)
        }
        return isHovered ? theme.subtleFill : .clear
    }
}
