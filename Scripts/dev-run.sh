#!/usr/bin/env bash
set -euo pipefail

pkill -x Nook 2>/dev/null || true
swift build
exec swift run Nook
