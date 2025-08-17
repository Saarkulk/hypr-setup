#!/bin/bash

set -euo pipefail
sleep 2
# ---- Brave app-IDs ----
WHATSAPP_CMD="/opt/brave-bin/brave --profile-directory=Default --app-id=hnpfjngllnobngcgfapefoaidbinmjnm"
APPLEMUSIC_CMD="/opt/brave-bin/brave --profile-directory=Default --app-id=blgdilankhbcpipclgpdndahbehalgkh"
SPOTIFY_CMD="spotify"

# ---- Launch WhatsApp ----
echo "Launching WhatsApp..."
$WHATSAPP_CMD &

# ---- Wait for WhatsApp window to appear ----
echo "Waiting for WhatsApp window..."
while ! hyprctl clients | grep -q "WhatsApp Web"; do
    sleep 0.5
done
echo "WhatsApp is running."

# ---- Launch Apple Music and Spotify ----
echo "Launching Apple Music..."
$APPLEMUSIC_CMD &

echo "Launching Spotify..."
$SPOTIFY_CMD &
