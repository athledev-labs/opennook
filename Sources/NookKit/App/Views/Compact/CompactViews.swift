// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import AppKit
import SwiftUI

/// Compact slot to the **left** of the notch when the nook is collapsed. The shimmer
/// peripheral cue lives in `NookSurface.NookFeedbackOverlay`; this view just renders the
/// static icon flanking the cutout.
public struct NookCompactLeadingView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var theme: NookResolvedTheme {
        NookResolvedTheme.live(appState: appState)
    }

    public var body: some View {
        Image(systemName: "house")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(theme.primaryLabel.opacity(0.88))
            .frame(width: NookLayout.compactSlotSize, height: NookLayout.compactSlotSize)
    }
}

/// Compact slot to the **right** of the notch.
public struct NookCompactTrailingView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var theme: NookResolvedTheme {
        NookResolvedTheme.live(appState: appState)
    }

    public var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(theme.primaryLabel.opacity(0.82))
            .frame(width: NookLayout.compactSlotSize, height: NookLayout.compactSlotSize)
    }
}
