# Claude Fable 5 evidence notes

This reference records the provenance of the volatile facts stated in `SKILL.md`. It
is a dated snapshot from 2026-07-10, not a substitute for checking the official
Anthropic documentation available in the runtime. The skill remains self-contained
and does not require network access.

## Provenance

Checked on 2026-07-10 unless noted otherwise:

- Anthropic, "Models overview" and "Choosing the right model" in the Claude API
  documentation.
- Anthropic, Claude API pricing documentation.
- Anthropic, Claude Fable 5 migration and extended-thinking documentation.
- Anthropic, beta headers and stop-reason handling documentation.
- Anthropic announcement, "Claude Fable 5 and Mythos 5"
  (https://www.anthropic.com/news/claude-fable-5-mythos-5).

When a `claude-api` or equivalent documentation skill is available in the runtime,
prefer it over this snapshot for any load-bearing number or availability claim.

## Evidence hierarchy

1. Current official Anthropic model, pricing, and API documentation.
2. Anthropic announcements and migration guides, ordered by publication date.
3. Controlled or same-harness independent comparisons.
4. Individual field reports and launch-week anecdotes.

Do not promote a lower-confidence observation into a universal rule.

## Volatile facts and their status

- Model ID `claude-fable-5`; Fable 5 and Mythos 5 share the same underlying model,
  with Fable carrying additional safety measures for dual-use capabilities. Source:
  Anthropic announcement and models documentation. Confidence: high on 2026-07-10;
  aliases and tiering are volatile.
- 1M-token context window with up to 128k output tokens per request. Source: models
  documentation. Confidence: high on 2026-07-10.
- Pricing $10/MTok input and $50/MTok output. Prices change without notice; never
  copy them into durable policy or derive subscription behavior from API prices.
  Confidence: high on 2026-07-10 only.
- 30-day data retention requirement; unavailable under zero data retention. Retention
  terms are contractual and volatile. Confidence: high on 2026-07-10.
- Adaptive thinking always on; manual thinking budgets unsupported; depth controlled
  with `effort` (`low` through `max`); `thinking.display` is `summarized` or
  `omitted` and raw thinking is never returned. Source: extended-thinking and
  migration documentation. Confidence: high on 2026-07-10.
- Task budgets are beta on the Messages API behind the `task-budgets-2026-03-13`
  header and are not supported by Claude Code or Cowork. Beta headers and surface
  support change frequently. Confidence: medium.
- Classifier refusals return HTTP 200 with `stop_reason: "refusal"`; observed
  categories include `cyber`, `bio`, `frontier_llm`, and `reasoning_extraction`.
  The category list is not exhaustive and can change. Confidence: medium.
- Server-side fallback uses the `fallbacks` parameter behind the
  `server-side-fallback-2026-06-01` beta header; unavailable for Message Batches,
  Amazon Bedrock, Google Cloud, and Microsoft Foundry. SDK middleware retries exist
  for TypeScript, Python, Go, Java, and C#; the `fallback-credit-2026-06-01` header
  avoids duplicate prompt-cache cost on manual retries. Platform coverage for beta
  features is the most volatile fact in this file. Confidence: medium.

## Updating the skill

Before changing a default or quoting one of these facts as current, verify it against
the official documentation, update the snapshot date here, and record what changed.
If verification is unavailable, state the snapshot date and label the uncertainty
rather than presenting the fact as current.
