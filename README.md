# OpenNook

**An open-source framework for building macOS notch apps.**

OpenNook gives you the hard part for free: a polished window that lives in the
menu-bar notch, expands and collapses on hover, paints a proper frosted
backdrop, and ships with a settings shell and a global hotkey. Drop your own
SwiftUI view into the expanded surface and you have a notch app.

It is a **base layer plus a working demo** — not a finished product. The demo
app is intentionally minimal: it shows the framework off and gives you a
known-good starting point to fork.

```
┌─────────────────────────────────────────────┐
│                  ▁▁▁▁▁▁▁                     │   ← collapsed: compact slots
│        ◖        │ notch │        ◗           │     flank the physical notch
│                  ▔▔▔▔▔▔▔                     │
└─────────────────────────────────────────────┘
                      │ hover / ⌥⌘;
                      ▼
            ┌───────────────────────┐
            │  ⌂          🔒    ⚙   │   ← expanded: top bar + your view
            │                       │
            │      ✨  Nook         │
            │   Replace this view   │
            └───────────────────────┘
```

## What's inside

OpenNook is two Swift modules, a thin demo app, and two ways to launch it.

### `NookSurface` — the notch window

The low-level chrome: the notch-shaped panel itself, its shape geometry,
hover behavior, expand/compact lifecycle, the translucent backdrop, and the
shimmer feedback overlay. This is a trimmed, renamed fork of
[DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) and is licensed
MIT (see [Licensing](#licensing)).

You usually don't edit `NookSurface` — you drive it through `NookKit`.

### `NookKit` — the app chrome

Everything built on top of `NookSurface` to make it feel like an app:

- `App/AppCoordinator.swift` — lifecycle (show / hide / toggle, keep-open,
  reset settings); binds the notch backdrop to appearance preferences.
- `App/AppState.swift` — `viewMode`, `appearancePreferences`, visibility
  flags. Add your product state alongside these.
- `App/AppServices.swift` — an empty dependency container. Add your services
  (clipboard, networking, persistence…) here so view initializers stay put.
- `App/NookAppearancePreferences.swift` — persisted theme / surface style /
  haptics, with forwards-compatible `Codable` decoding.
- `App/Views/NookExpandedView.swift` — the top-level expanded surface.
  **The placeholder home view here is what you replace.**
- `App/Views/NookTopBar.swift` — home glyph + lock (keep-open) + gear.
- `App/Views/Compact/CompactViews.swift` — the left/right slots flanking the
  physical notch when collapsed.
- `App/Views/Settings/` — Appearance, Shortcut, Data, and Advanced panels.
- `App/Views/Shared/` — reusable settings primitives.
- `System/HotkeyController.swift` — a Carbon-based global hotkey.
- `System/ClipboardService.swift` — a small utility.

### The demo app

- `Sources/NookApp/NookApp.swift` — the library entry point shared by both
  launch surfaces; sets up the `NSApplication`, the coordinator, and a
  menu-bar fallback.
- `Sources/NookExecutable/main.swift` — a three-line SPM trampoline so
  `swift run Nook` works.
- `App/main.swift` + `App/Info.plist` — the Xcode app-target trampoline and
  bundle metadata, for producing a real signed `.app`.

## Requirements

- macOS 13 or later
- Xcode command line tools
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
  — only if you want the Xcode project

## Build and run the demo

The fast path — a headless dev binary via SwiftPM:

```sh
swift build         # build
swift run Nook      # run the demo
swift test          # run the test suite
```

Once it's running, press **⌥⌘;** (or use the menu-bar item) to expand the
nook. You can rebind that shortcut in Settings → Shortcut & nook.

For a real `.app` bundle (signing, notarization, Cmd-R in Xcode):

```sh
./Scripts/regenerate-xcodeproj.sh   # generates Nook.xcodeproj from project.yml
open Nook.xcodeproj
```

`Nook.xcodeproj` is a generated artifact and is gitignored — `project.yml` is
the source of truth. Regenerate it after a fresh clone or after editing
`project.yml`. Both build paths compile the same SwiftPM modules, so behavior
cannot drift between them.

## Start your own notch app

1. **Fork or clone** this repo (the module names `NookKit` / `NookApp` /
   `NookSurface` are independent of the repo name — you can keep them).
2. **Replace the home view.** Open
   `Sources/NookKit/App/Views/NookExpandedView.swift` and swap the
   `homeSurface` placeholder for your product surface.
3. **Add your state** to `AppState` (`Sources/NookKit/App/AppState.swift`) and
   your dependencies to `AppServices`
   (`Sources/NookKit/App/AppServices.swift`).
4. **Drive the chrome** through `AppCoordinator` — `showNook()`, `hideNook()`,
   `toggleNook()`, `toggleKeepNookOpen()` are the lifecycle vocabulary; the
   global hotkey and menu-bar fallback already call into them.
5. **Tune the look** via `NookAppearancePreferences` and the settings panels
   under `Sources/NookKit/App/Views/Settings/`.

Rename the product (`Nook` → your app) by editing `project.yml`,
`App/Info.plist`, and the `Package.swift` product name when you're ready to
ship.

## Licensing

OpenNook is licensed under the **Apache License 2.0** — see [`LICENSE`](LICENSE).

The `Sources/NookSurface/` subtree is licensed **MIT** instead, because it is
derived from [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) by
Kai Azim. See [`LICENSE-MIT-NOOKSURFACE`](LICENSE-MIT-NOOKSURFACE),
[`ThirdPartyLicenses/DynamicNotchKit.txt`](ThirdPartyLicenses/DynamicNotchKit.txt),
and [`NOTICE.md`](NOTICE.md) for the full license map.

Both licenses are permissive — you can build and ship a closed-source product
on top of OpenNook.
