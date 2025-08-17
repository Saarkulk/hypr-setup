#!/usr/bin/env bash
# Waybar WARP with instant "wait" transition via SIGRTMIN+11 and a tiny state file.
# LMB: connect/disconnect | RMB: start service if inactive
# No restarts. Uses `warp-cli registration` (falls back to `register`).

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
STATE_FILE="$STATE_DIR/warp.state"
mkdir -p "$STATE_DIR"

have(){ command -v "$1" >/dev/null 2>&1; }
st(){ if have timeout; then timeout 3s "$@" 2>/dev/null || true; else "$@" 2>/dev/null || true; fi; }

warp_status(){ st warp-cli --accept-tos status; }
warp_settings(){ st warp-cli --accept-tos settings; }

svc_active(){ have systemctl && systemctl is-active --quiet warp-svc && echo yes || echo no; }
svc_start_once(){ [[ "$(svc_active)" == "yes" ]] || (have systemctl && systemctl start warp-svc >/dev/null 2>&1 || true); }

is_connected(){ warp_status | grep -Eqi '\bConnected\b' && echo yes || echo no; }
is_registered(){ ! warp_status | grep -Eqi 'Not[[:space:]]*registered|Missing registration|Registration:.*(No|Disabled)' && echo yes || echo no; }

ensure_registered(){
  [[ "$(is_registered)" == "yes" ]] && return 0
  warp-cli --accept-tos registration >/dev/null 2>&1 || warp-cli --accept-tos register >/dev/null 2>&1 || true
}

# ---- tiny state machine ----------------------------------------------------
# state format: "<mode>|<epoch>|<message>"
# modes: idle, wait_connect, wait_disconnect
sig_refresh(){ pkill -SIGRTMIN+11 waybar 2>/dev/null || true; }

set_state(){ printf '%s|%s|%s\n' "$1" "$(date +%s)" "$3" >"$STATE_FILE"; }
get_state(){
  if [[ -f "$STATE_FILE" ]]; then cat "$STATE_FILE"; else echo "idle|0|"; fi
}
state_mode(){ awk -F'|' '{print $1}'; }
state_age_ok(){ # $1 = max_seconds
  now=$(date +%s); ts=$(awk -F'|' '{print $2}' "$STATE_FILE" 2>/dev/null || echo 0)
  (( now - ts <= ${1:-6} )) && echo yes || echo no
}

# ---- click actions (run real work in background, show wait immediately) ----
do_connect_bg(){
  svc_start_once
  ensure_registered
  warp-cli --accept-tos connect >/dev/null 2>&1 || true
  set_state idle "" ""
  sig_refresh
}
do_disconnect_bg(){
  warp-cli --accept-tos disconnect >/dev/null 2>&1 || true
  set_state idle "" ""
  sig_refresh
}

toggle_connect(){
  have warp-cli || return
  # Debounce: if already waiting and fresh, ignore extra clicks
  if [[ -f "$STATE_FILE" ]] && grep -q '^wait_' "$STATE_FILE" && [[ "$(state_age_ok 2)" == yes ]]; then
    return
  fi

  if [[ "$(is_connected)" == "yes" ]]; then
    set_state wait_disconnect "" "Disconnecting..."
    sig_refresh
    ( do_disconnect_bg ) &
  else
    set_state wait_connect "" "Connecting..."
    sig_refresh
    ( do_connect_bg ) &
  fi
}

start_service_click(){
  # Only start if inactive; don't restart
  [[ "$(svc_active)" == "yes" ]] || (systemctl start warp-svc >/dev/null 2>&1 || true)
  # Brief "starting..." hint
  set_state wait_connect "" "Starting service..."
  sig_refresh
  sleep 0.4
  set_state idle "" ""
  sig_refresh
}

# ---- entrypoint ------------------------------------------------------------
case "${1:-status}" in
  click-left)  toggle_connect; exit 0 ;;
  click-right) start_service_click; exit 0 ;;
  click)
    case "${2:-0}" in
      1) toggle_connect; exit 0 ;;
      3) start_service_click; exit 0 ;;
    esac
  ;;
esac

# ---- render (status path) --------------------------------------------------
svc="$(svc_active)"
connected="$(is_connected)"

# Check transient wait state first
mode="$(get_state | state_mode)"
if [[ "$mode" == wait_connect || "$mode" == wait_disconnect ]]; then
  if [[ "$(state_age_ok 8)" == yes ]]; then
    # Show waiting UI
    text="VPN…"; cls="wait"
    msg="$(cut -d'|' -f3 "$STATE_FILE" 2>/dev/null)"
    tip="${msg:-Working...}"
    # multiline with \r (safer across Waybar versions)
    tip="${tip}\rPlease wait…"
    # Emit JSON
    esc(){ sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
    printf '{"text":"%s","tooltip":"%s","class":"%s","alt":"%s"}\n' \
      "$text" "$(printf '%s' "$tip" | esc)" "$cls" "$cls"
    exit 0
  else
    # stale wait, clear
    set_state idle "" ""
  fi
fi

tip_lines=()
# Otherwise, normal UI
if [[ "$svc" != "yes" ]]; then
  cls="off";  text="VPN"
  tip_lines+=("WARP service: INACTIVE" "Right-click to start service.")
else
  if [[ "$connected" == "yes" ]]; then
    cls="on";  text="VPN"
    tip_lines+=("Cloudflare WARP: Connected" "Left-click to disconnect" "Right-click to start service")
  else
    cls="idle"; text="VPN"
    tip_lines+=("WARP: Disconnected" "Left-click to connect" "Right-click to start service")
  fi
fi
tip="$(printf '%s\r' "${tip_lines[@]}")"
tip="${tip%$'\r'}"
esc(){ sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
printf '{"text":"%s","tooltip":"%s","class":"%s","alt":"%s"}\n' \
  "$text" "$(printf '%s' "$tip" | esc)" "$cls" "$cls"
