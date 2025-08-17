#!/bin/bash

# Load pywal JSON file
WAL_COLORS="$HOME/.cache/wal/colors.json"
LOOK_FILE="$HOME/.config/hypr/themes/pretty-look.conf"
COLOR_FILE="$HOME/.cache/wal/colors-hyprland.conf"
HYPRLOCK_FILE="$HOME/.cache/wal/colors-hyprlock.conf"   # << added

if [ ! -f "$WAL_COLORS" ]; then
    echo "Pywal colors.json not found!"
    exit 1
fi
WALLPAPER=$(jq -r '.wallpaper' ~/.cache/wal/colors.json)

# Update hyprlock.conf background path
sed -i "s|^    path = .*|    path = $WALLPAPER|" ~/.config/hypr/hyprlock.conf

# Flatten to a single space-separated string
color_values=$(jq -r '.colors[]' "$WAL_COLORS" | paste -sd' ' -)

# Use read to assign to named variables
read -r color0 color1 color2 color3 color4 color5 color6 color7 \
         color8 color9 color10 color11 color12 color13 color14 color15 <<< "$color_values"

# Also pull special colors and alpha (percent 0..100)
foreground=$(jq -r '.special.foreground' "$WAL_COLORS")
background=$(jq -r '.special.background' "$WAL_COLORS")
alpha_pct=$(jq -r '.alpha // "100"' "$WAL_COLORS")

# ---- helpers ----
# Hyprland hex-in-rgba (kept as-is for pretty-look.conf)
to_rgba() {
    hex=${1#"#"}
    alpha=${2:-ff}
    echo "rgba(${hex}${alpha})"
}

# Minimal helpers for Hyprlock numeric rgba
alpha255() { # "100" -> 255, "75" -> 191, etc.
    awk -v p="${1:-100}" 'BEGIN{
        n = int((p+0) * 2.55 + 0.5);
        if (n < 0) n = 0; if (n > 255) n = 255;
        printf "%d", n
    }'
}
hex2rgb() { # "#RRGGBB" -> "r g b"
    local h="${1#\#}"
    printf '%d %d %d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}
# rgba_num() { # usage: rgba_num "#RRGGBB" [alpha_percent]
#     local hex="$1"
#     local p="${2:-$alpha_pct}"
#     local r g b a
#     read -r r g b < <(hex2rgb "$hex")
#     a=$(alpha255 "$p")
#     printf 'rgba(%d, %d, %d, %d)' "$r" "$g" "$b" "$a"
# }
rgba_num() { # usage: rgba_num "#RRGGBB" [alpha_percent]
    local hex="$1"
    local p="${2:-$alpha_pct}"
    local r g b a
    read -r r g b < <(hex2rgb "$hex")
    a=$(awk -v p="$p" 'BEGIN { printf "%.2f", p/100 }')
    printf 'rgba(%d, %d, %d, %s)' "$r" "$g" "$b" "$a"
}
# 1) Generate colors-hyprland.conf (HEX) — unchanged behavior
cat > "$COLOR_FILE" <<EOF
# Auto-generated Hyprland color definitions from pywal
\$color0  = $color0
\$color1  = $color1
\$color2  = $color2
\$color3  = $color3
\$color4  = $color4
\$color5  = $color5
\$color6  = $color6
\$color7  = $color7
\$color8  = $color8
\$color9  = $color9
\$color10 = $color10
\$color11 = $color11
\$color12 = $color12
\$color13 = $color13
\$color14 = $color14
\$color15 = $color15
\$foreground = $foreground
\$background = $background
EOF

# 2) Generate pretty-look.conf (HEX-in-RGBA) — unchanged behavior
cat > "$LOOK_FILE" <<EOF
# Auto-generated look and feel for Hyprland using pywal

general {
    gaps_in = 3
    gaps_out = 4
    border_size = 2
    col.active_border = $(to_rgba $color5) $(to_rgba $color6) 45deg
    col.inactive_border = $(to_rgba $color1)
    resize_on_border = false
    layout = dwindle
}

decoration {
    rounding = 12
    rounding_power = 3
    active_opacity = 1.0
    inactive_opacity = 0.8

    shadow {
        enabled = true
        range = 8
        render_power = 4
        color = $(to_rgba $color5)
    }

    blur {
        enabled = true
        size = 8
        passes = 3
        ignore_opacity = false
        new_optimizations = true
        xray = true
        vibrancy = 0.5
    }
}
EOF

# 3) Generate colors-hyprlock.conf (NUMERIC RGBA) — added for Hyprlock
{
  echo "# Auto-generated for Hyprlock (numeric rgba, alpha from pywal: ${alpha_pct}%)"
  echo "\$background = $(rgba_num "$background")"
  echo "\$foreground = $(rgba_num "$foreground")"
  echo "\$color0  = $(rgba_num "$color0")"
  echo "\$color1  = $(rgba_num "$color1")"
  echo "\$color2  = $(rgba_num "$color2")"
  echo "\$color3  = $(rgba_num "$color3")"
  echo "\$color4  = $(rgba_num "$color4")"
  echo "\$color5  = $(rgba_num "$color5")"
  echo "\$color6  = $(rgba_num "$color6")"
  echo "\$color7  = $(rgba_num "$color7")"
  echo "\$color8  = $(rgba_num "$color8")"
  echo "\$color9  = $(rgba_num "$color9")"
  echo "\$color10 = $(rgba_num "$color10")"
  echo "\$color11 = $(rgba_num "$color11")"
  echo "\$color12 = $(rgba_num "$color12")"
  echo "\$color13 = $(rgba_num "$color13")"
  echo "\$color14 = $(rgba_num "$color14")"
  echo "\$color15 = $(rgba_num "$color15")"
} > "$HYPRLOCK_FILE"

echo "✅ Generated:"
echo "  - $COLOR_FILE"
echo "  - $LOOK_FILE"
echo "  - $HYPRLOCK_FILE"
