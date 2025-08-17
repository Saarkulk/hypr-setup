function wal-from-kde
    # Get the wallpaper line from the KDE config
    #set line (grep -m 1 'Image=' ~/.config/plasma-org.kde.plasma.desktop-appletsrc)
    set config ~/.config/plasma-org.kde.plasma.desktop-appletsrc
    set current_uuid (qdbus org.kde.ActivityManager /ActivityManager/Activities CurrentActivity)
    #echo "UUID: $current_uuid"

    set cid (awk -v uuid="$current_uuid" '
        /^\[Containments\]\[[0-9]+\]/ {
            match($0, /\[Containments\]\[([0-9]+)\]/, arr)
            containment = arr[1]
            in_block = 1
            next
        }
        /^\[/ { in_block = 0 }
        in_block && /^activityId=/ {
            split($0, a, "=")
            if (a[2] == uuid) {
                print containment
                exit
            }
        }
    ' "$config")
    #echo "Containment ID: $cid"

    set wallpaper_path (awk -v cid="$cid" '
        index($0, "[Containments][" cid "][Wallpaper][org.kde.image][General]") == 1 {
            in_section = 1
            next
        }
        /^\[/ { in_section = 0 }
        in_section && $0 ~ /^Image=/ {
            split($0, a, "=")
            gsub(/^file:\/\//, "", a[2])
            print a[2]
            exit 0
        }
    ' "$config")

    #echo "Wallpaper path: $wallpaper_path"

    # If no result, abort
    #if test -z "$line"
    #    echo "No wallpaper entry found in KDE config"
    #    return 1
    #end

    # Extract and clean the path
     if test -z "$wallpaper_path"
        echo "Wallpaper path not found in KDE config"
        return 1
    end

    if test -f "$wallpaper_path"
        echo "Running wal on: $wallpaper_path"
        wal -i "$wallpaper_path"
    else
        echo "Wallpaper file not found: $wallpaper_path"
        return 1
    end

    if pgrep firefox > /dev/null
        echo "🦊 Firefox is already running — updating theme"
        pywalfox update
    else
        echo "🦊 Launching Firefox and waiting..."
        firefox & disown
        sleep 2
        pywalfox update
    end

end
