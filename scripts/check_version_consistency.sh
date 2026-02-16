#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

cmake_version="$(sed -n 's/^project(plasma-ai-usage-monitor VERSION \([0-9.]*\)).*/\1/p' CMakeLists.txt | head -1)"
metadata_version="$(sed -n 's/.*"Version": "\([0-9.]*\)".*/\1/p' package/metadata.json | head -1)"
spec_version="$(sed -n 's/^Version:[[:space:]]*\([0-9.]*\).*/\1/p' plasma-ai-usage-monitor.spec | head -1)"

if [[ -z "$cmake_version" || -z "$metadata_version" || -z "$spec_version" ]]; then
  echo "Failed to parse one or more version values"
  echo "  CMake:    '${cmake_version}'"
  echo "  metadata: '${metadata_version}'"
  echo "  spec:     '${spec_version}'"
  exit 1
fi

if [[ "$cmake_version" != "$metadata_version" || "$cmake_version" != "$spec_version" ]]; then
  echo "Version mismatch detected"
  echo "  CMake:    ${cmake_version}"
  echo "  metadata: ${metadata_version}"
  echo "  spec:     ${spec_version}"
  exit 1
fi

echo "Version consistency OK: ${cmake_version}"
