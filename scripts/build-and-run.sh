#!/bin/bash
set -euo pipefail

# ProxyGlass build-and-run script
# Usage: ./scripts/build-and-run.sh [--no-clean]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="$PROJECT_ROOT/build/Build/Products/Debug/ProxyGlass.app"

CLEAN="clean"
for arg in "$@"; do
  case "$arg" in
    --no-clean) CLEAN="" ;;
  esac
done

# 1. Kill existing process
if pgrep -x ProxyGlass >/dev/null 2>&1; then
  echo "Killing existing ProxyGlass process..."
  pkill -x ProxyGlass || true
  sleep 0.5
fi

# 2. Build
if [ -n "$CLEAN" ]; then BUILD_TYPE="clean build"; else BUILD_TYPE="incremental"; fi
echo "Building ProxyGlass ($BUILD_TYPE)..."
cd "$PROJECT_ROOT"

BUILD_OUTPUT=$(mktemp)
trap 'rm -f "$BUILD_OUTPUT"' EXIT

xcodebuild \
  -scheme ProxyGlass \
  -configuration Debug \
  -derivedDataPath build \
  $CLEAN build \
  2>&1 | tee "$BUILD_OUTPUT"

if ! grep -q "BUILD SUCCEEDED" "$BUILD_OUTPUT"; then
  echo ""
  echo "BUILD FAILED — app will not be launched."
  exit 1
fi

# 3. Launch
echo ""
echo "Launching ProxyGlass..."
open "$APP_PATH"
echo "Done."
