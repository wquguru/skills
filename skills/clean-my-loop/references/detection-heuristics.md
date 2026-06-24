# Loop-decay detection heuristics

Each smell below has a **quantitative trigger** (so findings are evidence, not vibes), a
**why it hurts**, and a **fix**. Run them top to bottom; cite the actual numbers you measure.

Sizing + recency baseline first:

```bash
wc -l -w -c <memory-dir>/*.md          # every memory/state file
wc -c <index-file>                      # MEMORY.md (Claude) or the loop's STATUS file
ls -lT <memory-dir>/*.md                # last-modified time per file (recency signal)
```

A healthy "one fact" memory file is roughly **0.5–3 KB**. Anything an order of magnitude past
that, in a file that's supposed to hold one fact, is the prime suspect.

**Translate size into recurring token cost** — that's what actually hurts. The index file and
any recalled memory are re-read *every iteration*, so a rough `tokens ≈ bytes / 4` (English;
~2 for CJK-heavy) makes the tax concrete: an 8 KB index line ≈ ~2k tokens **per run, forever**.
Report the per-iteration cost, not just the byte count — it's the number that justifies the
cleanup.

**Use last-modified as a staleness signal.** A memory file untouched for many iterations while
the loop kept running is either (a) settled fact (fine) or (b) abandoned/stale context nobody
re-validated. Cross-check the *claims* in long-dormant files against current reality (smell #7).
Conversely, a file that's rewritten *every single run* is the append-bloat signature (smell #1).

---

## 1. Memory-as-changelog

**Trigger:** a single memory/state file that (a) is large (≫3 KB for a "one fact" file), and
(b) grows every iteration. Confirm growth from history rather than guessing — if the file is
git-tracked, its size trend over recent commits is the proof:

```bash
git log --format='%h %ad' --date=short -- <file> | head     # how often it changes
for c in $(git log --format=%h -5 -- <file>); do \
  printf "%s %s\n" "$c" "$(git show $c:<file> 2>/dev/null | wc -c)"; done  # size at each
```

A size that only ever climbs, touched on nearly every run, is the append-bloat signature. Then
confirm with marker density:

```bash
for w in DONE deferred done "✅" "⏳" "PROD" "Phase" queue; do
  printf "%-10s %s\n" "$w" "$(grep -o "$w" <file> | wc -l)"
done
```

Dozens of `DONE` / `deferred` markers ⇒ it's a changelog wearing a memory's frontmatter.

**Why it hurts:** it's re-read (and often re-summarized into context) every run, costing
budget; worse, it re-injects the same "here's the long story so far" narrative each iteration,
biasing the loop toward *continuing the narrative* instead of re-deciding from current reality.

**Fix:** snapshot + cold archive (SKILL Step 5). The live file becomes a short current-state
snapshot ending in an explicit "overwrite, don't append" rule.

---

## 2. Bloated index

**Trigger:** Claude `MEMORY.md` where any single line is far past a one-line hook
(`awk '{print length, NR}' MEMORY.md | sort -rn | head`), or the whole index file is ≫3 KB.
The memory spec is "one line per memory, never put content in the index."

**Why it hurts:** the index is loaded into context **every session**. A multi-KB line is pure
recurring tax and, again, narrative anchoring.

**Fix:** rewrite the offending line as a single hook (what it is + current blocking state +
where to go for detail). Add a separate dim pointer line for any archive file.

---

## 3. No-exit task rule

**Trigger:** the cron/automation prompt contains a "if X fails / is blocked, skip / defer /
don't deploy" clause **with no matching exit** — no "after N consecutive fails" or "after M
hours blocked, stop and escalate." Grep the prompt for `skip`, `defer`, `不要`, `跳过`,
`rule 0` and check whether each guard has a bound.

**Why it hurts:** a guard meant for a *transient* failure becomes a *permanent* stall switch.
The loop keeps firing and keeps doing the degraded path indefinitely.

**Fix:** add an explicit exit + escalation. Ask the user for the policy (SKILL Step 4): stop
producing new deferred work → health-check only → one loud BLOCKED signal (+ notification).

---

## 4. Dead-end human handoff

**Trigger:** the prompt instructs the *unattended* loop to "ask the user to do X" / "tell the
operator to rotate Y" as its resolution path, and the same ask recurs in every run's report.

**Why it hurts:** nobody reads a cron's per-fire report in real time. "Ask the human" is a
no-op for an automation; the blocker never clears from inside the loop, so it churns.

**Fix:** convert to (a) a single persistent BLOCKED line in the state snapshot, (b) stop
churning new work while blocked, and (c) if a real channel exists (Slack/email/notification),
route one alert there instead of burying it in a report.

---

## 5. Unbounded queue growth

**Trigger:** each iteration produces work that can't reach its goal state (unvalidated,
unadopted, undeployed) and it piles up. Quantify with git against the last "real progress"
marker:

```bash
git rev-list --count <last-deployed-or-adopted-ref>..HEAD   # commits stacked up
git log --oneline <ref>..HEAD | cat
```

A monotonically rising count while the loop's reports stay upbeat ("queue now N ahead") is the
signature.

**Why it hurts:** the loop mistakes motion for progress. It produces a growing pile of work
that may never be validatable, defeating the task's actual purpose.

**Fix:** gate new work on the real blocker (Step 3 fix above), and make the queue depth a
first-class line in the state snapshot so it's visible, not buried.

---

## 6. Doc-as-cover (CLAUDE.md / AGENTS.md)

**Trigger:** an instruction file contains framing that, combined with a blocker, lets the loop
feel virtuous while missing its purpose — e.g. "validation only happens in env Z" + "build
locally first" ⇒ endless local builds that never get validated. Look for decoupling/discipline
language that the loop is using as permission to stay in the degraded path.

**Why it hurts:** it's the philosophical cover that makes the degenerate loop feel like
correct behavior, so the agent never re-frames "this is now blocked, pause."

**Fix:** add a counter-rule near the framing (e.g. "if blocked from validating for M hours,
stop building and escalate"), so the discipline has a backstop.

---

## 7. Stale / contradictory memory

**Trigger:** recalled memory names a file, function, flag, or commit. Verify it still exists
(`ls`, `git cat-file -e`, `grep`). Memory reflects what was true when written.

**Why it hurts:** the loop acts on a fact that's no longer true and compounds the error.

**Fix:** correct or delete the stale memory; never repeat a memory claim you couldn't verify.

---

## Forensics: read the run history, don't guess

The strongest evidence is the loop's own past iterations. For Claude Code, each fire's final
report is in `~/.claude/projects/<enc>/*.jsonl`. Extract per-iteration reports and look for
repetition and a rising queue number. A minimal pass (adapt as needed):

```python
import json, glob
for f in glob.glob("<enc-dir>/*.jsonl"):
    last=""
    for line in open(f):
        try: o=json.loads(line)
        except: continue
        if o.get("type")=="assistant":
            for b in o.get("message",{}).get("content",[]):
                if isinstance(b,dict) and b.get("type")=="text" and b["text"].strip():
                    last=b["text"]
    print(f, "\n", last[-600:], "\n---")
```

Signals that confirm a degenerate loop:
- The same closing action ("skipped deploy", "deferred", "asked to rotate token") repeats run
  after run.
- A self-reported counter ("queue N ahead", "M consecutive errors") only ever increases.
- Real progress (merges, deploys, adopts) flatlines while reports stay confident.

Bring these to Step 4 as the case for what to fix.
