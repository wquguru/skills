---
name: fable-5-best-practice
description: Route Claude tiers, effort, and subagents for Fable-led work, and handle Fable-specific prompting, long-running execution, API behavior, refusals, and fallback.
---

# Claude Fable 5 Best Practices

Use this skill as a Fable-specific routing and runtime overlay. Safety, permissions,
repository instructions, and explicit user constraints remain authoritative.

Default objective: satisfy the acceptance contract, then minimize accepted-result
cost. Lower latency or higher quality beyond the contract is a different objective; pursue it
at higher cost only when the user explicitly chooses that tradeoff.

## Product snapshot

As checked on 2026-07-10, the API model ID is `claude-fable-5`, the context window is
1M tokens with up to 128k output tokens, API pricing is $10/MTok input and $50/MTok
output, and the model requires 30-day retention rather than zero data retention. These
facts are volatile. Read `references/evidence-notes.md` before quoting them as current.

## Terms

- `acceptance contract`: observable acceptance criteria, required safety and
  verification, and approval boundaries.
- `tier`: a vendor-defined capability class: Haiku, Sonnet, Opus, or Fable.
- `effort`: reasoning and checking depth within one tier.
- `lane`: one `tier + effort` single-agent configuration.
- `orchestration`: the single-agent or lead/workers/verifier topology.
- `route`: lead lane, worker lanes, orchestration, and verification plan together.
- `accepted-result cost`: total spend required to pass the contract, measured in the
  surface's primary accounting unit: API dollars or subscription credits, never both.
- `non-inferior`: acceptance performance within a predeclared tolerance on
  representative work; it does not mean identical output on every run.
- `surface`: the active product/client, account entitlements, model controls, worker
  overrides, permissions, and accounting system.

Track tokens, latency, calls, and human correction as separate diagnostics or
guardrails. If the surface exposes no comparable spend signal, describe relative
resource intensity instead of claiming an exact cheapest route.

## Cost-aware routing procedure

Follow this order. Later sections explain vendor-specific mappings but do not override
the procedure.

1. **Fix the contract and objective.** Define the required deliverable, checks,
   semantic review, safety constraints, and approvals. Record any explicit user choice
   to trade higher cost for latency or quality beyond the contract.
2. **Inspect the surface.** Identify the active model, available tiers and effort
   values, lead-switch or new-task handoff mechanism, worker-model overrides and
   inheritance, orchestration limits, permissions, and accounting unit. If a
   capability is unavailable or unverified, do not promise savings from it.
3. **Choose direct-lane candidates.** Judge ambiguity, coupling, state depth, semantic
   risk, objective checkability, and expected rework. For recurring work, reuse
   validated evidence. Without a baseline, include both the cheapest plausible lane
   and a stronger reasonable baseline; do not treat the premium tier as ground truth.
   Label one-off task-shape judgments as heuristics.
4. **Apply the premium gate.** When the active lead is Fable, pause before the first
   task-execution tool call, state-changing write, or substantive multi-step analysis
   and wait for
   confirmation only when a cheaper lane is likely
   non-inferior, an actionable switch or complete new-task handoff exists, and expected
   remaining savings exceed duplicated prompt, context, restart, and handoff cost.
   Recommend one lane, one task-specific reason, and the supported switch or compact
   handoff. Do not continue while waiting. If the user chooses Fable, continue without
   repeating the gate. If any condition fails, continue and give at most one
   future-task reminder.
5. **Compare three routes before delegating for cost.** Prospectively assess the
   current single-agent route, the cheapest likely non-inferior single-agent lane, and
   an appropriate lead with routed workers. Use local history or task-shape evidence;
   do not execute all three merely to route a one-off task. Use the routed design for
   cost when—and only when—it is expected to be the cheapest accepted route and the
   work has independent scopes, compact handoffs,
   controlled write ownership, and affordable verification. Never manufacture workers
   to justify a Fable lead.
6. **Bound the chosen route.** Pin every worker model and effort when supported;
   otherwise do not claim tier-routing savings. Give each worker a goal, owned scope,
   distilled inputs, output contract, verification including residual semantic review,
   and a stop condition. Cap fan-out, depth, attempts, retries, and returned context.
   Higher-cost parallelism requires the explicit latency/quality tradeoff from step 1.
7. **Diagnose before escalating.** Repair missing or conflicting context first. Retry
   the same lane for a transient tool failure. Raise effort one level for insufficient
   checking on a clear task. Raise tier for a
   reasoning, ambiguity, or state-tracking mismatch. Lower effort for overexploration
   and lower tier for repetitive objective volume. Keep one agent for sequential or
   shared-state work. Change only one of tier, effort, prompt/context, tools, or
   orchestration at a time; escalate only the failing workstream and route back down
   after the hard decision is settled.
8. **Verify and update policy.** Verify against the unchanged contract and account for
   every lead, worker, verifier, retry, and rescue without double counting. A one-off
   heuristic may be used for low-risk, strongly verified work, but it does not become a
   default route. Standardize a cheaper route only after paired representative runs
   meet a predeclared non-inferiority and adoption rule.

Minimal read-only inspection needed to evaluate the premium gate is allowed before the
pause; task execution is not. For a new-task handoff, include the outcome, constraints, acceptance criteria, and
necessary paths or evidence so the user does not have to reconstruct the task.

## Claude tier and effort mapping

| Tier | Good starting work | Escalation rule / next action | Avoid |
| --- | --- | --- | --- |
| Haiku | Strict-schema extraction, classification, formatting, and isolated mechanical work with objective checks | Move to Sonnet for sustained state, multi-step tools, ambiguity, or judgment | Compensating for a tier mismatch with more prompting |
| Sonnet | Repository exploration, bounded implementation, routine debugging, tests, and supporting workstreams | Move to Opus for difficult bounded reasoning, semantic risk, or expensive rework | Treating it as a universal replacement for difficult coding work |
| Opus | Complex multi-file coding, difficult debugging, high-recall review, and research synthesis | Move to Fable when the hard part is sustained global judgment or arbitration | Using it for simple volume work |
| Fable | Long-horizon, high-stakes judgment, cross-workstream synthesis, and final arbitration | Repair context or raise effort only after a concrete contract failure | Using prestige, file count, or elapsed time as justification |

Fable effort settings:

- `low`: bounded work where cost and speed dominate.
- `medium`: interactive exploration or a balanced pass.
- `high`: normal starting point for serious Fable work without a calibrated route.
- `xhigh`: capability-sensitive long-horizon work with a measured need.
- `max`: highest supported effort setting; reserve it for a demonstrated quality gap.

Reduce effort when successful runs explore unused alternatives or produce unactionable
detail. Increase it only after ruling out prompt, context, tool, and verification gaps.

## Delegation and verification on Fable

Cost-routing workers should normally use Haiku, Sonnet, or Opus according to task
shape. An independent verifier is different: if the acceptance contract requires
fresh-context review, its cost is part of every eligible route and its tier follows
residual semantic risk, even when that means Opus or Fable.

Prefer one lead when work is sequential, shares mutable state, or would copy most of
the parent context. Concurrent writers need disjoint ownership; read-only workers may
share scope, and sequential handoffs may touch the same files with one writer at a
time. Read `references/prompt-patterns.md` for worker and verifier packets.

Deterministic gates reduce risk only for the properties they encode. They can justify
testing a cheaper worker but never replace semantic review for unencoded requirements.

In one unversioned Claude Code observation, workers with no explicit model inherited
the Fable lead and fork-style workers ignored overrides. Verify current inheritance and
override behavior before relying on it; avoid forks when cost behavior is uncertain.

## Prompting and migration

For substantial work, provide outcome, relevant evidence, hard constraints, approval
boundaries, acceptance criteria, verification, budget, and stop condition. Let Fable
choose intermediate steps. Read `references/prompt-patterns.md` for compact shapes.

When migrating older prompts, remove scaffolding that only compensated for weaker
models, but keep safety, data, budget, scope, style, and business constraints. Never ask
for hidden reasoning. Re-test prompt tokens, latency, accepted-result cost, timeouts,
streaming, and asynchronous UX.

## Fable API behavior

- Adaptive thinking is always on; control depth with `effort`, not a manual thinking
  budget.
- Raw thinking is not returned. `thinking.display` is `summarized` or `omitted`;
  preserve returned thinking blocks unchanged in same-model multi-turn conversations.
- `max_tokens` covers thinking and response output. Give high-effort runs enough room.
- Task budgets cover a full agentic loop and are distinct from `max_tokens`. They are a
  Messages API beta and are not supported by Claude Code or Cowork in this snapshot.

Read `references/evidence-notes.md` before depending on beta headers or current surface
support. Read `references/api-runtime.md` before implementing task budgets, refusals,
or fallback.

## Long-running execution

- Use asynchronous workers, scheduled checks, or harness-native waiting; never use an
  unbounded sleep or polling loop inside a tool call.
- Keep the lead context to decisions, risks, current state, and compact evidence.
- Ground progress and completion claims in tool results from the current run.
- Preserve only durable decisions, constraints, corrections, confirmed approaches,
  and the next action across sessions; keep one compact state snapshot when needed.
- Pause for destructive or irreversible actions, external commitments, real scope
  changes, or information only the user can provide.
- Report outcome first, then the evidence that determines what to trust or do next.

Read `references/operations.md` for the complete scope, progress, state, and reporting
rules used by analysis-only and long-running work.

## Refusals and fallback

Detect a Fable classifier refusal with HTTP 200 plus `stop_reason: "refusal"`; treat
any partial result as incomplete. Refusal categories are monitoring metadata, not a
license to bypass safeguards.

Choose exactly one fallback mechanism per request path: server-side fallback where
supported, SDK middleware retry, or one manual retry on a different model. Do not
combine mechanisms or create a fallback loop. Before retrying side-effecting work,
confirm idempotency or that no action completed. Implementation details are in
`references/api-runtime.md`; provenance and confidence boundaries are in
`references/evidence-notes.md`. Reverify both before implementation.

## Reference map

- `references/prompt-patterns.md`: lead, worker, and verifier packets.
- `references/routing-and-evaluation.md`: cost accounting, one-off routing, and route
  adoption procedure.
- `references/api-runtime.md`: thinking, budgets, refusal fields, and fallback matrix.
- `references/operations.md`: scope control, long-running state, progress, and output.
- `references/evidence-notes.md`: dated product/API provenance and field observations.

Read only the reference needed for the current task.
