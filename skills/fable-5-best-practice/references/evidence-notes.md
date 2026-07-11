# Claude Fable 5 evidence notes

This is a dated provenance record, not an operating policy. Reverify load-bearing
facts against current official documentation before implementation or quotation.

## Source hierarchy

1. Current Anthropic model, API, pricing, and migration documentation.
2. Anthropic announcements ordered by update date.
3. Controlled same-harness comparisons.
4. Individual field observations.

Checked on 2026-07-10:

- Anthropic, “Claude Fable 5”
  (https://www.anthropic.com/claude/fable): availability, model ID, pricing, intended
  use, and high-level fallback behavior.
- Anthropic, “Claude Fable 5 and Claude Mythos 5”
  (https://www.anthropic.com/news/claude-fable-5-mythos-5): launch capabilities,
  safeguards, tier relationship, pricing, and initial availability.
- Anthropic, “Pricing”
  (https://docs.anthropic.com/en/docs/about-claude/pricing): accounting structure,
  cache pricing, tool-token cost, and agent-workflow cost components. The indexed page
  can lag new model launches; use the Fable product page for its launch price.
- Anthropic, “Handling stop reasons”
  (https://docs.anthropic.com/en/api/handling-stop-reasons): successful Messages API
  responses and `stop_reason: "refusal"` handling.
- Anthropic, “CLI reference”
  (https://docs.anthropic.com/en/docs/claude-code/cli-usage): session model selection.
- Anthropic model, Fable migration, thinking, task-budget, beta-header, and fallback
  documentation available in the runtime. Exact beta pages and platform matrices are
  the least durable sources; confirm them again before coding.

## Volatile fact ledger

| Claim | Source | Confidence on 2026-07-10 | Boundary |
| --- | --- | --- | --- |
| Model ID `claude-fable-5`; 1M context; up to 128k output | Fable product/model documentation | High | Aliases and limits can change |
| $10/MTok input and $50/MTok output | Fable product page | High | API price does not describe subscription credits |
| 30-day retention; unavailable under zero data retention | Model/migration documentation | High | Contract and workspace policy are volatile |
| Adaptive thinking always on; effort `low` through `max`; thinking display summarized or omitted | Migration/thinking documentation | High | Request schema can change |
| Task budgets use `task-budgets-2026-03-13` and are unsupported by Claude Code/Cowork | Task-budget documentation | Medium | Beta header and surface support are volatile |
| Refusals are HTTP 200 with `stop_reason: "refusal"` | Stop-reason documentation | High | Category metadata is non-exhaustive |
| Server fallback uses `fallbacks` with `server-side-fallback-2026-06-01`; SDK/manual alternatives and platform exclusions apply | Fallback documentation | Medium | Reverify header, SDK list, cache credit, and exclusions |

Do not copy beta headers or platform matrices into durable implementation without a
fresh official lookup.

## Field observations: subagent routing

These sessions explain why the skill requires explicit worker routing. They do not
prove that cheaper workers would have been non-inferior.

| Session | Harness version | Workers | Explicit worker model | Observed result | Permitted conclusion |
| --- | --- | ---: | --- | --- | --- |
| Monitoring-stack overhaul | Unknown | 7 | No; 3 were forks | About 1.06M worker output tokens used Fable; a post-hoc review marked roughly 85% as bounded work worth testing on Sonnet/Opus | Verify inheritance and test a cheaper route; do not claim equivalent quality or a universal saving |
| Token-efficiency investigation | Unknown | 4 | No | About 300k worker tokens used Fable; lead review caught two decision-relevant errors | Explicit model choice changes spend, but this run does not establish Sonnet non-inferiority |

In the observed configuration, fork-style workers inherited the parent model and
ignored overrides. Because the harness version was not recorded, treat this only as a
reason to verify current behavior before using forks for cost-sensitive work.

## Updating this record

For every changed default, record the official page, access date, exact supported
claim, and evidence boundary. A one-off route may be a canary; it becomes a default
only after the procedure in `references/routing-and-evaluation.md` passes.
