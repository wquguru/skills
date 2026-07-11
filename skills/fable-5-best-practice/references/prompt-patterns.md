# Compact prompt for substantial Fable tasks

Use this shape only when the task benefits from Fable's long-horizon reasoning. Omit
fields that do not affect the work.

```text
Context and intent:
[Who needs this, why it matters, and the relevant evidence or source paths.]

Outcome:
[The concrete deliverable or decision required.]

Constraints and boundaries:
[Scope, prohibited actions, required tools or sources, and approval gates.]

Acceptance criteria:
- [Observable result]
- [Verification method]
- [Quality bar]

Budget and stop condition:
[Time, cost, tokens, attempts, or an externally checkable stopping rule.]

Reporting:
[Audience, format, and the evidence needed to support progress and completion claims.]

Choose the path and act when enough information exists. Ask only for missing input
that would materially change the result. Keep scope tight, verify before reporting
success, and use asynchronous workers only when delegation is available and useful.
```

## Worker packet for a subagent

```text
Goal:
[One sentence describing the result this worker owns.]

Owned scope:
[Files, systems, or questions this worker may touch. Keep write ownership disjoint.]

Inputs:
[Only the evidence and paths needed for this workstream.]

Output contract:
[Required fields, format, evidence, and maximum useful length.]

Verification:
[The checks that cover this worker's acceptance criteria, plus any residual semantic
review the checks do not cover.]

Stop condition:
[Attempt, time, cost, or failure boundary at which the worker reports back.]
```

Choose the worker model explicitly when the harness supports it. Use a fork only when
the worker genuinely needs the parent conversation; otherwise prefer this compact
packet and a fresh context.
