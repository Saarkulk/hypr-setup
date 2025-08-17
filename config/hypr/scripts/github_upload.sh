#!/usr/bin/env bash
set -euo pipefail

REPO="$HOME/github/hypr-setup"
DEST="$REPO/config"
LOG="$HOME/.cache/hypr-backup.log"

# Folders to sync (exactly what you listed)
FOLDERS=(
  "$HOME/.config/fish"
  "$HOME/.config/gtk-3.0"
  "$HOME/.config/gtk-4.0"
  "$HOME/.config/hypr"
  "$HOME/.config/kitty"
  "$HOME/.config/swaync"
  "$HOME/.config/systemd"
  "$HOME/.config/tmux"
  "$HOME/.config/wal"
  "$HOME/.config/waybar"
  "$HOME/.config/wlogout"
  "$HOME/.config/wofi"
)

notify() { command -v notify-send >/dev/null && notify-send "Waybar Git Sync" "$1" || true; }

# Sanity checks
if [[ ! -d "$REPO/.git" ]]; then
  notify "Repo not found at $REPO (no .git). Aborting."
  echo "ERROR: $REPO is not a git repo" | tee -a "$LOG"
  exit 1
fi

mkdir -p "$DEST"

# Sync using rsync (safer than cp -r). Exclude obvious junk.
# --delete keeps the repo mirror in sync with your live config.
RSYNC_EXCLUDES=(
  "--exclude=.cache/"
  "--exclude=cache/"
  "--exclude=__pycache__/"
  "--exclude=*.swp"
  "--exclude=*.tmp"
  "--exclude=*.log"
)

echo "==== $(date -Iseconds) Starting sync ====" >> "$LOG"

for src in "${FOLDERS[@]}"; do
  if [[ -d "$src" ]]; then
    rel="$(basename "$src")"
    mkdir -p "$DEST/$rel"
    rsync -a --delete "${RSYNC_EXCLUDES[@]}" "$src/" "$DEST/$rel/" >> "$LOG" 2>&1
  else
    echo "WARN: missing $src" >> "$LOG"
  fi
done

# Git add/commit/push
cd "$REPO"
git add config/ >> "$LOG" 2>&1 || true

# If nothing to commit, exit early
if git diff --cached --quiet; then
  notify "No changes to commit."
  echo "No changes" >> "$LOG"
  exit 0
fi

COMMIT_MSG="Latest additions ($(date  -Iseconds))"
git commit -m "$COMMIT_MSG" >> "$LOG" 2>&1 || {
  notify "Commit failed. See $LOG"
  exit 1
}

# Optional: show a short status in logs
git status --short >> "$LOG" 2>&1 || true

# Push
if git push >> "$LOG" 2>&1; then
  notify "Pushed: $COMMIT_MSG"
else
  notify "Push failed. See $LOG"
  exit 1
fi

echo "==== $(date -Iseconds) Done ====" >> "$LOG"
exit 0
