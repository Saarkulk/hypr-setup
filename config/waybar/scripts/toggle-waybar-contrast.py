#!/usr/bin/env python3
import json
import os
from pathlib import Path
from PIL import Image
import re
import tempfile, subprocess

# Paths
gtk_css_path = Path.home() / ".config/gtk-3.0/gtk.css"
override_path = Path.home() / ".config/waybar/style-override.css"
wal_path_file = Path.home() / ".cache/wal/wal"
colors_path = Path.home() / ".cache/wal/colors.sh"

# Helper to convert hex to rgba
def to_rgba(hex_color, alpha):
    hex_color = hex_color.lstrip('#')
    r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    return f"rgba({r}, {g}, {b}, {alpha})"

# Read current wallpaper path from wal
if wal_path_file.exists():
    with open(wal_path_file) as f:
        wallpaper_path = Path(f.read().strip())
else:
    wallpaper_path = Path.home() / ".config/hypr/wallpaper.png"  # fallback

# Confirm wallpaper exists
if not wallpaper_path.exists():
    raise FileNotFoundError(f"Wallpaper not found: {wallpaper_path}")

# Open and sample the top 30px strip
img = Image.open(wallpaper_path).convert("RGB")
strip = img.crop((0, 0, img.width, 30))
pixels = list(strip.getdata())

# Average brightness
brightness = sum(0.299*r + 0.587*g + 0.114*b for r, g, b in pixels) / len(pixels)
is_light = (brightness > 100)

STATE_FILE = Path("/tmp/waybar-theme-mode")
mode = "light" if is_light else "dark"
# Only write if changed; write atomically
prev = STATE_FILE.read_text().strip() if STATE_FILE.exists() else None
if prev != mode:
    with tempfile.NamedTemporaryFile("w", dir="/tmp", delete=False) as tf:
        tf.write(mode + "\n")
        tmp = tf.name
    os.chmod(tmp, 0o600)
    os.replace(tmp, STATE_FILE)

    # Reload Waybar so skalendar picks it up immediately
    try:
        subprocess.run(["waybar-msg", "-r"], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, check=False)
    except Exception:
        pass

# Parse pywal colors for precise RGBA values
foreground = "#ffffff"
background = "#000000"
if colors_path.exists():
    with open(colors_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("foreground="):
                foreground = line.split("=", 1)[1].strip("'\"")
            elif line.startswith("background="):
                background = line.split("=", 1)[1].strip("'\"")

text_color = background if is_light else foreground

# Generate GTK tooltip override block with absolute colors
new_tooltip_block = f"""

tooltip {{
  background-color: {to_rgba(foreground, 0.8) if is_light else to_rgba(background, 0.8)};
  color: {text_color};
  backdrop-filter: blur(5px);
  border-radius: 6px;
  padding: 6px;
}}
menu,
.context-menu {{
  background-color: {to_rgba(foreground, 0.8) if is_light else to_rgba(background, 0.8) }; /* Replace with a Pywal dark color */
  color: @theme_fg_color;    /* or a specific hex from Pywal */
}}

menu menuitem,
.context-menu menuitem {{
  background-color: transparent;
  color: {to_rgba(foreground, 0.8)}; /* Replace with Pywal foreground */
}}

menu menuitem:hover,
.context-menu menuitem:hover {{
  background-color: {to_rgba(foreground,0.2)}; /* Hover background */
}}
""".strip()

# Read and update gtk.css
if gtk_css_path.exists():
    content = gtk_css_path.read_text()
else:
    content = ""

START = "/* >>> BEGIN: pywal tray/tooltip override >>> */"
END   = "/* <<< END: pywal tray/tooltip override <<< */"

# Strip any existing marked section
content = re.sub(rf"(?s){re.escape(START)}.*?{re.escape(END)}\s*", "", content)

# Ensure a newline gap
content = re.sub(r"\n{3,}", "\n\n", content).rstrip() + "\n\n"

# Insert marked block
marked_block = f"{START}\n{new_tooltip_block}\n{END}\n"
content += marked_block
gtk_css_path.write_text(content)

# Write override CSS for Waybar text color only
with open(override_path, "w") as f:
    f.write(f"""
/* Auto-set contrast for Waybar foreground */
* {{
  color: {text_color};
}}
""")

print(f"Wallpaper: {wallpaper_path}")
print(f"Brightness: {brightness:.2f}")
print(f"Using {'light' if is_light else 'dark'} text")
