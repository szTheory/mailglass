---
phase: 04-webhook-ingest
plan: 07
subsystem: webhook
tags: [oban, cron, reconciler, pruner, retention, append_only, d16, d17, d18, d20, d22, d23]

# Dependency graph
requires:
  - phase: 04-webhook-ingest
    plan: 01
    provides: "V02 migration (mailglass_webhook_events table + needs_reconciliation column on mailglass_events); @mailglass_internal_types includes :reconciled"
  - phase: 04-webhook-ingest
    plan: 06
    provides: "Mailglass.Webhook.Ingest inserts orphan mailglass_events rows with delivery_id: nil + needs_reconciliation: true; Mailglass.Webhook.WebhookEvent schema + :status state machine (:received → :processing → :succeeded | :failed → :dead)"
  - phase: 02-persistence-tenancy
    provides: "Mailglass.Events.Reconciler.find_orphans/1 + attempt_link/1 (pure-query helpers); Events.append_multi/3 function form; Outbound.Projector.update_projections/2 + broadcast_delivery_updated/3"
  - phase: 01-foundation
    provides: "Mailglass.OptionalDeps.Oban.available?/0; Mailglass.Clock.utc_now/0; Mailglass.Application :persistent_term-gated boot-warning idiom; Mailglass.Repo facade"
provides:
  - "Mailglass.Webhook.Reconciler — Oban cron worker; queue :mailglass_reconcile; unique: [period: 60]; D-17/D-18 append-based reconciliation (NEVER UPDATEs orphan rows)"
  - "Mailglass.Webhook.Pruner — Oban cron worker; queue :mailglass_maintenance; D-16 three-knob retention with :infinity bypass"
  - "Mix.Tasks.Mailglass.Reconcile + Mix.Tasks.Mailglass.Webhooks.Prune — Oban-absent fallbacks per D-20"
  - "Mailglass.Application extended with maybe_warn_missing_oban_for_webhook_workers/0 — SINGLE consolidated Logger.warning (revision W2 option b) covers both workers"
  - "Mailglass.Config :webhook_retention NimbleOptions sub-tree with succeeded_days/dead_days/failed_days knobs (D-16)"
  - "Mailglass.Repo.delete_all/2 — new facade passthrough for Pruner DELETE-by-status+age; NO SQLSTATE 45A01 translation (that trigger fires only on mailglass_events per D-15 split)"
affects: [04-08, 04-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Oban-conditional compile gating: entire worker module body wrapped in `if Code.ensure_loaded?(Oban.Worker) do ... end`; sibling `available?/0` top-level function (also @compile {:no_warn_undefined}) exposed for callers (mix tasks + boot warning) so probe-site doesn't need Code.ensure_loaded? at every callsite. When Oban absent: module compiles to just `available?/0` returning false; mix compile --no-optional-deps --warnings-as-errors passes cleanly."
    - "Append-based reconciliation (CONTEXT D-18): Reconciler.attempt_reconcile/1 calls Events.Reconciler.attempt_link/1 to locate the matched Delivery, then builds ONE flat Multi: Events.append_multi(:reconciled_event, ...) → Multi.update(:projection, ...). Wrapped in Repo.transact(fn -> Repo.multi(multi) end). The orphan mailglass_events row is STRUCTURALLY UNCHANGED — no UPDATE; preserves the SQLSTATE 45A01 append-only invariant."
    - "Projector applied with the ORPHAN event, NOT the new :reconciled event (Rule 1 auto-fix during execution): Mailglass.Outbound.Delivery.last_event_type Ecto.Enum deliberately excludes :reconciled — it is audit-only, not a lifecycle transition per D-14 amendment. Passing the :reconciled event to update_projections/2 would trigger Ecto.ChangeError. Passing the orphan (with its original :delivered/:bounced/etc. type) applies the provider's actual event to the delivery summary while the :reconciled ledger row records the audit moment."
    - "Idempotency key for the :reconciled event: `reconciled:<orphan.id>` — single deterministic key per orphan. Two concurrent reconciler workers on the same orphan collapse to ONE :reconciled row via the partial UNIQUE index on mailglass_events.idempotency_key WHERE idempotency_key IS NOT NULL. Structural duplicate prevention, no :unique worker opts needed at this layer."
    - "60-second grace window via past_grace?/1 post-filter on find_orphans/1 results: orphans younger than 60s may reflect an in-flight dispatch where the Delivery commit is still pending. find_orphans/1 itself filters by max_age_minutes (7 days); the grace filter is applied in-memory in the worker to keep Events.Reconciler's query surface unchanged (Phase 2 shipped as pure query; adding grace would be an API break)."
    - "Pruner three-knob retention (D-16): prune_status(status, :infinity) is a STRUCTURAL bypass that returns {:ok, 0} WITHOUT issuing the DELETE. Adopters who disable a retention class face zero DB cost — not a no-op query, not a filter. failed_days: :infinity is the DEFAULT so :failed rows (investigatable) are never deleted out-of-the-box."
    - "Consolidated boot warning (revision W2 option b): ONE Logger.warning covers BOTH Reconciler AND Pruner. Previous two-warning approach repeated the same operator-action text twice per boot; consolidating reduces log noise while still surfacing both workers. :persistent_term-gated via {:mailglass, :oban_warning_webhook_workers} so emitted exactly once per BEAM lifetime, mirroring the Phase 3 D-17 :oban_warning_emitted gate."
    - "Mailglass.Repo.delete_all/2 facade passthrough: added as a thin delegate to repo().delete_all. Used by Pruner for retention DELETEs. Does NOT translate SQLSTATE 45A01 (per moduledoc — that trigger fires only on mailglass_events UPDATE/DELETE; mailglass_webhook_events is intentionally mutable + prunable per CONTEXT D-15 split)."

key-files:
  created:
    - "lib/mailglass/webhook/reconciler.ex"
    - "lib/mailglass/webhook/pruner.ex"
    - "lib/mix/tasks/mailglass.reconcile.ex"
    - "lib/mix/tasks/mailglass.webhooks.prune.ex"
    - "test/mailglass/webhook/reconciler_test.exs"
    - "test/mailglass/webhook/pruner_test.exs"
  modified:
    - "lib/mailglass/application.ex (+ maybe_warn_missing_oban_for_webhook_workers/0 consolidated boot warning)"
    - "lib/mailglass/config.ex (+ :webhook_retention NimbleOptions sub-tree with three knobs)"
    - "lib/mailglass/repo.ex (+ delete_all/2 facade passthrough)"

key-decisions:
  - "Rule 1 AUTO-FIX: Reconciler's Multi.update(:projection, ...) passes the ORPHAN event, NOT the new :reconciled event. The plan's verbatim shape (Projector.update_projections(delivery, e) where e is the reconciled event) would trigger Ecto.ChangeError because Delivery.last_event_type enum deliberately excludes :reconciled per D-14 amendment (audit-only lifecycle event). Passing the orphan preserves the semantic intent (apply the provider's actual event to the delivery projection) while the :reconciled ledger row records the audit moment."
  - "Plan 07 deviated from plan text by separating available?/0 out of the conditional-compile block: when Oban is absent, the defmodule body is elided but `available?/0` remains defined (returns false). This lets mix tasks and the boot warning call Mailglass.Webhook.Reconciler.available?/0 without first doing Code.ensure_loaded?(Mailglass.Webhook.Reconciler) — simpler contract, matches Mailglass.OptionalDeps.Oban.available?/0 shape already shipped in Phase 1."
  - "Mailglass.Repo.delete_all/2 added as a new facade function rather than accessing Repo.repo().delete_all/2 (as the plan suggested). Reason: repo/0 is deliberately private to keep the facade narrow; exposing it for Pruner use would mean every future worker that needs delete_all can also grab raw repo access. Adding delete_all/2 as a typed passthrough matches the established facade pattern (all/2, one/2, get/3) and constrains the public surface to what mailglass genuinely needs."
  - "Grace window filter applied in-memory via past_grace?/1 in the worker (not in Events.Reconciler.find_orphans/1). Reason: find_orphans/1 shipped in Phase 2 as pure Ecto queries with a max_age_minutes upper bound; adding min_age_seconds to the query would be an API extension. Keeping the grace filter in the worker isolates policy (retry cadence) from mechanism (query). Tests confirm the grace filter works via the ':mailglass, :webhook, :reconcile, :stop' telemetry's scanned_count."
  - "Idempotency key for :reconciled events uses the STRING interpolation form `\"reconciled:\" <> to_string(orphan.id)` — not `Atom.to_string` or the standard IdempotencyKey.for_webhook_event/3 helper. Reason: the orphan id IS the deterministic discriminator (one :reconciled per orphan); adding a provider prefix or incrementing index would break the idempotency contract. Tests assert `reconciled.idempotency_key == \"reconciled:\" <> orphan.id` to lock this shape."
  - "Reconciler's Repo.transact result pattern-matches THREE cases: {:ok, {:ok, changes}} (Repo.multi returns {:ok, changes} inside transact), {:ok, {:error, _step, reason, _}} (Multi step failed), {:error, reason} (transact itself failed). The plan's simpler two-case pattern missed the Repo.multi/1 semantics where transact wraps the multi's return shape. Documented inline."
  - "Telemetry emission path differs between Reconciler and Pruner: Reconciler uses :telemetry.span/3 (full start/stop/exception triad — matches CONTEXT D-22 line 184 'full span per reconciler run'); Pruner uses :telemetry.execute/3 single-emit on [:webhook, :prune, :stop] (matches CONTEXT D-22 line 185 'single-emit per CONTEXT discretion'). Both stay D-23 whitelist-conformant — no PII, no raw payloads, no IPs."
  - "Mix task Boundary classification: `use Boundary, classify_to: Mailglass` added to both Mix.Tasks.Mailglass.Reconcile and Mix.Tasks.Mailglass.Webhooks.Prune — Mix.Tasks.* modules sit outside the default boundary classifier, which emits 'not included in any boundary' warnings under --warnings-as-errors. The classify_to directive attributes the task modules to the root Mailglass boundary (they're part of mailglass's user-facing surface, not external adopters)."
  - "CLAUDE'S DISCRETION — `concurrency: 1` implicit at :mailglass_reconcile queue: the Ecto optimistic locking on Delivery.lock_version + the partial UNIQUE index on idempotency_key already make concurrent reconciler runs structurally correct (duplicate :reconciled events cannot insert), but tightening queue concurrency to 1 reduces wasted retries. Adopters can raise concurrency in their own Oban config if they need parallel reconciliation across tenants."
  - "CLAUDE'S DISCRETION — GDPR erasure is documented as adopter-handled (NOT Pruner's responsibility): Pruner's DELETEs are retention-policy-driven (status + age), not identity-driven. Targeted DELETE on mailglass_webhook_events.raw_payload->>'to' = ? for GDPR requests is adopter ad-hoc via Mailglass.Repo.delete_all/2. Pruner moduledoc explicitly documents this split per PROJECT-level GDPR surface ownership."

patterns-established:
  - "Oban-optional worker pattern: modules that require Oban.Worker ship TWO surfaces — (1) a top-level `available?/0` returning Code.ensure_loaded?(Oban.Worker) for probing, (2) the worker body conditionally compiled. Plan 07's Reconciler + Pruner establish this shape; future Phase 5+ background workers (Plan 08 Telemetry dashboards, v0.5 async-ingest) follow the same convention."
  - "Reconciler telemetry measurements: [:mailglass, :webhook, :reconcile, :stop] metadata carries %{tenant_id, scanned_count, linked_count, remaining_orphan_count, status} — D-23 whitelist-conformant. Plan 08 (Telemetry) consumers read these keys for Grafana dashboard panels; Plan 09 (UAT) asserts the whitelist via refute Map.has_key?(meta, :ip)/:raw_payload/:recipient/etc."
  - "Pruner :infinity bypass discipline: any retention knob set to :infinity MUST return {:ok, 0} WITHOUT issuing the DELETE query. Tests assert this structurally (row count unchanged after prune/0). Future retention classes (e.g. v0.5 per-tenant retention override) follow the same pattern."

requirements-completed: [HOOK-06]

# Metrics
duration: 20min
completed: 2026-04-24
---

# Phase 4 Plan 7: Webhook Reconciler + Pruner + Oban-Optional Fallbacks Summary

**Oban cron workers for webhook orphan reconciliation (D-17/D-18) and retention pruning (D-16) ship conditionally-compiled behind `if Code.ensure_loaded?(Oban.Worker)`. Reconciler appends `:reconciled` events to the ledger — the orphan `mailglass_events` row is structurally unchanged, preserving the SQLSTATE 45A01 append-only trigger invariant. Pruner honors three retention knobs (`succeeded_days`/`dead_days`/`failed_days`) with `:infinity` bypass. Mix tasks `mix mailglass.reconcile` + `mix mailglass.webhooks.prune` ship as Oban-absent fallbacks (D-20). `Mailglass.Application` emits a single consolidated Logger.warning at boot when Oban is missing (`:persistent_term`-gated, revision W2 option b). `Mailglass.Config :webhook_retention` NimbleOptions sub-tree wires the three retention knobs. `Mailglass.Repo.delete_all/2` added as a typed facade passthrough for the Pruner. HOOK-06 orphan-handling loop closed.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-04-24T~21:50Z
- **Completed:** 2026-04-24T~22:10Z
- **Tasks:** 2 (Task 1 = Reconciler + Application warning + mix task; Task 2 = Pruner + Config + mix task)
- **Commits:** 2 task commits
  - `1a6d9f9` — feat(04-07): Mailglass.Webhook.Reconciler Oban worker + mix task fallback (Task 1)
  - `5f342e2` — feat(04-07): Mailglass.Webhook.Pruner Oban worker + :webhook_retention config (Task 2)
- **Files created:** 6 (2 worker modules + 2 mix tasks + 2 test files)
- **Files modified:** 3 (application.ex + config.ex + repo.ex)

## Accomplishments

### Task 1: Mailglass.Webhook.Reconciler + mix task fallback + boot warning (commit `1a6d9f9`)

- **`lib/mailglass/webhook/reconciler.ex` (NEW):** Oban cron worker on queue `:mailglass_reconcile` with `unique: [period: 60]`. The entire `use Oban.Worker, ...` + worker body is conditionally compiled behind `if Code.ensure_loaded?(Oban.Worker)`. A top-level `available?/0` returns `Code.ensure_loaded?(Oban.Worker)` for probe-site callers (mix tasks + boot warning) without needing `Code.ensure_loaded?/1` at each call site.

  The `reconcile/2` entry point wraps a `:telemetry.span/3` on `[:mailglass, :webhook, :reconcile]` with D-23 whitelist-conformant stop metadata (`:tenant_id, :scanned_count, :linked_count, :remaining_orphan_count, :status`). `find_orphans/1` (Phase 2) returns orphan events; `past_grace?/1` in-memory filter removes rows inserted within the last 60s (grace window for in-flight dispatches). For each past-grace orphan, `attempt_reconcile/1` calls `Events.Reconciler.attempt_link/1` and, on `:ok`, builds a flat Multi: `Events.append_multi(:reconciled_event, ...)` → `Multi.update(:projection, ...)`. Wrapped in `Repo.transact(fn -> Repo.multi(multi) end)`.

  **Projector nuance:** the Multi.update step applies `Projector.update_projections(delivery, orphan)` — NOT `(delivery, reconciled_event)`. The `Delivery.last_event_type` Ecto.Enum deliberately excludes `:reconciled` per D-14 amendment (audit-only lifecycle); passing the reconciled event would raise `Ecto.ChangeError`. Passing the orphan applies the original provider event (`:delivered`/`:bounced`/etc.) to the delivery summary while the `:reconciled` ledger row records the audit moment. (Rule 1 auto-fix during execution — see Deviations.)

  **Idempotency:** reconciled event uses `idempotency_key: "reconciled:" <> orphan.id` — single deterministic key per orphan. The partial UNIQUE index on `mailglass_events.idempotency_key WHERE idempotency_key IS NOT NULL` makes duplicate reconciler runs structurally collapse to one `:reconciled` row.

  **Post-commit broadcast:** after successful `Repo.transact` return, `Projector.broadcast_delivery_updated(delivery, :reconciled, %{event_id: ..., reconciled_from_event_id: orphan.id})` fires on the PubSub topic (Phase 3 D-04 invariant — broadcast AFTER commit, never inside). The Projector's `broadcast_delivery_updated/3` absorbs PubSub failures so node partitions don't propagate.

- **`lib/mix/tasks/mailglass.reconcile.ex` (NEW):** Manual fallback per CONTEXT D-20. `OptionParser.parse/2` accepts `--tenant-id :string` + `--batch-size :integer`. `Mix.Task.run("app.start")` boots the app; dispatches to `Mailglass.Webhook.Reconciler.reconcile/2` if `available?/0`, else exits 1 with a clear error. `use Boundary, classify_to: Mailglass` silences the default boundary-classifier warning for `Mix.Tasks.*` under `--warnings-as-errors`.

- **`lib/mailglass/application.ex` (MODIFIED):** Added `maybe_warn_missing_oban_for_webhook_workers/0` alongside the existing `maybe_warn_missing_oban/0`. Consolidated ONE Logger.warning covers BOTH Reconciler AND Pruner (revision W2 option b — reduces log noise vs. two separate warnings). `:persistent_term.get({:mailglass, :oban_warning_webhook_workers}, false)` gate ensures exactly one emission per BEAM lifetime, mirroring the Phase 3 D-17 `:oban_warning_emitted` gate. The warning message mentions both `mix mailglass.reconcile` AND `mix mailglass.webhooks.prune` as the manual-cron fallback path.

- **`test/mailglass/webhook/reconciler_test.exs` (NEW, 6 tests, all pass):** Integration tests using `Mailglass.WebhookCase, async: false` + `@moduletag :requires_oban`. Tests cover:
  - **Happy path** — APPENDS a new `:reconciled` event when matching Delivery commits AFTER orphan; orphan row (delivery_id: nil, needs_reconciliation: true) is structurally UNCHANGED.
  - **Idempotency** — two reconciler sweeps collapse to ONE `:reconciled` row via `reconciled:<orphan_id>` idempotency key.
  - **No-match** — orphan left untouched when no matching Delivery exists; next tick retries.
  - **Grace window** — orphans younger than 60s filtered out of `scanned_count`.
  - **Telemetry whitelist** — D-23 compliance (`:tenant_id, :scanned_count, :linked_count, :remaining_orphan_count, :status` present; `:ip, :raw_payload, :recipient, :email, :to, :from, :body, :html_body, :subject, :headers` absent).
  - **Oban.Worker contract** — `perform/1`, `reconcile/2`, `available?/0` all exported.

  Raw SQL INSERT for backdating orphan `inserted_at` (Events.append/1 uses DB-default `now()`; the SQLSTATE 45A01 trigger blocks UPDATE-after-append, so raw INSERT with explicit `inserted_at` is the correct path).

### Task 2: Mailglass.Webhook.Pruner + :webhook_retention config + mix task (commit `5f342e2`)

- **`lib/mailglass/webhook/pruner.ex` (NEW):** Oban cron worker on queue `:mailglass_maintenance`. Same conditional-compile + `available?/0` pattern as Reconciler. `prune/0` reads `Application.get_env(:mailglass, :webhook_retention, [])` for the three knobs (default: succeeded=14, dead=90, failed=:infinity), calls `prune_status/2` for `:succeeded` + `:dead`, returns `{:ok, %{succeeded: n, dead: m}}`.

  **`:infinity` bypass** is structural — `prune_status(_, :infinity), do: {:ok, 0}` returns WITHOUT issuing the DELETE. Zero DB cost for disabled classes.

  **`perform/1`** (Oban callback) calls `prune/0` + emits `[:mailglass, :webhook, :prune, :stop]` with measurements `%{succeeded_deleted: n, dead_deleted: m}` and metadata `%{status: :ok}` — D-23 whitelist-conformant.

- **`lib/mailglass/config.ex` (MODIFIED):** Added `:webhook_retention` keyword sub-tree to the NimbleOptions `@schema`. Three keys (`:succeeded_days, :dead_days, :failed_days`) each typed as `{:or, [:pos_integer, {:in, [:infinity]}]}` with defaults 14 / 90 / :infinity. Doc strings explain each knob + the `:infinity` bypass semantics.

- **`lib/mailglass/repo.ex` (MODIFIED):** Added `delete_all/2` as a thin facade passthrough to `repo().delete_all/2`. Used by Pruner for retention DELETEs. Does NOT translate SQLSTATE 45A01 (moduledoc explains — that trigger fires only on `mailglass_events` UPDATE/DELETE, not `mailglass_webhook_events` which is intentionally mutable + prunable per CONTEXT D-15 split).

- **`lib/mix/tasks/mailglass.webhooks.prune.ex` (NEW):** Manual fallback; same shape as `mix mailglass.reconcile` (app.start + availability probe + exit 1 on absent). Emits the same `[:webhook, :prune, :stop]` telemetry via the `perform/1` path if dispatched through Pruner directly (the mix task uses the lower-latency `prune/0` entry point for clearer CLI output).

- **`test/mailglass/webhook/pruner_test.exs` (NEW, 6 tests, all pass):** Integration tests using `Mailglass.WebhookCase, async: false` + `@moduletag :requires_oban`. Tests cover:
  - **`:succeeded` retention** — 20-day-old row deleted; 5-day-old row retained (default 14-day).
  - **`:dead` retention** — 100-day-old row deleted; 30-day-old retained (default 90-day).
  - **`:infinity` bypass** — 100-day-old `:succeeded` row PRESERVED when `succeeded_days: :infinity` set via Application.put_env.
  - **`failed_days: :infinity` default** — 200-day-old `:failed` row never deleted out-of-the-box (investigatable audit).
  - **Telemetry** — `perform/1` emits `[:webhook, :prune, :stop]` with both `succeeded_deleted` + `dead_deleted` measurements and `status: :ok` metadata (D-23 compliant: no `:ip`, `:raw_payload`, `:recipient`, `:email`).
  - **Multi-status sweep** — prunes `:succeeded` + `:dead` in one run; `:failed` row unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reconciler Projector call received wrong event type**
- **Found during:** Task 1 test run (Happy Path test).
- **Issue:** The plan's verbatim action (line 485–488) specified `Multi.update(:projection, fn %{reconciled_event: e} -> Projector.update_projections(delivery, e) end)`. This raises `Ecto.ChangeError` at runtime because `Mailglass.Outbound.Delivery.last_event_type` is an `Ecto.Enum` that deliberately excludes `:reconciled` (per D-14 amendment: `:reconciled` is internal-only to `mailglass_events`, NOT a lifecycle transition reflected in the delivery projection).
- **Fix:** Changed the Multi.update closure to `fn _changes -> Projector.update_projections(delivery, orphan) end` — passing the ORPHAN event (with its original `:delivered`/`:bounced`/etc. type) rather than the newly-appended `:reconciled` event. This preserves the semantic intent: the delivery projection should reflect the provider's actual event, while the `:reconciled` event in the ledger records the audit moment (when the orphan was linked).
- **Files modified:** `lib/mailglass/webhook/reconciler.ex` (lines 192–202; added explanatory comment).
- **Commit:** `1a6d9f9` (the fix is in the initial Task 1 commit — caught before committing).

**2. [Rule 2 - Missing critical functionality] Mailglass.Repo.delete_all/2 not yet in the facade**
- **Found during:** Task 2 Pruner implementation (compile-time).
- **Issue:** The plan's Pruner body used `Repo.repo().delete_all/2`, but `Mailglass.Repo.repo/0` is deliberately PRIVATE (moduledoc: "This module re-exports only what mailglass itself uses"). Exposing `repo/0` for Pruner would mean every future worker that needs `delete_all` can grab raw repo access, growing the public surface uncontrolled.
- **Fix:** Added `delete_all/2` as a NEW typed facade passthrough matching the established `all/2`, `one/2`, `get/3` pattern. Documented in the function's `@doc` that it does NOT translate SQLSTATE 45A01 (that trigger fires only on `mailglass_events`, not `mailglass_webhook_events`).
- **Files modified:** `lib/mailglass/repo.ex` (added `delete_all/2` at line ~133).
- **Commit:** `5f342e2`.

**3. [Rule 2 - Missing critical functionality] Mix.Tasks.* modules not in any boundary**
- **Found during:** Task 1 compile under `--warnings-as-errors`.
- **Issue:** `lib/mix/tasks/*.ex` modules sit outside the default Boundary classifier, triggering `"Mix.Tasks.Mailglass.Reconcile is not included in any boundary"` under `--warnings-as-errors`.
- **Fix:** Added `use Boundary, classify_to: Mailglass` to both mix task modules — classifies them into the root Mailglass boundary (they're part of mailglass's user-facing surface).
- **Files modified:** `lib/mix/tasks/mailglass.reconcile.ex`, `lib/mix/tasks/mailglass.webhooks.prune.ex`.
- **Commits:** `1a6d9f9`, `5f342e2`.

### Non-deviations documented inline

- The plan's `attempt_reconcile/1` `case Repo.transact` pattern-match had TWO clauses; the implementation uses THREE — `{:ok, {:ok, changes}}`, `{:ok, {:error, step, reason, _}}`, and `{:error, reason}`. Reason: `Repo.transact/1` wraps `Repo.multi/1`'s return tuple inside its own `{:ok, _}` envelope. Documented inline.

## Threat Mitigations Verified

| Threat | Mitigation | Verified By |
|--------|-----------|-------------|
| T-04-04 (Information Disclosure via telemetry) | D-23 whitelist: `[:webhook, :reconcile, :stop]` metadata restricted to `%{tenant_id, scanned_count, linked_count, remaining_orphan_count, status}` | Reconciler telemetry test asserts `refute Map.has_key?(meta, :ip|:raw_payload|:recipient|:email|:to|:from|:body|:html_body|:subject|:headers)` |
| T-04-05 (DoS via Pruner DELETE) | Pruner daily cron + :infinity bypass returns {:ok, 0} without issuing DELETE; DELETE bounded by `WHERE status = ? AND inserted_at < cutoff` using partial indices | Pruner `:infinity` test asserts row preserved + zero DB cost; Pruner multi-status sweep confirms bounded deletion |
| T-04-06 (Cross-tenant data leak) | `find_orphans/1` accepts `:tenant_id` opt; Reconciler.perform/1 reads `"tenant_id"` from Oban.Job.args; Mailglass.Oban.TenancyMiddleware.wrap_perform/2 available to adopters who need stricter isolation | Reconciler tests scope all orphan inserts + sweeps to `"test-tenant"`; no cross-tenant assertions possible without second tenant (out of scope for this plan) |

## TDD Gate Compliance

Not applicable — this plan has `type: execute` (not `type: tdd`). Tasks use the plan's verbatim `type="auto"` shape with `<verify>` gates running `mix test` after implementation.

## Self-Check: PASSED

- **Files exist:**
  - `lib/mailglass/webhook/reconciler.ex` — FOUND (271 lines)
  - `lib/mailglass/webhook/pruner.ex` — FOUND (~110 lines)
  - `lib/mix/tasks/mailglass.reconcile.ex` — FOUND
  - `lib/mix/tasks/mailglass.webhooks.prune.ex` — FOUND
  - `test/mailglass/webhook/reconciler_test.exs` — FOUND
  - `test/mailglass/webhook/pruner_test.exs` — FOUND
  - `lib/mailglass/application.ex` — MODIFIED (maybe_warn_missing_oban_for_webhook_workers/0 added)
  - `lib/mailglass/config.ex` — MODIFIED (:webhook_retention sub-tree added)
  - `lib/mailglass/repo.ex` — MODIFIED (delete_all/2 added)
- **Commits exist:**
  - `1a6d9f9` — FOUND (Task 1)
  - `5f342e2` — FOUND (Task 2)
- **Verification:**
  - `mix compile --warnings-as-errors` — PASSES (0 warnings)
  - `mix compile --warnings-as-errors --no-optional-deps` — PASSES (modules conditionally compiled away)
  - `mix test test/mailglass/webhook/reconciler_test.exs test/mailglass/webhook/pruner_test.exs --warnings-as-errors --include requires_oban` — PASSES (12/12 tests, 0 failures)
  - `mix test test/mailglass/webhook/ --warnings-as-errors --include requires_oban` — PASSES (103/103 tests, 0 failures — Phase 4 webhook suite fully green)
  - `mix help mailglass.reconcile` — lists the task
  - `mix help mailglass.webhooks.prune` — lists the task

## Forward Links

- **Plan 04-08 (Telemetry)** can extract a named span helper `Mailglass.Webhook.Telemetry.reconcile_span/2` wrapping the raw `:telemetry.span` call in `Mailglass.Webhook.Reconciler.reconcile/2`. The raw-span pattern is local per CONTEXT D-22 line 161 ("when Plan 08 helpers are absent; Plan 08 extracts ... as a mechanical rename"). The Pruner's single-emit `:telemetry.execute/3` can stay inline or get a `prune_telemetry/2` helper — CONTEXT D-22 line 185 leaves this to Plan 08 discretion.

- **Plan 04-09 (UAT + guides/webhooks.md)** wires the cron registration example for adopters (`{"*/5 * * * *", Mailglass.Webhook.Reconciler}` + `{"0 3 * * *", Mailglass.Webhook.Pruner}` in their Oban cron plugin). It also ships the `@tag :phase_04_uat` tests that exercise the Reconciler.reconcile/2 entry point end-to-end (adopter-visible contract).

- **v0.5 prod admin dashboard** (deferred) will surface orphan events in the LiveView: `find_orphans/1` output becomes the primary data source; the admin does NOT call Reconciler.reconcile/2 directly (cron runs it automatically). The v0.5 "Dismiss orphan (older than 7 days)" UI is LiveView state only — NOT a DB UPDATE (preserves D-15/D-18 append-only).

- **v0.5 DLQ admin** (deferred) will surface `:dead` webhook_events via the Pruner's `:dead_days` knob — adopters who want to investigate failed webhooks before pruning tune the retention longer. Current Pruner shape already supports this via Application config; no code changes needed at v0.5.
