#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/Clash.Meta"

echo "Applying FlClash compatibility patches..."
git apply ../patches/flclash-compat.patch
echo "Patches applied."
