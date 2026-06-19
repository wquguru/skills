# Alerting Rules And Notifications

Provisioned Grafana-managed alert rules use a 3-stage chain: refId `A` = the
datasource query (`datasourceUid` = your InfluxDB uid), `B` = `reduce`
(last/max), `C` = `threshold`; `B`/`C` use `datasourceUid: __expr__` and
`condition: C`.

Alert-rule Flux differs from panel Flux: the reduce/threshold expression
(`__expr__`) wants the per-series time-series frames the InfluxDB datasource
returns, not a reshaped table. (Flux/InfluxDB-datasource specific; PromQL/other
datasources don't hit this.)

- A trailing `|> group(columns: [...])` often reshapes the result into a "long"
  frame and the reduce step then fails with `[sse.readDataError] input data must
  ...`. Default to leaving the datasource's per-series frames — the reducer
  yields one alert instance per series, tag available as `{{ $labels.<tag> }}`.
  Add `group()` only when you deliberately need to aggregate across series, and
  re-check the rule's health afterward.
- If `increase()` / `derivative()` trip the reducer with the same error,
  `spread()` (max − min over the window ≈ a monotonic counter's growth) is a
  robust alternative — it returns one scalar per series and reduces cleanly.
- `noDataState: Alerting` only where silence == failure (liveness / "down"
  rules, where a stopped scrape IS the signal); everything else `OK` so an empty
  query never phantom-pages.

Notification delivery (Telegram, but the lesson generalizes):

- `parse_mode: HTML`/`Markdown` rejects alert summaries containing `<`, `>`, or
  `&` (e.g. "queue > 50", "code < 200") with `400 can't parse entities`. Use
  plain text (`parse_mode: None`) + emojis unless every dynamic field is escaped.
  Generate the contact point at container start so numeric chat IDs are
  string-typed (Grafana 10.x numeric-chatid bug).
- A Telegram group upgraded to a supergroup CHANGES its chat_id: the old id 400s
  `group chat was upgraded to a supergroup chat`; the new `-100…` id is in the
  error's `parameters.migrate_to_chat_id`. Fix it once in the env — the same
  creds usually feed other app pushes too.
- **Forum/topic supergroups need `message_thread_id`.** Enabling Topics on a group
  converts it to a supergroup (so the chat_id changes too, per the bullet above) and
  gives each topic a numeric thread id. A message sent WITHOUT `message_thread_id`
  lands in the General topic — a silent "wrong place", not an error. Grafana's Telegram
  contact point gained `message_thread_id` only in **10.4** (a UI bug that marked the
  field required was fixed in **10.4.1**); on older Grafana, routing to a topic REQUIRES
  a version bump. In a provisioned/generated contact point it's just another setting
  beside `chatid`: `message_thread_id: "<n>"` — emit it ONLY when configured, since an
  empty/`0` thread id is rejected. Find a topic's thread id from the Bot API
  `getUpdates` (`message.message_thread_id` / `forum_topic_created`) or a get-id bot.
- **Audit EVERY Telegram sender, not just Grafana.** A chat_id or topic change breaks
  every place that posts to the group — Grafana alerts, the app's own notification
  pushes, and ops "send test" buttons can each have their own `sendMessage`. Grep the
  whole repo (`sendMessage`, `api.telegram.org`) and update each independently; the
  Grafana contact point does NOT cover app-level pushes, and each needs its own
  `message_thread_id`.
- **Inline keyboard button URLs must be public http(s).** Telegram rejects buttons that
  point at internal hostnames (e.g. a Docker service name, `http://grafana:3000/...`)
  with `400 ... button URL ... is invalid: Wrong HTTP URL`, which fails the whole send.
  Build button URLs from the public base (e.g. Grafana's `GF_SERVER_ROOT_URL`), not the
  in-network address.

Verify alerting against the live system, not file diffs:

- Rule health: `GET /api/prometheus/grafana/api/v1/rules` — every rule's
  `health` must be `ok`. An `error` means its Flux/expr is broken (e.g. the
  trailing-group trap above). This is the alerting analog of running panel
  queries through `/api/ds/query`.
- Delivery & routing: `POST /api/alertmanager/grafana/config/api/v1/receivers/test`
  (admin auth) IS a fast, faithful check that the bot token, `chatid`, and
  `message_thread_id` actually reach the target — it returns a per-receiver
  `status:"ok"` and really posts the message, or an error status (Telegram's 4xx
  description) if the token/chat/thread is invalid. Use it for credential, chat_id,
  and topic changes. It is NOT a faithful **template** preview, though: it sends a
  built-in test payload, so a custom message template can render incompletely or error
  on missing labels ("Missing receiver / group labels").
- Template / end-to-end: to validate the actual rule + rendered message body, fire a
  real short-lived canary rule (provisioning API + header `X-Disable-Provenance: true`,
  `for: 10s`, an always-true threshold such as cpu `usage_idle` > -1), then read the
  Grafana log for `Notify for alerts failed ... webhook response status 4xx`. Delete the
  canary after. (Folder UID is random per boot on tmpfs Grafana — resolve folders by
  title.)
