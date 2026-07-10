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
