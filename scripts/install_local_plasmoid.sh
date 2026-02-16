#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
  echo "kpackagetool6 not found. Install KDE Plasma 6 development tools first."
  exit 1
fi

echo "Upgrading local plasmoid package from: ${ROOT_DIR}/package"
kpackagetool6 --type Plasma/Applet --upgrade "${ROOT_DIR}/package"

echo "Done. Local package installed at:"
echo "  ${HOME}/.local/share/plasma/plasmoids/com.github.loofi.aiusagemonitor"

