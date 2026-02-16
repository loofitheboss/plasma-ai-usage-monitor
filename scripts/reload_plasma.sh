#!/usr/bin/env bash
set -euo pipefail

echo "Reloading plasmashell..."
if command -v kquitapp6 >/dev/null 2>&1; then
  kquitapp6 plasmashell || true
else
  pkill -x plasmashell || true
fi

nohup plasmashell >/dev/null 2>&1 &
echo "plasmashell restarted."

