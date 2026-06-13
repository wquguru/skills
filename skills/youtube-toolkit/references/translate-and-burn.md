# Translate & burn subtitles + watermark

Goal: a hard-subbed mp4 with translated subtitles (e.g. Chinese) and a translator watermark like `@handle 翻译`. The agent translates; `burn-subs.sh` does the deterministic encode.

## Step 1 — Get source subtitles

Translate from the **original language**, not YouTube's auto-translated track — the machine `zh-Hans` track is low quality and unworthy of a translator credit.

```bash
yt-dlp --list-subs --skip-download "<URL>"          # see what exists
yt-dlp --write-auto-subs --sub-langs en --convert-subs srt --skip-download \
       -o "subs_%(id)s.%(ext)s" "<URL>"             # -> subs_<ID>.en.srt
```

Prefer human subs (`--write-subs`) over `--write-auto-subs` when available.

## Step 2 — Re-segment the rolling captions

YouTube **auto-captions** are word-by-word *rolling* cues whose timestamps **overlap** (each cue starts ~2-3s before the previous ends). Burned as-is they double-stack on screen. Reconstruct clean, non-overlapping sentence cues:

- Concatenate the incremental text of consecutive cues into whole sentences.
- For each sentence cue: **start** = the start time of its first source cue; **end** = the start time of the *next* sentence's first cue (so cues never overlap). The last cue ends at the video duration.
- Aim for ~2-6s per cue, ≤2 lines, breaking at natural clause boundaries.

Human-authored subtitle tracks are usually already clean — skip re-segmentation.

## Step 3 — Translate into a .zh.srt

Write faithful, natural target-language text, one entry per sentence cue, e.g.:

```srt
1
00:00:00,520 --> 00:00:06,960
想花 1 美元买一辆新 SUV？
还真有人这么试过。

2
00:00:06,960 --> 00:00:12,200
他们找上了某家汽车经销商的聊天机器人。
```

Keep `,` (comma) in SRT timestamps, a blank line between entries, sequential numbers, and at most two display lines per cue.

## Step 4 — Preview before the full encode

A full 1080p encode takes minutes; verify font + sizing + timing on one frame first. Use `-copyts` so the subtitle filter sees the real timestamp (plain `-ss` before `-i` resets PTS and the wrong/no subtitle shows):

```bash
FF=/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg
$FF -y -copyts -ss 20 -i in.webm \
  -vf "subtitles=subs_ID.zh.srt,drawtext=fontfile=/System/Library/Fonts/Hiragino Sans GB.ttc:text='@handle 翻译':fontcolor=white@0.7:fontsize=30:x=w-text_w-24:y=24" \
  -frames:v 1 -update 1 /tmp/preview.png
```

Open the PNG; check Chinese glyphs render (not boxes), size is readable, and the subtitle for that timestamp is correct.

## Step 5 — Burn it in

```bash
bash scripts/burn-subs.sh -i in.webm -s subs_ID.zh.srt -w "@handle 翻译" -o out_zh.mp4
```

The script: finds a libass ffmpeg → converts SRT→ASS and sets the style (font, size, outline, bottom margin) → adds the watermark via `drawtext` → encodes H.264/AAC/+faststart from your source.

## Styling reference (ASS)

`burn-subs.sh` rewrites the `Style: Default` line. The ASS the SRT converts to uses `PlayResY: 288`, so on 1080p everything scales ×3.75 (Fontsize 17 ≈ 64px). Style field order:

```
Style: Default, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour,
       BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing,
       Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
```

Defaults used: white text (`&H00FFFFFF`), black outline (`&H00000000`), `BorderStyle=1` (outline+shadow), `Outline=1.6`, `Alignment=2` (bottom-center), `MarginV=18`. Colours are ASS `&HAABBGGRR` (alpha 00 = opaque).

### Why not `force_style`?

`subtitles=foo.srt:force_style='FontName=…,FontSize=…'` *looks* simpler but the commas inside `force_style` are eaten by the filtergraph parser (`No option name near …`). Converting to ASS and editing the `Style:` line avoids the escaping entirely — which is what the script does.

## Watermark as an ASS event (alternative)

Instead of `drawtext`, you can make the watermark a permanent ASS line so it travels with the subtitle file:

```
Dialogue: 0,0:00:00.00,9:59:59.99,Default,,0,0,0,,{\an9\fs36\alpha&H60&\pos(1896,24)}@handle 翻译
```

`\an9` = top-right anchor. Useful if you want a single self-contained `.ass`. `burn-subs.sh` uses `drawtext` by default for simplicity.

## Fonts

libass (the `subtitles` filter) resolves fonts by **family name** via fontconfig; `drawtext` needs an actual **font file**. CJK options:

| OS | Family (for subtitles) | File (for drawtext) |
|---|---|---|
| macOS | `Hiragino Sans GB`, `STHeiti`, `Songti SC` | `/System/Library/Fonts/Hiragino Sans GB.ttc` (note: no `PingFang.ttc` at the legacy path) |
| Linux | `Noto Sans CJK SC` | `/usr/share/fonts/.../NotoSansCJK-Regular.ttc` |

List installed CJK fonts: `fc-list :lang=zh` (if fontconfig is installed).
