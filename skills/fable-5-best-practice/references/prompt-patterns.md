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

Chosen lane and reason:
[Model/tier + effort, why it fits, and expected cost effect.]

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
