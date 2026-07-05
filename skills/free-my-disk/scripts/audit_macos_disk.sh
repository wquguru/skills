#!/usr/bin/env bash
set -u

section() {
  printf '\n== %s ==\n' "$1"
}

safe_du() {
  du -sh "$@" 2>/dev/null || true
}

section "Filesystem"
df -h /

section "Low-risk cache candidates"
safe_du \
  "$HOME/Library/Caches/Homebrew" \
  "$HOME/.npm/_cacache" \
  "$HOME/.pnpm-store" \
  "$HOME/.yarn" \
  "$HOME/.cache" \
  "$HOME/Library/Logs" \
  "$HOME/.Trash"

section "Developer and app storage candidates"
safe_du \
  "$HOME/Library/Containers/com.docker.docker" \
  "$HOME/Library/Developer" \
  "$HOME/Library/Developer/Xcode/DerivedData" \
  "$HOME/Library/Developer/CoreSimulator" \
  "$HOME/.local/share/uv" \
  "$HOME/.vscode/extensions" \
  "$HOME/.cursor/extensions" \
  "$HOME/.claude/projects" \
  "$HOME/.codex/sessions"

if [ "${PROJECT_SCAN:-0}" = "1" ]; then
  section "Common user and project roots"
  safe_du \
    "$HOME/Desktop" \
    "$HOME/Documents" \
    "$HOME/Downloads" \
    "$HOME/Movies" \
    "$HOME/Music" \
    "$HOME/Pictures" \
    "$HOME/Workshop" \
    "$HOME/qb"
else
  section "Skipped project roots"
  echo "Set PROJECT_SCAN=1 to size common user and project roots."
fi

if command -v brew >/dev/null 2>&1; then
  section "Homebrew cleanup dry run"
  brew cleanup -n 2>/dev/null | tail -80 || true
fi

if command -v docker >/dev/null 2>&1; then
  section "Docker system df"
  docker system df 2>/dev/null || echo "Docker daemon is not running."
fi

if [ "${FULL_SCAN:-0}" = "1" ]; then
  section "Home directory top level"
  du -hd 1 "$HOME" 2>/dev/null | sort -h | tail -30 || true

  section "Large files over 1 GiB"
  find "$HOME" -xdev -type f -size +1G -print 2>/dev/null | head -100 || true
else
  section "Skipped full scan"
  echo "Set FULL_SCAN=1 to run home-level du and large-file discovery."
fi

section "APFS local snapshots"
tmutil listlocalsnapshots / 2>/dev/null || true
