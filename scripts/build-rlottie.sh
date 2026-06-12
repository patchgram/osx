#!/usr/bin/env bash
# Build the rlottie static library (arm64) the overlay uses to render .tgs animated stickers.
# Output: Sources/PatchgramCore/Resources/librlottie.a  (an APP resource — not part of the signed
# patch bundle, so the bundle manifest/format is unaffected by rebuilding it).
#
# Apple-Silicon gotchas baked in below:
#   - LOTTIE_MODULE=OFF  : no dlopen'd external image-loader module (vector stickers only).
#   - -U__ARM_NEON__ / -U__ARM_NEON : rlottie's NEON drawhelper (vdrawhelper_neon.cpp) calls
#     hand-written 32-bit-ARM pixman assembly (pixman-arm-neon-asm.S) that does NOT assemble for
#     Mach-O/arm64 and is only added when ARCH==arm. Undefining the macro disables that path so the
#     portable C++ rasterizer (vdrawhelper.cpp) is used → no undefined _pixman_composite_*_neon.
#   - CMAKE_POLICY_VERSION_MINIMUM=3.5 : rlottie's CMakeLists predates cmake 4's floor.
#
# Usage: scripts/build-rlottie.sh [rlottie-git-rev]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REV="${1:-bf689b7}"   # known-good pinned commit
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git clone https://github.com/Samsung/rlottie.git "$WORK/rlottie"
git -C "$WORK/rlottie" checkout "$REV"

cmake -S "$WORK/rlottie" -B "$WORK/rlottie/build" -G "Unix Makefiles" \
  -DBUILD_SHARED_LIBS=OFF -DLOTTIE_MODULE=OFF -DLOTTIE_THREAD=ON \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_CXX_FLAGS="-U__ARM_NEON__ -U__ARM_NEON" \
  -DCMAKE_C_FLAGS="-U__ARM_NEON__ -U__ARM_NEON"
cmake --build "$WORK/rlottie/build" -j8 --target rlottie

DEST="$ROOT/Sources/PatchgramCore/Resources/librlottie.a"
cp "$WORK/rlottie/build/librlottie.a" "$DEST"
echo "Installed $DEST ($(du -h "$DEST" | cut -f1), $(lipo -info "$DEST" | sed 's/.*architecture: //'))"
nm "$DEST" | grep -q lottie_animation_from_data && echo "C API present ✓"
nm "$DEST" | grep -q 'pixman_composite.*neon' && { echo "ERROR: NEON asm refs still present" >&2; exit 1; } || echo "No NEON asm deps ✓"
