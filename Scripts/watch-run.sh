#!/usr/bin/env bash
set -euo pipefail

if ! command -v fswatch >/dev/null 2>&1; then
  echo "fswatch is required for watch mode. Install it with: brew install fswatch" >&2
  echo "For now, use: Scripts/dev-run.sh" >&2
  exit 1
fi

restart() {
  pkill -x Nook 2>/dev/null || true
  swift build
  swift run Nook &
}

restart

fswatch -o Package.swift Sources Tests | while read -r _; do
  restart
done
