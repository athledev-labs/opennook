// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

// HelloNook — the smallest possible OpenNook app.
//
// "Register a view, go": hand `NookApp.main` one SwiftUI view and you have a notch
// app — top bar, Settings, hotkey, compact pill all come for free. Run with
// `swift run HelloNook`, then press ⌥⌘; to expand.

import NookApp
import SwiftUI

/// The expanded home surface. It reads `\.nookResolvedTheme` from the environment so
/// its text tracks the chrome's light/dark palette automatically.
struct HelloHomeView: View {
    @Environment(\.nookResolvedTheme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.wave")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(theme.secondaryLabel)
            Text("Hello from the notch")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.primaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

NookApp.main { HelloHomeView() }
