// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import AppKit
import SwiftUI

/// Top-level expanded notch surface. Renders the top bar, then either the home placeholder
/// or the settings panel. Fork this to plug your product surface in where `homeSurface`
/// lives now.
///
/// Sizing: the chrome sizes the panel to whatever this view measures. The demo pins a
/// stable `NookLayout.width` so the panel doesn't resize between the home and settings
/// surfaces — remove that `.frame(width:)` to let the panel size purely to content.
public struct NookExpandedView: View {
    @ObservedObject var appState: AppState

    let services: AppServices
    let toggleKeepOpen: () -> Void
    let hide: () -> Void
    let resetAllSettings: () -> Void

    @State private var isHomeIconHovered = false

    public init(
        appState: AppState,
        services: AppServices,
        toggleKeepOpen: @escaping () -> Void,
        hide: @escaping () -> Void,
        resetAllSettings: @escaping () -> Void
    ) {
        self.appState = appState
        self.services = services
        self.toggleKeepOpen = toggleKeepOpen
        self.hide = hide
        self.resetAllSettings = resetAllSettings
    }

    private var resolvedTheme: NookResolvedTheme {
        NookResolvedTheme.live(appState: appState)
    }

    private var chromeInteractionAccent: Color {
        Color(nsColor: .controlAccentColor)
    }

    public var body: some View {
        VStack(spacing: 8) {
            NookTopBar(
                appState: appState,
                chromeInteractionAccent: chromeInteractionAccent,
                isHomeIconHovered: $isHomeIconHovered,
                toggleKeepOpen: toggleKeepOpen
            )

            Group {
                if appState.isSettingsView {
                    settingsSurface
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            )
                        )
                } else {
                    homeSurface
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .leading)),
                                removal: .opacity.combined(with: .move(edge: .trailing))
                            )
                        )
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.84), value: appState.viewMode)
        }
        .frame(width: NookLayout.width)
        .padding(NookLayout.edgePadding)
        .environment(\.nookResolvedTheme, resolvedTheme)
        .environment(\.appServices, services)
        // The nook lives on a `.nonactivatingPanel` so opening it never steals focus from
        // the user's editor. Side effect: until the user clicks the surface, AppKit
        // desaturates accent-tinted controls. Forcing `.active` makes the chrome paint as
        // if focused without changing key-window behaviour.
        .environment(\.controlActiveState, .active)
        .tint(.accentColor)
        .preferredColorScheme(appState.appearancePreferences.chromeColorSchemeOverride)
        .onChange(of: appState.viewMode) { _ in
            isHomeIconHovered = false
        }
        .onExitCommand(perform: hide)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: appState.viewMode)
    }

    /// Placeholder home surface. Replace with your product content when forking.
    private var homeSurface: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(resolvedTheme.secondaryLabel)
            Text("Nook")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(resolvedTheme.primaryLabel)
            Text("Replace this view to start building your notch app.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(resolvedTheme.tertiaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var settingsSurface: some View {
        SettingsView(
            appState: appState,
            onToggleKeepOpen: toggleKeepOpen,
            onResetAllSettings: resetAllSettings
        )
    }
}
