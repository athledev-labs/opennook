# Notices

OpenNook is open-source software. The project as a whole is licensed under the
Apache License 2.0. One subtree — the `NookSurface` notch-chrome target —
carries the MIT License instead, to preserve the license lineage of the
upstream project it is derived from. Both licenses are permissive and
compatible; this split simply keeps upstream attribution intact.

## License map

| Path | License | Coverage |
|---|---|---|
| `LICENSE` | Apache-2.0 | The whole repository, except the paths listed below |
| `LICENSE-MIT-NOOKSURFACE` | MIT | `Sources/NookSurface/` — OpenNook's modifications to the chrome |
| `ThirdPartyLicenses/DynamicNotchKit.txt` | MIT (Kai Azim) | The DynamicNotchKit upstream `NookSurface` is derived from |

## NookSurface (`Sources/NookSurface/`)

The notch chrome surface (`Nook`, `NookView`, `NookShape`, `NookPanel`,
`NookContentView`, related screen / visual-effect helpers, the supporting
style / state / transition / backdrop configuration types, and the
`NookFeedbackOverlay` peripheral-cue layer) is derived from
[DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) by Kai Azim.

DynamicNotchKit is distributed under the MIT License (see
`ThirdPartyLicenses/DynamicNotchKit.txt`). The original kit has been
substantially trimmed and renamed: the `DynamicNotchInfo` preset family, the
`floating` and `auto` style modes, and the `NotchlessView` floating-window
renderer have all been removed; remaining types now live under the `Nook*`
namespace.

OpenNook's modifications to the kit are licensed under the MIT License — see
`LICENSE-MIT-NOOKSURFACE` — preserving compatibility with the original
DynamicNotchKit license and keeping the chrome freely usable for any purpose,
including downstream forks.
