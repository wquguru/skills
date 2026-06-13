#!/usr/bin/env bash
#
# burn-subs.sh — burn an SRT/ASS subtitle (+ optional watermark) into a video.
#
# Handles the gotchas:
#   - auto-detects an ffmpeg that actually has libass (prefers ffmpeg-full on macOS)
#   - converts SRT->ASS and edits the Style line (avoids force_style comma parsing bug)
#   - picks an installed CJK-capable font for the watermark
#   - encodes H.264 + AAC + faststart for broad compatibility
#
# Usage:
#   burn-subs.sh -i INPUT -s SUBS.(srt|ass) [-w "WATERMARK"] [-o OUTPUT]
#                [-f "Font Name"] [--size N] [--pos tr|tl|br|bl] [--crf N]
#
# Examples:
#   burn-subs.sh -i in.webm -s in.zh.srt -w "@wquguru 翻译" -o out_zh.mp4
#   burn-subs.sh -i in.mp4  -s in.ass    --pos br --size 18
#
set -euo pipefail

# ---- defaults ----
INPUT="" ; SUBS="" ; OUTPUT="" ; WATERMARK=""
FONT="Hiragino Sans GB"   # libass resolves by family name (override per-OS with -f)
SIZE=17                   # ASS Fontsize at PlayResY=288 (~64px on 1080p)
POS="tr"                  # watermark corner: tr/tl/br/bl
CRF=20
MARGIN=24                 # watermark px from edge

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//' ; exit 1 ; }

while [ $# -gt 0 ]; do
  case "$1" in
    -i) INPUT="$2"; shift 2 ;;
    -s) SUBS="$2"; shift 2 ;;
    -o) OUTPUT="$2"; shift 2 ;;
    -w) WATERMARK="$2"; shift 2 ;;
    -f) FONT="$2"; shift 2 ;;
    --size) SIZE="$2"; shift 2 ;;
    --pos)  POS="$2"; shift 2 ;;
    --crf)  CRF="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

[ -n "$INPUT" ] && [ -n "$SUBS" ] || { echo "ERROR: -i INPUT and -s SUBS are required" >&2; usage; }
[ -f "$INPUT" ] || { echo "ERROR: input not found: $INPUT" >&2; exit 1; }
[ -f "$SUBS" ]  || { echo "ERROR: subtitle not found: $SUBS" >&2; exit 1; }
[ -n "$OUTPUT" ] || OUTPUT="${INPUT%.*}.subbed.mp4"

# ---- 1. find an ffmpeg with libass (subtitles + drawtext) ----
find_ffmpeg() {
  local candidates=(
    /opt/homebrew/opt/ffmpeg-full/bin/ffmpeg
    /usr/local/opt/ffmpeg-full/bin/ffmpeg
    ffmpeg
  )
  local f out
  for f in "${candidates[@]}"; do
    command -v "$f" >/dev/null 2>&1 || [ -x "$f" ] || continue
    # case-match instead of `| grep -q` (which would SIGPIPE ffmpeg under pipefail)
    out="$("$f" -hide_banner -filters 2>/dev/null || true)"
    case "$out" in
      *" subtitles "*|*" drawtext "*) echo "$f"; return 0 ;;
    esac
  done
  return 1
}
FF="$(find_ffmpeg)" || {
  echo "ERROR: no ffmpeg with libass/drawtext found." >&2
  echo "       macOS:  brew install ffmpeg-full" >&2
  echo "       Linux:  apt/dnf ffmpeg (distro builds include libass)" >&2
  exit 1
}
echo ">> using ffmpeg: $FF"

# ---- 2. ensure an ASS file with our style (SRT -> ASS, then edit Style line) ----
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ext="$(printf '%s' "${SUBS##*.}" | tr '[:upper:]' '[:lower:]')"
if [ "$ext" = "ass" ]; then
  ASS="$SUBS"
else
  ASS="$WORK/subs.ass"
  "$FF" -y -i "$SUBS" "$ASS" >/dev/null 2>&1
  # Restyle: Chinese font, readable size, outline for legibility, bottom margin.
  # PrimaryColour white, OutlineColour black, BorderStyle=1 (outline+shadow).
  NEW_STYLE="Style: Default,${FONT},${SIZE},&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,1.6,0.6,2,40,40,18,1"
  # rewrite the Default style line with awk — sed would treat the '&' in the
  # colour codes (&H00FFFFFF …) as "insert the whole match" and corrupt the line.
  awk -v ns="$NEW_STYLE" '/^Style: *Default,/{print ns; next} {print}' "$ASS" > "$ASS.new" && mv "$ASS.new" "$ASS"
fi

# ---- 3. build the filtergraph (subtitles [+ watermark]) ----
# escape the ASS path for the subtitles filter (':' and '\' are special)
esc_ass="$(printf '%s' "$ASS" | sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g" -e 's/:/\\:/g')"
VF="subtitles='${esc_ass}'"

if [ -n "$WATERMARK" ]; then
  # locate a CJK-capable font file for drawtext (needs an actual file, not a family name)
  FONTFILE=""
  for cand in \
    "/System/Library/Fonts/Hiragino Sans GB.ttc" \
    "/System/Library/Fonts/STHeiti Medium.ttc" \
    "/System/Library/Fonts/Supplemental/Songti.ttc" \
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf" \
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc" \
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc" ; do
    [ -f "$cand" ] && { FONTFILE="$cand"; break; }
  done
  [ -n "$FONTFILE" ] || { echo "ERROR: no CJK font file found for watermark" >&2; exit 1; }

  case "$POS" in
    tr) X="w-text_w-${MARGIN}"; Y="${MARGIN}" ;;
    tl) X="${MARGIN}";          Y="${MARGIN}" ;;
    br) X="w-text_w-${MARGIN}"; Y="h-text_h-${MARGIN}" ;;
    bl) X="${MARGIN}";          Y="h-text_h-${MARGIN}" ;;
    *)  echo "ERROR: --pos must be tr/tl/br/bl" >&2; exit 1 ;;
  esac
  # escape watermark text for drawtext (':' '%' '\' are special)
  wm="$(printf '%s' "$WATERMARK" | sed -e 's/\\/\\\\/g' -e 's/:/\\:/g' -e 's/%/\\%/g')"
  VF="${VF},drawtext=fontfile=${FONTFILE}:text='${wm}':fontcolor=white@0.7:fontsize=30:x=${X}:y=${Y}:shadowcolor=black@0.6:shadowx=2:shadowy=2"
fi

echo ">> filtergraph: $VF"
echo ">> encoding -> $OUTPUT"

# ---- 4. encode ----
"$FF" -y -i "$INPUT" -vf "$VF" \
  -c:v libx264 -crf "$CRF" -preset medium \
  -c:a aac -b:a 192k -movflags +faststart \
  "$OUTPUT"

echo ">> done: $OUTPUT"
