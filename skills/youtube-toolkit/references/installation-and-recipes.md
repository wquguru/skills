# Installation & recipe cookbook

## Tool installation

### macOS (Homebrew)

```bash
brew install yt-dlp          # downloader
brew install ffmpeg-full     # ffmpeg WITH libass/drawtext (lean `ffmpeg` lacks them)
brew install deno            # optional JS runtime for yt-dlp's YouTube extractor
```

Why `ffmpeg-full`: Homebrew's default `ffmpeg` formula no longer bundles
libass/libfreetype (they moved to `ffmpeg-full`). Without them there is no
`subtitles` or `drawtext` filter, so subtitle burn-in and watermarks fail.
`ffmpeg-full` is **keg-only** — it installs to
`/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg` and does **not** shadow your existing
`ffmpeg`. Plain downloading/converting works with either build.

Verify a build supports burn-in:

```bash
ffmpeg -hide_banner -filters | grep -E ' subtitles | drawtext '
```

### Linux

Distro ffmpeg builds normally include libass:

```bash
sudo apt-get install ffmpeg python3-pip fonts-noto-cjk   # Debian/Ubuntu
python3 -m pip install -U --user yt-dlp
```

`fonts-noto-cjk` gives you a CJK font for Chinese subtitles/watermarks
(`Noto Sans CJK SC`).

### conda / pip (any OS)

```bash
pip install -U yt-dlp
conda install -c conda-forge ffmpeg   # conda-forge ffmpeg includes libass
```

### The "No supported JavaScript runtime" warning

yt-dlp's YouTube extractor wants a JS runtime. Without one it warns and falls
back to the Android client (usually still works, some formats may be missing).
Install `deno` (`brew install deno`) to silence it and get all formats.

---

## yt-dlp recipes

```bash
# Best quality, sensible filename
yt-dlp -o "~/Downloads/%(title)s [%(id)s].%(ext)s" "<URL>"

# Force an mp4 container result (re-mux/encode as needed)
yt-dlp -f "bv*+ba/b" --merge-output-format mp4 -o "~/Downloads/%(title)s.%(ext)s" "<URL>"

# Audio only -> mp3
yt-dlp -x --audio-format mp3 --audio-quality 0 -o "~/Downloads/%(title)s.%(ext)s" "<URL>"

# Inspect available formats / subtitle tracks
yt-dlp -F "<URL>"
yt-dlp --list-subs --skip-download "<URL>"

# Download subtitles (auto-generated) as SRT, no video
yt-dlp --write-auto-subs --sub-langs en --convert-subs srt --skip-download \
       -o "subs_%(id)s.%(ext)s" "<URL>"

# Human-made subs if present (drop "auto")
yt-dlp --write-subs --sub-langs en,zh-Hans --convert-subs srt --skip-download -o "subs_%(id)s.%(ext)s" "<URL>"

# A time range only
yt-dlp --download-sections "*00:01:30-00:03:00" -o "~/Downloads/%(title)s.%(ext)s" "<URL>"

# Age/region/login-gated: use browser cookies
yt-dlp --cookies-from-browser chrome "<URL>"

# Whole playlist, numbered
yt-dlp -o "~/Downloads/%(playlist_index)s - %(title)s.%(ext)s" "<PLAYLIST_URL>"
```

Localhost note (unrelated to yt-dlp but common on this kind of box): if a local
HTTP proxy is set, `curl http://localhost:PORT` may 502 — use
`curl --noproxy '*' http://localhost:PORT`.

---

## ffmpeg recipes

```bash
# webm (AV1/VP9 + Opus) -> H.264 + AAC mp4 (universally playable), streamable
ffmpeg -i in.webm -c:v libx264 -crf 20 -preset medium -c:a aac -b:a 192k -movflags +faststart out.mp4

# Remux only (no re-encode) when codecs are already mp4-friendly (H.264/AAC) — fast, lossless
ffmpeg -i in.mkv -c copy -movflags +faststart out.mp4

# Extract audio without re-encoding (if already aac/m4a)
ffmpeg -i in.mp4 -vn -c:a copy out.m4a

# Trim (re-encode-free seek; -ss before -i is fast, -to is absolute)
ffmpeg -ss 00:01:00 -to 00:02:30 -i in.mp4 -c copy clip.mp4

# Inspect codecs / duration / resolution
ffprobe -v error -show_entries stream=codec_type,codec_name:format=duration -of default=noprint_wrappers=1 in.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 in.mp4
```

Quality: re-encoding is lossy. When you must re-encode (e.g. to burn subtitles),
encode from the **highest-quality source you have** (the original download), not
a file you already compressed once.
