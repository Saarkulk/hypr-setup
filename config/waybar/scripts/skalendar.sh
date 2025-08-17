#!/bin/bash

STATE_FILE="/tmp/waybar-clock-mode"

if [[ -f $STATE_FILE ]]; then
    rm "$STATE_FILE"
else
    touch "$STATE_FILE"
fi

pkill waybar && waybar &
