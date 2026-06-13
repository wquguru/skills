# Skills

A small collection of practical Claude Code skills.

## Skills

### `english-swe-daily`

A practical English coach for everyday engineering communication. Built for
developers who can already work in English but want to sound less textbook-like
and more like a real teammate in standups, Slack threads, 1:1s, code reviews,
and meetings.

Many engineers do not struggle with grammar — they struggle with sounding
natural. This skill teaches the kind of English people actually use in software
teams, with a strong focus on natural phrasing, collaboration tone, and
day-to-day workplace situations.

Install:

```bash
npx skills add https://github.com/wquguru/skills --skill english-swe-daily
```

Ask for help with prompts like:

- "Teach me English for standups."
- "Help me sound more natural in Slack."
- "Practice English for code reviews."
- "How do I say this more naturally at work?"
- "Give me today's SWE English session."

### `pi-setup`

Configures Pi Agent (`@earendil-works/pi-coding-agent`) with DeepSeek V4
(built-in provider) and Ant-Ling Ring-2.6-1T (custom OpenAI-compatible
provider), plus a curated extension set, while automatically working around 7
known pitfalls.

It detects before it acts: it probes whether pi is installed, whether config
already exists, and where keys live before changing anything. Keys are never
written in plaintext — pi config only stores lazy `!shell` commands and the key
stays in the user's original file. Model selection, default model, default
thinking tier, and the extension set are all confirmed interactively.

Install:

```bash
npx skills add https://github.com/wquguru/skills --skill pi-setup
```

Trigger it in Claude Code by saying "配置 pi", "setup pi agent", "把
ring/deepseek 配到 pi", or run `/pi-setup` manually.

Prerequisites:

- Node.js / npm (to install pi)
- A DeepSeek key (in `~/.deepseek` or an environment variable)
- An Ant-Ling/Ling key (`LING_API_KEY`, in a shell rc or environment
  variable) — only needed when enabling Ring

### `youtube-toolkit`

Downloads YouTube videos with `yt-dlp` and post-processes them with `ffmpeg`:
fetch best-quality streams, convert containers (e.g. AV1/webm → H.264 mp4),
extract audio, and burn in translated subtitles with a translator watermark.

It is macOS-first and bakes in the gotchas learned the hard way — chiefly that
Homebrew's lean `ffmpeg` ships without libass/drawtext (so subtitle burn-in
needs `ffmpeg-full`), that YouTube auto-captions are overlapping rolling cues
that must be re-segmented before they read cleanly, and that styling via an ASS
file avoids the `force_style` comma-parsing trap. Two helper scripts do the
deterministic work: `install-tools.sh` and `burn-subs.sh`.

Install:

```bash
npx skills add https://github.com/wquguru/skills --skill youtube-toolkit
```

Ask for help with prompts like:

- "Download this YouTube video to ~/Downloads."
- "Convert it to mp4."
- "Add Chinese subtitles and a @handle 翻译 watermark."

Prerequisites:

- Homebrew (macOS) or apt/pip (Linux)
- `yt-dlp` and a libass-enabled `ffmpeg` — `install-tools.sh` sets both up

## Repository Structure

```text
skills/
  english-swe-daily/
    SKILL.md
    references/
      expressions-bank.md
  pi-setup/
    SKILL.md
    references/
      config-templates.md
      troubleshooting.md
  youtube-toolkit/
    SKILL.md
    scripts/
      install-tools.sh
      burn-subs.sh
    references/
      installation-and-recipes.md
      translate-and-burn.md
```

## License

Add a license if you plan to distribute this publicly.
