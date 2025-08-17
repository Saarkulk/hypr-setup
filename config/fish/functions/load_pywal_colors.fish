function load_pywal_colors
    for line in (grep -E '^(color[0-9]+|foreground|background|cursor)=' ~/.cache/wal/colors.sh)
        set key (string split -m1 '=' -- $line)[1]
        set val (string split -m1 '=' -- $line)[2]

        # Strip all unwanted characters
        set val (string replace -a "'" '' -- $val)
        set val (string replace -a '"' '' -- $val)
        set val (string replace -a '#' '' -- $val)
        set val (string trim -- $val)

        set -gx $key $val
    end
end
