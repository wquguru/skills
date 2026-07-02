---
name: fable5-best-practice
description: Guides agents in scoping, prompting, budgeting, supervising, validating, and routing Claude Fable 5 work across Fable, Opus, and Sonnet for long-horizon reasoning, design, coding, research, and agentic workflows.
---

# fable5-best-practice

Claude Fable 5 is best treated as a long-horizon thinking and design partner, not a
faster chat model. Use it where judgment, decomposition, verification, and sustained
tool use matter enough to justify premium cost and latency.

As of 2026-07-02, official Anthropic guidance describes Fable 5 as a generally
available Mythos-class model for demanding reasoning and long-horizon agentic work,
with adaptive thinking always on, effort control, task budgets, memory, code
execution, programmatic tool calling, context editing, compaction, vision, and
conservative safeguards that can refuse or fall back to Opus 4.8. It requires
30-day data retention and is not available under zero data retention arrangements.
Re-check official docs before giving current pricing, availability, retention, or
platform-specific API advice.

## When to use Fable 5

Reach for Fable 5 when the work has at least one of these properties:

- It spans many steps, files, systems, stakeholders, or days of work.
- The path is ambiguous and requires framing, architecture, taste, tradeoff judgment,
  or pre-mortem thinking.
- The user needs a strategy, design, research plan, migration plan, evaluation suite,
  or agent loop rather than a small answer.
- Verification matters: the agent can inspect evidence, run tools, test assumptions,
  and correct itself before declaring success.
- The model will benefit from persistent memory or a durable working notes file.

Avoid Fable 5 for cheap, frequent, low-value tasks: simple Q&A, mechanical edits,
formatting, one-off summaries, or work that a lower-cost model can do in one pass.

## Operating posture

Prefer goals over step-by-step micromanagement:

- Ask for the outcome, success criteria, constraints, and audience.
- Ask what "done" looks like and how success should be verified.
- Ask which actions require user approval before proceeding.
- Give Fable 5 tools, files, tests, and evidence sources so it can measure progress.
- Let it propose the path, but require checkpoints for irreversible, expensive,
  scope-changing, or externally visible actions.

Use compact instructions. Old prompts written to compensate for weaker models can
over-constrain Fable 5. Remove brittle scaffolding, excessive persona text, and
unneeded micro-rules unless they protect safety, budget, data, or business judgment.

When the user is asking a question, sharing a problem, or thinking out loud rather
than requesting a change, deliver an assessment and stop. Do not apply fixes until
asked. Fable 5's proactive behavior is useful only inside a clearly delegated task.

## Audit prompts before migrating

Before moving an existing workflow or skill to Fable 5, remove instructions that fight
the model's new defaults:

- Drop step-by-step scaffolding that only existed to compensate for weaker models.
- Keep rules that protect safety, budget, data, style, or business constraints.
- Remove "show your reasoning", "transcribe your thoughts", or similar instructions;
  they can trigger the `reasoning_extraction` refusal category.
- Check client timeouts, streaming, progress indicators, and async job handling because
  hard turns can run for many minutes and autonomous runs can last hours or days.
- Re-baseline cost and token use on real workloads before promoting the migration.

## Start by interviewing the user

For consequential work, use `AskUserQuestion` before planning. Do not ask for facts
you can inspect yourself; ask for intent, priorities, constraints, and judgment calls.
Keep the interview short and high-leverage.

Ask questions like:

- What is the ambitious target state, not just the next task?
- Who will use the output, and what decision or workflow should it enable?
- What constraints are real: deadline, budget, stack, policy, data, quality bar?
- What should Fable 5 pause for: destructive changes, purchases, deploys, external
  messages, legal/security/privacy topics, or major scope changes?
- What would make the run a failure even if it produces a lot of work?

If `AskUserQuestion` supports choices, make the recommended default first and mark it
`(Recommended)`. If the tool is unavailable, ask concise plain-language questions and
continue with reasonable assumptions when the risk is low.

## Match effort to the task

Use effort deliberately:

- `low`: routine classification, extraction, and other cheap bounded work.
- `medium`: interactive exploration, quick design feedback, simple debugging, or
  when latency and cost matter more than deep search.
- `high`: default for serious coding, architecture, planning, research synthesis,
  product strategy, and multi-step tool use.
- `xhigh` or the highest available effort: high-stakes decisions, large migrations,
  complex root-cause analysis, evaluation design, deep pre-mortems, and runs where
  self-verification is worth the cost.

For long runs, set explicit task budgets where available: time, token, cost, tool-call
limits, maximum files touched, maximum attempts, and stop conditions. A strong Fable 5
prompt says both what to achieve and when to stop.

At high effort, add a short scope-control instruction when the task is narrow: do not
add features, broad refactors, abstractions, compatibility shims, or speculative error
handling beyond what the task requires.

## State boundaries and checkpoints

Use an allow/deny boundary for long-running or sensitive work:

```text
Boundary:
- Allowed: [files, tools, systems, actions]
- Forbidden: [external messages, deploys, branch changes, destructive commands,
  purchases, secrets, unrelated directories]

Pause only for destructive or irreversible actions, real scope changes, or information
only the user can provide. Otherwise continue and report when done.
```

If the agent finds a useful action outside the boundary, it should propose it and wait
instead of doing it. Keep the boundary short enough to survive compaction.

## Design loops, not one-shot chats

For ambitious work, structure a loop:

1. Clarify the goal, constraints, and approval gates.
2. Build a plan with milestones, risks, dependencies, and verification.
3. Execute the next highest-leverage slice.
4. Verify with tools, tests, review, or evidence from source systems.
5. Record concise learnings and update the plan.
6. Continue until the done criteria, budget, or stop condition is reached.

Do not let the model grade its own important work in isolation. Use an independent
verifier when possible: a subagent, a cheaper model, test suite, linter, benchmark,
query, screenshot check, stakeholder checklist, or human review gate.

For Claude Code-style autonomy, match the loop primitive to the work:

- Use `/goal` when "done" can be evaluated, such as tests passing, no failing CI jobs,
  a Lighthouse score threshold, or all review comments addressed.
- Use `/loop` for local recurring checks whose cadence is shorter-lived than the
  machine session, such as polling a PR every few minutes.
- Use `/schedule` for cloud-side recurring work that must survive local downtime.
- Use dynamic workflows or subagents only after a small pilot estimates cost and
  verifies the coordination pattern.

Every loop needs a deterministic stop condition, maximum attempts, and a reporting
shape that includes remaining failures or the reason it stopped.

## Ground progress claims

Long autonomous runs must tie progress reports to evidence. Add this instruction when
accuracy of status matters:

```text
Before reporting progress, audit each claim against a tool result from this session.
Only report work you can point to evidence for. If something is not verified, label it
unverified. If tests failed or a step was skipped, say so plainly.
```

Do not treat "I plan to run X" as progress. If the agent says it will run a tool and
the action is allowed, it should run the tool before ending the turn.

## Use memory carefully

For multi-session work, ask Fable 5 to maintain a short persistent memory file such
as `learnings.md` or `state.md`. Keep it as a living snapshot, not a changelog.

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

Each loop should update this file by replacing stale content, not appending a diary.
If the memory grows beyond what a human would reread, compact it.

## Model mix and delegation

Treat cost as deployment-specific. Official API sticker prices, batch discounts,
prompt caching, user subscriptions, plan entitlements, and internal quotas can produce
very different marginal costs. Maintain a local routing table with three scores:
intelligence, taste, and effective marginal cost. For deliverables, prioritize
intelligence and taste before cost; use cost mainly as a tie-breaker once quality is
good enough.

Quick Claude routing:

| Model | Default role | Avoid using for |
| --- | --- | --- |
| Sonnet | Fast execution, exploration, long tool loops, browser/computer-use, mechanical implementation | Final arbitration, high-taste deliverables, ambiguous architecture calls |
| Opus | Taste-heavy craft, UI/prose/API design, code quality review, experienced implementation | Bulk token burn, simple searches, routine plumbing |
| Fable 5 | Hard battles: deepest reasoning, long-horizon autonomy, pre-mortems, high-stakes review, final arbitration | Cheap frequent tasks, raw codebase exploration, repetitive execution |

These are defaults, not ceilings. Upgrade Sonnet to Opus when execution is adequate
but taste, judgment, or review quality is lacking. Upgrade Opus to Fable 5 when the
problem requires deeper autonomy, sustained decomposition, or final arbitration across
conflicting evidence. When the user has granted a standing budget, upgrade without
asking and record why the weaker model missed the acceptance criteria.

Avoid Fable 5 and Opus for high-token, low-difficulty work even when the local
marginal cost is low. Use Sonnet or scripts for repository exploration, grep-style
investigation, bulk file reading, browser/computer-use plumbing, log triage, and
deterministic transforms. Hand distilled evidence to Opus or Fable 5 for judgment.

When designing a workflow, subagent tree, or model allocation policy, read
`references/claude-model-routing.md` for the detailed routing matrix and handoff
prompts.

When delegating, pass the goal, constraints, plan, acceptance criteria, and exact
handoff artifacts. Do not pass a vague "continue this" instruction.

Prefer async delegation: dispatch independent subtasks, keep the orchestrator moving,
and intervene only when a subagent lacks context or is drifting. Use fresh-context
verifier agents for acceptance checks rather than asking the executing context to
critique itself.

## Safeguards, refusals, and fallback

Fable 5 may decline or fall back for sensitive domains such as offensive
cybersecurity, exploit construction, malware, certain biology/chemistry requests, or
attempts to extract hidden reasoning. Treat refusals as a product behavior, not a
crash.

For integrations:

- Handle `stop_reason: "refusal"` as a successful response that requires routing.
- Configure server-side, client-side, or manual fallback where available.
- Tell the user when a request may be better handled by a safer lower-capability
  model or by narrowing the request to benign defensive, educational, or compliance
  work.
- Do not try to bypass Fable 5 safeguards. Reformulate toward the legitimate goal or
  stop.

If a harness surfaces remaining context budget to the model, avoid making the number
part of the task framing. If it must be visible, explicitly say not to stop, summarize,
or hand off solely because of context limits.

For long asynchronous products, consider a `send_to_user`-style tool that displays a
message verbatim without ending the agent turn. Use it only for partial deliverables,
specific progress updates, or user-facing text that must not be summarized.

## Prompt pattern

Use this shape for substantial tasks. It maps to four essentials: context, request,
output format, and constraints.

```text
Context:
I am working on [larger goal] for [audience/users]. This matters because [why].

Request:
[One sentence describing the concrete thing needed.]

Current state:
[Facts, links, repo paths, data sources, constraints, prior attempts.]

Output format:
[Deliverable shape, length, style, language, and audience.]

Success criteria:
- [Observable result]
- [Verification method]
- [Quality bar]

Approval gates:
Pause before [destructive / expensive / external / scope-changing actions].

Your job:
Interview me if key intent is missing. Then propose a plan, pre-mortem the likely
failure modes, identify the first highest-leverage slice, execute where allowed, and
verify before reporting success.
```

For strategy work, add:

```text
Before planning, assume this fails 12-24 months from now. What were the most likely
causes, what early signals would reveal them, and how should we design around them?
```

## Final guidance to users

When advising a user, be explicit about the working mode:

- "This is Fable-worthy" when the task benefits from long-horizon autonomy.
- "Use Fable only for the decision layer" when the task is mostly execution.
- "Use a cheaper model" when the task is small or repetitive.
- "Add a verifier" when correctness, safety, or external impact matters.
- "Set a budget and stop condition" when the run could sprawl.

For final reports after long unattended work, write for a reader who did not see the
tool calls. Lead with the outcome, then the one or two decisions or actions they need
to know. Avoid arrow-chain shorthand, invented labels, hidden-reasoning references, and
dense compound jargon.

The best Fable 5 use changes the user's role from operator to system designer:
define the goal, constraints, tools, memory, verification, and gates, then let the
model do sustained work inside that system.
