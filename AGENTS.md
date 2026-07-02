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

## Commit & Pull Request Guidelines

Use concise Conventional Commit-style messages, matching recent history: `feat(scope): ...` or `docs(scope): ...`. Examples include `feat(skills): add english swe daily practice skill` and `docs(readme): add positioning and install guide`.

Pull requests should describe the changed skill, list validation commands run, and note any generated or vendored changes such as `external.lock`. Include screenshots only for changes to `index.html` or visual site assets.

## Agent-Specific Instructions

When creating or updating a skill, use the `skill-creator` guidance. Do not overwrite user-owned skill directories in `~/.claude/skills` or `~/.codex/skills`; use `just add` and `just remove` so symlinks remain auditable.
