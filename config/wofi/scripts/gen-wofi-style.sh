#!/bin/bash

# === File Paths ===
COLORS="$HOME/.cache/wal/colors-waybar.css"
STYLE_BASE_SCSS="$HOME/.config/wofi/style-base.scss"
STYLE_BASE_CSS="$HOME/.config/wofi/style-base.css"
STYLE_OUT_SCSS="$HOME/.config/wofi/style.scss"
STYLE_OUT_CSS="$HOME/.config/wofi/style.css"

# === Validate Inputs ===
if [[ ! -f "$COLORS" || ! -f "$STYLE_BASE_SCSS" || ! -f "$STYLE_BASE_CSS" ]]; then
    echo "❌ Missing input files."
    exit 1
fi

# === Build color map ===
declare -A COLOR_MAP

while read -r line; do
    [[ "$line" =~ @define-color[[:space:]]+([a-zA-Z0-9_-]+)[[:space:]]+#([a-fA-F0-9]{6}) ]] || continue
    COLOR_MAP["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
done < "$COLORS"

# === Read base style ===
STYLE_CSS=$(<"$STYLE_BASE_CSS")
STYLE_SCSS=$(<"$STYLE_BASE_SCSS")

# === Replace @colorX-0.6 with rgba ===
for name in "${!COLOR_MAP[@]}"; do
    hex="${COLOR_MAP[$name]}"
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))

    # Match any @name-A format like @color0-0.4
    while [[ "$STYLE_CSS" =~ @$name-([0-9.]+) ]]; do
        alpha="${BASH_REMATCH[1]}"
        rgba="rgba($r, $g, $b, $alpha)"
        STYLE_CSS="${STYLE_CSS//@$name-$alpha/$rgba}"
    done
done

# === Replace remaining @colorX with #hex ===
for name in "${!COLOR_MAP[@]}"; do
    STYLE_CSS="${STYLE_CSS//@$name/#${COLOR_MAP[$name]}}"
done

# === Write out final style.css ===
echo "$STYLE_CSS" > "$STYLE_OUT_CSS"
echo "✅ Generated $STYLE_OUT_CSS"

# === Replace @colorX-0.6 with rgba ===
for name in "${!COLOR_MAP[@]}"; do
    hex="${COLOR_MAP[$name]}"
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))

    # Match any @name-A format like @color0-0.4
    while [[ "$STYLE_SCSS" =~ @$name-([0-9.]+) ]]; do
        alpha="${BASH_REMATCH[1]}"
        rgba="rgba($r, $g, $b, $alpha)"
        STYLE_SCSS="${STYLE_SCSS//@$name-$alpha/$rgba}"
    done
done

# === Replace remaining @colorX with #hex ===
for name in "${!COLOR_MAP[@]}"; do
    STYLE_SCSS="${STYLE_SCSS//@$name/#${COLOR_MAP[$name]}}"
done

# === Write out final style.css ===
echo "$STYLE_SCSS" > "$STYLE_OUT_SCSS"
echo "✅ Generated $STYLE_OUT_SCSS"
