#!/usr/bin/env bash
# Usage: fade-brightness.sh <target_percent 1-100> [duration_ms=400]
set -euo pipefail

target=${1:-}
duration_ms=${2:-400}

if [[ -z "${target}" || "${target}" -lt 1 || "${target}" -gt 100 ]]; then
  echo "Target brightness must be 1..100" >&2
  exit 1
fi

# Single-instance lock so fades don't overlap
LOCK="/tmp/fade-brightness.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0  # another fade is running; skip

# Allow graceful cancel
trap 'exit 0' TERM INT

# Current % from brightnessctl -m (CSV), 4th field like "53%"
cur_raw=$(brightnessctl -m | awk -F',' '{print $4}')
cur=${cur_raw%\%}

# Nothing to do?
if (( cur == target )); then
  exit 0
fi

# ~60 FPS steps
steps=$(( duration_ms / 16 ))
(( steps < 1 )) && steps=1

# Cosine ease-in-out
for i in $(seq 1 "$steps"); do
  val=$(awk -v c="$cur" -v tgt="$target" -v i="$i" -v n="$steps" '
    function pi(){ return 3.141592653589793 }
    BEGIN{
      t = i / n
      ease = (1 - cos(pi()*t)) / 2
      x = c + (tgt - c) * ease
      if (x < 1) x = 1
      if (x > 100) x = 100
      printf "%.0f", x
    }')
  brightnessctl set "${val}%" -q || true
  # sleep per frame
  awk -v ms="$duration_ms" -v st="$steps" 'BEGIN{ printf "sleep %.6f\n", (ms/st)/1000 }' | bash
done

# ensure exact target
brightnessctl set "${target}%" -q || true
