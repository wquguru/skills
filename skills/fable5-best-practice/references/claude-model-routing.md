# Claude Model Routing

Use this reference when designing workflows, subagent trees, or model allocation
policies across Sonnet, Opus, and Fable 5.

## Capability Profile

Scores are local defaults, not universal truth. Re-score them when pricing,
entitlements, latency, or observed model behavior changes.

| Model | Effective cost | Intelligence | Taste | Throughput | Best short label |
| --- | ---: | ---: | ---: | ---: | --- |
| Sonnet | 8 | 6 | 7 | 9 | execution layer |
| Opus | 5 | 8 | 9 | 6 | tasteful senior |
| Fable 5 | 3 | 10 | 10 | 4 | hard-battle brain |

Definitions:

- `Effective cost`: actual marginal cost in this deployment, after subscriptions,
  quotas, cache discounts, batch discounts, and rate limits.
- `Intelligence`: difficulty of work that can be delegated with little supervision.
- `Taste`: judgment quality for UI/UX, prose, API design, architecture shape, and
  code maintainability.
- `Throughput`: how suitable the model is for many tool calls, high-token context
  gathering, or routine execution.

## Routing Rules

Treat these as defaults, not ceilings:

- Use Sonnet for codebase exploration, bulk reading, grep-style investigation,
  browser/computer-use, log triage, deterministic transformations, and mechanical
  implementation from a clear spec.
- Use Opus for user-facing UI, copy, API design, architecture review, code quality
  review, and implementation where taste matters more than raw autonomy.
- Use Fable 5 for ambiguous architecture decisions, high-stakes reviews, deep
  pre-mortems, multi-day autonomous work, synthesis across conflicting evidence, and
  final arbitration.
- Do not burn Opus or Fable 5 on raw discovery. First ask Sonnet to gather and
  compress evidence, then pass the distilled packet upward.
- Cost breaks ties only after quality is good enough. For deliverables, optimize for
  `intelligence > taste > cost`.
- Do not default to Haiku for Fable 5 workflows unless the user explicitly requests a
  small-model baseline or the task is extremely bounded.

## Upgrade Rules

Use automatic escalation when the user has given a standing budget or autonomy grant:

- Sonnet -> Opus: execution is mostly correct, but taste, API shape, wording,
  maintainability, or review judgment is not good enough.
- Opus -> Fable 5: the task needs deeper decomposition, long-horizon autonomy,
  high-stakes reasoning, adversarial review, or final arbitration.
- Sonnet -> Fable 5: skip Opus when the failure is not taste but core reasoning,
  ambiguous planning, or inability to hold the whole system in view.

When upgrading, record:

- what model attempted the task
- what acceptance criterion was missed
- what evidence shows the miss
- what the stronger model should decide or redo

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
- A compact evidence packet suitable for Opus or Fable 5 review.
```

### Sonnet Executor

```text
Use Sonnet for this subtask.

Goal:
Implement [clear spec] within [owned paths].

Constraints:
Follow existing patterns. Avoid broad refactors. Stop if the spec is ambiguous or
requires architecture judgment.

Output:
- Files changed.
- Verification run and result.
- Any judgment calls that should be reviewed by Opus or Fable 5.
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

## Anti-Patterns

- Starting Fable 5 before the problem is framed or evidence is gathered.
- Asking Opus or Fable 5 to read huge code areas that Sonnet could summarize first.
- Letting Sonnet make final architecture calls just because it already did the
  implementation.
- Treating the routing table as a budget cap. It is a default map, not a ceiling.
- Upgrading silently without recording what failed and what the stronger model must
  improve.
