# Deployment And Verification

Prefer repository-driven provisioning over manual Grafana UI edits. For Docker-provisioned Grafana, deploy by syncing dashboard/provisioning files, rebuilding or recreating the Grafana container, and leaving data-producing services alone unless needed. A config-only change (datasource/dashboard/alerting/contact-point) needs only the Grafana service rebuilt — `docker compose up -d --build grafana`, app/data containers untouched. Contact-point creds and chat/topic ids usually live in a server-side env-file outside the repo; update that too, since a file sync won't carry it.

Grafana major-version-bump gotchas (e.g. 10.x → 11.x — often forced because a setting is version-gated, like `message_thread_id` needing ≥ 10.4):

- A dashboard provider that sets BOTH `folder:` and `folderUid:` crash-loops Grafana 11
  at startup with `a folder with the same name already exists in the current location`
  (pre-11 silently ignored `folderUid`). Keep `folder:` (the title) only; if code needs
  the uid, resolve it by title at runtime.
- For ephemeral/tmpfs Grafana state, set `GF_DATABASE_WAL=true`. The 11.x startup burst
  (schema migrations + provisioning + RBAC/secret migration all hitting SQLite at once)
  otherwise throws a fatal `database is locked` — e.g. it stops the secret-migration
  service, breaking datasource secret decryption. WAL turns it into benign
  `Database locked, sleeping then retrying` info logs that succeed.
- Re-verify after the bump, not from the file diff: provisioning loads clean
  (`finished to provision` with no `level=error` `Failed to provision`), datasources
  still decrypt (`/api/datasources` lists them; `/api/health` `database: ok`), the
  container has `0` restarts, and a delivery test still reaches the chat/thread.

Minimum post-deploy verification:

```bash
curl -fsS https://<grafana>/api/health
curl -fsS https://<grafana>/api/folders
curl -fsS "https://<grafana>/api/search?type=dash-db&tag=<base-tag>"
curl -sS -L -o /tmp/page.html -w '%{http_code}' "https://<grafana>/d/<uid>/..."
curl -sS -L -o /tmp/browse.html -w '%{http_code}' "https://<grafana>/dashboards"
```

For each dashboard, fetch the live JSON and confirm:

- Expected folder title.
- Expected tags.
- No time series legend remains at `bottom` unless intentionally justified.
- No bar chart lacks a `sort()`.
- Prometheus queries that keep columns do not drop `instance` accidentally.
- Time series and compact Prometheus stat/gauge panels have short display names.

For each panel target, execute the live query through `/api/ds/query` with representative variables expanded, for example `${instance:regex}` -> `.*`. Treat query errors, HTTP errors, and unexpected long labels as failures.

Scan query response field labels for long or noisy metadata:

```text
environment
project
url
```

These labels may exist in storage, but should not leak into rendered field names after friendly `set/keep/group` handling.

Monitoring-stack (compose + Telegraf) gotchas:

- A stack gated behind a compose `profiles:` flag still has its env interpolated
  for the WHOLE file on any `docker compose up`, so a `${VAR:?required}` in the
  (inactive) metrics services fails the APP's own `up` before monitoring is even
  seeded. Use `${VAR:-}` defaults and guard non-empty in the monitoring-up recipe.
- Loopback monitoring ports get grabbed by sibling stacks on a shared host —
  `ss -tlnp` right before `up`; don't trust a stale port survey.
- Telegraf scraping an app's JSON endpoint (not Prometheus): `inputs.http` + the
  v1 `json` parser auto-flattens nested objects with `_` (avoids json_v2
  last-segment field-name collisions like `sources.total` vs `items.total`); pass
  auth via `[inputs.http.headers]`. Containerized Telegraf needs
  `network_mode: host` where the host firewall drops bridge→host, plus
  `user: telegraf` + `group_add: <host docker GID>` (varies per host) and
  `/:/hostfs` for host metrics. Validate with `telegraf --test` (include
  `--user telegraf --group-add <gid>` to exercise the docker input).
