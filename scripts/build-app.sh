#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/Patchgram.app"
EXECUTABLE="$ROOT/.build/release/patchgram"
LOGO="$ROOT/Sources/Patchgram/Resources/PatchgramLogo.svg"
TELEGRAM_LOGO="$ROOT/Sources/Patchgram/Resources/TelegramLogo.svg"
APP_ICON_SVG_SOURCE="$ROOT/assets/PatchgramAppIcon.svg"
APP_ICON_PNG_SOURCE="$ROOT/assets/PatchgramAppIcon.png"
RESOURCE_BUNDLE="$ROOT/.build/release/Patchgram_Patchgram.bundle"
# PatchgramCore ships patches.json + engine.c.template via Bundle.module; its resource bundle must
# sit next to the executable in the installed .app or Bundle.module fails to resolve at runtime.
CORE_RESOURCE_BUNDLE="$ROOT/.build/release/Patchgram_PatchgramCore.bundle"
SWIFTPM_CACHE="$ROOT/.build/swiftpm-cache"
SWIFTPM_CONFIG="$ROOT/.build/swiftpm-config"
SWIFTPM_SECURITY="$ROOT/.build/swiftpm-security"
MODULE_CACHE="$ROOT/.build/module-cache"
ICON_WORK="$ROOT/.build/app-icon"
ICON_SVG="$ICON_WORK/PatchgramIcon.svg"
ICONSET="$ICON_WORK/Patchgram.iconset"
ICON_PNG="$ICON_WORK/PatchgramIcon.svg.png"
ICON_FILE="$APP/Contents/Resources/Patchgram.icns"

if /usr/bin/pgrep -x Patchgram >/dev/null 2>&1; then
  /usr/bin/osascript -e 'tell application id "local.patchgram.app" to quit' >/dev/null 2>&1 || true
  for _ in {1..30}; do
    if ! /usr/bin/pgrep -x Patchgram >/dev/null 2>&1; then
      break
    fi
    sleep 0.2
  done
  if /usr/bin/pgrep -x Patchgram >/dev/null 2>&1; then
    /usr/bin/pkill -x Patchgram >/dev/null 2>&1 || true
  fi
fi

cd "$ROOT"
mkdir -p "$SWIFTPM_CACHE" "$SWIFTPM_CONFIG" "$SWIFTPM_SECURITY" "$MODULE_CACHE"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"

python3 scripts/generate-binary-patch-registry.py
swift build \
  --disable-sandbox \
  --cache-path "$SWIFTPM_CACHE" \
  --config-path "$SWIFTPM_CONFIG" \
  --security-path "$SWIFTPM_SECURITY" \
  --manifest-cache local \
  -Xswiftc -module-cache-path \
  -Xswiftc "$MODULE_CACHE" \
  -c release

# Resolve the real products dir from SwiftPM (the .build layout / triple varies by toolchain) so we
# never silently miss the resource bundle and ship an app that crashes on launch.
BIN_PATH="$(swift build \
  --cache-path "$SWIFTPM_CACHE" \
  --config-path "$SWIFTPM_CONFIG" \
  --security-path "$SWIFTPM_SECURITY" \
  --manifest-cache local \
  -c release --show-bin-path)"
EXECUTABLE="$BIN_PATH/patchgram"
RESOURCE_BUNDLE="$BIN_PATH/Patchgram_Patchgram.bundle"
CORE_RESOURCE_BUNDLE="$BIN_PATH/Patchgram_PatchgramCore.bundle"

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
rm -f "$APP/Contents/Resources/PatchgramLogo.png"
cp "$EXECUTABLE" "$APP/Contents/MacOS/Patchgram"
cp "$LOGO" "$APP/Contents/Resources/PatchgramLogo.svg"
cp "$TELEGRAM_LOGO" "$APP/Contents/Resources/TelegramLogo.svg"
if [ -d "$RESOURCE_BUNDLE" ]; then
  rm -rf "$APP/Contents/Resources/$(basename "$RESOURCE_BUNDLE")"
  cp -R "$RESOURCE_BUNDLE" "$APP/Contents/Resources/"
fi
# PatchgramCore's resource bundle is REQUIRED (patches.json / engine.c.template / librlottie.a). A
# missing copy makes the app fatal-error at first launch, so fail the build loudly instead.
if [ ! -d "$CORE_RESOURCE_BUNDLE" ]; then
  echo "error: required resource bundle not found at $CORE_RESOURCE_BUNDLE" >&2
  exit 1
fi
rm -rf "$APP/Contents/Resources/$(basename "$CORE_RESOURCE_BUNDLE")"
cp -R "$CORE_RESOURCE_BUNDLE" "$APP/Contents/Resources/"

rm -rf "$ICON_WORK"
mkdir -p "$ICON_WORK" "$ICONSET"
# Prefer a ready-made 1024 PNG app icon (assets/PatchgramAppIcon.png); else render the SVG fallback.
if [ -f "$APP_ICON_PNG_SOURCE" ]; then
  cp "$APP_ICON_PNG_SOURCE" "$ICON_PNG"
else
  if [ -f "$APP_ICON_SVG_SOURCE" ]; then
    cp "$APP_ICON_SVG_SOURCE" "$ICON_SVG"
  else
    {
      printf '%s\n' '<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">'
      printf '%s\n' '<defs><linearGradient id="bg" x1="168" y1="112" x2="856" y2="912" gradientUnits="userSpaceOnUse"><stop stop-color="#37C7FF"/><stop offset="0.55" stop-color="#249BEF"/><stop offset="1" stop-color="#1572D2"/></linearGradient></defs>'
      printf '%s\n' '<rect x="80" y="80" width="864" height="864" rx="200" fill="url(#bg)"/>'
      printf '%s\n' '<svg x="132" y="132" width="760" height="760" viewBox="190 190 690 690">'
      sed -n '/<path /p' "$LOGO"
      printf '%s\n' '</svg></svg>'
    } > "$ICON_SVG"
  fi
  /usr/bin/qlmanage -t -s 1024 -o "$ICON_WORK" "$ICON_SVG" >/dev/null 2>&1 || true
fi

if [ -f "$ICON_PNG" ]; then
  /usr/bin/sips -z 16 16 "$ICON_PNG" --out "$ICONSET/icon_16x16.png" >/dev/null
  /usr/bin/sips -z 32 32 "$ICON_PNG" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
  /usr/bin/sips -z 32 32 "$ICON_PNG" --out "$ICONSET/icon_32x32.png" >/dev/null
  /usr/bin/sips -z 64 64 "$ICON_PNG" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
  /usr/bin/sips -z 128 128 "$ICON_PNG" --out "$ICONSET/icon_128x128.png" >/dev/null
  /usr/bin/sips -z 256 256 "$ICON_PNG" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
  /usr/bin/sips -z 256 256 "$ICON_PNG" --out "$ICONSET/icon_256x256.png" >/dev/null
  /usr/bin/sips -z 512 512 "$ICON_PNG" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
  /usr/bin/sips -z 512 512 "$ICON_PNG" --out "$ICONSET/icon_512x512.png" >/dev/null
  /usr/bin/sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
  /usr/bin/iconutil -c icns "$ICONSET" -o "$ICON_FILE"
else
  printf 'warning: skipped app icon generation because QuickLook could not render %s\n' "$ICON_SVG" >&2
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Patchgram</string>
  <key>CFBundleIdentifier</key>
  <string>local.patchgram.app</string>
  <key>CFBundleIconFile</key>
  <string>Patchgram</string>
  <key>CFBundleName</key>
  <string>Patchgram</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.2.0</string>
  <key>CFBundleVersion</key>
  <string>23</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

/usr/bin/codesign --force --deep --sign - "$APP"
/usr/bin/codesign --verify --deep --strict "$APP"

echo "Built $APP"
