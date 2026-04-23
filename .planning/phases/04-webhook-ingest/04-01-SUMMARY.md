---
phase: 04-webhook-ingest
plan: 01
subsystem: testing
tags: [postgres, ecto, migration, ecdsa, p256, public_key, crypto, plug, basic_auth, fixtures]

# Dependency graph
requires:
  - phase: 02-persistence-tenancy
    provides: "V01 migration dispatcher (Mailglass.Migrations.Postgres), Mailglass.Events.Event schema + @anymail_event_types + @mailglass_internal_types, Mailglass.Repo facade with SQLSTATE 45A01 translation, mailglass_events immutability trigger, Mailglass.Tenancy behaviour"
  - phase: 03-transport-send-pipeline
    provides: "Mailglass.MailerCase (inherited by WebhookCase), Mailglass.Clock.Frozen (re-exported as freeze_timestamp/1), Projector broadcast tuple shape {:delivery_updated, id, type, meta}, Mailglass.PubSub.Topics.events/1,2"
provides:
  - "mailglass_webhook_events table (UUID PK, UNIQUE(provider, provider_event_id), partial status index)"
  - "mailglass_events.raw_payload column DROP (evidence moves to mailglass_webhook_events per D-15)"
  - "Mailglass.Repo.query!/2 — raw Postgrex passthrough (no SQLSTATE rescue) for SET LOCAL inside Repo.transact/1"
  - ":reconciled atom added to @mailglass_internal_types (D-14 amended; Reconciler-only, never from provider mappers)"
  - ":public_key OTP app declared in extra_applications (release builds keep the dependency)"
  - "verify.phase_04 mix alias (mirrors verify.phase_03; zero-test pass is Wave 0 correct behaviour)"
  - "Mailglass.WebhookFixtures — ECDSA P-256 keypair mint, SendGrid sign, Postmark Basic Auth header, fixture loader"
  - "Mailglass.WebhookCase — mailglass_webhook_conn/3, assert_webhook_ingested/1-2, stub_*_fixture/1, freeze_timestamp/1"
  - "7 payload-only fixture JSONs (5 Postmark + 2 SendGrid) at test/support/fixtures/webhooks/"
  - "docs/api_stability.md §Webhook scaffolding + 4 forward-ref markers for plans 02–08"
affects: [04-02, 04-03, 04-04, 04-05, 04-06, 04-07, 04-08, 04-09]

# Tech tracking
tech-stack:
  added: [":public_key (OTP stdlib)"]
  patterns:
    - "Oban-style migration dispatcher version bump: @current_version 1→2"
    - "Per-wrapper down-version scoping: wrapper N calls Mailglass.Migration.down(version: N-1) to avoid rolling back earlier wrappers' lifecycle"
    - "Test fixtures as payload-only JSON; signatures generated fresh per-test via Mailglass.WebhookFixtures"
    - ":crypto.sign/4 for ECDSA over :public_key.sign/3 (avoids the {:ECPrivateKey, _, _, _, _, _} 6-tuple record incantation)"
    - "Provider config installed per-test in WebhookCase setup with snapshot-restore on_exit (sendgrid public_key + postmark basic_auth)"

key-files:
  created:
    - "lib/mailglass/migrations/postgres/v02.ex"
    - "priv/repo/migrations/00000000000003_mailglass_webhook_events.exs"
    - "test/support/webhook_fixtures.ex"
    - "test/support/fixtures/webhooks/postmark/delivered.json"
    - "test/support/fixtures/webhooks/postmark/bounced.json"
    - "test/support/fixtures/webhooks/postmark/opened.json"
    - "test/support/fixtures/webhooks/postmark/clicked.json"
    - "test/support/fixtures/webhooks/postmark/spam_complaint.json"
    - "test/support/fixtures/webhooks/sendgrid/single_event.json"
    - "test/support/fixtures/webhooks/sendgrid/batch_5_events.json"
  modified:
    - "mix.exs (:public_key extra_app + verify.phase_04 alias)"
    - "lib/mailglass/repo.ex (query!/2 passthrough)"
    - "lib/mailglass/events/event.ex (:reconciled in internal types; drop :raw_payload field)"
    - "lib/mailglass/events.ex (attrs typespec drops :raw_payload)"
    - "lib/mailglass/events/reconciler.ex (extract/2 reads :metadata → :normalized_payload chain)"
    - "lib/mailglass/adapters/fake.ex (trigger_event writes :metadata instead of :raw_payload)"
    - "lib/mailglass/migrations/postgres.ex (@current_version 1→2)"
    - "test/support/webhook_case.ex (Wave 0 helper suite replaces 36-line stub)"
    - "docs/api_stability.md (§Webhook section + 4 forward-ref markers)"
    - "test/mailglass/migration_test.exs (assertion bound to current_version/0)"
    - "test/mailglass/persistence_integration_test.exs (same + webhook ledger metadata)"
    - "test/mailglass/events/reconciler_test.exs (raw_payload → metadata rename; fallback test rewritten)"
    - "test/mailglass/adapters/fake_test.exs (assertion on event.metadata)"
    - "test/mailglass/events/event_test.exs (attrs cleanup)"
    - "test/mailglass/outbound/projector_test.exs (attrs cleanup)"
    - "test/mailglass/outbound/projector_broadcast_test.exs (attrs cleanup)"
    - "test/mailglass/properties/idempotency_convergence_test.exs (attrs cleanup)"
    - "test/support/generators.ex (attrs cleanup)"
    - ".gitignore (/.claude/ local tooling)"

key-decisions:
  - "V02 migration ships as additive evolution on top of V01 — NOT amending V01, matches D-15 rationale that V01 is the adopter-install anchor"
  - "Migration wrapper #3's down/0 calls Mailglass.Migration.down(version: 1) not bare down/0 — per-wrapper ownership of V-step lifecycle; bare down would roll back V01 too"
  - ":crypto.sign(:ecdsa, :sha256, _, [priv, :secp256r1]) chosen over :public_key.sign/3 for fixture signing — the {:ECPrivateKey, _, _, _, :asn1_NOVALUE, :asn1_NOVALUE} 6-tuple shape is OTP 27-specific and fragile; :crypto.sign is stable"
  - "SendGrid SPKI DER constructed via :public_key.pem_entry_encode(:SubjectPublicKeyInfo, {{:ECPoint, pub}, {:namedCurve, secp256r1_oid}}) then extracting element 1 — canonical OTP path; round-trips cleanly with :public_key.der_decode/2 which is what the production verifier will call"
  - "Fake.trigger_event/3 stores opts[:metadata] in Event.metadata (not Event.raw_payload) — the original field name was an inversion; :metadata was always the right semantic home"
  - "Reconciler extract/2 fallback chain is :metadata → :normalized_payload (not :raw_payload → :metadata); Plan 06 Ingest writes provider identifiers into :metadata at insert"
  - "assert_webhook_ingested/2 macro supports three dispatch forms (bare, atom, map pattern) — pattern match against Phase 3 broadcast tuple shape; Plan 06 extends meta with :provider + :event_count without breaking this"
  - "WebhookCase setup installs :sendgrid + :postmark Application env per-test with snapshot-restore on_exit; @tag webhook_config: false opts out for pure-reader tests that can safely run async: true"
  - "7 fixture JSONs are payload-only (no baked-in signatures) per Pitfall 10 — signatures are non-deterministic so caching them would break re-runs; WebhookCase signs at conn-build time"

patterns-established:
  - "Oban-style migration version dispatch: `@current_version N` drives `Mailglass.Migration.up/0` to execute each V-step from migrated_version+1 through N"
  - "Per-wrapper down-version scoping: each migration wrapper owns its own V-step and passes `version: prior_step` when rolling back"
  - "ECDSA P-256 fixtures via :crypto.sign + :public_key.pem_entry_encode SPKI construction; verifier uses :public_key.der_decode + :public_key.verify"
  - "Test ECDSA keypairs minted per-test in setup; never from disk; fresh on every run"
  - "Webhook fixtures stored payload-only; signatures generated fresh at test time"
  - "Claude's Discretion: the `assert_webhook_ingested/2` macro accepts three dispatch forms — nil (presence), atom (event_type match), map (meta pattern) — matching Phase 3 test_assertions.ex"

requirements-completed: [HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05, HOOK-06, HOOK-07, TEST-03]

# Metrics
duration: 25min
completed: 2026-04-23
---

# Phase 4 Plan 1: Webhook Ingest Wave 0 Foundations Summary

**V02 migration creates `mailglass_webhook_events` + drops `mailglass_events.raw_payload`; Repo.query!/2 passthrough unlocks SET LOCAL in Ingest Multi; `:reconciled` internal type joins the ledger; WebhookFixtures + WebhookCase + 7 fixture JSONs form the Wave 1-4 test substrate.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-04-23T20:07:30Z
- **Completed:** 2026-04-23T20:33:03Z
- **Tasks:** 2 (plus 1 deviation-fix commit)
- **Commits:** 3 task/deviation commits + 1 metadata commit
- **Files created:** 11
- **Files modified:** 19

## Accomplishments

- **Database:** V02 migration creates `mailglass_webhook_events` with 11 user columns, UNIQUE on `(provider, provider_event_id)`, and a partial index scanning only `status IN ('failed','dead')`. Migration drops the unused `mailglass_events.raw_payload` column in the same step.
- **Repo facade:** `Mailglass.Repo.query!/2` added as a raw passthrough (no SQLSTATE rescue). Plan 06's Ingest Multi can now call `Repo.query!("SET LOCAL statement_timeout = '2s'")` inside `Repo.transact/1` per D-29.
- **Events schema:** `:reconciled` joins `@mailglass_internal_types` (never `@anymail_event_types` — Pitfall 8). `:raw_payload` removed from the schema, cast list, and typespec to match the V02 column drop.
- **OTP release safety:** `:public_key` declared in `extra_applications` so `mix release` keeps the dependency; SendGrid ECDSA verify no longer risks `:undef` in production.
- **UAT gate:** `verify.phase_04` mix alias wired (mirrors `verify.phase_03`). Wave 0 zero-test pass is correct; Wave 4 Plan 09 ships the first `:phase_04_uat`-tagged tests.
- **Test infrastructure:** `Mailglass.WebhookFixtures` mints fresh ECDSA P-256 keypairs via `:crypto.generate_key/2`, signs SendGrid payloads via `:crypto.sign/4`, and builds Postmark Basic Auth headers. `Mailglass.WebhookCase` replaces its 36-line Phase 3 stub with the full D-26 helper suite: `mailglass_webhook_conn/3`, `assert_webhook_ingested/1,2`, `stub_postmark_fixture/1`, `stub_sendgrid_fixture/1`, `freeze_timestamp/1`.
- **Fixtures:** 7 payload-only JSON fixtures (5 Postmark `RecordType`-shaped + 2 SendGrid array-shaped) ready for plans 02+ to load.
- **API stability:** `docs/api_stability.md` gains a §Webhook section + 4 forward-ref markers so Plan 03 (verifier), Plan 06 (plug/router/ingest), and Plan 07 (reconciler) each know where to append their locked contracts.

## Task Commits

Each task was committed atomically:

1. **Task 1: Mix + Repo + Events foundation** — `54aced9` (feat)
2. **Deviation fix: raw_payload cleanup** — `2ea1e74` (fix — Rule 1 + Rule 3)
3. **Task 2: WebhookFixtures + WebhookCase + fixtures + api_stability scaffolding** — `6bcbcd5` (feat)

**Plan metadata:** _pending final commit after SUMMARY.md + STATE.md updates_

## Files Created/Modified

### Created

- `lib/mailglass/migrations/postgres/v02.ex` — V02 migration module (mailglass_webhook_events + raw_payload drop)
- `priv/repo/migrations/00000000000003_mailglass_webhook_events.exs` — migration wrapper calling `Mailglass.Migration.up/0` + down-version scoped to 1
- `test/support/webhook_fixtures.ex` — ECDSA P-256 keypair + SendGrid signing + Postmark Basic Auth + fixture loader (7 public functions)
- `test/support/fixtures/webhooks/postmark/{delivered,bounced,opened,clicked,spam_complaint}.json` — 5 Postmark fixtures with `RecordType` keys, `MessageID`, `Recipient`/`Email`
- `test/support/fixtures/webhooks/sendgrid/{single_event,batch_5_events}.json` — 2 SendGrid fixtures (array of events with `sg_event_id` + `sg_message_id`)

### Modified

- `mix.exs` — `:public_key` in `extra_applications`, `verify.phase_04` alias
- `lib/mailglass/repo.ex` — `query!/2` raw passthrough added
- `lib/mailglass/events/event.ex` — `:reconciled` in `@mailglass_internal_types`; `:raw_payload` removed from schema + cast + typespec
- `lib/mailglass/events.ex` — `@type attrs` drops `:raw_payload`
- `lib/mailglass/events/reconciler.ex` — `extract/2` chain is `:metadata → :normalized_payload`; moduledoc + @doc updated
- `lib/mailglass/adapters/fake.ex` — `trigger_event/3` writes to `:metadata` not `:raw_payload`
- `lib/mailglass/migrations/postgres.ex` — `@current_version 1 → 2`
- `test/support/webhook_case.ex` — replaced 36-line stub with full Wave 0 helper suite
- `docs/api_stability.md` — §Webhook section + 4 forward-ref markers + WebhookCase + WebhookFixtures subsections
- `test/mailglass/migration_test.exs` — two assertions bound to `current_version()`
- `test/mailglass/persistence_integration_test.exs` — `migrated_version()` assertion + one test's `raw_payload:` attrs renamed to `:metadata`
- `test/mailglass/events/reconciler_test.exs` — 5 `raw_payload:` → `metadata:` renames; "falls back to metadata" test rewritten as "falls back to normalized_payload"
- `test/mailglass/adapters/fake_test.exs` — assertion on `event.metadata` (was `event.raw_payload`)
- `test/mailglass/events/event_test.exs` — `valid_attrs/1` drops `:raw_payload` key
- `test/mailglass/outbound/projector_test.exs` — `build_event/2` drops `:raw_payload`
- `test/mailglass/outbound/projector_broadcast_test.exs` — same
- `test/mailglass/properties/idempotency_convergence_test.exs` — attrs generator drops `:raw_payload`
- `test/support/generators.ex` — attrs generator drops `:raw_payload`
- `.gitignore` — `/.claude/` (local tooling)

## Decisions Made

- **`:crypto.sign/4` over `:public_key.sign/3`** for fixture signing — the `{:ECPrivateKey, 1, priv, params, :asn1_NOVALUE, :asn1_NOVALUE}` 6-tuple shape required by OTP 27's `:public_key` module is fragile; the raw `:crypto.sign(:ecdsa, :sha256, _, [priv, :secp256r1])` path is stable across OTP versions and produces identical signatures that `:public_key.verify/4` (the production verifier path) accepts. Documented in `WebhookFixtures` moduledoc.
- **SPKI DER construction via `:public_key.pem_entry_encode(:SubjectPublicKeyInfo, {{:ECPoint, pub}, params})`** — extracting element 1 of the returned 3-tuple gives the raw DER bytes. `:public_key.der_encode(:EcpkParameters, ...)` was tried first but failed on OTP 27.3.x; `pem_entry_encode` round-trips cleanly with `:public_key.der_decode(:SubjectPublicKeyInfo, _)` which is exactly what Plan 03's SendGrid verifier will call.
- **`Fake.trigger_event/3` writes `:metadata`**, not `:raw_payload`. The opt is already called `:metadata`; the original "raw_payload" sink was a semantic mismatch. V02's DDL simply forced the correction.
- **Reconciler fallback chain inverted** — now `:metadata → :normalized_payload`, was `:raw_payload → :metadata`. Plan 06 Ingest writes provider identifiers into `:metadata` at insert time; orphan reconciliation reads the same field.
- **Migration wrapper #3 down-version scoped to 1** — `Mailglass.Migration.down(version: 1)` instead of bare `down()`. Bare `down()` reads pg_class for `migrated_version`, sees 2, and rolls back to 0 — dropping V01 AND V02, leaving the plain-Ecto migration 2 unable to reapply its `mailglass_deliveries_idempotency_key_unique_idx` on the next up. Per-wrapper down-version scoping is the correct pattern when multiple wrappers interleave with plain-Ecto migrations.
- **`assert_webhook_ingested/2` supports three dispatch forms** — bare (presence), event_type atom, meta map pattern. Matches the Phase 3 `assert_mail_sent/1` macro pattern. Plan 06 extends broadcast meta with `:provider` + `:event_count` without breaking the contract.
- **Provider config installed per-test** in WebhookCase setup with snapshot-restore on_exit. Tests that do not mutate the config (pure CachingBodyReader / header parsing) opt out via `@tag webhook_config: false` and can run `async: true`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug + Rule 3 — Blocking] `raw_payload` references broke after V02 drop**

- **Found during:** Task 1 verification (running `mix verify.phase_03` after Task 1 commit)
- **Issue:** V02 migration dropped `mailglass_events.raw_payload`, but 5 shipped code files + 7 test files still referenced the column. First failure: `Fake.trigger_event/3` INSERT raised `ERROR 42703 (undefined_column) column "raw_payload" does not exist`. Plan's RESEARCH Runtime State Inventory asserted the column was unused — it was partially right (no WRITER populated it with meaningful data) but the Ecto schema still declared the field and several call sites passed `raw_payload: %{}` as attrs, which Ecto translates into INSERT column lists.
- **Fix:**
  - `Mailglass.Events.Event` schema + cast + typespec drops `:raw_payload`
  - `Mailglass.Events` attrs typespec drops `:raw_payload`
  - `Mailglass.Adapters.Fake.trigger_event/3` writes `:metadata` (the correct semantic home — the opt was named `:metadata` all along)
  - `Mailglass.Events.Reconciler.extract/2` fallback chain flipped from `:raw_payload → :metadata` to `:metadata → :normalized_payload`
  - 7 test files cleaned up: attrs drop `:raw_payload: %{}` keys; reconciler_test renames + rewrites the "falls back" case; fake_test asserts on `event.metadata`
- **Files modified:** `lib/mailglass/events/event.ex`, `lib/mailglass/events.ex`, `lib/mailglass/events/reconciler.ex`, `lib/mailglass/adapters/fake.ex`, `test/mailglass/events/event_test.exs`, `test/mailglass/events/reconciler_test.exs`, `test/mailglass/adapters/fake_test.exs`, `test/mailglass/outbound/projector_test.exs`, `test/mailglass/outbound/projector_broadcast_test.exs`, `test/mailglass/persistence_integration_test.exs`, `test/mailglass/properties/idempotency_convergence_test.exs`, `test/support/generators.ex`
- **Verification:** Full-suite regressions went from 68 failures → 4 failures (all 4 are pre-existing citext OID staleness, Phase 2 deferred-items); `mix verify.phase_02` / `verify.phase_03` / `verify.phase_04` all exit 0
- **Committed in:** `2ea1e74` (separate fix commit — distinguished from feat commits)

**2. [Rule 1 — Bug] `Mailglass.Migration.migrated_version()` assertions hardcoded `== 1`**

- **Found during:** Running `mix verify.phase_02` after Task 1 commit
- **Issue:** Two tests asserted `migrated_version() == 1` — now returns 2 because `@current_version` was bumped. These are test-contract updates, not behaviour bugs.
- **Fix:** Both assertions now bound to `Mailglass.Migrations.Postgres.current_version()` so future V03+ bumps don't re-break them
- **Files modified:** `test/mailglass/migration_test.exs`, `test/mailglass/persistence_integration_test.exs`
- **Verification:** `mix verify.phase_02` 59/0/0; migration_test 8/0
- **Committed in:** `2ea1e74`

**3. [Rule 1 — Bug] Migration wrapper #3 `down/0` rolled back too far**

- **Found during:** Running `mix test test/mailglass/migration_test.exs` (migration_test's down/up round-trip)
- **Issue:** Wrapper #3's bare `Mailglass.Migration.down()` read `migrated_version` = 2 from pg_class and rolled back to 0 — dropping V01 in addition to V02. Then migration 2's down clause tried to drop `mailglass_deliveries_idempotency_key_unique_idx` which no longer existed (cascaded with its parent table V01's `mailglass_deliveries`). Error: `ERROR 42704 (undefined_object) index … does not exist`.
- **Fix:** Wrapper #3 now calls `Mailglass.Migration.down(version: 1)` — rolls back to V01 only, leaving the schema in a state where plain-Ecto migration 2 can cleanly apply its own down clause next. Per-wrapper ownership of V-step lifecycle is the correct pattern when wrappers interleave with plain-Ecto migrations.
- **Files modified:** `priv/repo/migrations/00000000000003_mailglass_webhook_events.exs`
- **Verification:** `mix test test/mailglass/migration_test.exs` → 8 tests, 0 failures
- **Committed in:** `2ea1e74`

---

**Total deviations:** 3 auto-fixed (2 × Rule 1 bug, 1 × Rule 1 + Rule 3 combo)
**Impact on plan:** All three were direct consequences of Task 1's migration (V02 dropped a column + bumped current_version); none represent scope creep. Pre-existing citext OID flakiness (4 failures in full-suite runs) is unchanged and remains in Phase 2 `deferred-items.md` per SCOPE BOUNDARY.

## Issues Encountered

- **`mix verify.phase_04` requires `MIX_ENV=test`** — the `ecto.drop -r Mailglass.TestRepo` step fails in dev env because `Mailglass.TestRepo` is only compiled under `elixirc_paths(:test)`. Matches `verify.phase_02` / `verify.phase_03` behaviour exactly; documented in `verify.phase_03` during Phase 3.
- **Local postgres role is `jon`, not `postgres`** — running on a dev laptop with homebrew Postgres. Test config already reads `POSTGRES_USER` env var with `"postgres"` default (config/test.exs), so `POSTGRES_USER=jon POSTGRES_PASSWORD='' mix verify.phase_04` is the local invocation. CI uses `postgres` defaults.
- **Full-suite run shows 4 pre-existing failures** — all `cache lookup failed for type X` errors from citext OID staleness after `migration_test.exs` runs its down/up round-trip. Documented in `.planning/phases/02-persistence-tenancy/deferred-items.md` with 4 candidate Phase 6 fixes. Not a Wave 0 regression.

## User Setup Required

None — no external service configuration. Phase 4 is library-only code; Plans 03+ will document adopter config keys (`config :mailglass, :postmark, :sendgrid`) in `guides/webhooks.md` (Phase 7).

## Next Phase Readiness

Wave 0 unblocks every downstream plan in Phase 4. Immediate dependencies:

- **Plan 02 (CachingBodyReader + Webhook.Plug)** — can `use Mailglass.WebhookCase, async: false` and call `mailglass_webhook_conn(:postmark, stub_postmark_fixture("delivered"))` from day 1.
- **Plan 03 (Postmark + SendGrid verifiers)** — `Mailglass.WebhookFixtures.generate_sendgrid_keypair/0` + `sign_sendgrid_payload/3` round-trip against `:public_key.verify/4` (proven at build time); `postmark_basic_auth_header/2` returns the exact wire format `Plug.Crypto.secure_compare/2` needs.
- **Plan 06 (Ingest Multi)** — `Mailglass.Repo.query!/2` unlocks `SET LOCAL statement_timeout = '2s'; SET LOCAL lock_timeout = '500ms'` inside `Repo.transact/1`; `mailglass_webhook_events` table ready for the first `INSERT ... ON CONFLICT (provider, provider_event_id) DO NOTHING` step.
- **Plan 07 (Reconciler)** — `:reconciled` atom callable; `Mailglass.Events.Event.changeset/1` accepts it via the `@event_types` concat.
- **Plans 02–08 (api_stability)** — 4 forward-ref markers + §Webhook placeholder make it clear where each plan's locked contracts append without collision.

**Blockers or concerns:** None.

**Phase 4 progress:** 1/9 plans complete.

## Self-Check: PASSED

All 12 created files exist at the documented paths; all 3 task/deviation commits (`54aced9`, `2ea1e74`, `6bcbcd5`) are present in `git log --all`.

---
*Phase: 04-webhook-ingest*
*Completed: 2026-04-23*
