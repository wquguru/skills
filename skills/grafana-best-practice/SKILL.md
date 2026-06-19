---
name: grafana-best-practice
description: Review, improve, organize, deploy, and verify Grafana dashboards, provisioned alert rules, and the Telegraf→InfluxDB→Grafana monitoring stack. Use when working on Grafana dashboards, dashboard folders, tags, legends, panel readability, Flux/InfluxDB queries, Prometheus/Telegraf dimensions, Telegraf JSON/HTTP scraping, anonymous access, dashboard/alert provisioning, Grafana Docker deployments, provisioned alert rules and Flux alert conditions, contact points and Telegram/notification delivery, or requests like "review this dashboard", "optimize Grafana panels", "fix legends", "move dashboards into a folder", "add tags", "set up Grafana alerting", "alert won't fire / won't deliver", "fix Telegram alerts", "route alerts to a Telegram topic/thread (message_thread_id)", "bump/upgrade the Grafana version", "deploy and verify dashboards", or "Grafana best practices".
---

# Grafana Best Practice

Use this skill to make Grafana dashboards readable, correctly aggregated, navigable, and safely deployable. Treat the rendered dashboard, Grafana API state, datasource query results, and container health as the source of truth.

## Core Workflow

1. Inspect the current dashboard JSON and provisioning files before editing:
   - Dashboard JSON: `uid`, `title`, `tags`, `templating.list`, `links`, `panels`.
   - Provisioning: `provisioning/dashboards/*.yaml`, especially `folder`, provider `path`, and `allowUiUpdates`.
   - Runtime state when available: `/api/search`, `/api/folders`, `/api/dashboards/uid/<uid>`, `/api/ds/query`, `/api/health`.
2. Audit dashboards for:
   - Filters: default values, multi/all behavior, variable labels, and whether All views preserve required dimensions.
   - Aggregation dimensions: each metric's real labels — a per-instance/shard id, per-event labels (e.g. `symbol`, `reason`, `side` in a trading app), `container_name` for containers, and host-level metrics that carry none of these.
   - Legend placement, values, sorting, and display names.
   - Long labels leaking into stat cards or legends, such as `environment`, `project`, `url`, or raw Prometheus family names.
   - Bar chart sorting and limits.
   - Anonymous/read-only access if the dashboard is public.
3. Patch dashboard JSON narrowly and preserve existing panel intent.
4. Validate locally with JSON parsing, repository tests, and static checks.
5. Validate queries against the real datasource before deployment when possible.
6. Deploy through the repository's normal provisioning path.
7. Verify post-deploy using live Grafana API and datasource query results. Do not rely only on file diffs.

## Folder And Tag Rules

Prefer a named Grafana folder when permissions are known to be handled. For provisioned Grafana OSS dashboards with anonymous access, verify folder permissions explicitly because named folders can 403 even when dashboards exist.

Safe folder checklist:

- `provisioning/dashboards/default.yaml` uses the intended folder, for example `folder: Trader`.
- Startup or deployment code grants Viewer read on every provisioned folder and dashboard when Grafana state is ephemeral.
- `/api/folders` shows the folder.
- `/api/search?type=dash-db&tag=<base-tag>` shows every dashboard with the expected `folderTitle`.
- Anonymous probes return `200` for both `/d/<uid>/...` and `/dashboards`.

Use one stable base tag for dashboard links and discovery, then add semantic tags. Keep tags low-cardinality and queryable.

Recommended tag shape — one stable base tag (the service slug) plus semantic axes. The values below are an illustrative set from a trading app; substitute your own facets:

```text
<service>                     # stable base tag, e.g. `trader`
area:<facet>                  # e.g. area:overview | area:trading | area:risk | area:infra
audience:<role>               # e.g. audience:operator | audience:oncall
plane:<data-plane>            # e.g. plane:prometheus | plane:trade | plane:host
```

Keep dashboard dropdown links on the stable base tag (the service slug, e.g. `trader`) so adding semantic tags does not break navigation.

## Variables And Filters

Use explicit labels that explain important defaults:

```json
{
  "name": "instance",
  "label": "Instance (All by default)",
  "multi": true,
  "includeAll": true,
  "allValue": ".*"
}
```

For high-level fleet dashboards, defaulting `instance` to All is good only if every panel handles All safely. When All is selected:

- Stat panels should either show one compact value per instance or deliberately aggregate fleet-wide.
- Time series panels should not collapse multiple instances into one unlabeled series.
- Legends and display names should stay short.

## Flux And Dimension Rules

For Telegraf `metric_version = 2`, Prometheus metrics land as measurement `prometheus`, with the metric name as `_field` and each Prometheus label as a tag (the field name below, `<metric_name>`, is e.g. a trading app's `trader_total_value_usdt`):

```flux
from(bucket: v.defaultBucket)
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "prometheus")
  |> filter(fn: (r) => r["instance"] =~ /${instance:regex}/)
  |> filter(fn: (r) => r._field == "<metric_name>")
```

Preserve the metric's real grouping label after renaming the field (here a per-instance/shard label):

```flux
  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)
  |> set(key: "_field", value: "Total value")
  |> keep(columns: ["_time", "_value", "_field", "instance"])
  |> group(columns: ["instance", "_field"])
```

Avoid collapsing multiple series into one unlabeled series:

```flux
  |> keep(columns: ["_time", "_value"])
  |> set(key: "_field", value: "total_value")
  |> group(columns: ["_field"])
```

Use each plane's true dimensions — they differ by data source:

- Per-instance metric plane: keep the instance/shard label plus a friendly `_field`.
- Event plane (high-cardinality per-event rows): group by the instance/shard label when comparing instances; group by per-event labels (e.g. `symbol`, `reason`, `side` in a trading app) only when the panel intentionally aggregates across the selected instances.
- Host infra plane: do not invent an `instance`/shard label the measurement doesn't have. Host CPU/memory/disk are usually fleet/host-level.
- Docker/container plane: keep and display `container_name`.

When using `map()` to turn labels into friendly series names, finish with a bounded keep/group (this example maps a trading app's exit-`reason` label):

```flux
  |> map(fn: (r) => ({ r with _field:
    if r.reason == "stop_loss" then "Stop-loss"
    else if r.reason == "take_profit" then "Take-profit"
    else "Other" }))
  |> keep(columns: ["_time", "_value", "_field", "instance"])
  |> group(columns: ["instance", "_field"])
```

## Panel Readability Standards

Stat and gauge panels:

- Set `fieldConfig.defaults.displayName` to a short value, often `${__field.labels.instance}` for per-instance cards.
- Query with backend `last()` when the panel only needs the current value.
- Do not allow raw names like `trader_total_pnl_usdt {environment="...", url="..."}` to render in compact cards.

Time series panels:

- Prefer right-side table legends for operational dashboards:

```json
"legend": {
  "displayMode": "table",
  "placement": "right",
  "calcs": ["last", "max"],
  "sortBy": "Last",
  "sortDesc": true
}
```

- When the worst/lowest value is what matters (e.g. PnL, returns, win rate, free disk, error budget), sort ascending or include `min`.
- Set a compact display name, for example `${__field.labels.instance} ${__field.name}` or `${__field.labels.container_name}`.
- Use tooltip sorting consistent with legend sorting.

Bar charts:

- Sort by `_value`.
- For loss/PnL attribution, sort ascending to put the worst contributors first.
- For counts, volume, holding time, or pressure, sort descending.
- Hide legends when category labels already carry the meaning.

## Alerting Rules And Notifications

When configuring or debugging provisioned alert rules, contact points, or notification delivery (Telegram chat_id / supergroup / topic `message_thread_id`, parse-mode escaping, live rule-health and delivery verification), read [references/alerting.md](references/alerting.md).

## Deployment And Verification

When deploying dashboards/alerts, bumping the Grafana major version, running the minimum post-deploy verification curls, or wiring the compose + Telegraf monitoring stack, read [references/deployment.md](references/deployment.md).

## Review Output

When reviewing or finishing work, report evidence, not just intent:

- Files changed.
- Dashboard count and panel query count verified.
- Folder and tag API evidence.
- Anonymous access probes.
- Datasource query result summary.
- Alert rule health (`/api/.../rules` all `ok`) and a real delivery test, when alerting changed.
- Container/service health.
- Any risks intentionally left unchanged.

If a validation failure appears, fix the dashboard and rerun the relevant static, API, and datasource checks before declaring completion.
