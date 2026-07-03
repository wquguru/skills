# Claude Model Routing

Use this reference when designing workflows, subagent trees, or model allocation
policies across Sonnet, Opus, Fable 5, and Codex where available.

## Contents

- Capability Profile
- Cost Model
- Token And Context Hygiene
- Loop Design
- Routing Rules
- Upgrade Rules
- Subagent Patterns
- Anti-Patterns

## Capability Profile

Scores are local defaults, not universal truth. Re-score them when pricing,
entitlements, latency, or observed model behavior changes.

Higher `Cost efficiency` means cheaper for the same accepted outcome.

| Model | Cost efficiency | Acceptance reliability | Taste | Throughput | Best short label |
| --- | ---: | ---: | ---: | ---: | --- |
| Sonnet | 8 | 6 | 7 | 9 | execution layer |
| Opus | 5 | 8 | 9 | 6 | tasteful senior |
| Fable 5 | 3 | 10 | 10 | 4 | hard-battle brain |
| Codex | varies | 9 | 8 | 7 | peer senior engineer |

Definitions:

- `Cost efficiency`: actual marginal cost in this deployment, after subscriptions,
  quotas, cache discounts, batch discounts, and rate limits.
- `Acceptance reliability`: chance the model can satisfy the task's quality bar
  without expensive retries or supervision.
- `Taste`: judgment quality for UI/UX, prose, API design, architecture shape, and
  code maintainability.
- `Throughput`: how suitable the model is for many tool calls, high-token context
  gathering, or routine execution.

## Cost Model

Official Anthropic API prices as of 2026-07-02:

| Model | Input | 5m cache write | 1h cache write | Cache hit | Output | Batch input | Batch output |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Claude Sonnet 5 through 2026-08-31 | $2/MTok | $2.50/MTok | $4/MTok | $0.20/MTok | $10/MTok | $1/MTok | $5/MTok |
| Claude Sonnet 5 from 2026-09-01 | $3/MTok | $3.75/MTok | $6/MTok | $0.30/MTok | $15/MTok | $1.50/MTok | $7.50/MTok |
| Claude Opus 4.8 | $5/MTok | $6.25/MTok | $10/MTok | $0.50/MTok | $25/MTok | $2.50/MTok | $12.50/MTok |
| Claude Fable 5 | $10/MTok | $12.50/MTok | $20/MTok | $1/MTok | $50/MTok | $5/MTok | $25/MTok |

Use this estimate before assigning an expensive agent:

```text
expected_cost =
  uncached_input_tokens * input_rate
  + cache_write_tokens * cache_write_rate
  + cache_hit_tokens * cache_hit_rate
  + output_tokens * output_rate
  + expected_retry_cost
  + expected_subagent_cost
```

Cost rules:

- Optimize for accepted outcome cost, not single-call price. A cheap model that loops
  three times can cost more than one stronger pass.
- Put stable prefixes in cacheable positions: system rules, repository instructions,
  tool schemas, API docs, and long standing context. Put volatile task details later.
- Use batch mode for offline, non-interactive review or research queues when latency
  is acceptable.
- Pilot before scaling. Dynamic workflows and broad subagent trees can multiply token
  use quickly; run one small slice, measure, then expand.
- Poll no faster than the external state changes. A five-minute loop watching an
  hourly signal wastes most of its runs.
- Use Fable only for the decision layer when the task is mostly execution. Let Sonnet
  gather files, logs, screenshots, and benchmark output, then hand Fable a compact
  evidence packet.
- Re-baseline after model or tokenizer changes. Fable 5 uses the newer tokenizer; for
  text migrated from pre-Opus-4.7 workflows, the same prompt can be materially larger.
- Track total loop cost: orchestrator tokens, worker tokens, verifier tokens, tool
  result tokens, failed attempts, and final synthesis all count.
- Review usage by skill, model, subagent, workflow, or MCP when the harness exposes
  such reporting. Stop or resize agents that consume budget without changing the
  accepted outcome.
- For Codex, do not convert subscription access into "free" work. It consumes usage
  limits or credits, and background/review gates can drain them quickly.

## Token And Context Hygiene

Use this checklist in any multi-agent or long-horizon workflow:

- Start with a short design packet: goal, constraints, owned paths, acceptance
  criteria, affected files, verification commands, and approval gates.
- Send workers the design packet plus exact artifacts, not the whole conversation.
- Have explorers return facts with paths, command outputs, contradictions, and
  unknowns. Avoid narrative transcripts.
- Have executors return files changed, verification run, result, blockers, and
  judgment calls needing review.
- Keep Fable's context to decisions, risks, evidence packets, and current state. Do
  not paste raw repository dumps into Fable unless the evidence itself is disputed.
- Use task budgets where the API or harness supports them. Set the budget around the
  whole agentic loop, including thinking, tool calls, tool results, and final output.
- Clear bulky old tool results or compact the conversation when they are no longer
  active evidence. Prompt caching reduces price, but cached tokens still occupy the
  context window.
- Do independent verification in a fresh context. The verifier should see the goal,
  acceptance criteria, diff or artifact, and evidence, not the executor's private
  self-justification.
- Prefer deterministic tools and scripts for repetitive transforms, counting,
  formatting, and extraction. Models should judge or adapt, not simulate grep.

## Loop Design

Choose the loop primitive by what the user is delegating:

| Loop type | User delegates | Use when | Guardrail |
| --- | --- | --- | --- |
| Turn-based | review and next decision | exploration or ambiguous decisions | make the review checklist explicit |
| Goal-based | stop condition | "done" is externally checkable | use numeric or deterministic criteria |
| Time-based | trigger cadence | external state changes over time | match polling interval to change frequency |
| Proactive workflow | whole repeated process | task is clear, recurring, and bounded | pilot, cap agents, and review usage |

Good `/goal` prompts define an evaluator, not a method:

```text
/goal Fix all failing integration tests, up to 8 iterations.
After each iteration, report the remaining failing test count and the concrete
failure reason for each unresolved test.
```

Avoid vague goals such as "improve performance" or "make the PR better" unless they
also include an observable threshold, maximum attempts, and what to report when the
threshold is not reached.

For scheduled or polling work:

- Use `/loop` only for local work that can stop with the machine session.
- Use `/schedule` only when the work must survive local downtime.
- Include the scope, cadence, stop condition, and pause conditions in the prompt.
- Do not ask every poll to do full analysis if only a status check is needed.

For dynamic workflows and many subagents:

- Start with a small representative batch and record cost, latency, and result quality.
- Cap fan-out, maximum attempts, and maximum active agents.
- Use a fresh-context verifier or judge agent for acceptance, not the executor's own
  self-review.
- Prefer async delegation when subtasks are independent; the orchestrator should not
  idle on the slowest worker unless that worker gates the decision.

## Routing Rules

Treat these as defaults, not ceilings:

- Use Sonnet for codebase exploration, bulk reading, grep-style investigation,
  browser/computer-use, log triage, deterministic transformations, and mechanical
  implementation from a clear spec.
- Use Opus for user-facing UI, copy, API design, architecture review, code quality
  review, and implementation where taste matters more than raw autonomy.
- Use Fable 5 for ambiguous architecture decisions, high-stakes reviews, deep
  pre-mortems, multi-day autonomous work, synthesis across conflicting evidence, and
  final arbitration. Start most coding workflows at high effort; reserve maximum
  effort for high-stakes arbitration, complex root-cause analysis, or evidence that
  high effort missed the acceptance criteria.
- Use Codex as an independent senior engineering peer with a different model family
  and local tooling when the current harness exposes it. In Claude Code, that means
  the `codex@openai-codex` plugin is installed and `/codex:setup` confirms Codex is
  ready. A standalone Codex CLI is useful for direct Codex work, but it does not by
  itself make Claude Code delegation available.
- Do not burn Opus or Fable 5 on raw discovery. First ask Sonnet to gather and
  compress evidence, then pass the distilled packet upward.
- Route to the cheapest model expected to pass the acceptance criteria. For
  deliverables, quality is a gate and cost is the optimizer after the gate is met.
- Do not default to Haiku for Fable 5 workflows unless the user explicitly requests a
  small-model baseline or the task is extremely bounded.
- Upgrade a worker from Sonnet to Opus when Sonnet retries are consuming more budget
  than a stronger implementation pass, or when subtle code quality matters.
- Upgrade to Fable only for the part that requires it. It can decide the plan,
  arbitrate a conflict, or run a pre-mortem, then delegate execution back down.

## Upgrade Rules

Use automatic escalation when the user has given a standing budget or autonomy grant:

- Sonnet -> Opus: execution is mostly correct, but taste, API shape, wording,
  maintainability, or review judgment is not good enough.
- Opus -> Fable 5: the task needs deeper decomposition, long-horizon autonomy,
  high-stakes reasoning, adversarial review, or final arbitration.
- Sonnet -> Fable 5: skip Opus when the failure is not taste but core reasoning,
  ambiguous planning, or inability to hold the whole system in view.
- Claude-only -> Codex: use Codex when a coding decision would benefit from an
  independent model family, local Codex tooling, or a fresh rescue attempt.

When upgrading, record:

- what model attempted the task
- what acceptance criterion was missed
- what evidence shows the miss
- what the stronger model should decide or redo
- the maximum extra budget or attempts allowed for the stronger pass

Downgrade after the hard decision is made:

- Fable -> Opus for taste-sensitive implementation or review.
- Fable -> Sonnet for mechanical edits, test generation, formatting, or broad
  exploration from a clear spec.
- Opus -> Sonnet when the remaining work is deterministic and verification is clear.

## Subagent Patterns

### Sonnet Explorer

```text
Use Sonnet for this subtask.

Goal:
Gather evidence for [question].

Scope:
Read only [paths/systems]. Do not modify files or make external changes.

Output:
- Key facts with file paths, commands, or source references.
- Unknowns and conflicts.
- Token-light evidence packet suitable for Opus, Codex, or Fable review.
- Recommended next model, if this looks harder than expected.
```

### Sonnet Executor

```text
Use Sonnet for this subtask. Use Opus instead if the orchestrator says the worker
needs stronger implementation judgment or if Sonnet has already failed the same
acceptance criterion.

Goal:
Implement [clear spec] within [owned paths].

Constraints:
Follow existing patterns. Avoid broad refactors. Stop if the spec is ambiguous or
requires architecture judgment.

Output:
- Files changed.
- Verification run and result.
- Any judgment calls that should be reviewed by Opus or Fable 5.
- Estimated follow-up cost risk: low / medium / high.
- Keep this concise. Do not include full hidden reasoning transcripts.
```

### Opus Reviewer

```text
Use Opus for this subtask.

Goal:
Review [artifact/change/design] for taste, maintainability, API shape, user impact,
and code quality.

Input:
Use the distilled evidence packet and relevant changed files. Do not redo raw
exploration unless evidence is missing.

Output:
- Findings ordered by severity.
- Concrete improvements.
- Whether Fable 5 arbitration is needed and why.
- Keep this concise. Include evidence and conclusions, not full reasoning transcript.
```

### Fable Arbitrator

```text
Use Fable 5 for this subtask.

Goal:
Make the final call on [ambiguous/high-stakes decision].

Input:
Review the goal, constraints, evidence packet, Sonnet findings, Opus review, and
acceptance criteria.

Output:
- Decision.
- Rationale grounded in evidence.
- Risks and rollback/verification plan.
- Work that can be delegated back to Sonnet or Opus.
```

### Codex Peer Engineer

```text
Use Codex for this subtask.

Availability gate:
Codex means the Claude Code plugin `codex@openai-codex`, not merely the standalone
Codex CLI. Check plugin/slash-command availability first; CLI presence is not a
prerequisite for detecting whether the plugin is installed. If the plugin exists,
use `/codex:setup` to check local Codex CLI/auth/runtime readiness. If the plugin is
missing or setup says Codex is not ready, do not continue as if this peer exists and
do not install it silently.

Setup question:
When the independent peer perspective is material and the plugin is missing, ask
whether to install or set it up. Include the proposed Claude Code commands when known:

/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup

Mention that `/codex:setup` may offer to install Codex or require local auth. If
installation is declined or out of scope, report the fallback and use Opus plus a
fresh-context verifier.

Goal:
Provide an independent senior-engineering pass on [problem/design/change].

Input:
Use the same goal, constraints, acceptance criteria, and distilled evidence packet
given to Opus. Do not read Opus's answer or Claude's private deliberation.

Output:
- Recommended path or concrete patch plan.
- Risks, missing evidence, and verification steps.
- Where your conclusion agrees or conflicts with the supplied evidence.
```

Claude Code Codex command choices:

- `/codex:review --background`: read-only review of current changes or branch.
- `/codex:adversarial-review --background [focus]`: challenge design assumptions,
  failure modes, and risk areas.
- `/codex:rescue --background [task]`: delegate investigation or a concrete fix.
- `/codex:status`, `/codex:result`, `/codex:cancel`: manage background jobs.
- Avoid enabling automatic review gates by default; they can create long-running
  Claude/Codex loops and drain usage limits.

### Fable Orchestrator With Opus, Sonnet, And Codex

```text
Use Fable 5 at high effort as lead orchestrator. Use the highest available reasoning
effort only for high-stakes arbitration or complex root-cause analysis.

Before delegation:
Write a compact design packet with goal, constraints, architecture or patch plan,
invariants, affected files, acceptance criteria, and verification commands.

Delegation:
- deep-reasoner (Opus): reasoning-heavy phases, architecture, complex debugging,
  algorithm design, and tradeoff analysis.
- fast-worker (Sonnet by default, Opus when quality/retry economics justify it):
  mechanical implementation, tests, formatting, simple edits, repository exploration,
  and evidence gathering.
- Codex: independent peer senior engineer for fresh perspective, rescue passes, and
  high-stakes parallel reasoning.

Rule:
For high-stakes decisions, run Opus and Codex in parallel on the same problem without
sharing either answer with the other. Fable 5 synthesizes the outputs, decides, then
delegates execution to the cheapest agent that can meet the acceptance criteria.
If the Codex plugin is missing or `/codex:setup` says local Codex is not ready, ask
before installing/authenticating it; otherwise fall back to Opus plus a fresh-context
verifier and label the run Claude-only.
```

Useful `CLAUDE.md` snippet:

```markdown
## Orchestration workflow

You are the Fable 5 orchestrator. Plan, decompose, delegate, synthesize, and decide.

- Reasoning-heavy phases: delegate to `deep-reasoner` (Opus).
- Mechanical work: delegate to `fast-worker` (Sonnet).
- Fresh perspective or rescue: ask Codex through the installed Codex plugin when
  `/codex:setup` confirms readiness.
- If Codex is unavailable, ask before installing or authenticating it. If setup is
  declined or out of scope, use Opus plus a fresh-context verifier and label the run
  Claude-only.
- High-stakes decisions: task Opus and Codex on the same problem in parallel without
  revealing either answer to the other, then synthesize the evidence-backed path.
- Keep Fable context lean. Delegate raw exploration and execution; keep only compact
  evidence packets, decisions, risks, and verification state in the lead context.
- Subagents return concise conclusions and evidence, not full reasoning transcripts.
- For larger changes, write a compact design packet first, then delegate execution.
```

Prompt Fable like a tech lead:

```text
Goal: [what you want]
Context: [files, constraints, acceptance criteria, approval gates]
Budget: [token/cost/time/tool-call limits and stop condition]

You are the lead. Delegate reasoning-heavy work to Opus, mechanical work to Sonnet,
and fresh-perspective or rescue work to Codex if the harness has it ready. Start with
a compact design packet, then execute within the allowed boundaries. Keep Fable's
context lean: workers return concise conclusions, evidence, changed files,
verification results, and blockers only. Verify before reporting success.
```

## Anti-Patterns

- Starting Fable 5 before the problem is framed or evidence is gathered.
- Asking Opus or Fable 5 to read huge code areas that Sonnet could summarize first.
- Asking subagents to return full reasoning transcripts instead of compact
  conclusions, evidence, and blockers.
- Letting Sonnet make final architecture calls just because it already did the
  implementation.
- Treating Codex as a rubber-stamp reviewer instead of an independent peer with a
  separately formed view.
- Running every Fable workflow at maximum effort by default instead of starting at
  high and escalating only when the risk or evidence warrants it.
- Using this multi-agent pattern for simple CRUD or one-pass edits where orchestration
  overhead costs more than it saves.
- Treating the routing table as a budget cap. It is a default map, not a ceiling.
- Upgrading silently without recording what failed and what the stronger model must
  improve.
