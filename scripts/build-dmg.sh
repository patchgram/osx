#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/Patchgram.app"
DMG_ROOT="$ROOT/.build/dmg-root"
DMG="$ROOT/.build/Patchgram.dmg"
RW_DMG="$ROOT/.build/Patchgram-rw.dmg"
VOLUME_NAME="Patchgram"
MOUNT_DIR="/Volumes/$VOLUME_NAME"
APP_NAME="Patchgram.app"
BACKGROUND_NAME="dmg-background.tiff"
VOLUME_ICON_NAME="dmg-volume.icns"

find_asset() {
  local name
  for name in "$@"; do
    if [[ -f "$ROOT/assets/$name" ]]; then
      printf '%s\n' "$ROOT/assets/$name"
      return 0
    fi
  done
  return 1
}

cleanup() {
  if [[ -d "$MOUNT_DIR" ]]; then
    /usr/bin/hdiutil detach "$MOUNT_DIR" -quiet >/dev/null 2>&1 || \
      /usr/bin/hdiutil detach "$MOUNT_DIR" -force -quiet >/dev/null 2>&1 || true
    rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
  fi
  rm -rf "$DMG_ROOT"
  rm -f "$RW_DMG"
}

trap cleanup EXIT

"$ROOT/scripts/build-app.sh"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
rm -f "$DMG" "$RW_DMG"
if [[ -d "$MOUNT_DIR" ]]; then
  /usr/bin/hdiutil detach "$MOUNT_DIR" -quiet >/dev/null 2>&1 || \
    /usr/bin/hdiutil detach "$MOUNT_DIR" -force -quiet >/dev/null 2>&1 || \
    rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
fi

cp -R "$APP" "$DMG_ROOT/$APP_NAME"
ln -s /Applications "$DMG_ROOT/Applications"

BACKGROUND_SRC="$(find_asset dmg-background.tiff dmg-background.tif dmg-background.png dmg-background.jpg dmg-background.jpeg || true)"
VOLUME_ICON_SRC="$(find_asset "$VOLUME_ICON_NAME" || true)"
if [[ -z "$VOLUME_ICON_SRC" && -f "$APP/Contents/Resources/Patchgram.icns" ]]; then
  VOLUME_ICON_SRC="$APP/Contents/Resources/Patchgram.icns"
fi

if [[ -n "$BACKGROUND_SRC" ]]; then
  mkdir -p "$DMG_ROOT/.background"
  case "${BACKGROUND_SRC##*.}" in
    tiff|tif|TIFF|TIF)
      cp "$BACKGROUND_SRC" "$DMG_ROOT/.background/$BACKGROUND_NAME"
      ;;
    *)
      /usr/bin/sips -s format tiff "$BACKGROUND_SRC" --out "$DMG_ROOT/.background/$BACKGROUND_NAME" >/dev/null
      ;;
  esac
fi

if [[ -n "$VOLUME_ICON_SRC" ]]; then
  cp "$VOLUME_ICON_SRC" "$DMG_ROOT/.VolumeIcon.icns"
fi

/usr/bin/hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_ROOT" \
  -size 1g \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  -o "$RW_DMG"

/usr/bin/hdiutil attach "$RW_DMG" \
  -readwrite \
  -noverify \
  -nobrowse \
  -mountpoint "$MOUNT_DIR"

if [[ -n "$VOLUME_ICON_SRC" ]]; then
  cp "$VOLUME_ICON_SRC" "$MOUNT_DIR/.VolumeIcon.icns"
fi

if [[ -f "$MOUNT_DIR/.VolumeIcon.icns" && -x /usr/bin/SetFile ]]; then
  /usr/bin/SetFile -a C "$MOUNT_DIR"
fi

if [[ -f "$MOUNT_DIR/.background/$BACKGROUND_NAME" ]]; then
  BACKGROUND_SCRIPT='set background picture of viewOptions to file ".background:dmg-background.tiff"'
else
  BACKGROUND_SCRIPT='set background color of viewOptions to {65535, 65535, 65535}'
fi

/usr/bin/osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {100, 100, 580, 340}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 80
    set text size of viewOptions to 12
    $BACKGROUND_SCRIPT
    set position of item "$APP_NAME" of container window to {120, 124}
    set position of item "Applications" of container window to {360, 124}
    close
    open
    update without registering applications
    delay 2
  end tell
end tell
APPLESCRIPT

/usr/sbin/bless --folder "$MOUNT_DIR" --openfolder "$MOUNT_DIR" || true

if [[ -n "$VOLUME_ICON_SRC" ]]; then
  cp "$VOLUME_ICON_SRC" "$MOUNT_DIR/.VolumeIcon.icns"
  if [[ -x /usr/bin/SetFile ]]; then
    /usr/bin/SetFile -a C "$MOUNT_DIR"
  fi
fi

sync
/usr/bin/hdiutil detach "$MOUNT_DIR" -quiet
rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true

/usr/bin/hdiutil convert "$RW_DMG" \
  -format UDBZ \
  -imagekey bzip2-level=9 \
  -o "$DMG"

rm -f "$RW_DMG"
rm -rf "$DMG_ROOT"

echo "Built $DMG"
