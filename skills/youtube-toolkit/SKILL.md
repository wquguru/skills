---
name: youtube-toolkit
description: Download YouTube videos with yt-dlp and post-process them with ffmpeg — fetch best-quality video/audio, convert formats, extract audio, and burn in translated (e.g. Chinese) subtitles with a translator watermark. Covers cross-environment tool installation (macOS-focused) including the ffmpeg-full / libass gotcha. Triggers on "youtube 视频下载处理".
license: MIT
allowed-tools: "Read,Write,Edit,Bash"
version: "1.0.0"
---

# YouTube Toolkit

Download and process YouTube videos: grab best-quality streams, convert/extract,
and burn in translated subtitles + a watermark. macOS-first, with Linux notes.

Two helper scripts do the deterministic work; the agent does the judgement work
(choosing formats, translating subtitles). Read the relevant `references/` file
before a non-trivial task instead of guessing flags.

## ⚠️ Pick the right ffmpeg first (the #1 gotcha)

Homebrew's **lean `ffmpeg`** formula ships **without libass/libfreetype**, so it
has **no `subtitles` and no `drawtext` filter** — subtitle burn-in and watermarks
fail with `No option name` / `Error parsing filterchain`. Verify before relying
on it:

```bash
ffmpeg -hide_banner -filters 2>/dev/null | grep -E ' subtitles | drawtext ' || echo "NO subtitle/drawtext support"
```

If missing, install the full build (keg-only, **does not touch your `ffmpeg`**):

```bash
brew install ffmpeg-full     # binary at /opt/homebrew/opt/ffmpeg-full/bin/ffmpeg
```

`scripts/burn-subs.sh` auto-detects an ffmpeg with libass, preferring
`ffmpeg-full`. Plain download/convert work fine with the lean `ffmpeg`.

## Install tools

One shot: `bash scripts/install-tools.sh` (detects OS; installs yt-dlp, an
ffmpeg with libass, and optionally the `deno` JS runtime). Or do it manually —
details and Linux/conda variants in `references/installation-and-recipes.md`.

> yt-dlp prints `No supported JavaScript runtime` and falls back to the Android
> client. It usually still works; install `deno` (`brew install deno`) to silence
> it and unlock all formats.

## Common tasks

### Download (best quality)

```bash
yt-dlp -o "~/Downloads/%(title)s [%(id)s].%(ext)s" "<URL>"
```

Best video+audio merge to mp4, audio-only mp3, playlists, cookies, sections —
see the recipes in `references/installation-and-recipes.md`.

### Convert / extract

Re-encode webm (often AV1+Opus, not universally playable) to H.264+AAC mp4:

```bash
ffmpeg -i in.webm -c:v libx264 -crf 20 -preset medium -c:a aac -b:a 192k -movflags +faststart out.mp4
```

More recipes (remux without re-encode, trim, extract audio) in references.

### Burn in translated subtitles + watermark  ← marquee workflow

Produces a hard-subbed mp4 with a translator watermark (e.g. `@handle 翻译`).
Full detail in `references/translate-and-burn.md`; the loop is:

1. **List + fetch source subtitles** (translate from the *original* language, not
   YouTube's machine-translated track, for quality worthy of a translator credit):
   ```bash
   yt-dlp --list-subs --skip-download "<URL>"
   yt-dlp --write-auto-subs --sub-langs en --convert-subs srt --skip-download -o "subs_%(id)s.%(ext)s" "<URL>"
   ```
2. **Re-segment + translate.** YouTube auto-captions are word-by-word *rolling*
   cues with **overlapping timestamps** — burning them as-is double-stacks lines.
   Re-segment into whole sentences (start = first cue's start, end = next
   sentence's start) and translate each into a clean `.zh.srt`. The agent does
   this; see `references/translate-and-burn.md` for the method.
3. **Burn it in:**
   ```bash
   bash scripts/burn-subs.sh -i in.webm -s subs_ID.zh.srt -w "@handle 翻译" -o out_zh.mp4
   ```
   Encode from the **highest-quality source** (the original webm), not an
   already-compressed mp4, to avoid a second generation loss. Preview a single
   frame first (`-copyts -ss T … -frames:v 1`, see references) before the full run.

## Gotchas (learned the hard way)

| Symptom | Cause → Fix |
|---|---|
| `No option name` / filterchain parse error on `-vf subtitles=…` | Lean Homebrew `ffmpeg` lacks libass → use `ffmpeg-full` |
| `force_style='…,…'` breaks `-vf` parsing | Commas in `force_style` confuse the parser → convert SRT→ASS and edit the `Style:` line instead (what `burn-subs.sh` does) |
| Two subtitle lines stack / overlap | Source is rolling auto-captions → re-segment into non-overlapping sentences |
| Subtitle missing in preview frame | `-ss` before `-i` resets PTS → add `-copyts` for preview seeks |
| AV1+Opus `.mp4` won't play in QuickTime | Re-encode to H.264+AAC (`+faststart`) |
| Chinese subtitles render as boxes | Pick a CJK font; macOS has `Hiragino Sans GB.ttc`, `STHeiti *.ttc`, `Songti.ttc`, `Arial Unicode.ttf` (no `PingFang.ttc` at the legacy path) |

## References

- `references/installation-and-recipes.md` — cross-env install (brew/pip/conda/apt), yt-dlp & ffmpeg recipe cookbook.
- `references/translate-and-burn.md` — subtitle re-segmentation, translation, ASS styling, preview/encode details.
- `scripts/install-tools.sh` — installs yt-dlp + libass-enabled ffmpeg (+ optional deno).
- `scripts/burn-subs.sh` — burns an SRT/ASS subtitle + optional watermark into a video.
