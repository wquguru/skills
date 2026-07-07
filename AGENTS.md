# Repository Guidelines

## Project Structure & Module Organization

This repository is a collection of Agent Skills. Self-authored skills live in `skills/<skill-name>/`, and each skill must include a `SKILL.md`. Optional skill resources belong under the same skill folder, commonly `scripts/`, `references/`, `assets/`, and `agents/openai.yaml`. Third-party vendored skills are declared in `external.yml`, materialized into `external/` under a `3rd-` name prefix (e.g. `3rd-dashboarding`), and pinned in `external.lock`. Site files for the public index live at the repository root (`index.html`, `styles.css`, `assets/`).

## Build, Test, and Development Commands

- `just`: list available recipes.
- `just vendor`: fetch third-party skills from `external.yml` into `external/` and update `external.lock`.
- `just add`: symlink all local and vendored skills into `~/.claude/skills` and `~/.codex/skills`.
- `just remove`: remove only symlinks that point back to this repository.
- `just status`: show whether each skill is linked in both destinations.

There is no package build step. For a new or edited skill, run the system validator when available:

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/<skill-name>
```

## Public Site & Deployment

The public site is a static GitHub Pages index at `https://wquguru.github.io/skills/`. Keep `main` as the source of truth for site edits, and publish from the `gh-pages` branch root with `.nojekyll` preserved.

Prefer branch-based Pages for this repo. Do not reintroduce an Actions-based Pages workflow unless intentionally changing the deploy strategy; `actions/deploy-pages` has a 10 minute deploy timeout, and repeated `deployment_queued` statuses usually mean a GitHub Pages backend queue issue rather than a site-code problem.

When a deployment stalls, inspect Pages state before changing site files:

```bash
gh api repos/wquguru/skills/pages
gh run list --limit 8
gh api 'repos/wquguru/skills/deployments?per_page=8'
gh api repos/wquguru/skills/deployments/<id>/statuses
```

To publish new site changes, update `gh-pages` from `origin/main` in a temporary worktree, keep `.nojekyll`, push `gh-pages`, and verify the live URL. Treat deployment as complete only after Pages reports `built`, the Pages run succeeds, the live HTML contains the expected title/content, and referenced assets return 200.

## Coding Style & Naming Conventions

Name skill folders with lowercase hyphen-case, for example `youtube-toolkit` or `agent-compat-sync`. Keep `SKILL.md` concise and task-focused, with YAML frontmatter containing `name` and `description`. Put deterministic automation in executable scripts under `scripts/`; prefer Bash for repository plumbing and Python for structured validation or filesystem logic. Avoid adding extra docs such as standalone installation guides unless they are directly used by the skill.

## Testing Guidelines

Validate every changed skill with `quick_validate.py`. If a skill includes scripts, run a representative smoke test in a temporary directory or against harmless sample input. For symlink or filesystem automation, test both success and conflict paths before committing.

### Security auditing

Skills are executed by agents, so a malicious or careless skill is a supply-chain risk. CI audits every changed skill with [NVIDIA SkillSpector](https://github.com/NVIDIA/skillspector), a static scanner for prompt injection, data exfiltration (with taint tracking), unicode/zero-width deception, unsafe code, and supply-chain issues. To scan locally before committing:

```bash
uv tool install git+https://github.com/NVIDIA/skillspector.git   # or: pipx install …
skillspector scan skills/<skill-name> --no-llm   # exit 1 == DO_NOT_INSTALL (risk > 50)
```

The scan runs offline (`--no-llm`, no API key), gates the build when a skill scores DO_NOT_INSTALL (risk > 50), and uploads SARIF to the repo Security tab. SkillSpector is pinned to a commit SHA in `.github/workflows/security-audit.yml`; bump it deliberately to adopt upstream changes. Gitleaks (secrets) and shellcheck (shell scripts) also run there. To save compute, PR/push runs scan only the changed skills; the weekly schedule and manual `workflow_dispatch` run a full scan.

The static ruleset is deliberately aggressive and can false-positive on legitimate content (e.g. cautionary prose that mentions `rm -rf`, or `yt-dlp --cookies-from-browser`). When a skill trips the gate on reviewed false positives, accept them into a committed per-skill baseline that the workflow picks up automatically:

```bash
skillspector baseline skills/<skill-name> --no-llm \
  -o skills/<skill-name>/.skillspector-baseline.yaml --reason "why these are safe"
```

Baselines suppress only the listed findings, so the gate still fires on any *new* risk. Review each entry before committing — never baseline a finding you haven't understood.

A third AI layer, Anthropic's security review, catches prompt injection in `SKILL.md` prose. It only activates when a `CLAUDE_API_KEY` repository secret is set; to route it through a third-party Anthropic-compatible gateway, also set an `ANTHROPIC_BASE_URL` secret and use the gateway's key as `CLAUDE_API_KEY`.

## Commit & Pull Request Guidelines

Use concise Conventional Commit-style messages, matching recent history: `feat(scope): ...` or `docs(scope): ...`. Examples include `feat(skills): add english swe daily practice skill` and `docs(readme): add positioning and install guide`.

Pull requests should describe the changed skill, list validation commands run, and note any generated or vendored changes such as `external.lock`. Include screenshots only for changes to `index.html` or visual site assets.

## Agent-Specific Instructions

When creating or updating a skill, use the `skill-creator` guidance. Do not overwrite user-owned skill directories in `~/.claude/skills` or `~/.codex/skills`; use `just add` and `just remove` so symlinks remain auditable.
