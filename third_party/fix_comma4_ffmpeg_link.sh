#!/usr/bin/env bash
# Fix for a comma-4 (larch64/AGNOS) link error building loggerd/encoderd/bootlog/ubloxd:
#
#   undefined reference to `vaMapBuffer2'
#
# Root cause: the static ffmpeg libs bundled in the venv's `ffmpeg` pip package
# were built against a newer libva API than the system's libva.so.2 on this
# AGNOS image (checked: /usr/lib/aarch64-linux-gnu/libva.so.2 -> libva.so.2.2000.0,
# which exports vaMapBuffer but not vaMapBuffer2).
#
# Fix: link against the *static* libva/libva-drm/libdrm/libz/libswresample/libx264
# that shipped alongside that same ffmpeg build (matching ABI) instead of the
# system's dynamic libva, via a GROUP linker script at third_party/libavformat.so.
#
# Run this from the openpilot repo root before building:
#   bash third_party/fix_comma4_ffmpeg_link.sh
#
# Why a script and not committed binaries: these libs come from whatever
# ffmpeg pip package version is installed in /usr/local/venv on the device.
# Committing a binary snapshot would silently go stale (or wrong) if that
# venv is ever rebuilt with a different ffmpeg version. Regenerating from
# the live venv keeps the fix correct.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_FFMPEG_LIB="/usr/local/venv/lib/python3.12/site-packages/ffmpeg/install/lib"
THIRD_PARTY="$REPO_ROOT/third_party"

if [ ! -d "$VENV_FFMPEG_LIB" ]; then
  echo "ERROR: $VENV_FFMPEG_LIB not found (venv ffmpeg package layout may have changed)" >&2
  exit 1
fi

LIBS=(libx264.a libswresample.a libva.a libva-drm.a libdrm.a libz.a)

for lib in "${LIBS[@]}"; do
  src="$VENV_FFMPEG_LIB/$lib"
  if [ ! -f "$src" ]; then
    echo "ERROR: missing $src -- venv ffmpeg package may not bundle this lib anymore" >&2
    exit 1
  fi
  cp -v "$src" "$THIRD_PARTY/$lib"
done

cat > "$THIRD_PARTY/libavformat.so" << 'EOF'
GROUP ( libavformat.a libavcodec.a libavutil.a libswresample.a libx264.a libva.a libva-drm.a libdrm.a libz.a )
EOF

echo "Wrote $THIRD_PARTY/libavformat.so (GROUP linker script) and matching static libs."
echo "Sanity check: system libva.so.2 vaMapBuffer2 support:"
if command -v nm >/dev/null 2>&1; then
  target=$(readlink -f /usr/lib/aarch64-linux-gnu/libva.so.2 2>/dev/null || true)
  if [ -n "$target" ]; then
    if nm -D /usr/lib/aarch64-linux-gnu/libva.so.2 2>/dev/null | grep -q vaMapBuffer2; then
      echo "  system libva ($target) already has vaMapBuffer2 -- this workaround may no longer be necessary."
    else
      echo "  system libva ($target) lacks vaMapBuffer2 -- this workaround is still needed."
    fi
  fi
fi
