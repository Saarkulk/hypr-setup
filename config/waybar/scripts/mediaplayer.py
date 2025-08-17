#!/usr/bin/env python3
import json
import subprocess

def run(cmd):
    try:
        return subprocess.check_output(cmd).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        return ""
    except FileNotFoundError:
        return ""

def get_players():
    try:
        return subprocess.check_output(["playerctl", "-l"]).decode("utf-8").splitlines()
    except:
        return []

def get_playing_player():
    for player in get_players():
        status = run(["playerctl", "-p", player, "status"])
        if status.lower() == "playing":
            return player
    return None

def main():
    player = get_playing_player()
    if not player:
        output = {
            "text": "No media",
            "tooltip": "Nothing playing",
            "class": "custom-media",
            "alt": "Stopped"
        }
    else:
        artist = run(["playerctl", "-p", player, "metadata", "artist"])
        title = run(["playerctl", "-p", player, "metadata", "title"])
        status = run(["playerctl", "-p", player, "status"])
        output = {
            "text": f"{artist} - {title}",
            "tooltip": f"{artist} - {title} ({status})",
            "class": "custom-media",
            "alt": status
        }

    print(json.dumps(output))

if __name__ == "__main__":
    main()
