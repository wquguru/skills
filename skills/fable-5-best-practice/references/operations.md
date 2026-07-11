# Fable operating rules

Use this reference for substantial, high-effort, analysis-only, or long-running work.
These rules preserve scope without obscuring the routing decision in `SKILL.md`.

## Scope and authorization

For analysis, review, diagnosis, or reporting requests, inspect and report; do not
create files, modify state, deploy, purchase, or send external messages unless the
request also authorizes those actions.

At higher effort, stay within the requested scope. Do not add features, broad
refactors, abstractions, backups, feature flags, compatibility shims, or validation for
impossible internal states unless the acceptance contract requires them. Validate at
system boundaries and recommend the path being pursued rather than surveying unused
alternatives.

## Long-running execution

- Use asynchronous workers, scheduled checks, or harness-native waiting. Never keep an
  agent alive with an unbounded sleep or polling loop inside a tool call.
- Keep the lead context to decisions, risks, current state, and compact evidence.
- Pause for destructive or irreversible actions, external commitments, real scope
  changes, or information only the user can provide.
- Prefer harness memory when available. Across sessions, preserve only durable
  decisions, constraints, corrections, confirmed approaches, and the next action.
  When a file is necessary, maintain one compact state snapshot and delete stale or
  disproved notes.
- A remaining-context countdown alone is not a reason to stop. Continue unless a real
  limit, acceptance stop condition, or user-only blocker is reached.

## Progress and completion

Before reporting progress, audit each claim against evidence from the current run.
Label unverified work, failed tests, and skipped steps explicitly. Plans, promises, and
intended tool calls do not count as completed work.

Deterministic gates establish only the properties they encode. Report residual
semantic risk and any required human or stronger-model review rather than treating a
green command as complete acceptance.

## Communication

Lead with the outcome, then the evidence that changes what the reader should trust or
do next. Use complete sentences. Avoid arrow chains, invented labels,
hidden-reasoning references, and unexplained implementation shorthand.
