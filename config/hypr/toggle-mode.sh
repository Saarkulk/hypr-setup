#!/bin/bash

theme_dir="$HOME/.config/hypr/themes"
current_link="$theme_dir/current.conf"
pretty="$theme_dir/pretty.conf"
performance="$theme_dir/performance.conf"

if readlink "$current_link" | grep -q "pretty.conf"; then
    ln -sf "$performance" "$current_link"
    notify-send "Hyprland" "⚡ Switched to Performance Mode"
else
    ln -sf "$pretty" "$current_link"
    notify-send "Hyprland" "✨ Switched to Dude Mode"
fi

hyprctl reload
