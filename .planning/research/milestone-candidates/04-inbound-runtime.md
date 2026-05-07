# Milestone Candidate: Inbound Operator/Runtime Tooling (v1.2)

## Verdict

**Ship in v1.2 (Tier-1):** `mix mailglass.inbound.doctor`, `mix mailglass.inbound.replay`, `mix mailglass.inbound.prune`, inbound telemetry spans (ingress/route/execute/persist), per-tenant + per-sender ingress rate limit.

**Ship in v1.2 (Tier-2):** suppression cross-check at ingress (flag-only, no auto-bounce), 1000-replay convergence property test for inbound.

**Defer to v1.3:** auto-suppression of inbound flooders, MX/relay reachability checks (only meaningful when relay-mode lands; today only Postmark/SendGrid HTTPS providers ship — `ingress/providers/`), provider-side inbound bounce policy hooks.

Rationale: inbound v1.1 shipped the data plane (`Ingress.Plug`, `Internal.Replay`, Oban worker) but **zero `:telemetry` calls exist in `mailglass_inbound/lib/`** (verified via grep) and there are **no mix tasks** in `mailglass_inbound/lib/mix/` — every operator concern outbound got across v0.4–v0.6 is missing for the inbound sibling.

## Tool Inventory

| Mix Task | Function | Complexity | Outbound Analog |
|---|---|---|---|
| `mailglass.inbound.doctor` | DNS-free correctness check: routes compile + don't conflict (use `Router.Matcher`); mailbox modules implement `MailglassInbound.Mailbox` behaviour; provider signature config present (`Application.get_env(:mailglass_inbound, :postmark/:sendgrid)`); `CachingBodyReader` wired in endpoint. **Skip MX/HTTPS reachability** until relay-mode exists. Exit-coded, `--format json`. | S | `mix mail.doctor` (`lib/mix/tasks/mail.doctor.ex`, DNS-only, exit-coded, json/human) |
| `mailglass.inbound.replay` | CLI wrapper over `MailglassInbound.Internal.Replay.replay/2`. Modes: `--id <uuid>` (single), `--tenant-id X --from ISO --to ISO` (window), `--since-no-match` (replay all `:no_match` runs after a route fix — the canonical reason replay exists). `--dry-run` prints what would execute without dispatching. | S–M | none direct; closest is `mailglass.reconcile` argv shape |
| `mailglass.inbound.prune` | Retention sweep over `mailglass_inbound_records`, `mailglass_inbound_evidence` (cascade), `mailglass_execution_runs`, `mailglass_replay_runs`. Config keys: `inbound_retention: [records_days: 90, evidence_days: 30, execution_runs_days: 90, replay_runs_days: 30]`, each `pos_integer | :infinity`. Oban cron when available, mix task fallback. | S | `mix mailglass.webhooks.prune` + `Mailglass.Webhook.Pruner` (`lib/mix/tasks/mailglass.webhooks.prune.ex`) |

All three follow the **`Mix.Task.run("app.start")` + `OptionParser.parse(strict:)` + `Mix.raise` on validation failure** pattern locked in by `mailglass.suppressions.resync` and `mail.doctor`. Reuse `Boundary, classify_to: Mailglass`.

## Rate Limiting

**Recommendation:** wire ingress-stage rate limit, not execution-stage.

- **Where:** inside `MailglassInbound.Ingress.Plug.call/2`, after `verify_request!` and `resolve_tenant!`, before `normalize_request!` + `persistence.persist`. Refusing post-verify is correct: signature-valid requests from a saturating sender still consume DB writes.
- **Buckets** (extend `Mailglass.RateLimiter`'s multi-bucket pattern from `lib/mailglass/rate_limiter.ex`):
  - `:inbound_tenant` — `{tenant_id}` — capacity 1000/min default
  - `:inbound_sender_domain` — sender envelope domain — capacity 200/min default (DoS guard against single-domain floods)
  - `:inbound_recipient` — `{tenant_id, envelope_recipient}` — capacity 500/min default (mailbox-level shielding)
- **No `:transactional` bypass** — that invariant is outbound-specific (D-24).
- **On bucket depletion:** return HTTP 429 with `Retry-After`. Provider behavior: Postmark + SendGrid both retry on 429 (verified: SendGrid Inbound Parse retries up to 3 days; Postmark requeues), so back-pressure works correctly.

## Suppression Integration

**Recommendation:** cross-check + flag, do **not** auto-bounce in v1.2.

If the sender envelope address matches an active row in `mailglass_suppressions` for that tenant, persist the inbound record normally but stamp `inbound_evidence.flags: ["sender_suppressed"]` and emit `[:mailglass_inbound, :ingress, :sender_suppressed]` telemetry. Mailboxes can opt into rejecting via a `process/1` policy on their own.

Why not auto-bounce: a suppressed *outbound* recipient (they hard-bounced our mail) sending us inbound is **diagnostically valuable** — typically a forwarder, a retry from a now-fixed mailbox, or a complaint reply. Silent-dropping it loses signal. ActionMailbox does not auto-bounce; Anymail (Django) treats inbound + suppression as orthogonal concerns. v1.3 can layer opt-in `auto_bounce_suppressed: true` once we have user feedback.

## Retention Policy

Defaults proposed:
- `inbound_records`: 90 days (raw text/html bodies are the heaviest column, and most ops only need <30 days for debugging)
- `inbound_evidence` (raw provider payload + verification facts): 30 days (forensics window only)
- `execution_runs`: 90 days
- `replay_runs`: 30 days

Pattern mirrors `Mailglass.Webhook.Pruner` exactly: Oban cron entry under optional `if Code.ensure_loaded?(Oban.Worker)`, `available?/0` predicate, mix task fallback for Oban-less adopters, `:succeeded_days | :infinity` config knobs, `[:mailglass_inbound, :prune, :stop]` telemetry with `%{records_deleted, evidence_deleted, execution_runs_deleted, replay_runs_deleted}` measurements.

## Telemetry Gap Analysis

**Current state: zero events.** `grep -rn ':telemetry\|telemetry\.' mailglass_inbound/lib/` returns nothing. This is the largest gap.

Required spans (start/stop/exception, all on `[:mailglass_inbound, ...]`):
- `[:ingress, :verify]` — provider signature/basic-auth check
- `[:ingress, :persist]` — `Ingress.Persist.persist/2`
- `[:route, :match]` — `Router.Matcher` resolution; metadata `%{matched: bool, mailbox: atom_or_nil}`
- `[:execute, :mailbox]` — wrap `Execution.classify_mailbox_result/3` (currently rescues silently — exception telemetry would surface mailbox bugs immediately)
- `[:replay, :execute]` — `Internal.Replay.replay/2`
- `[:prune, :stop]`, `[:rate_limit, :stop]` — match outbound naming

**PII whitelist:** metadata limited to `tenant_id`, `provider`, `mailbox` (atom), `outcome`, `route_status`, counts, durations. **Never** `:from`, `:to`, `:subject`, `:envelope_recipient`, `headers`, body fields. Same rules as outbound (CLAUDE.md "Things Not To Do" #3).

## Idempotency

Already present: `unique_constraint(:provider_message_id, name: :mailglass_inbound_records_postmark_idempotency_idx)` in `inbound_record.ex` plus Oban worker `unique: [period: 3600, fields: [:args], keys: [:inbound_record_id, :source]]`. This is structurally equivalent to outbound's `IdempotencyKey`. **Add** the convergence property test (mirror outbound's 1000-replay test): replay one record N times, assert exactly one `execution_run` per `{inbound_record_id, source: :replay}` cohort beyond the seed and stable terminal `outcome`.

## Anti-Patterns to Avoid

1. **Don't add MX/HTTPS reachability checks to `inbound.doctor` until relay-mode ships.** Today inbound is HTTP-webhook-only via `Ingress.Plug`; probing `MX` records is meaningless and would mislead operators.
2. **Don't auto-suppress inbound senders on rate-limit trip.** Trips are noisy (legitimate burst from a CRM mass-reply) and the suppression list is a *delivery* contract, not an inbound-firewall. Use 429 + telemetry.
3. **Don't `UPDATE` the inbound replay table to mark "replayed".** The execution-runs table already records `source: :replay` rows and is append-only-shaped; add another row, don't mutate.
4. **Don't run `inbound.prune` cascade-deletes inside a single transaction over the full retention window.** Batch by `LIMIT 1000` like `Webhook.Pruner` does or risk replication lag spikes.
5. **Don't put recipient or sender addresses in rate-limit telemetry metadata** — outbound `RateLimiter` already learned this (see PII note in `rate_limiter.ex` line 43).

## References

1. `lib/mix/tasks/mail.doctor.ex` — exit-coded, `--format json`, `Mix.raise` validation idiom.
2. `lib/mix/tasks/mailglass.webhooks.prune.ex` + `Mailglass.Webhook.Pruner` — Oban-optional pruner pattern with mix-task fallback.
3. `lib/mailglass/rate_limiter.ex` — multi-bucket ETS token bucket, telemetry/PII rules.
4. `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` — replay primitive ready for CLI wrapping.
5. ActionMailbox `Inbound::ConductorsController` retention semantics (Rails default 30 days for `raw_email`, configurable) — informs our `evidence_days: 30` default.
