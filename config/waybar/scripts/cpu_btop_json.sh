#!/usr/bin/env bash
# wb_sys.sh — CPU | MEM | TEMP custom modules for Waybar
# - Last-good JSON cache (no flicker on failures)
# - Threshold-based icons & CSS classes
# - Rich tooltips
# Usage: wb_sys.sh cpu|mem|temp

set -o pipefail
MODE="${1:-cpu}"

# ── cache (one file per mode) ────────────────────────────────────────────────
STATE_BASE="/tmp/waybar_cache"; mkdir -p "$STATE_BASE"
CACHE="$STATE_BASE/$MODE.json"
json_escape(){ sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'; }
emit_json(){ local j="$1"; printf '%s\n' "$j"; printf '%s\n' "$j" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"; }
emit_cached_or_placeholder(){
  if [ -r "$CACHE" ]; then cat "$CACHE"
  else printf '{"text":"…","tooltip":"waiting for first update","class":"wb-stale"}\n'
  fi
}
trap 'emit_cached_or_placeholder; exit 0' ERR

# ── knobs (env overrides) ────────────────────────────────────────────────────
: "${WB_TEMP_PATH:=/sys/class/hwmon/hwmon5/temp1_input}"   # your Tctl path
: "${WB_TEMP_ICONS:=,,}"   # cold,warm,hot
: "${WB_TEMP_THRESH:=45,70}"    # °C thresholds
: "${WB_TEMP_CRIT:=80}"         # °C -> class "temp-critical"

: "${WB_CPU_ICONS:=,,}"     # low,med,high (change to other glyphs if you like)
: "${WB_CPU_THRESH:=35,70}"     # usage % thresholds
: "${WB_CPU_TOP_N:=5}"

: "${WB_MEM_ICONS:=,,}"     # low,med,high
: "${WB_MEM_THRESH:=50,80}"     # used % thresholds
: "${WB_MEM_TOP_N:=5}"

SEP="<span>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>"

# ── helpers ─────────────────────────────────────────────────────────────────
human(){ awk -v b="${1:-0}" 'BEGIN{u[0]="B";u[1]="K";u[2]="M";u[3]="G";i=0;while(b>=1024&&i<3){b/=1024;i++}printf(i?"%.1f%s":"%.0f%s",b,u[i])}'; }
make_bar(){ val=$1; max=$2; len=$3; [ "$val" -lt 0 ]&&val=0; [ "$val" -gt "$max" ]&&val="$max";
  filled=$(awk -v v="$val" -v m="$max" -v l="$len" 'BEGIN{printf "%d",(v/m)*l}');
  [ "$filled" -lt 0 ]&&filled=0; [ "$filled" -gt "$len" ]&&filled="$len";
  printf -v L '%*s' "$filled" ''; printf -v R '%*s' "$((len-filled))" '';
  echo "${L// /█}${R// /░}"; }
map_spark(){ v=$1; if [ "$v" -le 12 ]; then echo -n "▁"; elif [ "$v" -le 25 ]; then echo -n "▂";
  elif [ "$v" -le 37 ]; then echo -n "▃"; elif [ "$v" -le 50 ]; then echo -n "▄";
  elif [ "$v" -le 62 ]; then echo -n "▅"; elif [ "$v" -le 75 ]; then echo -n "▆";
  elif [ "$v" -le 87 ]; then echo -n "▇"; else echo -n "█"; fi; }
get_temp(){ [ -r "$WB_TEMP_PATH" ] && awk '{printf "%.1f°C\n",$1/1000}' "$WB_TEMP_PATH" || echo "n/a"; }
pick_icon_class(){  # $1=value $2="a,b" thresholds $3="x,y,z" icons -> echo "icon classkey"
  local v="$1" t="$2" i="$3"
  IFS=',' read -r lo hi <<< "$t"; IFS=',' read -r i1 i2 i3 <<< "$i"
  local icon="$i1" cls="low"
  if [ "${v%.*}" -ge "$hi" ]; then icon="$i3"; cls="high"
  elif [ "${v%.*}" -ge "$lo" ]; then icon="$i2"; cls="med"; fi
  echo "$icon $cls"
}

# ── modules ─────────────────────────────────────────────────────────────────
case "$MODE" in
  cpu)
    STATE="/tmp/waybar_cpu"; mkdir -p "$STATE"
    HIST="$STATE/usage_hist"; STAT="$STATE/prev_stat"

    if [ -r "$STAT" ]; then read prev_idle prev_total < "$STAT"; else prev_idle=0; prev_total=0; fi
    read _ u n s i io irq sirq st _ < /proc/stat
    idle_now=$(( i + io )); non_idle=$(( u + n + s + irq + sirq + st )); total_now=$(( idle_now + non_idle ))
    if [ "$prev_total" -gt 0 ]; then
      td=$(( total_now - prev_total )); id=$(( idle_now - prev_idle ))
      usage=$(awk -v td="$td" -v id="$id" 'BEGIN{if(td>0) printf"%.1f",100*(td-id)/td; else print "0.0"}')
    else usage="0.0"; fi
    echo "$idle_now $total_now" > "$STAT"

    u_int=$(awk -v u="$usage" 'BEGIN{printf "%d",u+0}')
    hist=$( { cat "$HIST" 2>/dev/null; echo "$u_int"; } | tail -n 28)
    printf '%s\n' "$hist" > "$HIST"
    spark=""; while IFS= read -r v; do spark="$spark$(map_spark "$v")"; done <<< "$hist"
    loadavg=$(awk '{printf "%.2f %.2f %.2f",$1,$2,$3}' /proc/loadavg)
    bar=$(make_bar "$u_int" 100 28)
    top=$(ps -eo pcpu,comm --no-headers 2>/dev/null | sort -rk1 | head -n "$WB_CPU_TOP_N" | awk '{printf "%5s%%  %s\n",$1,$2}')

    read -r icon clskey <<< "$(pick_icon_class "$u_int" "$WB_CPU_THRESH" "$WB_CPU_ICONS")"
    text="${usage}% $icon"
    tip="$SEP
<span rise='300' size='large' weight='bold' font_family='monospace'>              CPU</span>
Usage: ${usage}%                    |     Load: ${loadavg}
$spark
$bar
$SEP
                           Top CPU processes
$top
$SEP"
    emit_json "$(printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
      "$(printf '%s' "$text" | json_escape)" \
      "$(printf '%s' "$tip"  | json_escape)" \
      "cpu-$clskey")"
    ;;

  mem)
    eval "$(awk '
      /^MemTotal:/     {mt=$2*1024}
      /^MemAvailable:/ {ma=$2*1024}
      /^SwapTotal:/    {st=$2*1024}
      /^SwapFree:/     {sf=$2*1024}
      END{mu=mt-ma; su=st-sf; printf "MT=%d\nMU=%d\nST=%d\nSU=%d\n",mt,mu,st,su }' /proc/meminfo)"
    pct=$(awk -v a=$MU -v b=$MT 'BEGIN{printf "%.0f",100*a/b}')
    bar=$(make_bar "$pct" 100 28)
    top=$(ps -eo rss,comm --no-headers 2>/dev/null | sort -nr | head -n "$WB_MEM_TOP_N" | awk '{printf "%6s  %s\n",$1,$2}')

    read -r icon clskey <<< "$(pick_icon_class "$pct" "$WB_MEM_THRESH" "$WB_MEM_ICONS")"
    text="${pct}% $icon"
    tip="$SEP
<span rise='300' size='large' weight='bold' font_family='monospace'>            Memory</span>
Mem:  $(human "$MU") / $(human "$MT")
Swap: $(human "$SU") / $(human "$ST")
$bar
$SEP
                           Top RSS processes
$top
$SEP"
    emit_json "$(printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
      "$(printf '%s' "$text" | json_escape)" \
      "$(printf '%s' "$tip"  | json_escape)" \
      "mem-$clskey")"
    ;;

  temp)
    t="$(get_temp)"; tval=$(printf '%s' "$t" | tr -dc '0-9.' | awk '{print ($0==""?0:$0)}'); tint="${tval%.*}"
    bar=$(make_bar "$tint" 100 28)
    IFS=',' read -r COLD WARM HOT <<< "$WB_TEMP_ICONS"
    IFS=',' read -r T_COLD T_WARM <<< "$WB_TEMP_THRESH"
    icon="$COLD"; cls="temp-cold"
    if [ "$tint" -ge "$T_WARM" ]; then icon="$HOT"; cls="temp-hot"
    elif [ "$tint" -ge "$T_COLD" ]; then icon="$WARM"; cls="temp-warm"; fi
    [ "$tint" -ge "$WB_TEMP_CRIT" ] && cls="temp-critical"

    text="$t $icon"
    tip="$SEP
<span rise='300' size='large' weight='bold' font_family='monospace'>         CPU Temperature</span>
Temp: $t
$bar
$SEP"
    emit_json "$(printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
      "$(printf '%s' "$text" | json_escape)" \
      "$(printf '%s' "$tip"  | json_escape)" \
      "$cls")"
    ;;

  *) emit_cached_or_placeholder ;;
esac
