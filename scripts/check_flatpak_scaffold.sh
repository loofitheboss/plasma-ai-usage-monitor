#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

MANIFEST="packaging/flatpak/com.github.loofi.aiusagemonitor.yaml"
README="packaging/flatpak/README.md"

[[ -f "$MANIFEST" ]] || { echo "Missing ${MANIFEST}" >&2; exit 1; }
[[ -f "$README" ]] || { echo "Missing ${README}" >&2; exit 1; }

grep -q '^app-id:[[:space:]]*com.github.loofi.aiusagemonitor' "$MANIFEST" || {
  echo "Flatpak manifest app-id mismatch" >&2
  exit 1
}

grep -q '^runtime:[[:space:]]*org.kde.Platform' "$MANIFEST" || {
  echo "Flatpak manifest runtime missing/invalid" >&2
  exit 1
}

echo "Flatpak scaffold check OK"
