---
name: fable5-best-practice
description: >
  Advise, prompt, and design workflows for Claude Fable 5. Use when choosing whether
  Fable is worth its cost, migrating prompts or skills to Fable, setting effort and
  budgets, routing work across Fable/Opus/Sonnet/Codex, designing long-running agent
  loops, grounding progress claims, or controlling context/cost for high-autonomy
  reasoning, coding, research, strategy, and review work.
---

# fable5-best-practice

Treat Claude Fable 5 as a long-horizon decision and orchestration model, not a faster
chat model. Use it when judgment, decomposition, verification, or sustained tool use
matters enough to justify premium cost and latency.

Current Fable facts are volatile. Before giving pricing, availability, retention,
fallback, or platform-specific API advice, re-check official Anthropic docs. As of
2026-07-09, official docs describe Fable 5 as a high-autonomy model with always-on
adaptive thinking, `high` as the normal starting effort, higher price than Opus/Sonnet,
and a 30-day data-retention requirement that makes it unavailable under zero data
retention arrangements.

## Core rule

Use the cheapest model that can reliably meet the acceptance criteria.

- Use Sonnet for exploration, mechanical execution, long tool loops, and deterministic
  verification.
- Use Opus for taste-heavy craft, architecture/API review, subtle implementation, and
  senior judgment.
- Use Fable 5 for hard reasoning, long-horizon autonomy, pre-mortems, synthesis across
  conflicting evidence, and final arbitration.
- Use Codex, when the harness exposes it, as an independent senior engineering peer
  with a different model family and strong local tooling.

Upgrade only when a cheaper model misses a specific acceptance criterion, or when the
task is high-stakes enough that a weaker pass would be false economy. Spend Fable
tokens on judgment, not bulk context gathering.

## Reach for Fable

Prefer Fable 5 when the work has at least one of these properties:

- It spans many steps, files, systems, stakeholders, or days of work.
- The path is ambiguous and requires framing, architecture, taste, tradeoff judgment,
  or pre-mortem thinking.
- The user needs a strategy, design, research plan, migration plan, evaluation suite,
  or agent loop rather than a small answer.
- Verification matters and the agent can inspect evidence, run tools, test
  assumptions, and correct itself before declaring success.
- Persistent memory or durable working notes would materially improve the outcome.

Avoid Fable 5 for simple Q&A, formatting, mechanical edits, one-off summaries, routine
repository search, or work a cheaper model can do in one pass.

## Operate it well

Prefer goals over step-by-step micromanagement:

- Ask for the outcome, success criteria, constraints, audience, and approval gates.
- Ask why the output matters and what decision or workflow it will enable.
- Give Fable tools, files, tests, and evidence sources so it can measure progress.
- Let it propose the path, but require checkpoints for destructive, expensive,
  externally visible, or scope-changing actions.

Use compact instructions. Keep rules that protect safety, budget, data, style, scope,
or business judgment. Remove scaffolding that only forces the model to re-explain,
over-plan, over-structure, or expose hidden reasoning.

When there is enough information to act, act. Do not re-derive settled facts, reopen
decisions the user has already made, survey options you will not pursue, or end with a
promise to do work that can be done now.

Keep higher-effort runs scoped. Do not add features, broad refactors, defensive
backups, feature flags, compatibility shims, abstractions, or validation beyond the
task unless the evidence shows they are necessary. Validate at system boundaries such
as user input and external APIs; trust internal framework guarantees where appropriate.

When the user is asking a question, sharing a problem, or thinking out loud rather
than delegating a change, deliver an assessment and stop.

## Audit older prompts

Before migrating an existing prompt, skill, or workflow to Fable 5:

- Drop step-by-step scaffolding that only compensated for weaker models.
- Keep rules that protect safety, budget, data, style, scope, or business constraints.
- Remove "show your reasoning", "transcribe your thoughts", and similar instructions.
- Check timeouts, streaming, progress indicators, and async job handling; hard turns
  can run for many minutes, and autonomous runs can last hours or days.
- Re-baseline cost and token use on real workloads before promoting the migration.

## Work the unknowns

The prompt is the map. The codebase, design space, users, constraints, and deployment
surface are the territory. Fable's output is usually bottlenecked by how well the run
surfaces unknowns, not by raw model ability.

Sort uncertainty into four buckets:

- Known knowns: state them in the prompt.
- Known unknowns: ask, research, or prototype them.
- Unknown knowns: surface "know it when I see it" taste through brainstorms and
  throwaway prototypes.
- Unknown unknowns: request a blind spot pass.

For consequential or ambiguous work, read `references/phase-playbook.md` and choose
only the techniques that fit the task:

- Before: blind spot pass, brainstorm/prototype, interview, source-code references,
  and an implementation plan that leads with mutable decisions.
- During: keep a temporary `implementation-notes.md` deviation log in the fresh
  implementation session.
- After: produce a pitch/explainer artifact or a quiz before merging.

Prefer HTML artifacts for brainstorms, prototypes, plans, pitches, and quizzes when
the user needs to react to a shape rather than prose.

## Interview briefly

For consequential work, use the harness's user-question tool before planning when it
is available. Ask for intent, priorities, constraints, and judgment calls, not facts
you can inspect yourself.

High-leverage questions:

- What is the ambitious target state, not just the next task?
- Who will use the output, and what decision or workflow should it enable?
- Which constraints are real: deadline, budget, stack, policy, data, quality bar?
- What should Fable pause for: destructive changes, purchases, deploys, external
  messages, legal/security/privacy topics, or major scope changes?
- What would make the run a failure even if it produces a lot of work?
- Can this harness spawn subagents? If yes, design model routing explicitly.

If the question tool supports choices, make the recommended default first and mark it
`(Recommended)`. If no question tool is available, ask concise plain-language
questions and continue with reasonable assumptions when risk is low.

## Set effort and budgets

Use effort deliberately:

- `low`: routine classification, extraction, reliable bounded work, and cheap
  mechanical sweeps.
- `medium`: interactive exploration, quick design feedback, simple debugging, or
  cases where latency matters more than deep search.
- `high`: default for serious coding, architecture, planning, research synthesis,
  product strategy, and multi-step tool use.
- `xhigh` or the highest available effort: high-stakes decisions, large migrations,
  complex root-cause analysis, evaluation design, deep pre-mortems, and final
  arbitration.

Default Fable-led coding workflows to `high`, not maximum effort. Escalate only when
the decision is high-risk or `high` misses acceptance criteria. Drop to `medium` when
`high` solves the task but explores unused alternatives, adds unsolicited
improvements, or produces more detail than the user can act on.

Set explicit budgets where available: time, token, cost, tool calls, maximum files
touched, maximum attempts, and stop conditions. For narrow tasks, add a scope-control
instruction.

Effort is independent from model choice. A Sonnet-low mapping pass and an Opus-high
design review are different points on the same grid.

## Define boundaries

Use a short allow/deny boundary for long-running or sensitive work:

```text
Boundary:
- Allowed: [files, tools, systems, actions]
- Forbidden: [external messages, deploys, branch changes, destructive commands,
  purchases, secrets, unrelated directories]

Pause only for destructive or irreversible actions, real scope changes, or information
only the user can provide. Otherwise continue and report when done.
```

If the agent finds a useful action outside the boundary, propose it and wait.

## Design loops

For ambitious work, structure a loop:

1. Clarify the goal, constraints, and approval gates.
2. Build a plan with milestones, risks, dependencies, and verification.
3. Execute the next highest-leverage slice.
4. Verify with tools, tests, review, or evidence from source systems.
5. Record concise learnings and update the plan.
6. Continue until the done criteria, budget, or stop condition is reached.

Every loop needs a deterministic stop condition, maximum attempts, and a report shape
that includes remaining failures or the reason it stopped. Prefer numeric or
externally checkable completion criteria over "make it better" language.

Do not let the executing context grade important work alone. Add an independent
verifier when correctness, safety, cost, or external impact matters: a subagent,
cheaper model, test suite, linter, benchmark, query, screenshot check, stakeholder
checklist, or human gate.

Use `/goal`, `/loop`, `/schedule`, `/sprint`, custom commands, or dynamic workflows
only when the local harness actually provides them. Treat them as phase-control
primitives, not substitutes for acceptance criteria, budgets, and stop conditions.

## Ground progress

Long autonomous runs must tie status to evidence. Add this instruction when accuracy
of status matters:

```text
Before reporting progress, audit each claim against a tool result from this session.
Only report work you can point to evidence for. If something is not verified, label it
unverified. If tests failed or a step was skipped, say so plainly.
```

Do not count "I plan to run X" as progress. If the agent says it will run a tool and
the action is allowed, it should run the tool before ending the turn.

If the agent may stop early with a plan instead of action, add:

```text
Before ending your turn, check whether your last message is a plan, promise, question,
or list of next steps. If the original request allows the work and no user-only input
is required, do the work now with tools.
```

## Use memory carefully

For multi-session work, maintain short persistent memory such as `state.md`, and use
`learnings/` only when lessons need to persist across tasks. Keep memory as a living
snapshot, not a changelog.

Recommended shape:

```markdown
# Current State

One-sentence summary of the goal and current status.

## Decisions
- Durable decisions that should affect future work.

## Constraints
- Real constraints and approval gates.

## Learnings
- Things discovered through failed attempts, tests, user feedback, or measurement.

## Next
- The next highest-leverage action.
```

Replace stale content instead of appending a diary. Do not duplicate facts already in
the repo or chat. Update duplicate notes before creating more files, and delete notes
that later evidence proves wrong.

## Route models and control context

For any workflow, subagent tree, model allocation policy, or prompt for an agent that
can spawn subagents, read `references/claude-model-routing.md`. That reference contains
the detailed routing matrix, cost rules, cache/session economics, token hygiene
checklist, Codex readiness gates, and handoff prompts.

Keep this operating pattern in the main prompt:

- Ask Fable to frame the problem, decompose work, keep context lean, and make final
  judgment calls.
- Delegate raw discovery, file reading, log triage, browser/computer-use plumbing,
  scripted ops, and mechanical implementation to Sonnet when acceptance criteria are
  clear.
- Use Opus for architecture, subtle code quality, taste-heavy UI/prose/API work, and
  design review.
- Use Codex as an independent peer only when the current harness exposes it and setup
  confirms it is ready.
- Give workers compact design packets: goal, constraints, owned paths, invariants,
  acceptance criteria, verification commands, and approval gates.
- Require worker outputs to be concise: conclusion, evidence, files changed,
  verification result, blockers, and decisions needing escalation.

Never delegate bulk work to a Fable fork. Forks inherit expensive context, so the
intended cheap worker runs at orchestrator prices. Spawn a fresh-context Sonnet/Opus
worker instead.

For long-running workers, add:

```text
Never end your turn while work remains. Wait by blocking (sleep/poll loops inside a
tool call with a generous timeout), not by stopping to await notifications.
```

## Handle refusals

Treat Fable refusals and fallbacks as product behavior, not crashes.

- Handle `stop_reason: "refusal"` as a successful response that requires routing.
- Configure server-side, client-side, or manual fallback where available.
- Reformulate toward benign defensive, educational, or compliance work when
  appropriate.
- Do not try to bypass safeguards.
- Do not instruct Fable to reproduce, transcribe, or expose hidden reasoning.

## Communicate outcomes

Fable can over-explain after long runs. In final responses, lead with the outcome:
what happened, what was found, or what changed. Add only details that affect what the
reader should trust or do next.

Write for a user who did not watch the tool calls. Avoid dense shorthand, unexplained
labels, arrow chains, hidden-reasoning references, and invented taxonomy unless it
helps the user make a decision.

Pause for the user only when the work genuinely requires them: destructive or
irreversible actions, real scope changes, external commitments, or information only
they can provide.

If a harness surfaces remaining context budget to the model, do not make that number
part of the task framing. If it must be visible, explicitly say not to stop, summarize,
or hand off solely because of context limits.

## Prompt pattern

For substantial tasks, use `references/prompt-patterns.md`. It maps a Fable prompt to
context, request, output format, constraints, current state, success criteria,
delegation/model mix, approval gates, and a "your job" close that asks the model to
interview, do a blind spot pass, plan, pre-mortem, execute, and verify.

When advising a user, be explicit about the mode:

- "This is Fable-worthy" when the task benefits from long-horizon autonomy.
- "Use Fable only for the decision layer" when the task is mostly execution.
- "Use a cheaper model" when the task is small or repetitive.
- "Add a verifier" when correctness, safety, or external impact matters.
- "Set a budget and stop condition" when the run could sprawl.
