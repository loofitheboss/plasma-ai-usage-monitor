#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f build/compile_commands.json ]]; then
  echo "error: build/compile_commands.json not found. Configure with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON." >&2
  exit 1
fi

if ! command -v clang-tidy >/dev/null 2>&1; then
  echo "error: clang-tidy is not installed." >&2
  exit 1
fi

mapfile -t SOURCES < <(find plugin -maxdepth 1 -type f \( -name '*.cpp' -o -name '*.h' \) | sort)

if [[ ${#SOURCES[@]} -eq 0 ]]; then
  echo "error: no plugin source files found for clang-tidy." >&2
  exit 1
fi

clang-tidy -p build --warnings-as-errors='*' "${SOURCES[@]}"
