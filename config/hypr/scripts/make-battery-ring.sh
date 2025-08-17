#!/usr/bin/env bash
set -euo pipefail

SIZE="${1:-250}"
RING_W="${2:-10}"
TRACK_A="${3:-0.28}"

ACC="${ACC:-#88c0d0}"
TRK="${TRK:-#ffffff}"

BAT=$(upower -e | grep -m1 BAT || true)
if [[ -z "${BAT}" ]]; then P=100
else P=$(upower -i "$BAT" | awk -F': ' '/percentage/{gsub("%","",$2);print int($2)}')
fi

MARGIN=$((RING_W/2 + 2))
X0=$MARGIN; Y0=$MARGIN
X1=$((SIZE - MARGIN)); Y1=$((SIZE - MARGIN))
START=-90
END=$(awk -v p="$P" -v s="$START" 'BEGIN{printf "%.2f", s + 3.6*p}')

OUT="/tmp/hyprlock_battery_ring.png"

magick -size ${SIZE}x${SIZE} xc:none \
  \( -size ${SIZE}x${SIZE} xc:none -fill none -stroke "$TRK" -strokewidth "$RING_W" \
     -draw "arc $X0,$Y0 $X1,$Y1 0,359.9" \
     -alpha set -channel A -evaluate multiply "$TRACK_A" +channel \) \
  -compose over -composite \
  \( -size ${SIZE}x${SIZE} xc:none -fill none -stroke "$ACC" -strokewidth "$RING_W" \
     -draw "arc $X0,$Y0 $X1,$Y1 $START,$END" \) \
  -compose over -composite "$OUT"

echo "$OUT"
