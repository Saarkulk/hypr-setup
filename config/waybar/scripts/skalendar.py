#!/usr/bin/env python3
import calendar
import datetime
import json
import os
import re

# Read @define-color values from colors.css
def read_color(name):
    path = os.path.expanduser("~/.config/waybar/colors.css")
    with open(path) as f:
        for line in f:
            if line.strip().startswith(f"@define-color {name}"):
                return line.strip().split()[-1].strip(";")
    return "#ffffff"  # fallback

# Convert hex color to RGB tuple
def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

# Make a color darker by a factor (0-1)
def darken(hex_color, factor=0.8):
    r, g, b = hex_to_rgb(hex_color)
    r, g, b = int(r * factor), int(g * factor), int(b * factor)
    return f"#{r:02x}{g:02x}{b:02x}"

# Detect light/dark mode based on theme file

def is_light_mode():
    state_file = "/tmp/waybar-theme-mode"
    if os.path.exists(state_file):
        with open(state_file) as f:
            return f.read().strip() == "light"
    return False

light = is_light_mode()

# Define adaptive colors
if light:
    today_color = darken(read_color("color0"))
    header_color = darken(read_color("color3"))
    day_head_color = darken(read_color("color5"))
    weekend_color = darken(read_color("color6"))
else:
    today_color = read_color("color2")
    header_color = read_color("color3")
    day_head_color = read_color("color5")
    weekend_color = read_color("color6")

# Check if date mode is toggled
show_date = os.path.exists("/tmp/waybar-clock-mode")

# Current time
now = datetime.datetime.now()
day = now.day
month = now.month
year = now.year

# Format the clock text
if show_date:
    bar_text = now.strftime(" <b>%a, %b %d</b> <span color='gray'>(%H:%M)</span>")
else:
    bar_text = now.strftime(" <b>%H:%M</b>")

# Calendar setup
cal = calendar.TextCalendar(firstweekday=6)
month_matrix = cal.monthdayscalendar(year, month)

# Build tooltip with Pango formatting
styled_lines = []
header = cal.formatmonthname(year, month, 20)
days_header = "Su Mo Tu We Th Fr Sa"

styled_lines.append(f"<span font='JetBrainsMono Nerd Font 12' color='{header_color}'><b>{header}</b></span>")
styled_lines.append(f"<span font='JetBrainsMono Nerd Font 12' color='{day_head_color}'><b>{days_header}</b></span>")

for week in month_matrix:
    line = []
    for idx, day_num in enumerate(week):
        if day_num == 0:
            token = "  "
        else:
            raw = f"{day_num:2}"
            weekend = (idx == 0 or idx == 6)
            if day_num == day:
                token = raw.replace(str(day_num), f"<span color='{today_color}'><b><u>{day_num}</u></b></span>")
            elif weekend:
                token = f"<span color='{weekend_color}'>{raw}</span>"
            else:
                token = raw
        line.append(token.rjust(2))
    styled_lines.append(" ".join(line))

tooltip = "\n".join(f"{line.center(40)}" for line in styled_lines)

# Output JSON for Waybar
print(json.dumps({
    "text": bar_text,
    "tooltip": f"<tt><span font='JetBrainsMono Nerd Font 12'>{tooltip}</span></tt>",
    "class": "custom-clock",
    "alt": "calendar"
}))
