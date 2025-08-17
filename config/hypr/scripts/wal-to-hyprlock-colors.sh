#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-$HOME/.cache/wal/colors-hyprland.conf}"
DST="${2:-$HOME/.cache/wal/colors-hyprlock.conf}"

tmp="$(mktemp)"
{
  echo "# Auto-generated for Hyprlock (rgba numeric, no '#')"
  while read -r name eq val; do
    # expect lines like: $color11 = #E5447A
    [[ "$name" =~ ^\$color[0-9]+$ ]] || continue
    hex="${val#\#}"              # strip leading #
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    echo "$name = rgba($r, $g, $b, 1.0)"
  done < "$SRC"
  # optional: foreground if present in hyprland file
  fg="$(grep -E '^\$foreground' "$SRC" 2>/dev/null | awk '{print $3}')"
  if [[ -n "${fg:-}" ]]; then
    hex="${fg#\#}"; r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
    echo "\$foreground = rgba($r, $g, $b, 1.0)"
  fi
} > "$tmp"

mv "$tmp" "$DST"
echo "Wrote $DST"
