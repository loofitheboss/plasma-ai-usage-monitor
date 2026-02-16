#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

REPO_METADATA="${ROOT_DIR}/package/metadata.json"
USER_METADATA="${HOME}/.local/share/plasma/plasmoids/com.github.loofi.aiusagemonitor/metadata.json"
SYSTEM_METADATA="/usr/share/plasma/plasmoids/com.github.loofi.aiusagemonitor/metadata.json"

extract_version() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "not-installed"
    return 0
  fi

  sed -n 's/.*"Version": "\([0-9.]*\)".*/\1/p' "$file" | head -1
}

echo "AI Usage Monitor version report"
echo "  repo:   $(extract_version "$REPO_METADATA")  ($REPO_METADATA)"
echo "  user:   $(extract_version "$USER_METADATA")  ($USER_METADATA)"
echo "  system: $(extract_version "$SYSTEM_METADATA")  ($SYSTEM_METADATA)"

