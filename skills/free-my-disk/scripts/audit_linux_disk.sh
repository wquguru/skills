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
df -ih /

section "System identity"
uname -a
if [ -r /etc/os-release ]; then
  sed -n '1,8p' /etc/os-release
fi

section "Low-risk cache candidates"
safe_du \
  "$HOME/.cache" \
  "$HOME/.npm/_cacache" \
  "$HOME/.pnpm-store" \
  "$HOME/.yarn" \
  "$HOME/.cache/pip" \
  "$HOME/.local/share/uv" \
  "$HOME/.local/share/Trash"

section "Developer and app storage candidates"
safe_du \
  "$HOME/.vscode/extensions" \
  "$HOME/.cursor/extensions" \
  "$HOME/.claude/projects" \
  "$HOME/.codex/sessions" \
  "$HOME/.local/share/containers" \
  "$HOME/.docker"

section "System storage candidates"
safe_du \
  /var/cache/apt \
  /var/log \
  /var/tmp \
  /tmp \
  /snap \
  /var/lib/snapd \
  /var/lib/docker

if command -v journalctl >/dev/null 2>&1; then
  section "Systemd journal usage"
  journalctl --disk-usage 2>/dev/null || echo "Permission denied; rerun this specific check with sudo if needed."
fi

if command -v docker >/dev/null 2>&1; then
  section "Docker system df"
  docker system df 2>/dev/null || echo "Docker daemon is not running or permission is denied."
fi

if [ "${PROJECT_SCAN:-0}" = "1" ]; then
  section "Common user and project roots"
  safe_du \
    "$HOME/Downloads" \
    "$HOME/workshop" \
    "$HOME/Workshop" \
    "$HOME/projects" \
    "$HOME/src" \
    /opt \
    /srv
else
  section "Skipped project roots"
  echo "Set PROJECT_SCAN=1 to size common user and project roots."
fi

if [ "${FULL_SCAN:-0}" = "1" ]; then
  section "Root filesystem top level"
  du -xhd 1 / 2>/dev/null | sort -h | tail -30 || true

  section "Home directory top level"
  du -xhd 1 "$HOME" 2>/dev/null | sort -h | tail -30 || true

  section "Large files over 1 GiB in home"
  find "$HOME" -xdev -type f -size +1G -print 2>/dev/null | head -100 || true
else
  section "Skipped full scan"
  echo "Set FULL_SCAN=1 to run root/home-level du and large-file discovery."
fi
