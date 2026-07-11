# GPT-5.6 routing evidence

This reference records the evidence used to derive the routing defaults. It is a dated
snapshot from 2026-07-10, not a substitute for local evaluation. Source titles are
included for provenance; the skill remains self-contained and does not require network
access.

## Provenance

Accessed on 2026-07-10 unless noted otherwise:

- OpenAI, “Models” in the Codex documentation
  (https://developers.openai.com/codex/models).
- OpenAI, “Subagents” in the Codex documentation
  (https://learn.chatgpt.com/docs/agent-configuration/subagents).
- OpenAI, “Model guidance: Using GPT-5.6”
  (https://developers.openai.com/api/docs/guides/latest-model).
- OpenAI, “GPT-5.6: Frontier intelligence that scales with your ambition.”
- OpenAI Help Center, “Codex rate card.”
- Artificial Analysis, GPT-5.6 Sol, Terra, Luna, and effort-variant model pages.
- CodeRabbit, “GPT-5.6 Sol and Terra Benchmark.”
- Qodo, “GPT-5.6: More Precise and Efficient Code Review.”

## Evidence hierarchy

1. Current OpenAI model, Codex, subagent, and migration documentation.
2. Controlled or same-harness independent comparisons.
3. Multi-repository practitioner benchmarks with disclosed limitations.
4. Individual field reports and launch-week anecdotes.

Do not promote a lower-confidence observation into a universal rule.

## Official baseline

- GPT-5.6 defines durable capability tiers: flagship Sol, balanced Terra, and fast,
  lowest-cost Luna.
- Codex normally uses Sol at Medium for demanding work. Cost-sensitive routing must
  select Terra or Luna explicitly where the surface permits model choice.
- Current local Codex clients load custom agents from `.codex/agents/` or
  `~/.codex/agents/`. Agent files require `name`, `description`, and
  `developer_instructions` and may pin `model`, `model_reasoning_effort`, and
  `sandbox_mode`. Source: the official “Subagents” page above.
- Current GPT-5.6 model IDs are `gpt-5.6-sol`, `gpt-5.6-terra`, and
  `gpt-5.6-luna`. Source: the official GPT-5.6 model-guidance page above.
- Max is deeper single-agent reasoning. Codex Ultra is multi-agent orchestration, not
  an API reasoning-effort value and not a token-saving mode.
- Higher effort increases latency and token use. OpenAI recommends starting from a
  working baseline, comparing adjacent levels, and reserving Max for the hardest cases.
- Each subagent performs its own model and tool work. Budget parallel work for more
  total tokens than a comparable single-agent run unless measurement shows otherwise.
- Official internal coding-agent evaluations found that leaner prompts sometimes
  improved scores by about 10–15% while reducing total tokens by 41–66% and cost by
  33–67%. OpenAI labels these ranges directional and requires workload-specific
  validation.
- `agents.max_depth` defaults to `1`, while `agents.max_threads` defaults to `6` as a
  cap rather than a target.
- API GPT-5.6 efforts are `none`, `low`, `medium`, `high`, `xhigh`, and `max`. Pro mode
  and the Responses API multi-agent beta are separate from Codex Ultra.
- Sol, Terra, and Luna API prices were published in a 5:2.5:1 input ratio and a
  30:15:6 output ratio. Equal-token price ratios do not predict cost per accepted task.

June 26 preview material and stale search indexes were superseded by the July 9
general-availability release. Always order volatile availability claims by publication
and update time. Treat entitlements, aliases, credit rates, defaults, and beta features
as volatile.

## Same-harness independent comparison

Artificial Analysis Intelligence Index v4.1 reported:

| Configuration | Score | Aggregate evaluation output tokens | Reported total cost |
| --- | ---: | ---: | ---: |
| Luna Low | 33 | 7.0M | $68.80 |
| Luna Medium | 38 | 12M | $105.84 |
| Luna High | 46 | 37M | $275.02 |
| Luna Extra High | 49 | 67M | $479.37 |
| Luna Max | 51 | 130M | $870.30 |
| Terra Low | 40 | 5.9M | $160.65 |
| Terra Medium | 46 | 10M | $240.23 |
| Terra High | 49 | 24M | $495.77 |
| Terra Extra High | 52 | 36M | $740.21 |
| Terra Max | 55 | 96M | $1,753.94 |
| Sol Low | 49 | 6.6M | $353.49 |
| Sol Medium | 54 | 12M | $593.04 |
| Sol High | 56 | 21M | $955.55 |
| Sol Extra High | 58 | 35M | $1,542.52 |
| Sol Max | 59 | 70M | $2,824.18 |

This supports several directional conclusions:

- Sol Low matched Terra High and Luna Extra High while using far fewer output tokens.
- Sol Medium exceeded Luna Max and nearly matched Terra Max with much less output.
- Terra Medium matched Luna High with substantially fewer output tokens.
- Returns diminished sharply above Sol Medium in this broad suite.

Confidence is high only that this table transcribes the published same-harness
comparison; external validity for a particular repository is low. Reported total cost
also follows Artificial Analysis's task weighting and cache assumptions and is not a
Codex subscription-quota measure. The table justifies testing a stronger tier at lower
effort; it does not establish one universal route.

## Third-party coding evidence

CodeRabbit reported more than 100 repository tasks across TypeScript, Go, Python,
JavaScript, and Rust. Sol passed more tasks and used fewer output tokens per task than
Terra. Using published output prices alone, Sol appeared cheaper per successful task
despite costing twice as much per output token. The article did not disclose effort,
the full harness, or raw data, and contained one inconsistent Terra percentage.

Safe inference: for complex coding, optimize cost per solved task rather than per-token
price. Confidence: medium.

Qodo reported comparable code-review quality to GPT-5.5 with roughly half the tokens
and lower latency. It is an OpenAI launch partner and did not disclose every evaluation
detail. Do not repeat secondary claims of three-times fewer tokens; they conflict with
Qodo's own article. Confidence: medium.

## Ultra evidence boundary

No controlled evidence reviewed here establishes Ultra as a token-saving mode. Ultra
and parallel workers usually add duplicated model and tool work. Budget for more total
tokens unless a controlled local comparison shows that reduced retries or context
duplication offsets the overhead. Use Ultra for measured parallel quality or wall-clock
gains, and never derive Codex subscription duration from API token prices.

## Updating the routing policy

Change a default only when a representative local comparison records the prompt,
tools, model tier, effort, orchestration, accepted outcome, token accounting, latency,
retries, and verification result. Prefer repeated local evidence over this snapshot.
