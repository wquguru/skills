#!/usr/bin/env bash
#
# install-tools.sh — install yt-dlp + a libass-enabled ffmpeg (+ optional deno).
# macOS (Homebrew) and Debian/Ubuntu Linux. Idempotent: skips what's present.
#
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
note() { printf '  \033[33m›\033[0m %s\n' "$1"; }

ffmpeg_has_libass() {
  local f="${1:-ffmpeg}" out
  # case-match instead of `| grep -q` (which would SIGPIPE ffmpeg under pipefail)
  out="$("$f" -hide_banner -filters 2>/dev/null || true)"
  case "$out" in *" subtitles "*|*" drawtext "*) return 0 ;; esac
  return 1
}

os="$(uname -s)"
echo "== installing YouTube toolkit deps ($os) =="

if [ "$os" = "Darwin" ]; then
  have brew || { echo "Homebrew required: https://brew.sh"; exit 1; }

  if have yt-dlp; then ok "yt-dlp present ($(yt-dlp --version))"; else
    note "installing yt-dlp"; brew install yt-dlp; fi

  # ffmpeg: the lean brew formula has NO libass. Need ffmpeg-full for subtitles.
  if have ffmpeg && ffmpeg_has_libass ffmpeg; then
    ok "ffmpeg has libass"
  elif [ -x /opt/homebrew/opt/ffmpeg-full/bin/ffmpeg ] || [ -x /usr/local/opt/ffmpeg-full/bin/ffmpeg ]; then
    ok "ffmpeg-full present"
  else
    note "installing ffmpeg-full (keg-only; won't shadow your existing ffmpeg)"
    brew install ffmpeg-full
    ok "ffmpeg-full -> $(brew --prefix)/opt/ffmpeg-full/bin/ffmpeg"
  fi

  if have deno; then ok "deno present"; else
    note "installing deno (JS runtime — silences yt-dlp's warning, unlocks all formats)"
    brew install deno || note "deno optional; skipped"
  fi

elif [ "$os" = "Linux" ]; then
  SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
  if have apt-get; then
    note "apt-get install ffmpeg (distro builds include libass)"
    $SUDO apt-get update -qq && $SUDO apt-get install -y ffmpeg python3-pip fonts-noto-cjk
  else
    note "non-apt distro: install ffmpeg + python3-pip + a Noto CJK font via your package manager"
  fi
  if have yt-dlp; then ok "yt-dlp present"; else
    note "installing yt-dlp via pip"; python3 -m pip install -U --user yt-dlp; fi
  ffmpeg_has_libass ffmpeg && ok "ffmpeg has libass" || note "your ffmpeg lacks libass — install a full build"

else
  echo "Unsupported OS: $os. Install yt-dlp and a libass-enabled ffmpeg manually."; exit 1
fi

echo "== done =="
have yt-dlp && yt-dlp --version | sed 's/^/  yt-dlp /'
