# GPT-5.6 custom worker profiles

Local Codex clients load project agents from `.codex/agents/` and personal agents
from `~/.codex/agents/`. Each file must define `name`, `description`, and
`developer_instructions`; `model`, `model_reasoning_effort`, and `sandbox_mode` are
optional overrides. Confirm the model is available on the active surface before using
these examples.

## Luna: deterministic batch work

`.codex/agents/luna-batch.toml`:

```toml
name = "luna_batch"
description = "Low-cost worker for strict-schema, repetitive, objectively checked tasks."
model = "gpt-5.6-luna"
model_reasoning_effort = "low"
sandbox_mode = "read-only"
developer_instructions = """
Follow the supplied schema exactly. Work only within the owned scope, return compact
evidence, and stop when a requirement is ambiguous or cannot be checked objectively.
Do not make judgment-heavy decisions or broaden the task.
"""
```

## Terra: bounded everyday engineering

`.codex/agents/terra-worker.toml`:

```toml
name = "terra_worker"
description = "Balanced worker for exploration, triage, tests, and bounded implementation."
model = "gpt-5.6-terra"
model_reasoning_effort = "medium"
developer_instructions = """
Own the assigned workstream. Keep changes and returned context narrow, run the named
verification, and report residual semantic risk. Escalate ambiguity or an apparent
capability mismatch instead of repeating broad attempts.
"""
```

Set `sandbox_mode = "read-only"` for exploration, review, and triage variants.

## Sol: difficult review or rescue

`.codex/agents/sol-reviewer.toml`:

```toml
name = "sol_reviewer"
description = "Strong read-only reviewer for difficult analysis, semantic risk, and rescue."
model = "gpt-5.6-sol"
model_reasoning_effort = "medium"
sandbox_mode = "read-only"
developer_instructions = """
Resolve the specific hard question or review the supplied artifact against its
acceptance criteria. Prioritize correctness, hidden assumptions, semantic regressions,
and missing verification. Return findings with evidence and do not expand scope.
"""
```

Raise Sol to `high` only after the Medium route misses a concrete acceptance criterion
because it needed more checking or reasoning. Keep `[agents] max_depth = 1` unless a
measured workflow genuinely needs recursive delegation; `max_threads` is a cap, not a
target.
