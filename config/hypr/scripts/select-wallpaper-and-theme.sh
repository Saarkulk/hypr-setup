#!/bin/bash

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/wallpaper"
THEME_SCRIPT="$HOME/.config/hypr/scripts/wal-to-hyprland.sh"
# LOOK_SCRIPT="$HOME/.config/hypr/scripts/gen-pretty-look.sh"
BACKUP_DIR="/tmp/wal-backup-$$"

mkdir -p "$BACKUP_DIR"
restart_waybar() {
    echo "Restarting Waybar..."
    pkill waybar &>/dev/null || true
    waybar & disown
    sleep 1

    if ! pgrep -x waybar > /dev/null; then
        notify-send "⚠️ Waybar failed to start" "Check config or style for errors"
        echo "Waybar did not restart. Please check ~/.config/waybar/config.jsonc and style.css"
        restore_previous
        exit 1
    fi
}
# YAD wallpaper picker (RUN FIRST before backing up anything!)
selected=$(GTK_THEME=Breeze:dark yad --fontname="JetBrainsMono Nerd Font 12" --file \
    --title="Select a Wallpaper" \
    --file-filter="Wallpapers | *.png *.jpg *.jpeg *.webp" \
    --filename="$WALLPAPER_DIR/" \
    --width=1500 --height=800 \
    --add-preview \
    --large-preview)

# Handle cancel or blank selection
if [[ -z "$selected" ]] || [[ ! -f "$selected" ]]; then
    notify-send "❌ Cancelled or invalid selection" "No wallpaper was selected. No changes made."
    echo "No valid wallpaper selected. Exiting safely."
    exit 0
fi

# Continue only after safe selection
echo "Wallpaper selected: $selected"

# Backup current state AFTER selection is confirmed
cp ~/.cache/wal/colors.{sh,json} "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.cache/wal/colors-hyprland.conf "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.config/hypr/hyprpaper.conf "$BACKUP_DIR/" 2>/dev/null || true

restore_previous() {
    echo "Reverting to previous theme..."
    cp "$BACKUP_DIR/colors.sh" ~/.cache/wal/colors.sh 2>/dev/null || true
    cp "$BACKUP_DIR/colors.json" ~/.cache/wal/colors.json 2>/dev/null || true
    cp "$BACKUP_DIR/colors-hyprland.conf" ~/.cache/wal/colors-hyprland.conf 2>/dev/null || true
    cp "$BACKUP_DIR/hyprpaper.conf" ~/.config/hypr/hyprpaper.conf 2>/dev/null || true
    cp "$BACKUP_DIR/swaync-style.css" ~/.config/swaync/style.css 2>/dev/null || true

    killall hyprpaper &>/dev/null || true
    hyprpaper & disown
        # try to gracefully reload or restart SwayNC
    if pgrep -x swaync >/dev/null 2>&1; then
        swaync-client -rs >/dev/null 2>&1 || { pkill swaync || true; (swaync & disown) || true; }
    fi
    hyprctl reload
    notify-send "❌ Theme change failed" "Restored previous setup"
}

restart_swaync() {
  # Prefer graceful style reload; fall back to full restart
  if command -v swaync-client >/dev/null 2>&1 && pgrep -x swaync >/dev/null 2>&1; then
    swaync-client -rs >/dev/null 2>&1 || { pkill swaync || true; swaync & disown; }
  else
    pkill swaync &>/dev/null || true
    swaync & disown
  fi
}
# Trap any error and revert
trap restore_previous ERR

# Apply Pywal
wal -i "$selected"

# Update Hyprpaper
echo -e "preload = $selected\nwallpaper = ,$selected" > ~/.config/hypr/hyprpaper.conf
killall hyprpaper &>/dev/null
hyprpaper & disown

# Generate Hyprland themes
"$THEME_SCRIPT"
# "$LOOK_SCRIPT"
~/.config/wofi/scripts/gen-wofi-style.sh

# Update Waybar contrast colors
~/.config/waybar/scripts/toggle-waybar-contrast.py || echo "Contrast script failed"

echo "Reloading Waybar with new theme..."
restart_waybar

echo "Reloading swaync with new theme..."
restart_swaync

# Firefox update
if command -v pywalfox &>/dev/null; then
    if pgrep firefox > /dev/null; then
        echo "Updating existing Firefox theme..."
        pywalfox update
    else
        echo "Launching Firefox..."
        firefox & disown
        sleep 2
        pywalfox update
    fi
fi

# Reload Hyprland config
hyprctl reload

notify-send "✅ Theme Applied!" "$selected"
echo "Theme applied successfully!"
