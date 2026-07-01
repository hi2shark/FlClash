#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/patches/flclash-compat.patch"
CORE_DIR="$SCRIPT_DIR/Clash.Meta"

cd "$CORE_DIR"

if git apply --check "$PATCH_FILE" >/dev/null 2>&1; then
  echo "Applying FlClash compatibility patches..."
  git apply "$PATCH_FILE"
  echo "Patches applied."
elif git apply --reverse --check "$PATCH_FILE" >/dev/null 2>&1; then
  echo "FlClash compatibility patches are already applied."
else
  echo "FlClash compatibility patches cannot be applied cleanly." >&2
  exit 1
fi
