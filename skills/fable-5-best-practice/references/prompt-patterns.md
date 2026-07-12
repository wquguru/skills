# Compact packets for Fable work

Use these shapes only when the field affects execution. Do not repeat rules already
provided by the active system, repository, or skill.

## Lead task

```text
Outcome:
[Concrete deliverable or decision.]

Context and evidence:
[Only the facts, paths, and prior decisions needed.]

Constraints and approvals:
[Scope, prohibited actions, and confirmation boundaries.]

Routing intent:
[Cost-saving delegation is conditional or topology is mandatory; available model or
profile overrides; maximum useful workers.]

Acceptance contract:
- [Observable result]
- [Required verification and residual semantic review]
- [Safety or quality floor]

Budget and stop condition:
[Cost/accounting unit, time, attempts, or external stopping rule.]

Reporting:
[Audience, format, and evidence required for completion claims.]
```

## Worker packet

```text
Goal:
[One result this worker owns.]

Dispatch binding:
[Named profile or runtime override; effective model/tier + effort, how it will be
verified, and whether this route is measured, heuristic, or user-mandated.]

Marginal contribution:
[Independent output this worker adds and which lead work it avoids duplicating.]

Owned scope:
[Files, systems, or questions. Concurrent writers must have disjoint ownership;
read-only or explicitly sequential work may share scope.]

Inputs:
[Distilled evidence and paths; no raw log or repository dump.]

Output contract:
[Required fields, evidence, format, and maximum useful length.]

Verification:
[Objective checks plus residual semantic review they do not cover.]

Stop condition:
[Attempt, time, cost, ambiguity, or failure boundary.]
```

## Fresh-context verifier

```text
Goal:
Independently determine whether the artifact satisfies the acceptance contract.

Inputs:
[Acceptance contract, artifact or diff, and execution evidence. Do not include the
executor's argument for why its work is correct.]

Output:
[Pass/fail by criterion, evidence, residual risk, and required correction.]

Stop condition:
[Evidence gap or scope boundary that prevents a defensible verdict.]
```

Pin the worker model when the harness supports it. Use a fork only when the worker
genuinely needs the parent conversation and current inheritance behavior is verified;
otherwise prefer a compact packet and fresh context.

## Cost-aware invocation

The skill already enforces this policy when active. Use the following wording when an
external harness needs the routing intent stated explicitly:

```text
Minimize accepted-result cost while meeting the acceptance contract. Use the smallest
useful number of independent subagents only when the routed plan is expected to cost
less than the cheapest qualified single-agent route after coordination, verification,
retries, and rescue.

For every worker, pin and verify its model and effort; do not assume inheritance. If
worker pinning is unavailable or delegation is not net-cheaper, do not fan out.
Recommend the cheaper direct lane and apply the premium gate when it is eligible.
```
