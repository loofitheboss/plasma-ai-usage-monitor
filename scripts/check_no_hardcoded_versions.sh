#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

hardcoded="$(rg -n 'text:[[:space:]]*"([0-9]+\.[0-9]+\.[0-9]+)"' package/contents/ui || true)"

if [[ -n "$hardcoded" ]]; then
  echo "Hardcoded semantic version string detected in QML:"
  echo "$hardcoded"
  exit 1
fi

echo "No hardcoded semantic version strings detected in QML."

