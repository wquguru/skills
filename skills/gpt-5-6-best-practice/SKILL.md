---
name: gpt-5-6-best-practice
description: Choose GPT-5.6 tiers, reasoning effort, and subagent configurations to minimize accepted-outcome cost while preserving measured quality.
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

Sum usage once across every lead, worker, verifier, and retry call:

```text
accepted-outcome cost = total API or credit cost of all work required to pass
token efficiency = accepted tasks / total non-overlapping tokens across those calls
```

An apparently cheap run is expensive when it fails, omits evidence, causes rework, or
needs a stronger rescue pass. Fewer tokens are useful only after correctness,
completeness, evidence, and required verification pass. Track latency, calls, and
human corrections separately rather than adding incompatible units. Cached-input and
reasoning tokens are breakdowns of input and output usage, not extra tokens to add
again. Across tiers, compare accepted outcomes per dollar or credit; use tokens as a
diagnostic metric rather than a cross-tier cost proxy.

## Understand the capability tiers

| Tier | Start here for | Move up when | Do not use as |
| --- | --- | --- | --- |
| Luna | Fixed-schema extraction, classification, transformation, short summaries, isolated mechanical edits, and other clear high-volume work | The task needs a multi-step tool chain, sustained state, ambiguity resolution, or nontrivial judgment | A tier mismatch that higher effort is assumed to fix |
| Terra | Bounded implementation, routine debugging, repository exploration, tool use, short reviews, and supporting workers | The task becomes ambiguous, spans unfamiliar systems, needs architectural judgment, or makes failure/rework expensive | A universal replacement for Sol on hard coding |
| Sol | Ambiguous multi-file coding, difficult debugging, architecture, high-recall review, research synthesis, polished frontend work, and high-value decisions | Higher effort only after a representative failure shows that more reasoning or checking is needed | The default for simple volume work |

These are starting roles, not permanent assignments. Route from task shape and local
evidence. Do not invent universal capability scores.

## Prevent oversized Sol runs

When the active lead is Sol, apply this gate before starting the requested work. Stop
and recommend Luna or Terra only when the cheaper tier is likely to preserve the
acceptance outcome, the surface offers an actionable switch or new-task handoff, and
expected remaining savings exceed duplicated prompt, context, restart, and handoff
overhead. Do not create subagents merely to rationalize the Sol lead.

When those conditions hold, use:

```text
This task is likely to achieve the same accepted outcome on [Luna or Terra] at lower
cost because [task-specific reason]. [Switch to that tier here, or start a new task on
that tier using the compact handoff below.] If you intentionally want this task to
remain on Sol, say so.
```

Use only the action the surface supports. For a new-task route, include a compact
handoff containing the outcome, constraints, acceptance criteria, and necessary paths
or evidence; do not make the user reconstruct the task.

After an explicit request to remain on Sol, continue without repeating the advisory.
If switching is unavailable or its overhead may erase the saving, finish the current
task and give at most one short recommendation for future tasks. This includes
immediate answers and short tool-backed work. In strict cost mode, stop whenever a
supported cheaper route is likely to be non-inferior and net-cheaper after rerouting.

## Choose the initial lane

Before standardizing a route for a workload family whose quality needs are uncertain,
establish a representative acceptance baseline with Sol Medium. Then test Terra
Medium and, for deterministic work, Luna Low or Medium. This calibration is not
required for an obviously simple one-off task. After a route repeatedly passes the
same checks, use the lowest-cost validated lane:

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

## Make worker routing executable

Inspect the active surface before promising savings: identify available model IDs,
effort controls, inheritance behavior, and whether worker overrides are supported. If
the surface cannot select worker models, optimize decomposition, context, fan-out, and
verification instead of claiming tier-routing savings.

Local Codex clients support custom agents under `.codex/agents/` or
`~/.codex/agents/`. Pin `model` and `model_reasoning_effort` in the agent file when a
stable route matters; otherwise Codex may choose them dynamically. Read
`references/worker-profiles.md` for Luna, Terra, and Sol profiles. Treat those profiles
as starting configurations, not proof that a tier fits a particular repository.

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

## Migrate older prompts

Before moving an existing prompt, `AGENTS.md`, skill, or harness to GPT-5.6:

- Remove step-by-step scaffolding that only compensated for weaker models; official
  internal evaluations found leaner prompts sometimes improved scores while cutting
  tokens substantially (see `references/evidence-notes.md` for the measured ranges).
- Keep rules that protect safety, data, budget, scope, style, and business judgment.
- Re-map effort settings: old defaults tuned for a previous model are not evidence for
  the new one. Re-run the routing comparison instead of carrying the setting over.
- Re-test prompt token counts, latency, accepted-outcome cost, and timeout behavior on
  the representative suite before standardizing the migrated prompt.

## Use subagents economically

Every worker adds model and tool work. Under the default cost-minimizing policy,
delegate only when independent workstreams are expected to lower total
accepted-outcome cost with non-inferior acceptance performance. Use higher-cost
parallelism only when the user explicitly prioritizes latency or additional quality
and accepts the cost tradeoff. Measure exceptions locally.

- Luna workers, when available and locally validated: fixed-schema, repeatable,
  independently verifiable subtasks.
- Terra workers: read-heavy exploration, tests, triage, summaries, and bounded changes
  with clear ownership.
- Sol workers: genuinely difficult independent analysis where weaker workers would
  likely churn or need rescue.
- Give each worker a goal, owned scope, inputs, output contract, verification method,
  and stop condition. Read `references/prompt-patterns.md` for a reusable packet shape.
- Cap fan-out, nesting, attempts, and returned context. Keep write ownership disjoint.
- Keep `agents.max_depth = 1` unless recursive delegation is demonstrably necessary.
  The default `agents.max_threads = 6` is a cap, not a target worker count.
- Prefer one strong worker over several weak workers when the task cannot be decomposed
  without repeated context or cross-worker negotiation.
- Give semantic verification to a tier that matches the residual risk. Objective gates
  may use a cheap verifier; high-risk judgment may require Sol even when execution did
  not.

## Evaluate routing on real work

Build a small representative suite before standardizing a route. Include simple volume
work, bounded implementation, ambiguous debugging, multi-file change, and review.

For every configuration record:

- acceptance result and failed criterion;
- non-overlapping input and output usage for every lead, worker, verifier, and retry
  call, with cached-input and reasoning breakdowns when exposed;
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
- Continuing material Luna- or Terra-suitable work on Sol without a routing advisory.
- Creating subagents solely to rationalize an oversized Sol lead.
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
