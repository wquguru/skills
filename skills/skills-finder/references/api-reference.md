# skills.sh API reference

Base URL: `https://skills.sh` — all endpoints under `/api/v1/`, JSON responses.
Full upstream docs: https://www.skills.sh/docs/api

## Authentication — what actually works

The docs say every endpoint needs a **Vercel OIDC token**
(`Authorization: Bearer <VERCEL_OIDC_TOKEN>`). Verified against the live API:

| Endpoint | Token required? | Use it via |
|---|---|---|
| `GET /api/v1/skills/audit/{owner}/{repo}/{skill}` | **No — PUBLIC** | `curl` / `scripts/audit.py` |
| `GET /api/v1/skills/search?q=` | Yes (401 without) | `npx skills find` (CLI handles auth) |
| `GET /api/v1/skills` (leaderboard) | Yes (401) | needs token |
| `GET /api/v1/skills/curated` | Yes (401) | needs token |
| `GET /api/v1/skills/{owner}/{repo}/{skill}` (detail) | Yes (401) | needs token |

Practical consequence: **discover with the `npx skills` CLI** (no manual token),
and **security-gate with the public audit endpoint** (no manual token). Only reach
for a raw token if you need the leaderboard/curated/detail JSON directly. To get
one: link a Vercel project and run `vercel env pull` (writes `VERCEL_OIDC_TOKEN`
to `.env.local`), then pass `Authorization: Bearer $VERCEL_OIDC_TOKEN`.

## Identifier forms (all map to the same audit path)

A skill is `{owner}/{repo}/{skill}`. The path after `https://skills.sh/` IS the
audit path suffix. These are equivalent inputs to `scripts/audit.py`:

```
owner/repo@skill          # npx skills find output (uses @)
owner/repo/skill          # slash form
github/owner/repo@skill   # with sourceType prefix
https://skills.sh/owner/repo/skill   # full URL from find output
```

## GET /api/v1/skills/audit/{owner}/{repo}/{skill}  (the security gate)

Public. Returns multi-provider security audits. `404` if none exist yet (audits
generate automatically minutes after a skill's first install).

```json
{
  "id": "vercel-labs/skills/find-skills",
  "source": "vercel-labs/skills",
  "slug": "find-skills",
  "audits": [
    {
      "provider": "Gen Agent Trust Hub",
      "slug": "agent-trust-hub",
      "status": "pass",
      "summary": "…",
      "auditedAt": "2026-03-14T07:45:39.850Z",
      "riskLevel": "SAFE",
      "categories": ["COMMAND_EXECUTION", "EXTERNAL_DOWNLOADS"]
    }
  ]
}
```

Providers seen: **Gen Agent Trust Hub, Socket, Snyk, Runlayer, ZeroLeaks**.
- `status`: `pass` | `warn` | `fail`
- `riskLevel` (may be absent): `SAFE` | `NONE` | `LOW` | `MEDIUM` | `HIGH` | `CRITICAL`
- `categories`: present only for Agent Trust Hub (e.g. `COMMAND_EXECUTION`,
  `EXTERNAL_DOWNLOADS`) — useful context for why a skill is risky.

A single skill commonly gets **different verdicts from different providers**
(e.g. one `pass`, one `warn/MEDIUM`, one `fail/HIGH`). The gate must consider all.

## Discovery endpoints (token-gated — prefer the CLI)

`GET /api/v1/skills/search?q=<≥2 chars>&limit=<1-200>&owner=<gh-owner>` →
`{ data: [skill], query, searchType, count, durationMs }`.

`GET /api/v1/skills?view=all-time|trending|hot&page=&per_page=` → leaderboard
`{ data: [skill], pagination }`; `hot` adds `installsYesterday`, `change`.

`GET /api/v1/skills/curated` → official first-party sets grouped by owner.

`GET /api/v1/skills/{owner}/{repo}/{skill}` → detail incl. `files: [{path, contents}]`
and `hash` (SHA-256) — the raw skill source for manual inspection.

Skill object (listings/search): `id`, `slug`, `name`, `source`, `installs`,
`sourceType` (`github`|`well-known`), `installUrl`, `url`, `isDuplicate?`.

Rate limit (authenticated): 600 req/min per (team, project). Errors:
`{error, message}` with 400/401/404/429/503.
