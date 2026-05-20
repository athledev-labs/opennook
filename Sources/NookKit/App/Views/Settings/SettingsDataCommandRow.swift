// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import SwiftUI

/// Visual treatment buckets for `SettingsDataCommandRow`. Standard for benign actions,
/// destructive for "this can't be undone."
enum SettingsDataCommandStyle {
    case standard
    case destructive
}

/// Tap row used inside the Data settings group: icon plate, title + subtitle, trailing chevron.
struct SettingsDataCommandRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let style: SettingsDataCommandStyle
    let action: () -> Void

    @Environment(\.nookResolvedTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconTint)
                    .frame(width: 26, height: 26)
                    .background(iconPlate, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(titleTint)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(theme.secondaryLabel.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.quaternaryLabel)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(rowFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(rowStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var iconTint: Color {
        switch style {
        case .standard:
            theme.primaryLabel.opacity(0.92)
        case .destructive:
            Color.red.opacity(0.92)
        }
    }

    private var iconPlate: Color {
        switch style {
        case .standard:
            theme.subtleFill.opacity(isHovering ? 1 : 0.72)
        case .destructive:
            Color.red.opacity(isHovering ? 0.22 : 0.14)
        }
    }

    private var titleTint: Color {
        switch style {
        case .standard:
            theme.primaryLabel
        case .destructive:
            Color.red.opacity(0.95)
        }
    }

    private var rowFill: Color {
        theme.subtleFill.opacity(isHovering ? 0.42 : 0.22)
    }

    private var rowStroke: Color {
        switch style {
        case .standard:
            theme.subtleStroke.opacity(isHovering ? 0.55 : 0.38)
        case .destructive:
            Color.red.opacity(isHovering ? 0.45 : 0.28)
        }
    }
}

/// About card surfaced in the About settings group: app name, version, and a one-line
/// note that the app is built on OpenNook.
struct SettingsAboutCard: View {
    @Environment(\.nookResolvedTheme) private var theme

    /// Reads `CFBundleShortVersionString` from the running bundle. The SPM `swift run`
    /// build has no `Info.plist` on disk, so it falls back to the package version.
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.headerInactiveIcon)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Nook")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.primaryLabel.opacity(0.95))
                    Text("v\(version)")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(theme.tertiaryLabel)
                }
                Text("A demo notch app built with OpenNook, an open-source framework for macOS notch apps.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(theme.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
