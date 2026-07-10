---
name: gpt-56-best-practice
description: Optimize GPT-5.6 Codex model-tier, reasoning-effort, and subagent choices for accepted-outcome performance per token across Sol, Terra, and Luna.
---

# GPT-5.6 Codex Efficiency

Use this skill as a routing and evaluation overlay for GPT-5.6 in Codex. It does not
replace normal coding, review, safety, Git, or repository instructions. Optimize the
cost of an accepted result, not the price of one token or the brevity of one response.

## Product snapshot

As verified on 2026-07-10:

- Sol, Terra, and Luna are durable capability tiers, not fixed job titles.
- Sol is the flagship tier; Terra is the balanced everyday tier; Luna is the fastest,
  lowest-cost tier.
- The `gpt-5.6` alias resolves to Sol. On surfaces that permit model choice, select
  explicit Terra or Luna lanes when appropriate. Codex cloud currently does not expose
  model selection.
- Light in the app and IDE corresponds to Low in the CLI; Extra High corresponds to
  `xhigh`. Max deepens one agent. Ultra appears beside reasoning levels but adds
  multi-agent orchestration; it is not an API `reasoning.effort` value. Budget for
  higher total token use unless local evidence shows otherwise.
- Availability, UI labels, subscription credits, defaults, and Fast-mode behavior are
  volatile. Inspect the current surface rather than assuming the snapshot is current.

## Optimize the right metric

Count the whole accepted-outcome cost:

```text
total tokens = lead + worker + tool-output-input + retry/rework + verification tokens
token efficiency = accepted tasks / total tokens
accepted-outcome cost = total API or credit cost of all work required to pass
```

An apparently cheap run is expensive when it fails, omits evidence, causes rework, or
needs a stronger rescue pass. Fewer tokens are useful only after correctness,
completeness, evidence, and required verification pass. Track latency, calls, and
human corrections separately rather than adding incompatible units.

## Understand the capability tiers

| Tier | Start here for | Move up when | Do not use as |
| --- | --- | --- | --- |
| Luna | Fixed-schema extraction, classification, transformation, short summaries, isolated mechanical edits, and other clear high-volume work | The task needs a multi-step tool chain, sustained state, ambiguity resolution, or nontrivial judgment | A tier mismatch that higher effort is assumed to fix |
| Terra | Bounded implementation, routine debugging, repository exploration, tool use, short reviews, and supporting workers | The task becomes ambiguous, spans unfamiliar systems, needs architectural judgment, or makes failure/rework expensive | A universal replacement for Sol on hard coding |
| Sol | Ambiguous multi-file coding, difficult debugging, architecture, high-recall review, research synthesis, polished frontend work, and high-value decisions | Higher effort only after a representative failure shows that more reasoning or checking is needed | The default for simple volume work |

These are starting roles, not permanent assignments. Route from task shape and local
evidence. Do not invent universal capability scores.

## Choose the initial lane

Use the lowest lane likely to finish successfully:

1. Luna Low for simple, repeatable work with an objective output schema.
2. Luna Medium when the same work needs modest reasoning or one short tool sequence.
3. Terra Low or Medium for bounded engineering and everyday agent work.
4. Sol Low or Medium for complex coding, ambiguity, long verification chains, or work
   where a failed cheap pass would cost more than starting strong.
5. High or Extra High only when a measured quality gap remains.
6. Max only for the hardest tightly coupled or single-agent work after comparing it
   with Extra High.
7. Ultra only for valuable work that separates into at least two meaningful independent
   streams. Select it for measured quality or wall-clock gains, not assumed token savings.

For difficult work, compare a stronger tier at Low or Medium with the current tier at
higher effort; do not assume either route wins. One dated broad API benchmark—not a
Codex repository or subscription evaluation—found Sol Low or Medium more token-efficient
than smaller tiers at very high effort in its suite. Transfer to a specific repository
is unknown. Read `references/evidence-notes.md` when this tradeoff is disputed.

## Diagnose before escalating

When a run misses acceptance criteria, identify the failure class:

- Missing context or conflicting instructions: fix the prompt or context; do not buy
  more reasoning.
- Clear task, insufficient checking: raise effort one level on the same tier.
- Core reasoning, ambiguity, or state-tracking failure: move up a tier, usually before
  raising a smaller model above Medium.
- Excessive exploration or verbosity: lower effort before changing tier.
- Repetitive, well-specified volume: move down a tier and keep deterministic checks.
- Independent branches dominate wall-clock time: consider bounded subagents or Ultra.
- Sequential work or shared mutable state: keep one agent; parallelism adds coordination
  and duplicate context.

Change one dimension at a time: tier, effort, prompt, tool set, or orchestration. A run
that changes several cannot reveal what caused the improvement.

## Keep prompts and context lean

- State each instruction once across the task prompt, `AGENTS.md`, skills, and tool
  descriptions. Remove duplicated safety, style, and workflow rules.
- Provide the outcome, relevant evidence, hard constraints, approval boundaries,
  acceptance criteria, required verification, and output shape.
- Do not prescribe every intermediate step when the path is not a product requirement.
- Expose only relevant tools. Keep tool descriptions and worker packets compact.
- Keep examples only when they encode a requirement or repair a measured failure.
- Trim inactive tool output and stale context. Make workers return distilled evidence,
  not raw logs, repository dumps, or reasoning transcripts.
- Do not rely on a bare "be concise" instruction. Name the decisions, evidence,
  caveats, and next actions that a short answer must preserve.

Leaner prompts are an evaluation hypothesis, not permission to delete real constraints.

## Use subagents economically

Every worker adds model and tool work. Delegate only when the expected quality or
wall-clock gain is worth the likely token overhead, and measure exceptions locally.

- Luna workers, when available and locally validated: fixed-schema, repeatable,
  independently verifiable subtasks.
- Terra workers: read-heavy exploration, tests, triage, summaries, and bounded changes
  with clear ownership.
- Sol workers: genuinely difficult independent analysis where weaker workers would
  likely churn or need rescue.
- Give each worker a goal, owned scope, inputs, output contract, verification method,
  and stop condition.
- Cap fan-out, nesting, attempts, and returned context. Keep write ownership disjoint.
- Keep `agents.max_depth = 1` unless recursive delegation is demonstrably necessary.
  The default `agents.max_threads = 6` is a cap, not a target worker count.
- Prefer one strong worker over several weak workers when the task cannot be decomposed
  without repeated context or cross-worker negotiation.

## Evaluate routing on real work

Build a small representative suite before standardizing a route. Include simple volume
work, bounded implementation, ambiguous debugging, multi-file change, and review.

For every configuration record:

- acceptance result and failed criterion;
- input, cached-input, reasoning, output, worker, and retry tokens when exposed;
- wall-clock time, tool calls, retries, and human corrections;
- verification result and total cost or subscription usage signal.

Hold the prompt, tools, and acceptance criteria constant. Compare adjacent choices,
such as Terra Medium versus Sol Low or Sol Medium versus High. Compare Sol Max
single-agent with Sol Ultra only on decomposable tasks. Adopt a route only when the
gain repeats across representative tasks. API prices and Codex subscription limits
are different accounting systems; never infer one from the other.

## Handle safeguards and latency honestly

GPT-5.6 uses real-time cyber and biology safeguards. Legitimate dual-use work may pause
mid-stream, take longer, or be refused. Do not diagnose every pause as a stuck agent,
loop retries adversarially, or hide the failure. State the benign context where useful,
report the refusal, and follow the current surface's allowed recovery path.

Fast mode charges credits at a higher rate for lower latency; it does not inherently
save or increase tokens. Max spends more reasoning on one agent. Neither is a default
token-saving feature.

## Avoid these anti-patterns

- Always starting with Luna because its tokens are cheapest.
- Pushing Luna or Terra to Max without comparing a stronger tier at Low or Medium.
- Using Sol for mechanical volume or using Ultra for sequential work.
- Launching many workers because the harness permits them.
- Treating fewer calls, shorter output, or lower per-token price as success by itself.
- Comparing configurations with different prompts, tools, or acceptance criteria.
- Copying volatile prices, credit multipliers, or rollout claims into durable policy.
- Duplicating general Codex behavior already enforced by the system or repository.

## Evidence discipline

The routing rules combine official product guidance with early independent evidence.
Read `references/evidence-notes.md` before changing the defaults, quoting benchmark
numbers, or presenting a claim as universal. Prefer local evals over vendor anecdotes.
