#!/usr/bin/env bash
# Build the Xcode app bundle and run OPENNOOK_UI_SMOKE_TEST against the real panel.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TIMEOUT_SECONDS="${OPENNOOK_SMOKE_TIMEOUT:-30}"

run_with_timeout() {
  local duration="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$duration" "$@"
    return
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$duration" "$@"
    return
  fi
  perl -e 'alarm shift; exec @ARGV or die "exec failed: $!\n"' "$duration" "$@"
}

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen not installed. Install with: brew install xcodegen" >&2
  exit 1
fi

./Scripts/regenerate-xcodeproj.sh

set -o pipefail
if command -v xcbeautify >/dev/null 2>&1; then
  xcodebuild \
    -project Nook.xcodeproj \
    -scheme NookHostApp \
    -configuration Debug \
    -destination 'platform=macOS' \
    build | xcbeautify
else
  xcodebuild \
    -project Nook.xcodeproj \
    -scheme NookHostApp \
    -configuration Debug \
    -destination 'platform=macOS' \
    build
fi

app_path="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path '*/Build/Products/Debug/Nook.app' -type d 2>/dev/null | head -1)"
if [[ -z "$app_path" || ! -x "$app_path/Contents/MacOS/Nook" ]]; then
  echo "::error::could not locate built Nook.app" >&2
  exit 1
fi

echo "UI smoke testing ${app_path}..."
run_with_timeout "${TIMEOUT_SECONDS}" env OPENNOOK_UI_SMOKE_TEST=1 "$app_path/Contents/MacOS/Nook"
echo "UI smoke passed."
