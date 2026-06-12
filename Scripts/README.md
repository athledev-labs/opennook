# Scripts

Developer scripts. All are simple wrappers around `swift` / `xcodegen`; none
are required to build or run the app.

- `apply-license-headers.sh` - stamp the SPDX/Apache-2.0 header on new files.
- `dev-run.sh` - `swift run Nook` with the right env. Headless
  iteration; no `Info.plist`, so URL-scheme dispatch does NOT work in this
  build. Use Cmd-R in Xcode for the bundled `.app`.
- `watch-run.sh` - auto-rebuild on file change for tight UI iteration.
- `regenerate-xcodeproj.sh` - rebuilds `Nook.xcodeproj` from
  `project.yml` (source of truth). Run after editing `project.yml`, or after
  a fresh clone before opening in Xcode the first time. Requires `xcodegen`
  (`brew install xcodegen`).

## Two build paths, one codebase

Both paths compile from the same SPM library targets. Pick the one that fits
the iteration:

| Path  | Command                                                              | When                                                          | Limitations                                                              |
| ----- | -------------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------ |
| SPM   | `swift run Nook` (or `Scripts/dev-run.sh`)                    | Fast headless iteration                                       | No `Info.plist` on disk -> Launch Services can't route URL-scheme links   |
| Xcode | Cmd-R in `Nook.xcodeproj` or `xcodebuild -scheme NookHostApp build` | End-to-end (signing, notarization, bundled `.app`)        | Slower first build; `DerivedData/` lives in `.build/xcode/`              |

`swift test` runs the test suite from the package root. Both paths share the
same module artifacts via SwiftPM, so behavior cannot drift.

## Cutting a release

1. Move `[Unreleased]` notes into `## [X.Y.Z] - YYYY-MM-DD` in `CHANGELOG.md`
   and update the compare links at the bottom.
2. Merge to `main`.
3. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`

Pushing a semver tag triggers `.github/workflows/release.yml`, which checks the
CHANGELOG section, builds DocC, and publishes a GitHub Release with the notes
and a `opennook-docs-vX.Y.Z.zip` attachment. Swift Package Index builds API
docs from the same tag via `.spi.yml`.

Validate locally before tagging:

```sh
./Scripts/validate-release-changelog.sh vX.Y.Z
./Scripts/extract-changelog-section.sh X.Y.Z   # preview release notes
```

## Launch smoke tests

Every example executable and the `Nook` demo support a deterministic expand/compact
cycle when launched with `OPENNOOK_SMOKE_TEST=1` (the process exits 0/1). Run them
all locally with:

```sh
./Scripts/smoke-examples.sh
```

The bundled Xcode app supports `OPENNOOK_UI_SMOKE_TEST=1` (expands the real panel,
checks the `opennook.panel` accessibility identifier, then exits). Run it with:

```sh
./Scripts/smoke-ui-app.sh
```
