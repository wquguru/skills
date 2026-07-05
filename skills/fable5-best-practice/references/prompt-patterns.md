# Prompt patterns for substantial Fable 5 tasks

Use the shape below for substantial tasks. It maps to four essentials: context, request,
output format, and constraints. Trim any section that does not apply rather than padding
it.

```text
Context:
I am working on [larger goal] for [audience/users]. This matters because [why].

Request:
[One sentence describing the concrete thing needed.]

Current state:
[Facts, links, repo paths, data sources, constraints, prior attempts.]

Why it matters:
[Decision, stakeholder, workflow, or risk this output should support.]

Output format:
[Deliverable shape, length, style, language, and audience.]

Success criteria:
- [Observable result]
- [Verification method]
- [Quality bar]

Delegation & model mix:
[Who executes: single model, or a subagent tree. If the target harness can spawn
subagents, specify which tier gathers evidence (Sonnet), which reviews for taste
and code quality (Opus), which provides independent senior engineering perspective
(Codex, if installed), which arbitrates and owns judgment calls (Fable), and the
independent fresh-context verifier. See references/claude-model-routing.md.
If the harness cannot spawn subagents, say "single model" and collapse this into
an explore-then-judge sequence.]

Approval gates:
Pause before [destructive / expensive / external / scope-changing actions].

Your job:
Interview me if key intent is missing, and do a blind spot pass on my unknown unknowns
before committing to an approach. Then propose a plan, pre-mortem the likely failure
modes, identify the first highest-leverage slice, execute where allowed, and verify
before reporting success.
```

For strategy work, add a pre-mortem:

```text
Before planning, assume this fails 12-24 months from now. What were the most likely
causes, what early signals would reveal them, and how should we design around them?
```
