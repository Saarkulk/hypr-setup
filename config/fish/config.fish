source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Import colorscheme from 'wal' asynchronously
# &   # Run the process in the background.
# ( ) # Hide shell job control messages.
# Optional: reload for fish prompt
# set -Ux QT_STYLE_OVERRIDE Oxygen
set -Ux QT_QPA_PLATFORMTHEME qt6ct
set -x LANG en_US.UTF-8
set -x LC_ALL en_US.UTF-8

# 1. Run wal-from-kde only *if* KDE is active
if status is-interactive
    if test "$XDG_CURRENT_DESKTOP" = "KDE"
        wal-from-kde >/dev/null 2>&1
    end

    set FLINE_PATH $HOME/.config/fish/fishline
    source $FLINE_PATH/init.fish

    function fish_prompt
        fishline -s $status
        echo
    end
end

# 2. Load shell and terminal colors
if test -f ~/.cache/wal/sequences
    cat ~/.cache/wal/sequences
end

if test -f ~/.cache/wal/colors-tty.sh
    sh ~/.cache/wal/colors-tty.sh
end

# 3. Load environment variables for prompt/colors
if functions -q load_pywal_colors
    load_pywal_colors
end
