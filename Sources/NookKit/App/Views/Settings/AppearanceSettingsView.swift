// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import SwiftUI

/// Theme + surface pickers. Lives inside the Appearance settings group.
struct AppearanceSettingsSection: View {
    @ObservedObject var appState: AppState
    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            labeledPicker(title: "Theme", accessibilityLabel: "Theme") {
                Picker("Theme", selection: chromePaletteBinding) {
                    Text("Match Mac").tag(NookChromePalette.followSystem)
                    Text("Dark").tag(NookChromePalette.dark)
                    Text("Light").tag(NookChromePalette.light)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
            }

            VStack(alignment: .leading, spacing: 5) {
                labeledPicker(title: "Surface", accessibilityLabel: "Chrome surface") {
                    Picker("Surface", selection: surfaceStyleBinding) {
                        Text("Solid").tag(NookSurfaceStyle.solid)
                        Text("Translucent").tag(NookSurfaceStyle.translucent)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                }

                Text(surfaceStyleBinding.wrappedValue == .solid
                    ? "Solid paints the chrome the same color as the notch — true black on dark, true white on light."
                    : "Translucent shows the wallpaper through a frosted material.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(theme.tertiaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func labeledPicker(title: String, accessibilityLabel: String, @ViewBuilder picker: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.secondaryLabel)
            picker()
                .accessibilityLabel(accessibilityLabel)
        }
    }

    private var chromePaletteBinding: Binding<NookChromePalette> {
        Binding(
            get: { appState.appearancePreferences.chromePalette },
            set: { next in
                var prefs = appState.appearancePreferences
                prefs.chromePalette = next
                appState.replaceAppearancePreferences(prefs)
            }
        )
    }

    private var surfaceStyleBinding: Binding<NookSurfaceStyle> {
        Binding(
            get: { appState.appearancePreferences.surfaceStyle },
            set: { next in
                var prefs = appState.appearancePreferences
                prefs.surfaceStyle = next
                appState.replaceAppearancePreferences(prefs)
            }
        )
    }
}
