---
name: fable5-best-practice
description: Guides agents in scoping, surfacing unknowns, prompting, budgeting, supervising, validating, and routing Claude Fable 5 work across Fable, Opus, Sonnet, and Codex for long-horizon reasoning, design, coding, research, and agentic workflows.
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

Cost snapshot as of 2026-07-02:

| Model | Base input | Output | Best use |
| --- | ---: | ---: | --- |
| Sonnet 5 | $2/MTok through 2026-08-31, then $3/MTok | $10/MTok through 2026-08-31, then $15/MTok | exploration and execution |
| Opus 4.8 | $5/MTok | $25/MTok | taste-heavy review and senior implementation |
| Fable 5 | $10/MTok | $50/MTok | decision layer, hard reasoning, arbitration |

Use the cheapest model that can reliably meet the acceptance criteria. Upgrade only
when cheaper execution misses a specific criterion, or when the task is already
high-stakes enough that a weaker pass would be false economy.

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
- Ask why the output matters and what decision or workflow it will enable.
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

## The map is not the territory: work your unknowns

The map is what you give the model: the prompt, skills, and context. The territory is
where the work actually happens: the codebase, the design space, the real constraints.
The gap between them is unknowns, and with Fable 5 the quality of the work is usually
bottlenecked by how well those unknowns get surfaced, not by the model's raw ability.
More work attempted in one run means more unknowns it can hit.

Sort what you know into four buckets and pick the technique that fills the empty ones:

- Known knowns: what you can already state. Put these in the prompt.
- Known unknowns: gaps you are aware of. Ask, research, or prototype them.
- Unknown knowns: "know it when I see it" criteria you would never write down. Surface
  them by reacting to brainstorms and prototypes.
- Unknown unknowns: what you have not considered at all. Surface them with a blind spot
  pass.

Discovering unknowns is iterative and happens before, during, and after implementation.
Every brainstorm, interview, prototype, reference, and explainer is a cheap way to learn
what you did not know before it gets expensive to fix in code. Give the model your
starting point — what you already know, your experience with this problem and codebase,
and where you are in your thinking — so it targets the real gaps instead of guessing.

When a task has meaningful unknowns, read `references/phase-playbook.md` for the
phase-by-phase techniques and example prompts:

- Before: blind spot pass (unknown unknowns), brainstorm and prototype with throwaway
  HTML (unknown knowns), interview, source-code references, and an implementation plan
  that leads with the decisions most likely to change.
- During: a temporary `implementation-notes.md` deviation log kept in a fresh
  implementation session.
- After: a pitch or explainer artifact for buy-in, and a quiz you must pass before merging.

Prefer HTML artifacts for brainstorms, prototypes, plans, pitches, and quizzes; they are
usually the best medium for reacting to and sharing this kind of work.

## Start by interviewing the user

For consequential work, use the harness's user-question tool before planning when it
is available. Do not ask for facts you can inspect yourself; ask for intent,
priorities, constraints, and judgment calls. Keep the interview short and
high-leverage.

Ask questions like:

- What is the ambitious target state, not just the next task?
- Who will use the output, and what decision or workflow should it enable?
- What constraints are real: deadline, budget, stack, policy, data, quality bar?
- What should Fable 5 pause for: destructive changes, purchases, deploys, external
  messages, legal/security/privacy topics, or major scope changes?
- What would make the run a failure even if it produces a lot of work?
- Where will this run, and can that harness spawn subagents? (Determines whether
  the prompt needs a delegation/model-routing section — see "Model mix and
  delegation".)

If the question tool supports choices, make the recommended default first and mark it
`(Recommended)`. If no question tool is available, ask concise plain-language
questions and continue with reasonable assumptions when the risk is low.

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

Default new Fable-led coding workflows to `high`, not the maximum effort, unless the
decision is high-risk or prior runs show `high` is missing the acceptance criteria.
Escalate to the maximum effort for final arbitration, pre-mortems, or root-cause
analysis; de-escalate after the decision layer is settled and delegate execution.
Drop to `medium` when `high` solves the task but spends too long exploring unused
alternatives, adds unsolicited improvements, or produces more detail than the user can
act on.

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
shape that includes remaining failures or the reason it stopped. Prefer numeric or
externally checkable completion criteria over "make it better" language; loose goals
invite early success claims or expensive empty iteration.

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
as `learnings.md` or `state.md`. Keep it as a living snapshot, not a changelog. For
repository loops with recurring lessons, a `notes/` directory with one durable lesson
per file can work better than a single growing document.

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
If the memory grows beyond what a human would reread, compact it. Do not duplicate
facts already in the repo or chat. Update existing notes before creating near-duplicates,
and delete notes that later evidence proves wrong.

## Model mix and delegation

Treat cost as deployment-specific. Official API sticker prices, batch discounts,
prompt caching, user subscriptions, plan entitlements, and internal quotas can produce
very different marginal costs. Maintain a local routing table with four scores:
acceptance reliability, taste, throughput, and effective marginal cost. For most work,
choose the lowest-cost model that is expected to pass the acceptance criteria without
churn; spend Fable tokens on judgment, not bulk context gathering.

Quick routing:

| Model | Default role | Avoid using for |
| --- | --- | --- |
| Sonnet | Fast execution, exploration, long tool loops, browser/computer-use, mechanical implementation | Final arbitration, high-taste deliverables, ambiguous architecture calls |
| Opus | Taste-heavy craft, UI/prose/API design, code quality review, experienced implementation | Bulk token burn, simple searches, routine plumbing |
| Fable 5 | Hard battles: deepest reasoning, long-horizon autonomy, pre-mortems, high-stakes review, final arbitration | Cheap frequent tasks, raw codebase exploration, repetitive execution |
| Codex | Peer senior engineer with a different model family, strong coding judgment, local tooling, and independent perspective | Blindly approving Claude's plan, replacing the orchestrator, routine work better handled by Sonnet |

These are defaults, not ceilings. Upgrade Sonnet to Opus when execution is adequate
but taste, judgment, or review quality is lacking. Upgrade Opus to Fable 5 when the
problem requires deeper autonomy, sustained decomposition, or final arbitration across
conflicting evidence. When the user has granted a standing budget, upgrade without
asking and record why the weaker model missed the acceptance criteria.

Avoid Fable 5 and Opus for high-token, low-difficulty work even when the local
marginal cost is low. Use Sonnet or scripts for repository exploration, grep-style
investigation, bulk file reading, browser/computer-use plumbing, log triage, and
deterministic transforms. Hand distilled evidence to Opus or Fable 5 for judgment.

When designing a workflow, subagent tree, model allocation policy, or a prompt
for any agent that can spawn subagents, read `references/claude-model-routing.md`
for the detailed routing matrix, cost rules, token hygiene checklist, Codex readiness
gates, and handoff prompts. Writing a prompt for an orchestrator is designing a
subagent tree; do not skip the reference because the task looks like "just prompt
writing".

### Fable-led orchestration with Codex peer

Use this pattern when Fable 5 usage is expensive but its judgment is still needed:

- Fable 5, usually at `high` effort and only at maximum effort for high-stakes
  arbitration, is the lead orchestrator. It frames the problem, decomposes work,
  assigns agents, keeps context lean, and synthesizes final decisions.
- `deep-reasoner`, pinned to Opus, handles reasoning-heavy phases: architecture,
  complex debugging, algorithm design, tradeoff analysis, and second-order risks.
- `fast-worker`, usually pinned to Sonnet, handles mechanical work: codebase
  exploration, boilerplate, tests, formatting, simple edits, and deterministic
  execution from a clear spec. Pin it to Opus instead when Sonnet churns, makes
  subtle implementation mistakes, or the local token economics make Opus-worker
  cheaper than repeated Sonnet retries.
- Codex, when available through the current harness, supplies an independent model
  family and local engineering perspective. In Claude Code, that means the
  `codex@openai-codex` plugin and a successful `/codex:setup`, not merely a
  standalone Codex CLI on disk.

For substantial implementation, have Fable produce a compact design packet before
delegation: goal, architecture or patch plan, invariants, affected files, acceptance
criteria, and verification commands. Give workers the design packet, not the whole
conversation.

Require subagents to return compact outputs only: conclusion, evidence, files changed,
verification result, blockers, and decisions that need escalation. Do not ask them to
transcribe full hidden reasoning. If a critique round is useful, run it as a bounded
second pass over artifacts and summarized conclusions.

For high-stakes decisions, ask Opus and Codex to work the same problem in parallel
without showing either one the other's answer. Give both the same goal, constraints,
evidence packet, and acceptance criteria. Fable 5 then compares the independent
outputs, resolves conflicts against evidence, and decides what to execute.

Use `/goal`, `/loop`, `/schedule`, `/sprint`, or custom commands only when the local
harness actually provides them. Treat them as phase-control primitives, not as a
replacement for explicit acceptance criteria, budgets, and stop conditions.

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

For substantial tasks, use the fill-in prompt template in
`references/prompt-patterns.md`. It maps to four essentials — context, request, output
format, and constraints — and includes slots for current state, success criteria,
delegation and model mix, approval gates, and a "your job" close that asks the model to
interview, do a blind spot pass, plan, pre-mortem, execute, and verify. The reference
also carries a pre-mortem add-on for strategy work.

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
