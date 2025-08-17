#!/usr/bin/env bash
set -euo pipefail

REPO="$HOME/github/hypr-setup"
DEST="$REPO/config"
LOG="$HOME/.cache/hypr-backup.log"
KEY="$HOME/.ssh/id_github"

# Folders to sync
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

# --- sanity checks ---
if [[ ! -d "$REPO/.git" ]]; then
  notify "Repo not found at $REPO (no .git)."
  echo "ERROR: $REPO is not a git repo" | tee -a "$LOG"
  exit 1
fi

mkdir -p "$DEST" "$(dirname "$LOG")"
echo "==== $(date -Iseconds) Starting sync ====" >> "$LOG"

# --- rsync mirror with excludes ---
RSYNC_EXCLUDES=(
  "--exclude=.cache/"
  "--exclude=cache/"
  "--exclude=__pycache__/"
  "--exclude=*.swp"
  "--exclude=*.tmp"
  "--exclude=*.log"
)

for src in "${FOLDERS[@]}"; do
  if [[ -d "$src" ]]; then
    rel="$(basename "$src")"
    mkdir -p "$DEST/$rel"
    rsync -a --delete "${RSYNC_EXCLUDES[@]}" "$src/" "$DEST/$rel/" >> "$LOG" 2>&1
  else
    echo "WARN: missing $src" >> "$LOG"
  fi
done

# --- git add / commit ---
cd "$REPO"
git add config/ >> "$LOG" 2>&1 || true

if git diff --cached --quiet; then
  notify "No changes to commit."
  echo "No changes" >> "$LOG"
  echo "==== $(date -Iseconds) Done (no-op) ====" >> "$LOG"
  exit 0
fi

COMMIT_MSG="Latest additions ($(date -Iseconds))"
if ! git commit -m "$COMMIT_MSG" >> "$LOG" 2>&1; then
  notify "Commit failed. See $LOG"
  exit 1
fi

git status --short >> "$LOG" 2>&1 || true

# --- decide how to push (agent vs fallback key) ---
remote_url="$(git remote get-url origin 2>/dev/null || true)"
echo "REMOTE: $remote_url" >> "$LOG"

# warn if using HTTPS (non-interactive prompts will fail)
if [[ "$remote_url" =~ ^https://github\.com/ ]]; then
  notify "Remote is HTTPS. Switch to SSH for seamless pushes."
  echo "ERROR: HTTPS remote detected. Use SSH (git@github.com:USER/REPO.git)." >> "$LOG"
  exit 1
fi

# prefer ssh-agent if available; otherwise force key via GIT_SSH_COMMAND
USE_FALLBACK=0
if ! ssh-add -l >/dev/null 2>&1; then
  USE_FALLBACK=1
  echo "No identities in ssh-agent; using key fallback." >> "$LOG"
fi
if [[ ! -S "${SSH_AUTH_SOCK:-}" ]]; then
  USE_FALLBACK=1
  echo "SSH_AUTH_SOCK not set; using key fallback." >> "$LOG"
fi
if [[ ! -f "$KEY" ]]; then
  # if no key file, try anyway (maybe agent exists but we mis-detected)
  echo "Fallback key $KEY missing; attempting plain push." >> "$LOG"
  USE_FALLBACK=0
fi

push_cmd="git push"
if [[ $USE_FALLBACK -eq 1 ]]; then
  push_cmd="GIT_SSH_COMMAND='ssh -i $KEY -o IdentitiesOnly=yes' git push"
fi
echo "PUSH_CMD: $push_cmd" >> "$LOG"

# --- push ---
if eval "$push_cmd" >> "$LOG" 2>&1; then
  notify "Pushed: $COMMIT_MSG"
else
  notify "Push failed. See $LOG"
  {
    echo "---- ssh -G github.com (excerpt) ----"
    ssh -G github.com | grep -i -E 'user|hostname|identityfile|identitiesonly' || true
    echo "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-<unset>}"
  } >> "$LOG" 2>&1
  exit 1
fi

echo "==== $(date -Iseconds) Done ====" >> "$LOG"
exit 0
