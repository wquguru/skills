---
name: fable-5-best-practice
description: Route Claude model tiers (Haiku, Sonnet, Opus, Fable) and effort levels, prompt and migrate prompts for Claude Fable 5 (claude-fable-5), handle its 1M context, adaptive thinking, refusal stop reasons, and fallback, and design long-running agentic runs.
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
