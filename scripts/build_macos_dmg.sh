#!/usr/bin/env bash
# Build a distributable macOS .dmg for Cairn.
#
# Usage:
#   scripts/build_macos_dmg.sh           # use version from pubspec.yaml
#   scripts/build_macos_dmg.sh 1.2.3     # override version suffix
#
# Output: build/Cairn-<version>.dmg
#
# Requires: flutter, create-dmg (brew install create-dmg).
# The resulting .dmg is NOT signed or notarized — first-time users will
# need to right-click → Open once to bypass Gatekeeper. For public
# distribution, sign & notarize after this script (see CLAUDE notes).

set -euo pipefail

# cd to repo root (script lives in scripts/)
cd "$(dirname "$0")/.."

# --- Preflight ---------------------------------------------------------
command -v flutter    >/dev/null || { echo "flutter not on PATH"; exit 1; }
command -v create-dmg >/dev/null || {
  echo "create-dmg not found. Install with: brew install create-dmg"
  exit 1
}

# --- Resolve version ---------------------------------------------------
VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
fi
if [[ -z "$VERSION" ]]; then
  echo "could not determine version"; exit 1
fi
echo "==> Building Cairn $VERSION"

# --- Build app ---------------------------------------------------------
flutter build macos --release

APP_PATH="build/macos/Build/Products/Release/cairn.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but $APP_PATH is missing"; exit 1
fi

# --- Package dmg -------------------------------------------------------
DMG_PATH="build/Cairn-$VERSION.dmg"
rm -f "$DMG_PATH"

echo "==> Creating $DMG_PATH"
create-dmg \
  --volname "Cairn $VERSION" \
  --window-size 520 340 \
  --icon-size 96 \
  --icon "cairn.app" 140 170 \
  --app-drop-link 380 170 \
  --hide-extension "cairn.app" \
  "$DMG_PATH" \
  "$APP_PATH"

echo
echo "✅ Done: $(pwd)/$DMG_PATH"
du -h "$DMG_PATH" | awk '{print "   size: "$1}'
