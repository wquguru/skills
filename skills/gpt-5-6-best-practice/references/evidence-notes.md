# GPT-5.6 routing evidence

This is a dated provenance record, not an operating policy. Reverify load-bearing
facts against current official documentation and prefer local route evaluations over
launch claims or broad benchmarks.

## Source hierarchy

1. Current OpenAI model, Codex, subagent, migration, and pricing documentation.
2. Controlled same-harness comparisons.
3. Multi-repository practitioner benchmarks with disclosed limitations.
4. Individual field reports and launch anecdotes.

Checked on 2026-07-10:

- OpenAI, “Models” (https://developers.openai.com/codex/models): Codex model and
  reasoning choices.
- OpenAI, “Subagents”
  (https://learn.chatgpt.com/docs/agent-configuration/subagents): worker token
  overhead, custom-agent paths and schema, model/effort overrides, sandbox inheritance,
  and `agents.max_depth`/`max_threads` behavior.
- OpenAI, “Using GPT-5.6”
  (https://developers.openai.com/api/docs/guides/latest-model): Sol/Terra/Luna IDs and
  alias, effort values, migration, lean-prompt evaluation, safeguards, caching, Pro,
  programmatic tool calling, and multi-agent beta.
- OpenAI, “GPT-5.6: Frontier intelligence that scales with your ambition”
  (https://openai.com/index/gpt-5-6/): launch positioning and availability.
- Artificial Analysis, “GPT-5.6 benchmarks across Intelligence, Speed and Cost”
  (https://artificialanalysis.ai/articles/gpt-5-6-has-landed): third-party aggregate
  score, reported token, and cost comparisons across tiers and efforts.
- CodeRabbit, “OpenAI GPT-5.6 Sol and Terra: Benchmark”
  (https://www.coderabbit.ai/blog/gpt-5-6-sol-and-terra-benchmark): repository-task
  pass rates and reported output tokens.
- Qodo, “GPT-5.6: More Precise and Efficient Code Review”
  (https://www.qodo.ai/blog/gpt-5-6-more-precise-and-efficient-code-review/): GPT-5.6
  versus GPT-5.5 review precision, recall, reported token use, and latency.

## Official baseline

| Claim | Source | Boundary |
| --- | --- | --- |
| `gpt-5.6-sol`, `gpt-5.6-terra`, and `gpt-5.6-luna`; `gpt-5.6` aliases Sol | Using GPT-5.6 | Availability and aliases are volatile |
| Sol is flagship, Terra balanced, Luna efficient/high-volume | Using GPT-5.6 | These are starting roles, not job guarantees |
| API efforts: `none`, `low`, `medium`, `high`, `xhigh`, `max` | Using GPT-5.6 | UI labels differ by surface |
| Max is deeper single-agent reasoning; Ultra is Codex orchestration, not API effort | Models / Using GPT-5.6 | Ultra behavior and entitlement can change |
| Custom agents may pin model, effort, and sandbox under `.codex/agents/` or `~/.codex/agents/` | Subagents | Effective runtime policy can constrain the file |
| `agents.max_depth` defaults to 1 and `max_threads` to 6 | Subagents | A cap is not a target worker count |
| Each subagent performs separate model/tool work and normally increases tokens | Subagents | A routed workflow can still reduce accepted-result cost after retries and rescue |
| Leaner prompts improved one internal coding-agent sample while reducing tokens/cost | Using GPT-5.6 | The published ranges are directional, not a universal route |
| Real-time cyber/biology safeguards can pause or refuse benign dual-use work | Using GPT-5.6 | Recovery depends on the active surface |

API prices, subscription credits, Fast-mode multipliers, entitlements, aliases, and
rollout defaults are different and volatile accounting systems. Never derive one from
another.

## Independent evidence boundaries

- Artificial Analysis reported several stronger-tier/lower-effort configurations with
  similar or higher aggregate scores and fewer reported output tokens than
  smaller-tier/high-effort configurations. The suite does not expose this skill's full
  lead/worker/retry accounting or repository accepted-result rate. It supports testing
  that tradeoff, not calling it universally token-efficient.
- CodeRabbit reported higher pass rate and fewer average output tokens for Sol than
  Terra in its repository harness. Its article does not fully disclose effort, input,
  cache, retry, or complete cost accounting. Use it only as evidence that per-token
  price can mislead.
- Qodo reported roughly half the tokens and lower latency for GPT-5.6 versus GPT-5.5 at
  comparable review recall. This is migration evidence, not Sol/Terra/Luna routing
  evidence, and it comes from an OpenAI launch partner.

No controlled evidence reviewed here establishes Ultra as a token-saving mode. Budget
parallel work for added model and tool usage unless a local end-to-end comparison shows
lower accepted-result cost.

## Updating this record

For every changed default, record the exact page, access date, supported claim, and
evidence boundary. A controlled diagnosis holds prompt and tools constant; final route
selection compares each candidate's validated end-to-end configuration as defined in
`SKILL.md`.
