#!/usr/bin/env bash
set -euo pipefail

W="${W:-1100}"
H="${H:-96}"
SW="${SW:-3}"
L="${L:-30}"

ST=$(awk '/^\$color6/{print $3}' ~/.cache/wal/colors-hyprlock.conf 2>/dev/null || echo "#ffffff")
OUT="/tmp/hyprlock_greeting_corners.png"

magick -size ${W}x${H} xc:none \
  -stroke "$ST" -strokewidth "$SW" -fill none \
  -draw "line 0,0  $L,0" \
  -draw "line 0,0  0,$L" \
  -draw "line $((W-1)),$((H-1))  $((W-1-L)),$((H-1))" \
  -draw "line $((W-1)),$((H-1))  $((W-1)),$((H-1-L))" \
  "$OUT"

echo "$OUT"
