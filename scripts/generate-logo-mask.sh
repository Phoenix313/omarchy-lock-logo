#!/usr/bin/env bash
# Converts a PNG into a white silhouette with transparency, ready to be
# colorized by QML MultiEffect (colorization) on the Omarchy lock screen.
# Dark motif on a plain light background works best.
#
# Usage: generate-logo-mask.sh <input.png> [output.png]

set -euo pipefail

IN="${1:?usage: generate-logo-mask.sh <input.png> [output.png]}"
OUT="${2:-logo-tint.png}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v magick >/dev/null || { echo "error: ImageMagick 7 (magick) not found" >&2; exit 1; }

# 1. Grayscale intensity, inverted: dark motif -> bright, light background -> dark.
#    -level pushes the background fully to black (alpha 0) and hardens the motif.
# 2. Recolor the shape to solid white.
# 3. Use the mask intensity as alpha channel (CopyOpacity).
# 4. Trim transparent margins and cap the size for QML loading.
magick "$IN" -colorspace gray -negate -level 12%,88% "$TMP/mask.png"
magick "$TMP/mask.png" -fill white -colorize 100 "$TMP/white.png"
magick "$TMP/white.png" "$TMP/mask.png" -alpha off -compose CopyOpacity -composite \
  -trim +repage -resize 900x900 "$OUT"

echo "Written: $OUT"
