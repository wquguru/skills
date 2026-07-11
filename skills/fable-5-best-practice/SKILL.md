---
name: fable-5-best-practice
description: Choose Claude tiers and effort for Fable-led runs, route subagents by task shape, and evaluate accepted-outcome cost while preserving quality.
---

# Claude Fable 5 Best Practices

Use this skill as a Fable-specific overlay, not as a general agent handbook. Treat
Fable as a premium long-horizon reasoning and orchestration model. Do not turn every
complex task into a Fable run or a multi-model workflow.

## Product snapshot

As checked on 2026-07-10:

- The API model ID is `claude-fable-5`.
- The context window is 1M tokens with up to 128k output tokens per request.
- API pricing is $10/MTok input and $50/MTok output.
- The model requires 30-day data retention and is unavailable in workspaces that
  remain under zero data retention.

Pricing, availability, retention, API behavior, and feature support can change. Treat
this as a dated operating baseline. When current accuracy is essential, verify the
specific fact against the official Anthropic documentation available in the runtime
instead of relying on memory or guessing. If verification is unavailable, state the
snapshot date and label the uncertainty. Provenance for the snapshot, the beta
headers, and the refusal categories lives in `references/evidence-notes.md`; read it
before quoting these facts as current or copying them into another policy.

## Decide whether Fable is warranted

Use the cheapest model that is likely to meet the acceptance criteria. Prefer Fable
when the difficult part is judgment rather than volume:

- ambiguous or high-stakes reasoning with consequential tradeoffs;
- sustained, goal-directed work whose path cannot be specified in advance;
- synthesis across conflicting evidence or final arbitration after cheaper attempts;
- long runs where instruction retention, self-correction, and verification matter.

File count, elapsed time, or use of memory does not by itself justify Fable. Avoid it
for routine Q&A, formatting, mechanical edits, bulk discovery, and deterministic work
that a cheaper model can reliably complete.

## Enforce the premium-tier gate

When the active lead is Fable, apply this gate before starting the requested work.
Decline to execute on Fable only when all three conditions hold:

1. Haiku, Sonnet, or Opus is likely to meet the same acceptance criteria.
2. The active surface offers an actionable switch or a new-task handoff.
3. Expected savings on the remaining work exceed the duplicated prompt, context,
   restart, and handoff overhead.

Recommend the cheapest suitable tier and give one task-specific reason:

```text
This task does not justify Fable. Use [tier] because [task-specific reason].
If you intentionally want to continue on Fable, say so explicitly.
```

Do not spawn workers merely to justify keeping a Fable lead. Under the default
cost-minimizing policy, subagents are appropriate only when independent workstreams
plus cheaper worker models reduce expected total accepted-outcome cost while
preserving acceptance performance. The only exception is an explicit user preference
for lower latency that accepts higher cost. If switching is unavailable or its
overhead may erase the saving, finish the current task and give at most one short
recommendation for future tasks. This includes immediate answers and short tool-backed
work. If the user explicitly chooses to continue on Fable after an advisory, proceed
without repeating it and still apply the normal delegation gate.

Start from task shape, not prestige:

| Tier | Start here for | Move up when | Do not use as |
| --- | --- | --- | --- |
| Haiku | Fixed-schema extraction, classification, formatting, short summaries, isolated mechanical edits, and other clear high-volume work | The task needs a multi-step tool chain, sustained state, ambiguity resolution, or nontrivial judgment | A tier mismatch that more prompting is assumed to fix |
| Sonnet | Bounded implementation, routine debugging, repository exploration, tool use, short reviews, and supporting workers | The task becomes ambiguous, spans unfamiliar systems, or makes failure and rework expensive | A universal replacement for Opus or Fable on hard coding |
| Opus | Complex multi-file coding, difficult debugging, high-recall review, research synthesis, and everyday hard problems | The difficulty is long-horizon judgment, orchestration, or final arbitration rather than depth on one bounded problem | The default for simple volume work |
| Fable | Ambiguous high-stakes reasoning, sustained goal-directed runs, synthesis across conflicting evidence, and final arbitration | Raise `effort` before looking for a bigger model; Fable is the top tier | A prestige default for work Opus completes reliably |

These are starting roles, not permanent assignments. Treat model routing as an
empirical deployment policy, not a universal hierarchy. Use cheaper workers for
bounded execution only when harness policy permits delegation,
the harness supports it, and local evaluations show that the handoff reduces the total
cost of obtaining an accepted result. Do not use invented capability scores or fixed
cost multipliers.

## Optimize accepted-outcome cost

Minimize total cost per accepted task, subject to non-inferior acceptance performance
and required safety and verification constraints. Count the lead, workers, repeated
context, tool-output ingestion, retries, rescue passes, and verification. Record human
correction separately unless an explicit labor-cost model exists. Keep API cost,
subscription credits, latency, and tokens as separate measurements rather than
converting them into a made-up common unit.

Compare a single-Fable baseline with a routed design while holding the task, prompt,
tools, acceptance criteria, and verification constant. Adopt the cheaper route only
when its acceptance rate stays within a declared tolerance across representative
tasks. A post-hoc judgment that work looked easy does not establish equal performance.

## Route subagents explicitly in Fable sessions

First inspect the active harness for available model IDs, effort controls,
inheritance behavior, and per-worker overrides. These capabilities are surface- and
version-specific. If worker models cannot be selected, do not claim model-routing
savings; optimize decomposition, context size, fan-out, and verification instead.

Delegate only when work has meaningful independent streams, a compact handoff, and
cheaper workers are expected to lower total accepted-outcome cost without reducing
acceptance performance. Treat latency as a separate constraint: use higher-cost
parallelism only when the user prioritizes wall-clock time over minimum cost. Prefer
one lead for sequential work, shared mutable state, or tasks whose handoff would
duplicate most of the context. Once delegation is chosen, set an explicit worker model
whenever the harness supports it. An omitted model on a Fable-led worker can silently
erase the intended savings.

Route by task shape, not phase name:

- Haiku: strict-schema, repetitive, independently checkable work.
- Sonnet: repository exploration, bounded implementation, routine testing, and
  checklist execution with clear ownership.
- Opus: difficult bounded debugging, semantic risk, high-recall review, or weak
  deterministic coverage.
- Fable: sustained global judgment, cross-worker synthesis, and arbitration; keep it
  as the lead unless an independent worker genuinely needs the same capability.

Deterministic gates reduce residual risk only for the properties they cover. They can
justify testing a cheaper tier, but they do not replace semantic review for unencoded
requirements. Diagnose the first failure: retry the same lane for transient tooling or
repairable context problems; raise effort for insufficient checking; move up a tier
for a reasoning, ambiguity, or state-tracking mismatch. Escalate only the failing
workstream, then route execution back down after the hard decision is settled.

In one observed Claude Code configuration, workers without an explicit model inherited
the Fable lead and fork-style workers ignored overrides. Treat this as a volatile field
observation, verify current behavior and usage, and avoid forks used only to save the
effort of writing a compact worker packet.

## Prompt compactly

Provide the outcome, why it matters, relevant evidence, constraints, observable
acceptance criteria, and approval gates. Let Fable choose the path. Read
`references/prompt-patterns.md` for a reusable shape when the task is substantial.

At higher effort, prevent unsolicited work explicitly:

```text
Stay within the requested scope. Do not add features, broad refactors, abstractions,
backups, feature flags, compatibility shims, or validation for impossible internal
states. Validate at system boundaries. When enough information exists to act, act;
recommend a path instead of surveying options you will not pursue.
```

When the user asks for analysis rather than a change, report the assessment and stop.
Do not create files, modify state, deploy, purchase, or send external messages unless
the request authorizes those actions.

## Migrate older prompts

Before moving an existing prompt, skill, or harness to Fable:

- Remove step-by-step scaffolding that only compensated for weaker models.
- Keep rules that protect safety, data, budget, scope, style, and business judgment.
- Remove instructions to reveal, reproduce, or transcribe hidden reasoning.
- Re-test prompt token counts, latency, accepted-outcome cost, and timeout behavior.
- Adjust streaming, progress UX, and asynchronous job handling for turns that can run
  many minutes and workflows that can run for hours or days.

## Handle Fable API differences

- Adaptive thinking is always on. Disabling thinking or configuring manual thinking
  budgets is unsupported; control depth with `effort`.
- Raw thinking is never returned. `thinking.display` is either `summarized` or
  `omitted`; preserve returned thinking blocks unchanged in same-model multi-turn
  conversations.
- `max_tokens` is a hard per-request cap covering thinking and response output. Give
  `xhigh` and `max` runs enough room to operate.
- Task budgets are an advisory budget for a full agentic loop and are distinct from
  `max_tokens`. They are beta on the Messages API with the
  `task-budgets-2026-03-13` header and are not supported by Claude Code or Cowork.

## Set effort deliberately

- `low`: bounded routine work where speed and cost dominate.
- `medium`: interactive exploration or a balanced agentic pass.
- `high`: the default and normal starting point for serious Fable work.
- `xhigh`: capability-sensitive, long-horizon agentic or coding work.
- `max`: absolute maximum capability for the hardest cases; do not use it by default.

Reduce effort when a successful run explores unused alternatives, takes longer than
needed, or produces detail the user cannot act on. Increase it only when risk is high
or a lower setting misses an acceptance criterion. Where supported, also set explicit
time, cost, attempt, and stop limits.

## Diagnose before escalating

When a run misses acceptance criteria, identify the failure class before spending more:

- Missing context or conflicting instructions: fix the prompt or context; do not buy
  more reasoning.
- Clear task, insufficient checking: raise `effort` one level on the same model.
- Core reasoning, ambiguity, or state-tracking failure: move up a tier, usually before
  pushing a smaller model past `high`.
- Excessive exploration, unused alternatives, or verbosity: lower `effort` before
  changing model.
- Repetitive, well-specified volume: move down a tier and keep deterministic checks.

Change one dimension at a time: model, effort, prompt, tool set, or orchestration. A
run that changes several cannot reveal what caused the improvement. Escalate after a
specific acceptance criterion fails; delegate back down after the hard decision is
settled.

## Design long-running runs

- Use asynchronous workers, scheduled checks, or harness-native waiting. Never keep an
  agent alive with an unbounded sleep or polling loop inside a tool call.
- Give independent workers compact packets: goal, evidence, constraints, owned scope,
  acceptance criteria, verification commands, and approval gates.
- Keep the lead context to decisions, risks, current state, and compact evidence.
  Clear or compact bulky tool results when they cease to be active evidence.
- When harness policy permits delegation and the task's risk and budget justify it,
  use a fresh-context verifier. Give it the goal, acceptance criteria, artifact or
  diff, and evidence rather than the executor's self-defense.
- Pause only for destructive or irreversible actions, real scope changes, external
  commitments, or information only the user can provide.

Ground progress in evidence:

```text
Before reporting progress, audit each claim against a tool result from this session.
Label unverified work explicitly. Report failed tests and skipped steps plainly; do
not count plans, promises, or intended tool calls as completed work.
```

For work spanning sessions, preserve only durable decisions, constraints, corrections,
confirmed approaches, and the next action. Use the harness's memory facility when
available. If a file is necessary, update one compact state snapshot rather than
creating a changelog or scattering notes through the repository. Delete stale or
disproved notes.

## Handle refusals and fallback

Fable classifier refusals arrive as successful HTTP 200 responses with
`stop_reason: "refusal"`; branch on the stop reason, not HTTP error handling or
`stop_details`. Categories can include `cyber`, `bio`, `frontier_llm`, and
`reasoning_extraction`. Benign work can also trigger them.

Configure a fallback model where continuity matters:

- On the Claude API or Claude Platform on AWS, server-side fallback uses the
  `fallbacks` parameter with the `server-side-fallback-2026-06-01` beta header. It is
  unavailable for Message Batches, Amazon Bedrock, Google Cloud, and Microsoft
  Foundry.
- The TypeScript, Python, Go, Java, and C# SDK middleware can retry refusals on any
  platform. Do not combine it with server-side fallback on the same request.
- For Ruby, PHP, raw HTTP, or custom retry logic, retry on a different model and use
  the `fallback-credit-2026-06-01` beta header to avoid duplicate prompt-cache cost.

Track refusals and fallback-served responses as separate operational signals. Treat
partial output from a refused attempt as incomplete, and never try to bypass
safeguards.

## Avoid these anti-patterns

- Defaulting to Fable or to `max` effort because the task feels important.
- Executing a clearly Haiku-, Sonnet-, or Opus-suitable task on Fable without first
  applying the premium-tier gate.
- Manufacturing subagent work to rationalize a Fable lead.
- Spawning subagents in a Fable session without an explicit model choice, or
  forking for context convenience — both can silently erase intended routing savings.
- Raising effort to compensate for a tier mismatch or a broken prompt.
- Keeping an agent alive with unbounded sleeps or polling loops inside tool calls.
- Scattering progress notes and changelogs through a repository instead of updating
  one compact state snapshot.
- Counting plans, promises, or intended tool calls as completed work.
- Handling refusals through HTTP error paths, or retrying them adversarially to get
  around safeguards.
- Copying dated pricing, retention rules, or beta headers into durable policy without
  re-verifying them.
- Stripping safety, budget, or scope rules along with the step-by-step scaffolding
  when migrating older prompts.

## Communicate the result

After a long run, write for someone who did not watch the tool calls. Lead with the
outcome, then the evidence that changes what the user should trust or do next. Use
complete sentences; avoid arrow chains, invented labels, hidden-reasoning references,
and unexplained implementation shorthand.

If a harness exposes a remaining-context countdown and Fable tries to stop solely
because of it, instruct it to continue unless a real limit or user-only blocker has
been reached.
