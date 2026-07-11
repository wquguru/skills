# Fable API runtime snapshot

This file preserves implementation detail that would overload `SKILL.md`. It is a
2026-07-10 snapshot, not a stable API contract. Reverify every beta header, parameter,
SDK list, and platform exclusion against current Anthropic documentation before coding.
If current verification is unavailable, state the snapshot date and uncertainty rather
than presenting the behavior as current.

## Thinking and budgets

- Adaptive thinking is always on; manual thinking budgets are unsupported. Use
  `effort` from `low` through `max`.
- Raw thinking is not returned. `thinking.display` is `summarized` or `omitted`.
  Preserve returned thinking blocks unchanged in same-model multi-turn requests.
- `max_tokens` is the per-request cap covering thinking and response output.
- Task budgets apply to a full agentic loop and are distinct from `max_tokens`. In this
  snapshot they require `task-budgets-2026-03-13` on the Messages API and are not
  supported by Claude Code or Cowork.

## Refusal handling

A classifier refusal is a successful HTTP 200 response identified by:

```json
{
  "stop_reason": "refusal"
}
```

Branch on `stop_reason`, not HTTP error handling or `stop_details`. Category metadata
observed in this snapshot includes `cyber`, `bio`, `frontier_llm`, and
`reasoning_extraction`; the list is non-exhaustive and should be used for monitoring,
not for bypass attempts. Treat partial content as incomplete.

## Fallback mechanisms

Choose one mechanism for a request path and allow at most one model fallback:

| Mechanism | Snapshot scope | Constraint |
| --- | --- | --- |
| Server-side fallback | `fallbacks` with `server-side-fallback-2026-06-01` on the Claude API or Claude Platform on AWS | Unavailable for Message Batches, Amazon Bedrock, Google Cloud, and Microsoft Foundry in this snapshot |
| SDK middleware | TypeScript, Python, Go, Java, and C# middleware retry on supported platforms | Do not combine with server-side fallback on the same request |
| Manual retry | Ruby, PHP, raw HTTP, or custom retry logic | Retry once on a different model; this snapshot uses `fallback-credit-2026-06-01` to avoid duplicate prompt-cache cost |

Before retrying a side-effecting workflow, confirm idempotency or that the refused
attempt completed no external action. Track original refusals and fallback-served
responses separately. Never loop across mechanisms or retry adversarially.

## Verification status

The general stop-reason behavior is traceable from
https://docs.anthropic.com/en/api/handling-stop-reasons. Search indexing did not expose
stable public URLs for the future-dated task-budget and fallback beta pages during the
2026-07-10 review. Those exact headers and matrices therefore remain dated snapshot
claims and must not be treated as verified current behavior without a fresh lookup.
