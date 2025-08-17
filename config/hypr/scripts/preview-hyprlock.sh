#!/usr/bin/env bash
set -euo pipefail

# ---- output ----
OUT="${1:-$HOME/Pictures/hyprlock-preview.png}"

# ---- sanity ----
: "${XDG_RUNTIME_DIR:="/run/user/$UID"}"
if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
  echo "XDG_RUNTIME_DIR not set/exists. Aborting."; exit 1
fi
if [[ "$(id -u)" = "0" ]]; then
  echo "Don't run this as root/sudo."; exit 1
fi

# ---- pick size ----
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  read -r W H < <(hyprctl monitors -j | jq -r '.[0] | "\(.width) \(.height)"')
else
  W=1920; H=1080
fi

# ---- temp config for nested Hyprland ----
TMPDIR="$(mktemp -d)"
CONF="$TMPDIR/hypr-preview.conf"
cat > "$CONF" <<EOF
monitor=,${W}x${H}@60,0x0,1
input { kb_layout = us }
# keep it minimal; no bars/wallpaper
EOF

# ---- remember existing wayland-* sockets ----
mapfile -t BEFORE < <(ls -1 "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | xargs -n1 -I{} basename {} || true)

# ---- generate optional assets (uses magick in your scripts) ----
[ -x "$HOME/.config/hypr/scripts/make-battery-ring.sh" ] && "$HOME/.config/hypr/scripts/make-battery-ring.sh" 250 10 0.28 >/dev/null || true
[ -x "$HOME/.config/hypr/scripts/make-greeting-corners.sh" ] && "$HOME/.config/hypr/scripts/make-greeting-corners.sh" >/dev/null || true

# ---- launch nested Hyprland (no socket args; let it create one) ----
HYPRLAND_INSTANCE_SIGNATURE="preview-$RANDOM" \
Hyprland --config "$CONF" >/tmp/hypr-preview.log 2>&1 &
NESTED_PID=$!

# ---- find the new socket name ----
SOCK=""
for i in {1..100}; do
  mapfile -t NOW < <(ls -1 "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | xargs -n1 -I{} basename {} || true)
  for s in "${NOW[@]}"; do
    FOUND_BEFORE=false
    for b in "${BEFORE[@]}"; do [[ "$s" == "$b" ]] && FOUND_BEFORE=true && break; done
    if ! $FOUND_BEFORE; then SOCK="$s"; break; fi
  done
  [[ -n "$SOCK" ]] && break
  sleep 0.05
done

if [[ -z "$SOCK" ]]; then
  echo "Couldn't detect nested Wayland socket. See /tmp/hypr-preview.log"
  kill "$NESTED_PID" 2>/dev/null || true
  rm -rf "$TMPDIR"; exit 1
fi

# ---- run hyprlock inside the nested session, then screenshot ----
WAYLAND_DISPLAY="$SOCK" hyprlock &         # render the lock UI
sleep 0.7                                   # let first frame draw; bump to 1.0 if blank
WAYLAND_DISPLAY="$SOCK" grim -t png "$OUT"  # capture the nested compositor

# ---- cleanup ----
kill "$NESTED_PID" 2>/dev/null || true
rm -rf "$TMPDIR"

echo "Saved: $OUT"
