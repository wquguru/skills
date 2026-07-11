# Routing and evaluation procedure

Use this reference when estimating a route, running a canary, or standardizing a
reusable routing policy.

## Accounting

Choose one primary spend unit from the active surface:

- API usage: dollars.
- Subscription usage: credits or the surface's exposed usage signal.
- No comparable spend signal: report relative resource intensity; do not claim an
  exact cheapest route.

For a completed evaluation set:

```text
cost per accepted result = total spend across accepted runs, failed runs, workers,
verifiers, retries, and rescues / number of accepted results
```

Do not add cached-input or reasoning tokens twice. Track tokens, latency, calls, and
human correction separately as diagnostics or guardrails.

## One-off routing

Prospectively compare three route shapes without executing all three:

1. The current single-agent route.
2. The cheapest plausible non-inferior single-agent lane.
3. An appropriate lead with routed workers and verification.

Use task shape, local history, context duplication, checkability, and rescue risk. If
evidence is weak, prefer one agent and label the decision heuristic. A low-risk,
strongly verified one-off can be a canary; it is not evidence for a durable default.

## Reusable routes

Evaluate in two stages:

1. **Controlled diagnosis:** hold task, prompt, tools, acceptance contract,
   verification, and budget constant; change one of tier, effort, or orchestration.
2. **End-to-end selection:** allow each candidate its validated prompt, effort, and
   worker setup; compare acceptance pass rate and cost per accepted result.

Before running, declare the representative task set, non-inferiority tolerance,
repetition or confidence rule, and adoption threshold. Do not hard-code one sample size
for every workload; the declaration must match the consequence and variance of the
task family.

Adopt the cheaper route only when it satisfies the acceptance contract and the
predeclared rule. Otherwise retain the stronger accepted baseline and record the failed
criterion. Change a durable default only from repeated evidence, not a post-hoc claim
that the work looked easy.
