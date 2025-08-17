#!/usr/bin/env bash
# Waybar Bluetooth: always prints JSON; resilient to failures/empty output.

# ---- helpers ----
have(){ command -v "$1" >/dev/null 2>&1; }
st(){ if have timeout; then timeout 2s "$@" 2>/dev/null || true; else "$@" 2>/dev/null || true; fi; }

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
CACHE_FILE="$CACHE_DIR/bluetooth.json"
mkdir -p "$CACHE_DIR"

# Option A (simplest): let tee write to file AND keep stdout
emit(){ printf '%s\n' "$1" | tee "$CACHE_FILE"; }

fallback(){
  # last good if present, else a safe default
  if [[ -s "$CACHE_FILE" ]]; then cat "$CACHE_FILE"
  else echo '{"text":"","tooltip":"Bluetooth: unknown","class":"off","alt":"off"}'
  fi
}

bt_power(){
  # returns: yes|no|empty
  st bluetoothctl show | awk -F': ' '/Powered:/ {print tolower($2)}'
}

list_connected_names(){
  st bluetoothctl devices | awk '{print $2}' | while read -r mac; do
    [[ -z "$mac" ]] && continue
    if st bluetoothctl info "$mac" | grep -q "Connected: yes"; then
      name="$(st bluetoothctl info "$mac" | awk -F': ' '/Name:/ {print $2}' | head -n1)"
      [[ -z "$name" ]] && name="$mac"
      printf '%s\n' "$name"
    fi
  done
}

disconnect_all(){
  st bluetoothctl devices | awk '{print $2}' | xargs -r -n1 -I{} sh -c 'timeout 2s bluetoothctl disconnect "$1" >/dev/null 2>&1 || true' _ {}
}

connect_last_paired(){
  st bluetoothctl paired-devices | awk '{print $2}' | while read -r mac; do
    [[ -z "$mac" ]] && continue
    st bluetoothctl info "$mac" | grep -q "Connected: yes" && continue
    st bluetoothctl connect "$mac" >/dev/null && return 0
  done
  return 1
}

# ---- clicks (Waybar should call: script click left|middle|right) ----
if [[ "${1:-}" == "click" ]]; then
  case "${2:-}" in
    left)
      s="$(bt_power)"
      if [[ "$s" == "yes" ]]; then st bluetoothctl power off >/dev/null
      else st bluetoothctl power on  >/dev/null
      fi
      ;;
    middle) disconnect_all ;;
    right)
      [[ "$(bt_power)" == "yes" ]] || st bluetoothctl power on >/dev/null
      connect_last_paired || true
      ;;
  esac
fi

# ---- build output (never silent) ----
powered="$(bt_power)"
# Join names with ', ' without hanging
names="$(list_connected_names | paste -sd ', ' - 2>/dev/null || true)"
count=0
[[ -n "$names" ]] && count=$(awk -v s="$names" 'BEGIN{print (length(s)?split(s,a,", "):0)}')

if [[ "$powered" == "yes" ]]; then
  if (( count > 0 )); then
    text=" ${count}"; cls="on connected"; tip="Bluetooth: ON\nConnected (${count}): ${names}"
  else
    text=""; cls="on"; tip="Bluetooth: ON\nNo devices connected"
  fi
else
  text=""; cls="off"; tip="Bluetooth: OFF"
fi

# Minimal JSON, escape quotes
json=$(printf '{"text":"%s","tooltip":"%s","class":"%s","alt":"%s"}\n' \
  "$(printf %s "$text" | sed 's/"/\\"/g')" \
  "$(printf %s "$tip"  | sed 's/"/\\"/g')" \
  "$(printf %s "$cls"  | sed 's/"/\\"/g')" \
  "$(printf %s "$cls"  | sed 's/"/\\"/g')" )

# If empty for any reason, fall back; else emit
if [[ -z "$json" ]]; then fallback; else emit "$json"; fi
