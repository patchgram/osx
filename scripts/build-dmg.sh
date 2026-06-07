#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/Patchgram.app"
DMG_ROOT="$ROOT/.build/dmg-root"
DMG="$ROOT/.build/Patchgram.dmg"
LEGACY_MOUNT_DIR="$ROOT/.build/dmg-mount"
LEGACY_RW_DMG="$ROOT/.build/Patchgram-rw.dmg"
VOLUME_NAME="Patchgram"

"$ROOT/scripts/build-app.sh"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
rm -f "$DMG" "$LEGACY_RW_DMG"
rm -rf "$LEGACY_MOUNT_DIR"

cp -R "$APP" "$DMG_ROOT/Patchgram.app"
ln -s /Applications "$DMG_ROOT/Applications"

/usr/bin/hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_ROOT" \
  -fs HFS+ \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG"

rm -rf "$DMG_ROOT"

echo "Built $DMG"
