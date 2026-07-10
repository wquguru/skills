# Compact prompt shapes for GPT-5.6 work

Use these shapes when the task is substantial. Omit fields that do not affect the
work; every field a worker must read is token cost.

## Task prompt for a lead agent

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
that would materially change the result. Keep scope tight, and verify before
reporting success.
```

## Worker packet for a subagent

```text
Goal:
[One sentence: the result this worker owns.]

Owned scope:
[Files, directories, or questions this worker may touch. Write ownership is disjoint
from every other worker.]

Inputs:
[Distilled evidence and paths the worker needs. Do not forward raw logs or dumps.]

Output contract:
[Exact shape of the return value: fields, format, and maximum length. Workers return
distilled evidence, not raw tool output or reasoning transcripts.]

Verification:
[The command or check the worker must run before claiming success.]

Stop condition:
[Attempt cap, budget, or the failure state at which the worker reports back instead
of continuing.]
```

Route the packet to the cheapest tier likely to finish (see the tier table in
`SKILL.md`), and cap fan-out, nesting, attempts, and returned context.
