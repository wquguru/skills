---
name: grafana-best-practice
description: Review, improve, organize, deploy, and verify Grafana dashboards, provisioned alert rules, and the Telegraf→InfluxDB→Grafana monitoring stack. Use when working on Grafana dashboards, dashboard folders, tags, legends, panel readability, Flux/InfluxDB query correctness or performance, Prometheus/Telegraf dimensions, Telegraf JSON/HTTP scraping, anonymous access, dashboard/alert provisioning, Grafana Docker deployments, high CPU or memory caused by dashboard queries, provisioned alert rules and Flux alert conditions, contact points and Telegram/notification delivery, or requests like "review this dashboard", "optimize Grafana panels", "why is this dashboard slow / using CPU", "fix legends", "move dashboards into a folder", "add tags", "set up Grafana alerting", "alert won't fire / won't deliver", "fix Telegram alerts", "route alerts to a Telegram topic/thread (message_thread_id)", "bump/upgrade the Grafana version", "deploy and verify dashboards", or "Grafana best practices".
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
   - Table column headers — no field-wide `defaults.displayName` (it overrides every column); columns renamed via the `organize` transform.
   - Multi-bucket / `union()` queries — every `filter()` pushed inside each `from()` (predicate pushdown), never after `union()`.
   - Query cost: panel count, target count, default time range, refresh interval, high-cardinality tags, expensive reshape operators, and whether current-value panels scan the whole dashboard range.
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

The InfluxDB Flux datasource IGNORES `legendFormat` — series names come from the frame's group-key labels plus the panel's `displayName` (`${__field.labels.x}`). To name or split synthetic series, add the value as a tag AND make it a group key so it becomes a real label, then render via `displayName` (a bare `set()` not in the group key is NOT exposed as a label):

```flux
  |> set(key: "leg", value: "spot")     // not a label on its own
  |> group(columns: ["venue", "leg"])   // group key -> real label -> ${__field.labels.leg}
```

When a time series panel hides high-cardinality tags behind a smaller visible
legend, collapse the hidden dimensions before returning data to Grafana. A common
failure is `aggregateWindow() |> difference() |> map(series: ...) |> keep(...)
|> group(columns: ["series"])`: this unions source/topic/status shards into one
visible frame without reducing duplicate `_time` rows, so Grafana reports "too
many datapoints" even though `v.windowPeriod` is present. After computing the
visible series label, group by `_time` plus that label and apply the reducer that
matches the metric:

```flux
  |> keep(columns: ["_time", "_value", "series"])
  |> group(columns: ["_time", "series"])
  |> sum()  // counters/deltas; use max() for worst latency/saturation, mean() only when intentional
  |> group(columns: ["series"])
```

For ratios and derived costs, aggregate the numerator/denominator or token
classes at `_time` + visible dimensions before `pivot()` and division. Do not
calculate per-hidden-shard ratios and then merely regroup them under one legend;
that both overproduces datapoints and changes the math.

Filter data-quality-suspect rows (error / stale / thin / "unsafe" states) out of headline stat, leaderboard, and min/max-extreme panels — otherwise the "max" is a noise artifact, not a signal. It also bounds cost: excluding churning bad-status series cuts the rows an extremes query scans.

## Query Performance Rules

When investigating slow dashboards, high InfluxDB CPU/memory, or Grafana query
timeouts, treat live dashboard JSON and datasource query results as evidence.
Do not stop at visual inspection.

Audit the query surface first:

- Count panels and target queries; one dashboard refresh can fire all targets.
- Check default time range and refresh interval. A 6h dashboard with many
  high-cardinality queries can scan millions of points per refresh.
- Identify high-cardinality tags (`sourceId`, `sourceName`, `url`, `status`,
  error labels, raw request ids) that are grouped or preserved but hidden behind
  a small visible legend.
- Flag expensive operators on wide streams: `pivot()`, `spread()`, `join()`,
  large `map()` condition trees, and `sort()` before `limit()`.
- Push selective filters on `_measurement`, `_field`, status, path, and
  provider/model before reshape or `map()`.

Use cheaper producer-provided fields when they exist. Do not recompute derived
costs or ratios from several cumulative token/counter fields inside Grafana when
a backend-recorded cumulative field such as `estimatedCostUsd` already exists.
For range totals on cumulative per-label rows, filter to the single derived field,
then use `spread() |> group() |> sum()`.

For cumulative time-series trend panels, `aggregateWindow(every:
v.windowPeriod, fn: last) |> difference()` can still be too expensive when it
runs over high-cardinality raw series. If the panel must stay operational, bound
the lookback and bucket size explicitly, then use per-window `spread()` before
collapsing hidden dimensions:

```flux
from(bucket: v.defaultBucket)
  |> range(start: -6h)
  |> filter(fn: (r) => r._measurement == "..." and r._field == "estimatedCostUsd")
  |> aggregateWindow(every: 15m, fn: spread, createEmpty: false)
  |> group(columns: ["_time", "path", "provider", "model"])
  |> sum()
```

Name and describe the panel honestly, for example "(last 6h)" and "15m
buckets". For multi-field ratios such as cache-hit rate, a 15m bucket can still
timeout because both numerator and denominator streams must be windowed and
pivoted; test coarser buckets such as 1h, or use a single overall point for the
bounded lookback if the operational question allows it. If this still times out,
add producer-side or Telegraf rollup metrics at the visible dashboard grain
instead of repeatedly deriving them in Grafana.

For current-state panels, use bounded fixed windows instead of the dashboard
range. Queue depth, breaker state, coverage, latest table rows, liveness, and
other "now" values should usually query `range(start: -15m)` or a similarly
small scrape-tolerant window plus `last()`. They should not scan 24h or 7d just
because the user changed the dashboard time picker.

Replace "map unwanted rows to zero" with early filters when the intent is to
exclude them:

```flux
  |> filter(fn: (r) => r._field == "requests" and r.status != "success")
  |> spread()
  |> group()
  |> sum()
```

Validate performance changes against the real datasource:

- Run old/new representative queries with narrow windows first; record elapsed
  time when possible, or at least HTTP status, frame counts, and errors.
- Use `/api/ds/query` when available so variables, datasource config, and auth
  match Grafana. Validate every changed panel target, not just one sample.
- Compare result semantics for key stats where possible. If switching from
  dashboard-side recomputation to a backend-derived field, state why the backend
  field is authoritative enough.
- After deploy, fetch live dashboard JSON and prove the optimized query is what
  Grafana is serving; provisioned files alone are not proof.
- Check datasource/container health after heavy-query work, especially InfluxDB
  CPU, memory, restarts, and recent query-cancel or OOM logs when accessible.

## Long-Term Retention And Downsampling

For data kept beyond a few weeks, run a dual-bucket scheme: a raw bucket (short retention) plus a downsampled long-term bucket fed by a scheduled task (InfluxDB task: `aggregateWindow(every: 5m, fn: mean)` raw → 1y bucket; provisioned reproducibly, and since `initdb.d` only runs on a fresh volume, the provisioning script must be idempotent and hand-applied once to a pre-existing volume). Downsample only analytical/business series; leave ops/infra (cpu/mem/docker/liveness) on the raw bucket — nobody needs a year of CPU%. DROP churning tags in the rollup (status flags, "best route" tags): they dominate long-term cardinality and the long-range view is for trends, not live filtering. For sparse per-event series (funding settlements, fills) MIRROR raw 1:1 with a wide idempotent lookback instead of aggregating — there is nothing to compress, and a narrow rolling window permanently drops any point a run missed.

To make ONE panel span both tiers, `union()` raw + downsampled:

```flux
src = (b) => from(bucket: b)
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "carry_pair")
  |> filter(fn: (r) => r._field == "mid_basis_bps")
  |> filter(fn: (r) => r["asset"] == "${asset}")    // ALL predicates go IN HERE
union(tables: [src(b: v.defaultBucket), src(b: "carrywatch_1y")])
  |> group(columns: ["venue"])
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
```

CRITICAL — push every `filter()` INSIDE each `from()` BEFORE `union()`. A `filter()` placed AFTER `union()` is NOT pushed down to storage: each `from()` then full-scans the WHOLE bucket into memory before filtering, which over a high-cardinality measurement OOMs/pegs the database and can wedge a shared host (sshd included — recovery may mean waiting out the swap-thrash). With pushdown the union costs the same as the single-bucket query. Corollary: never run an unfiltered/heavy ad-hoc Flux query against a shared production datasource; validate heavy queries with tight filters + `count()` first, and prefer restarting the DB container to free a runaway query over waiting.

## Panel Readability Standards

Dashboard information architecture:

- For operational, cost, reliability, or on-call dashboards, start with an
  answer-first summary row before trend panels. The first viewport should let a
  reader decide whether the system is healthy without reading graphs.
- Put the main operating questions in that top row, using compact stat panels:
  cost or spend in the selected time range, request or event volume, error rate
  or failed request count, worst or p95 latency, queue depth and oldest age,
  circuit-breaker / provider / dependency state, and important backlog,
  coverage, freshness, or saturation values.
- Use correct stat semantics. Counters and cumulative scrape values need
  range-correct deltas or increases, not lifetime totals. Gauges such as queue
  depth, breaker state, coverage, disk, and health should use the latest value.
  Latency and saturation should show p95, max, or the worst relevant value when
  the question is operational risk, not only averages.
- If a metric is unavailable, unknown, or provider-dependent, say so explicitly
  in panel title, description, or value mapping instead of implying precision.
- After the summary row, place explanatory panels in reading order: trend over
  time, volume by dimension, errors by dimension, latency by path/service, top
  contributors, queues/backlog, and detail tables.
- Avoid fake summary rows. A single full-width stat panel is not a summary row
  unless it answers the whole first-viewport operating question by itself.
  Multiple dimension-split series inside one compact stat card are also usually
  not a summary row; aggregate to a deliberate fleet/service value, or split
  into clearly labeled per-dimension cards.
- Watch Flux grouping before `count()`, `sum()`, or stat reducers. If a stat
  should show one fleet-wide total, collapse the group key first with `group()`;
  `group(columns: ["container_name"]) |> count()` usually produces one count per
  container rather than the total container count. Preserve dimensions only when
  the panel is intentionally comparing those dimensions and the display names
  make that obvious.
- Do not hide first-viewport risk below the fold. Host disk/memory saturation,
  restart deltas, failing probes, queue age, and breaker/dependency state belong
  in the top row when they determine whether an operator should act now.

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

Table panels:

- NEVER set `fieldConfig.defaults.displayName` on a table — it overrides EVERY column's header to that one string (so Venue / Asset / Status all render as e.g. "funding APR"). Rename columns in the `organize` transform's `renameByName`; color/format per column via field overrides matched `byName` on the renamed value.
- Flux: `pivot(rowKey: [...], columnKey: ["_field"], valueColumn: "_value")` turns fields into columns, then `organize` to order + rename.

## Alerting Rules And Notifications

When configuring or debugging provisioned alert rules, contact points, or notification delivery (Telegram chat_id / supergroup / topic `message_thread_id`, parse-mode escaping, message-template/body composition — group-label-in-header DRY, no-text-color emphasis, resolved-only context — live rule-health and delivery verification), read [references/alerting.md](references/alerting.md).

## Deployment And Verification

When deploying dashboards/alerts, bumping the Grafana major version, running the minimum post-deploy verification curls, or wiring the compose + Telegraf monitoring stack, read [references/deployment.md](references/deployment.md).

## Review Output

When reviewing or finishing work, report evidence, not just intent:

- Files changed.
- Dashboard count and panel query count verified.
- Folder and tag API evidence.
- Anonymous access probes.
- Datasource query result summary.
- Query performance evidence when performance changed: target count, expensive
  operators removed, bounded time windows added, old/new query result or timing
  comparison, and live dashboard JSON proof after deploy.
- First-viewport summary row evidence for operational dashboards: key stat
  cards render, use range-correct semantics, and are not blank when expected
  data exists.
- Alert rule health (`/api/.../rules` all `ok`) and a real delivery test, when alerting changed.
- Container/service health.
- Any risks intentionally left unchanged.

If a validation failure appears, fix the dashboard and rerun the relevant static, API, and datasource checks before declaring completion.
