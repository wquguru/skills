---
name: fable5-best-practice
description: Guides agents in scoping, prompting, budgeting, supervising, and validating Claude Fable 5 work for long-horizon reasoning, design, coding, research, and agentic workflows.
---

# fable5-best-practice

Claude Fable 5 is best treated as a long-horizon thinking and design partner, not a
faster chat model. Use it where judgment, decomposition, verification, and sustained
tool use matter enough to justify premium cost and latency.

As of 2026-07-01, official Anthropic guidance describes Fable 5 as a generally
available Mythos-class model for demanding reasoning and long-horizon agentic work,
with adaptive thinking always on, effort control, task budgets, memory, code
execution, programmatic tool calling, context editing, compaction, vision, and
conservative safeguards that can refuse or fall back to Opus 4.8. Re-check official
docs before giving current pricing, availability, retention, or platform-specific API
advice.

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

Use Fable 5 for the scarce judgments:

- problem framing and question selection
- architecture and data model decisions
- critical abstractions and migration strategy
- evaluation design and acceptance criteria
- pre-mortems, risk analysis, and review of final work

Delegate routine execution to cheaper or faster models when available:

- bulk implementation after Fable 5 has chosen the design
- context compression and note cleanup
- straightforward tests, formatting, documentation drafts, and repetitive edits
- independent verifier passes

When delegating, pass the goal, constraints, plan, acceptance criteria, and exact
handoff artifacts. Do not pass a vague "continue this" instruction.

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

## Prompt pattern

Use this shape for substantial tasks:

```text
Context:
I am working on [larger goal] for [audience/users]. This matters because [why].

Target outcome:
[Describe the ambitious finished state.]

Current state:
[Facts, links, repo paths, data sources, constraints, prior attempts.]

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

The best Fable 5 use changes the user's role from operator to system designer:
define the goal, constraints, tools, memory, verification, and gates, then let the
model do sustained work inside that system.
