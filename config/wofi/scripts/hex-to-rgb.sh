#!/bin/bash

# Usage: ./hex-to-rgba.sh "#061C24" 0.85

hex="${1:-#000000}"
alpha="${2:-1.0}"

# Strip the '#' if present
hex="${hex#\#}"

# Support short hex (#123 → #112233)
if [[ ${#hex} -eq 3 ]]; then
    hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
fi

# Convert to decimal
r=$((16#${hex:0:2}))
g=$((16#${hex:2:2}))
b=$((16#${hex:4:2}))

echo "rgba($r, $g, $b, $alpha)"
