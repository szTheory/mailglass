---
phase: 04-webhook-ingest
plan: 06
subsystem: webhook
tags: [ingest, multi, transact, statement_timeout, lock_timeout, idempotency, orphan, replay, webhook_event_schema, d10, d11, d14, d15, d21, d22, d29]

# Dependency graph
requires:
  - phase: 04-webhook-ingest
    plan: 01
    provides: "V02 migration (mailglass_webhook_events + needs_reconciliation column on mailglass_events), Mailglass.WebhookCase, Mailglass.Repo.query!/2 passthrough"
  - phase: 04-webhook-ingest
    plan: 02
    provides: "Postmark normalize/2 emitting STRING-keyed metadata (provider_event_id / message_id / event / record_type)"
  - phase: 04-webhook-ingest
    plan: 03
    provides: "SendGrid normalize/2 emitting STRING-keyed metadata (provider_event_id / sg_message_id / event)"
  - phase: 04-webhook-ingest
    plan: 04
    provides: "Mailglass.Webhook.Plug forward-references Ingest.ingest_multi/3 + events_with_deliveries 3-tuple contract consumed post-commit"
  - phase: 04-webhook-ingest
    plan: 05
    provides: "Mailglass.Config.webhook_ingest_mode/0, Mailglass.Tenancy.clear/0 (test helper), finalized error atom sets"
  - phase: 02-persistence-tenancy
    provides: "Mailglass.Events.append_multi/3 function form (name is_atom guard), Mailglass.Outbound.Projector.update_projections/2, Mailglass.Outbound.Delivery.changeset/1, Mailglass.Repo.transact/1 + Repo.multi/1, Mailglass.Tenancy.tenant_id!/0 fail-loud accessor, Mailglass.Schema UUIDv7 client-side macro"
provides:
  - "Mailglass.Webhook.Ingest.ingest_multi/3 — the single Ecto.Multi inside Repo.transact/1 that all of HOOK-06 reduces to (webhook_event insert + N event inserts + N projector updates + status flip)"
  - "Mailglass.Webhook.WebhookEvent Ecto schema (UUIDv7 PK via Mailglass.Schema, redact: true on :raw_payload, Ecto.Enum :status in @valid_statuses closed set, changeset/1 with Clock.utc_now/0 received_at default)"
  - "Mailglass.IdempotencyKey.for_webhook_event/3 (arity-3 form: provider:event_id:index for SendGrid batch per-event keying)"
  - "events_with_deliveries 3-tuple return shape [{event, delivery_or_nil, orphan?}, ...] — Plan 04-04's Plug consumes for post-commit broadcast"
  - "Duplicate-detection signal via deterministic :duplicate_check Multi step (pre-insert Repo.exists?/1) — decoupled from on_conflict: :nothing return-shape quirks"
  - "Orphan-skip projector pattern (Pitfall 4): events with delivery_id: nil insert with needs_reconciliation: true; projector step SKIPPED (pattern-matches %Delivery{}; would FunctionClauseError on nil)"
  - "SendGrid batch idempotency discriminator: SHA-256 hash of raw_body (32-char hex prefix) as provider_event_id — defends against false-positive duplicate collisions when batches share a first-event-id"
  - "SET LOCAL statement_timeout = '2s' + SET LOCAL lock_timeout = '500ms' issued INSIDE the transact closure (D-29 DoS bound; Pitfall 6 — outside a transaction these are no-ops)"
  - ":webhook_ingest_mode == :async runtime raise (CONTEXT D-11 v0.1 sync-only discipline; revision B2)"
affects: [04-07, 04-08, 04-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Atomic webhook ingest: one Ecto.Multi inside Repo.transact/1 composes (a) a deterministic :duplicate_check Repo.exists? step, (b) the webhook_event insert with on_conflict: :nothing + conflict_target [:provider, :provider_event_id], (c) N Events.append_multi function-form steps with lazy delivery_id resolution, (d) per-event :projector_categorize + :projector_apply Multi.run pair (flat, no nested Multi anti-pattern per revision W4), (e) :flip_status Multi.update_all setting :succeeded + processed_at. All in one transaction — partial failure rolls back the entire unit."
    - "Function-form Events.append_multi for lazy delivery_id resolution: the closure body runs inside Multi.run with access to prior changes, but resolve_delivery_id/2 doesn't actually depend on them — the query is against a committed mailglass_deliveries row, so it runs immediately. The function form is used for consistency with the Multi composition shape rather than because later steps change the resolution."
    - "Flat Multi composition over nested Repo.multi (revision W4 anti-pattern elimination): the previous nested-Multi pattern (Repo.multi(Multi.new() |> Multi.update(...)) inside Multi.run) broke transaction scoping — the outer transaction couldn't roll back the inner sub-transaction's writes if a later step failed. Now :projector_categorize classifies (no-event-row / orphan-skipped / {matched, delivery, event}); :projector_apply conditionally calls Projector.update_projections/2 on the OUTER Multi's repo handle. Single transaction; correct rollback semantics."
    - "Deterministic pre-insert duplicate signal via Multi.run :duplicate_check + Repo.exists?/1: works regardless of Ecto version-specific on_conflict: :nothing, returning: true return behavior (which returns the conflict-target row WITH its existing id — so `is_nil(webhook_event.id)` is structurally wrong; never triggers)."
    - "Per-event 3-tuple return shape {inserted_event, delivery_or_nil, orphan?}: lets Plan 04-04's Plug drive post-commit broadcast without set-difference recomputation. Matched → {event, delivery, false} → broadcast; orphan/missing → {event, nil, true} → skip (Plan 04-07 Reconciler re-emits :reconciled when matching Delivery surfaces)."
    - "SendGrid batch idempotency hash: :crypto.hash(:sha256, raw_body) |> Base.encode16(case: :lower) |> binary_part(0, 32). Content-addressable — identical payload bytes across retries produce the same discriminator; two different batches sharing an event id do NOT collide. Replaces the naive 'first event's id' approach which would false-positive-duplicate legitimate second batches."
    - "Mailglass.Schema UUIDv7 + redact: true on raw_payload: WebhookEvent.raw_payload field marked redact: true so Inspect output (IEx, test failures) never leaks PII bytes. The Mailglass.Schema `use` macro provides UUIDv7 client-side PK generation; schema mirrors Events.Event style."
    - "Atom-based Multi step naming with bounded atom creation: Events.append_multi/3 guards is_atom(name), so tuple keys like {:event, idx} don't work. event_step_name(idx) synthesizes :\"event_#{idx}\" — atom growth is O(128) bounded by SendGrid max batch size, not attacker-controlled. Categorize/apply keys remain tuple {:projector_categorize, idx} / {:projector_apply, idx} because Multi.run/3 accepts any term."

key-files:
  created:
    - "lib/mailglass/webhook/ingest.ex"
    - "lib/mailglass/webhook/webhook_event.ex"
    - "test/mailglass/webhook/ingest_test.exs"
  modified:
    - "lib/mailglass/idempotency_key.ex (+ for_webhook_event/3 arity-3 form + test coverage)"

key-decisions:
  - "Mailglass.Tenancy.tenant_id!/0 over Tenancy.current/0 for the top-of-ingest assertion: the fail-loud accessor raises %TenancyError{:unstamped} unconditionally when the process-dict key is absent. Tenancy.current/0 silently falls back to the SingleTenant 'default' literal, which would mask a missing Plug.with_tenant/2 stamping upstream — a programmer error we want to catch at the boundary. Mirrors accrue's Actor.actor_id! vs Actor.current split (STATE.md decision log)."
  - "Events.append_multi/3 guards is_atom(name) — the interim refactor that tried passing {:event, idx} failed at runtime. Resolved via private event_step_name/1 helper synthesizing :\"event_#{idx}\" (bounded atom growth, not attacker-controlled). The category/apply steps (:projector_categorize / :projector_apply) keep tuple keys because they call Multi.run/3 directly, which accepts any term. The asymmetry reflects an Events.append_multi-specific guard, not a Multi-wide constraint."
  - "Duplicate-detection signal: deterministic pre-insert Repo.exists?/1 in a Multi.run step, NOT `is_nil(webhook_event.id)` on the inserted row. Reason: Ecto's on_conflict: :nothing, returning: true returns the conflict-target row WITH its existing id populated — so the id-nil heuristic never triggers. Tests prove the deterministic signal: result.duplicate == true after second identical call (revision B5)."
  - "SendGrid batch idempotency uses SHA-256 of raw_body (32-char hex prefix), NOT the first event's id. Rationale: SendGrid retries the SAME batch bytes keyed on the batch's content; 'first event id' would false-positive-duplicate legitimate second batches where two different batches share a first-event-id (batch A: [evt_X, evt_Y]; batch B: [evt_X, evt_Z] both compute 'evt_X'). Hash-of-raw-body is content-addressable and collision-resistant for this scope (revision B6)."
  - "Orphan handling: events with delivery_id: nil insert with needs_reconciliation: true AND SKIP the projector step. Pitfall 4 — Projector.update_projections/2 pattern-matches %Delivery{} and would FunctionClauseError on nil. The skip is explicit via :projector_categorize → :orphan_skipped / :no_event_row → :projector_apply pass-through. Plan 04-07 Reconciler later appends a :reconciled event when the matching Delivery surfaces (D-18 — append, never UPDATE)."
  - "Flat Multi composition (revision W4) over nested Repo.multi anti-pattern: the previous nested-Multi pattern broke transaction scoping — the outer transaction couldn't rollback the inner sub-transaction's writes if a later step failed. Now :projector_categorize Multi.run classifies; :projector_apply Multi.run conditionally calls Projector.update_projections/2 on the OUTER Multi's repo handle. Single transaction; correct rollback semantics. Revision W9's string-keyed metadata reading (`meta[\"sg_message_id\"] || meta[\"message_id\"]`) aligns with Plans 04-02 + 04-03 normalize/2 output."
  - "SET LOCAL statement_timeout = '2s' + SET LOCAL lock_timeout = '500ms' issued INSIDE the Repo.transact/1 closure, BEFORE Repo.multi(multi). Pitfall 6: outside a transaction these are no-ops. Verified by the @tag :slow statement_timeout test — SET LOCAL 500ms + pg_sleep 2.0 raises Postgrex.Error SQLSTATE 57014 'canceling statement due to statement timeout'. The 2s Ingest value is a verifiable quoted constant."
  - ":webhook_ingest_mode == :async raises at runtime (not a NimbleOptions validation) — Plan 04-05 added the schema entry with the closed {:in, [:sync, :async]} set, but :async is reserved for v0.5 DLQ admin. Runtime raise catches adopters who set :async (valid at boot) with a clear error message instead of silent :sync fallback or confused downstream behavior (CONTEXT D-11 + revision B2)."
  - "WebhookEvent.changeset/1 defaults :status to :processing and :received_at to Clock.utc_now/0 via Map.put_new. Callers provide {:provider, :provider_event_id, :event_type_raw, :tenant_id, :raw_payload} as required; other fields fall to sensible defaults. Mirrors Events.Event.changeset/1 style."
  - "WebhookEvent schema uses Ecto.Enum values: @valid_statuses [:received, :processing, :succeeded, :failed, :dead] for application-side status validation — the DB column is TEXT, so casting happens on the Ecto side. __statuses__/0 exposes the closed set for external callers (Phase 04-08 pruner, 04-07 reconciler)."
  - "Tests use TestRepo (Mailglass.TestRepo) for raw aggregate/insert!/all, Repo (Mailglass.Repo) only for the narrow facade (transact/1, query!/2). Mailglass.Repo deliberately exposes a 9-function facade (transact, insert, update, delete, multi, one, all, get, query!); aggregate/insert! aren't in that set because the library doesn't need them. Tests reach around the facade via TestRepo since they're not library code."
  - "build_sg_event test helper uses STRING keys in metadata (\"provider\", \"provider_event_id\", \"event\", \"sg_message_id\") to match Plans 04-02 + 04-03 normalize/2 contract — atom-key fallback exists in resolve_delivery_id/2 defensively but tests exercise the happy path."

patterns-established:
  - "One transaction = one unit of work for webhook ingest: everything a single webhook produces (the webhook_event row + N event rows + N projection updates + status flip) commits atomically or rolls back together. If ANY step fails (DB constraint, statement_timeout, 45A01 trigger), the entire webhook is reprocessable — the duplicate_check will find no row and the next arrival from the provider's retry is a fresh attempt. Replay is safe because the UNIQUE(provider, provider_event_id) collision is a structural no-op."
  - "Plan 04-07 Reconciler reuses the append-based pattern (D-18 — append a :reconciled event, never UPDATE the orphan event row). It consumes this plan's needs_reconciliation: true indicator on mailglass_events, so the Reconciler's find_orphans/0 query is `from e in Event, where: e.needs_reconciliation == true`."
  - "Plan 04-08 Pruner reuses WebhookEvent.__statuses__/0 + the :succeeded | :failed | :dead atoms for retention policy — prunes :succeeded older than N days, keeps :failed / :dead for audit. The split is baked into the schema's Ecto.Enum."
  - "Atomic Multi step naming convention: atom for Events.append_multi steps (:\"event_#{idx}\") because the underlying append_multi guards is_atom; tuple for Multi.run classification/application steps ({:projector_categorize, idx} / {:projector_apply, idx}) because Multi.run accepts any term and the tuple shape is self-documenting. Downstream Map.get(changes, key) uses the matching shape."

requirements-completed: [HOOK-06]

# Metrics
duration: 30min
completed: 2026-04-23
---

# Phase 4 Plan 6: Webhook Ingest Wave 3A — Heart of HOOK-06 Summary

**`Mailglass.Webhook.Ingest.ingest_multi/3` ships the single `Ecto.Multi` inside `Mailglass.Repo.transact/1` that composes atomic (a) deterministic `:duplicate_check` Repo.exists? → (b) `mailglass_webhook_events` insert with `on_conflict: :nothing, conflict_target: [:provider, :provider_event_id]` → (c) N `Events.append_multi` function-form steps with lazy `delivery_id` resolution → (d) per-event `:projector_categorize` + `:projector_apply` Multi.run pair (flat, revision W4 — no nested Repo.multi anti-pattern) → (e) `:flip_status` update_all to `:succeeded` + `processed_at`. `SET LOCAL statement_timeout = '2s'` + `SET LOCAL lock_timeout = '500ms'` issued INSIDE the transact closure (D-29; Pitfall 6). `Mailglass.Webhook.WebhookEvent` Ecto schema ships with UUIDv7 PK + `redact: true` on `:raw_payload`. `IdempotencyKey.for_webhook_event/3` extends to the arity-3 form for SendGrid batch per-event keying. Returns `{:ok, %{webhook_event, duplicate, events_with_deliveries, orphan_event_count}}` — the `events_with_deliveries` 3-tuple shape lets Plan 04-04's Plug drive post-commit broadcast without set-difference recomputation. HOOK-06 complete.**

## Performance

- **Duration:** ~30 min (spans two executor sessions — initial stream timed out mid-Task-3; continuation agent finished)
- **Started:** 2026-04-23T21:15:00Z (approx; Task 1 commit c6b19d7)
- **Completed:** 2026-04-24T01:41:09Z
- **Tasks:** 3 (Task 1 + Task 2 completed in initial session; Task 3 completed in continuation session after fixing broken ingest.ex refactor)
- **Commits:** 3 task commits
  - `c6b19d7` — feat(04-06): WebhookEvent schema + IdempotencyKey arity-3 form (Task 1)
  - `4daa121` — feat(04-06): Mailglass.Webhook.Ingest.ingest_multi/3 heart of HOOK-06 (Task 2)
  - `1da95ff` — test(04-06): ingest_multi/3 integration tests + fail-loud Tenancy accessor (Task 3)
- **Files created:** 3
- **Files modified:** 1

## Accomplishments

### Task 1: WebhookEvent schema + IdempotencyKey arity-3 (commit `c6b19d7`)

- **`lib/mailglass/webhook/webhook_event.ex` (NEW, ~60 lines):** Ecto schema for the `mailglass_webhook_events` table (V02 migration, Wave 0 Plan 01). `use Mailglass.Schema` gives UUIDv7 client-side PK; `field :raw_payload, :map, redact: true` ensures Inspect output never leaks PII bytes. `Ecto.Enum values: [:received, :processing, :succeeded, :failed, :dead]` validates the status atom application-side (DB column is TEXT). `changeset/1` casts the 9 fields with `Map.put_new(:status, :processing)` + `Map.put_new(:received_at, Clock.utc_now())` defaults; validates `[:tenant_id, :provider, :provider_event_id, :event_type_raw, :status, :raw_payload, :received_at]` as required. `__statuses__/0` exposes the closed set for Plan 04-07/04-08 callers.
- **`lib/mailglass/idempotency_key.ex` (MODIFIED):** Added `for_webhook_event/3` arity-3 form for per-batch-event keying. Sanitizes `"{provider}:{event_id}:{index}"` so duplicate inserts of the same batch event collapse via the `mailglass_events.idempotency_key` partial UNIQUE index. Parallel test coverage.

### Task 2: Mailglass.Webhook.Ingest.ingest_multi/3 (commit `4daa121`)

- **`lib/mailglass/webhook/ingest.ex` (NEW, ~430 lines):** The single module HOOK-06 reduces to. `ingest_multi/3` asserts tenant via `Tenancy.tenant_id!/0`, rejects `:async` ingest mode via runtime raise, wraps `build_multi/4` in `Repo.transact/1`. Inside the transaction: SET LOCAL statement_timeout + lock_timeout are issued via `Repo.query!/2`, then the Multi runs with ordered steps (duplicate_check → webhook_event insert → N event appends → N projector categorize/apply → flip_status). `finalize_changes/2` extracts the duplicate signal from the `:duplicate_check` step's boolean and walks events in input order to build the 3-tuple events_with_deliveries output.

  Multi composition steps:
  - `:duplicate_check` (Multi.run) — Repo.exists? against (provider, provider_event_id) for the deterministic duplicate signal
  - `:webhook_event` (Multi.insert) — on_conflict: :nothing, conflict_target: [:provider, :provider_event_id], returning: true
  - `:"event_0"`, `:"event_1"`, ... (Events.append_multi function-form) — each resolves delivery_id lazily via resolve_delivery_id/2
  - `{:projector_categorize, 0}`, `{:projector_categorize, 1}`, ... (Multi.run) — classifies inserted event as :no_event_row / :orphan_skipped / {:matched, delivery, event}
  - `{:projector_apply, 0}`, `{:projector_apply, 1}`, ... (Multi.run) — conditional Projector.update_projections/2 on :matched; pass-through on others
  - `:flip_status` (Multi.update_all) — sets status: :succeeded + processed_at: Clock.utc_now()

  Helpers:
  - `derive_webhook_provider_event_id/3` — SendGrid: SHA-256 hash of raw_body (32-char hex prefix, content-addressable); Postmark: first event's provider_event_id metadata key
  - `resolve_delivery_id/2` — reads STRING keys "message_id" / "sg_message_id" from event.metadata (revision W9); queries mailglass_deliveries by (provider, provider_message_id)
  - `parse_raw_payload/1` — Jason.decode; falls back to `%{"_batch" => list}` for SendGrid list payloads or `%{"_raw" => body}` on decode failure
  - `finalize_changes/2` — builds per-event 3-tuple {inserted_event, delivery_or_nil, orphan?} in input order

### Task 3: Integration tests + fail-loud Tenancy accessor + event_step_name helper (commit `1da95ff`)

- **`lib/mailglass/webhook/ingest.ex` (MODIFIED):** Two coupled refactors:
  1. `Tenancy.current() || raise TenancyError.new(:unstamped)` → `Tenancy.tenant_id!/0`. The fail-loud accessor is the correct boundary — Tenancy.current/0 silently defaults to "default" (SingleTenant fallback), which would mask a missing Plug.with_tenant/2 stamping upstream. tenant_id!/0 raises unconditionally.
  2. Added private `event_step_name(idx)` helper synthesizing `:"event_#{idx}"` atoms. Events.append_multi/3 guards `is_atom(name)` — the previous `{:event, idx}` tuple key failed that guard at runtime. Downstream `Map.get(changes, {:event, idx})` calls in update_projections_for_each/2 + finalize_changes/2 updated to use `Map.get(changes, event_step_name(idx))`. Atom growth is O(128) bounded by SendGrid's max batch size — safe; not attacker-controlled.

- **`test/mailglass/webhook/ingest_test.exs` (NEW, 275 lines):** Six integration tests, `use Mailglass.WebhookCase, async: false`:
  - **Happy path (matched delivery)** — 1 webhook_event + 1 event + projection update + status flip. Seeds a Delivery with provider_message_id: "msg_001"; event metadata carries "message_id": "msg_001"; asserts delivery_id linked, needs_reconciliation: false, events_with_deliveries 3-tuple carries the matched %Delivery{}.
  - **Orphan path (no matching delivery)** — delivery_id: nil + needs_reconciliation: true + projector SKIPPED (Pitfall 4); webhook_event still flipped to :succeeded (orphan is normal flow).
  - **Duplicate replay (UNIQUE collision)** — first call: duplicate: false, second call: duplicate: true; TestRepo.aggregate(WebhookEvent, :count) == 1 after both; no second event row.
  - **SendGrid batch (5 events, mixed matched/orphan)** — seed 2 deliveries (msg_a, msg_b); events split msg_a x2 + msg_b x1 + msg_c + msg_d; events_with_deliveries contains all 5 entries; 3 matched + 2 orphan; 5 event rows persisted.
  - **statement_timeout primitive (@tag :slow)** — SET LOCAL statement_timeout = '500ms' + SELECT pg_sleep(2.0) raises Postgrex.Error SQLSTATE 57014 "canceling statement due to statement timeout". Proves CONTEXT D-29 primitive fires; Ingest's 2s is a verifiable constant (inspection).
  - **Missing tenant** — Tenancy.clear/0 + Ingest.ingest_multi/3 raises %TenancyError matching ~r/not stamped/. Per revision W7, uses the public Tenancy.clear/0 helper (Plan 04-05), NOT raw Process.delete.

  Test helpers:
  - `insert_delivery!/1` — uses Delivery.changeset/1 + TestRepo.insert!/1 (Mailglass.Repo facade doesn't expose insert! — tests reach around via TestRepo since they're not library code)
  - `build_sg_event/4` — constructs %Event{} with STRING-keyed metadata matching Plan 04-03 SendGrid normalize/2 output

## Deviations from Plan

### Continuation Session Context

The initial executor's stream timed out mid-Task-3, leaving the working tree in an intermediate state:

- `lib/mailglass/webhook/ingest.ex` modified but broken (introduced `event_step_name(idx)` call without its definition)
- `test/mailglass/webhook/ingest_test.exs` untracked (275-line test suite intact)

The continuation agent (this session) completed Task 3 by:

1. **[Continuation fix] Completed the event_step_name helper refactor** — added `defp event_step_name(idx)` producing `:"event_#{idx}"`. This was the intended shape; the previous executor committed the call site changes but was interrupted before adding the helper definition. Also updated downstream `Map.get(changes, {:event, idx})` → `Map.get(changes, event_step_name(idx))` in `update_projections_for_each/2` + `finalize_changes/2` (both references were still using the old tuple form after the partial refactor).

2. **[Continuation fix] Removed dead alias** — `TenancyError` alias was left over from the prior `Tenancy.current() || raise TenancyError` pattern; now unreferenced after the move to `Tenancy.tenant_id!/0`. Removed from the alias list. `mix compile --warnings-as-errors --no-optional-deps` stayed green after removal.

3. **[Continuation fix] Test file: Repo → TestRepo for aggregate/insert!** — the test file originally called `Mailglass.Repo.aggregate/2` and `Mailglass.Repo.insert!/1`, but Mailglass.Repo is a deliberately narrow 9-function facade (transact, insert, update, delete, multi, one, all, get, query!) that doesn't expose aggregate or insert!. Updated test calls to use `Mailglass.TestRepo.aggregate/2` and `TestRepo.insert!/1` directly. This matches the existing convention in `core_send_integration_test.exs`, `preflight_test.exs`, `suppression_store/ecto_test.exs`, `deliver_later_test.exs`. No impact on the library code — tests reach around the facade because they're not library callers.

No deviations to the plan's architectural intent; all three above are mechanical completions of the interrupted refactor.

## Threat Mitigations Verified

| Threat | Mitigation | Verified By |
|--------|-----------|-------------|
| T-04-02 (Replay) | UNIQUE(provider, provider_event_id) + on_conflict: :nothing | "duplicate replay" test: TestRepo.aggregate(WebhookEvent, :count) == 1 after second call |
| T-04-05 (DoS) | SET LOCAL statement_timeout = '2s' + lock_timeout = '500ms' inside transact (Pitfall 6) | "statement_timeout" @tag :slow test: Postgrex.Error SQLSTATE 57014 raises |
| T-04-06 (Cross-tenant) | Tenancy.tenant_id!/0 raises %TenancyError{:unstamped} at top of ingest_multi/3 | "missing tenant" test: Ingest.ingest_multi raises Mailglass.TenancyError |

## Self-Check: PASSED

- **Files exist:**
  - `lib/mailglass/webhook/ingest.ex` — FOUND (444 lines)
  - `lib/mailglass/webhook/webhook_event.ex` — FOUND
  - `test/mailglass/webhook/ingest_test.exs` — FOUND (275 lines)
  - `lib/mailglass/idempotency_key.ex` — FOUND (modified; for_webhook_event/3 present)
- **Commits exist:**
  - `c6b19d7` — FOUND (Task 1)
  - `4daa121` — FOUND (Task 2)
  - `1da95ff` — FOUND (Task 3)
- **Verification:**
  - `mix compile --warnings-as-errors --no-optional-deps` — PASSES (0 warnings)
  - `mix test test/mailglass/webhook/ingest_test.exs --warnings-as-errors --include slow` — PASSES (6/6 tests, 0 failures, 1.0s)
  - `mix test test/mailglass/webhook/ --warnings-as-errors --exclude flaky` — PASSES (91/91 tests, 0 failures)
  - `MIX_ENV=test mix verify.phase_02` — PASSES (59 tests, 0 failures)
  - `MIX_ENV=test mix verify.phase_03` — PASSES (62 tests, 0 failures, 2 skipped)
  - `MIX_ENV=test mix verify.phase_04` — zero-match pass (0 `:phase_04_uat` tests; Wave 4 Plan 09 ships the first ones per mix.exs alias comment)

## Forward Links

- **Plan 04-07 (Reconciler)** builds on this plan's:
  - `needs_reconciliation: true` indicator on orphan `mailglass_events` rows → `find_orphans/0` query shape
  - Append-based pattern (D-18 — Reconciler emits a `:reconciled` event, never UPDATEs the orphan row)
  - `Mailglass.Webhook.WebhookEvent` schema for audit lookups

- **Plan 04-08 (Pruner)** uses `WebhookEvent.__statuses__/0` + the `:succeeded` | `:failed` | `:dead` atoms for retention policy (prune :succeeded older than N days; retain :failed / :dead for audit).

- **Plan 04-04 (Plug)** already consumes the `events_with_deliveries` 3-tuple contract this plan establishes — each `{event, delivery_or_nil, orphan?}` entry drives `Projector.broadcast_delivery_updated/3` (matched) or skip (orphan). No plug changes required; Plan 06 simply implements the contract Plan 04-04 forward-referenced.
