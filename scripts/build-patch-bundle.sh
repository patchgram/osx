#!/usr/bin/env bash
# Build + Ed25519-sign a patch bundle from the in-repo resources, ready to attach to a
# `patches-vN` GitHub release. Output dir gets: patches.json, engine.c.template,
# patch-manifest.json, patch-manifest.json.sig.
#
# Usage: scripts/build-patch-bundle.sh <bundleVersion> <minAppVersion> <privateKeyPem> [outDir] [notes]
set -euo pipefail
VERSION="${1:?bundle version (integer)}"
MIN_APP="${2:?minimum app version, e.g. 1.0.4}"
KEY="${3:?path to ed25519 private key pem}"
OUT="${4:-dist}"
NOTES="${5:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RES="$ROOT/Sources/PatchgramCore/Resources"
mkdir -p "$OUT"
cp "$RES/patches.json" "$OUT/patches.json"
cp "$RES/engine.c.template" "$OUT/engine.c.template"

PHASH="$(shasum -a 256 "$OUT/patches.json" | cut -d' ' -f1)"
EHASH="$(shasum -a 256 "$OUT/engine.c.template" | cut -d' ' -f1)"

# Compact, sorted-key manifest — the detached signature covers these exact bytes.
python3 - "$VERSION" "$MIN_APP" "$PHASH" "$EHASH" "$NOTES" > "$OUT/patch-manifest.json" <<'PY'
import json, sys
version, min_app, phash, ehash, notes = sys.argv[1:6]
manifest = {
    "bundleVersion": int(version),
    "minAppVersion": min_app,
    "files": {"engine.c.template": ehash, "patches.json": phash},
}
if notes:
    manifest["notes"] = notes
sys.stdout.write(json.dumps(manifest, sort_keys=True, separators=(",", ":")))
PY

openssl pkeyutl -sign -inkey "$KEY" -rawin \
  -in "$OUT/patch-manifest.json" -out "$OUT/patch-manifest.json.sig"

echo "Built + signed patch bundle v$VERSION (minApp $MIN_APP) in $OUT/:"
ls -1 "$OUT"
