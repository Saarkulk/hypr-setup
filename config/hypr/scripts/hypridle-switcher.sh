#!/usr/bin/env bash
set -euo pipefail

AC_CFG="$HOME/.config/hypr/hypridle/hypridle-ac.conf"
BAT_CFG="$HOME/.config/hypr/hypridle/hypridle-battery.conf"
FADE="$HOME/.config/hypr/scripts/fade-brightness.sh"

pick_cfg() {
  # sysfs first
  if ACFILE=$(ls /sys/class/power_supply/AC*/online 2>/dev/null | head -n1); then
    [[ "$(cat "$ACFILE")" == "1" ]] && echo "$AC_CFG" || echo "$BAT_CFG"
    return
  fi
  # fallback: UPower
  if command -v upower >/dev/null 2>&1; then
    DEV="$(upower -e | grep -E 'line_power|AC' | head -n1 || true)"
    if [[ -n "${DEV:-}" ]]; then
      ONLINE="$(upower -i "$DEV" | awk '/online:/ {print $2}')"
      [[ "$ONLINE" == "yes" ]] && echo "$AC_CFG" || echo "$BAT_CFG"
      return
    fi
  fi
  echo "$BAT_CFG"
}

undim_now() {
  pkill -f fade-brightness.sh 2>/dev/null || true
  [[ -x "$FADE" ]] && "$FADE" 100 150 || true
}

launch_hypridle() {
  CFG="$1"
  undim_now
  pkill -x hypridle 2>/dev/null || true
  nohup hypridle --config "$CFG" >/dev/null 2>&1 & disown
  command -v notify-send >/dev/null 2>&1 && notify-send -t 5000 "Hypridle" "Using $(basename "$CFG")"
}

current=""

# initial
current="$(pick_cfg)"
launch_hypridle "$current"

# prefer instant udev events, fallback to 1s polling if udev monitor dies
udevadm monitor --subsystem-match=power_supply | while read -r _; do
  cfg="$(pick_cfg)"
  if [[ "$cfg" != "$current" ]]; then
    current="$cfg"
    launch_hypridle "$cfg"
  fi
done &

# watchdog fallback polling (covers TTY/rare cases)
while sleep 5; do
  if ! pgrep -f "udevadm monitor --subsystem-match=power_supply" >/dev/null; then
    cfg="$(pick_cfg)"
    if [[ "$cfg" != "$current" ]]; then
      current="$cfg"
      launch_hypridle "$cfg"
    fi
  fi
done
