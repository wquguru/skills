# Platform layout — where loop context lives

Discover, don't assume. Paths below are the common defaults; always `ls` to confirm before
reading. The encoded project dir, in particular, varies per machine.

---

## Claude Code (`/loop` cron)

### Scheduled task definition
- **Live list:** call the `CronList` tool (returns id, schedule, prompt for every job).
- **Durable files:** `<repo>/.claude/scheduled_tasks.json` (project) and
  `~/.claude/scheduled_tasks.json` (user). Each task has `id`, `cron`, `prompt`, `recurring`.
- To edit behavior you edit the `prompt` field (or recreate the cron). Confirm with the user
  first — this changes future runs.

### Persistent memory
- Dir: `~/.claude/projects/<encoded-project-path>/memory/`
- The encoded path is the absolute repo path with `/` → `-` (e.g.
  `/Users/x/work/foo` → `-Users-x-work-foo`). Find it:
  ```bash
  ls ~/.claude/projects/ | grep -i <repo-name>
  ```
- `MEMORY.md` is the **index** (loaded every session — one hook line per memory).
- Each `*.md` is one memory with frontmatter (`name`, `description`, `metadata.type` =
  user | feedback | project | reference).

### Instruction files
- `~/.claude/CLAUDE.md` (global, all projects) and `<repo>/CLAUDE.md` (project, committed).

### Run history (forensics)
- `~/.claude/projects/<enc>/*.jsonl` — one file per session; each cron fire appends to the
  session that created it (or spawns a new one). Filter user messages containing the task
  prompt to find fire boundaries.

---

## Codex (automation)

Codex has no `MEMORY.md` system — its persistent context is the **AGENTS.md** instruction
files plus whatever **state file the automation's prompt tells it to maintain** (often a
`STATUS.md` / `PROGRESS.md` in the repo). Treat that state file as the "memory" to clean.

### Discover the setup
```bash
ls -la ~/.codex/                 # config.toml, sessions/, history, automations?
cat ~/.codex/config.toml         # automations / scheduled config may live here
ls ~/.codex/sessions/ 2>/dev/null # run history for forensics, if present
```

### Instruction files
- `~/.codex/AGENTS.md` (global) and `<repo>/AGENTS.md` (project). Codex also reads nested
  `AGENTS.md` down the tree — check subdirs the loop touches.
- If the repo uses `agent-compat-sync`, `CLAUDE.md` and `AGENTS.md` may be symlinked together;
  editing one edits both. Note this before changing instruction files.

### Automation prompt
- Wherever the automation is defined (Codex cloud automation, a cron calling `codex exec`, or a
  CI schedule). The prompt is the equivalent of the Claude cron `prompt` field — same no-exit /
  dead-end-handoff checks apply.

### State / "memory" file
- Whatever file the prompt says to update each run (grep the prompt for `STATUS`, `PROGRESS`,
  `update`, `记录`, `append`). Same changelog-bloat and append-vs-overwrite heuristics apply;
  the snapshot + archive fix works identically.

---

## Cross-platform note

Both platforms share the same failure mode: **a recurring prompt that says "append your
progress / update the log each run" against a state file the loop also re-reads.** The cleanup
(snapshot + archive) and the prompt fix (overwrite-in-place + an exit condition) are the same
regardless of platform — only the file paths differ.
