---
phase: 2
slug: persistence-tenancy
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18+) + StreamData (property tests) + Ecto SQL Sandbox |
| **Config file** | `test/test_helper.exs` — starts `Mailglass.TestRepo`, runs `Mailglass.Migration.up/0`, sets Sandbox `:manual` mode |
| **Case templates** | `Mailglass.DataCase` (sandbox checkout + tenant stamp; introduced in Plan 02-01 / Task 3, upgraded in Plan 02-04 / Task 1 to call `Mailglass.Tenancy.put_current/1`) |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix test --trace` |
| **Estimated runtime** | ~15 seconds (unit) / ~90 seconds (property + integration) |

---

## Sampling Rate

- **After every task commit:** `mix test --stale`
- **After every plan wave:** `mix test --trace`
- **Before `/gsd-verify-work`:** Full suite green (incl. 1000-iteration idempotency property test)
- **Max feedback latency:** 90 seconds (full) / 15 seconds (stale)

---

## Per-Task Verification Map

> One row per task across all 6 plans. Requirement IDs, threat refs, and automated commands are extracted from the committed plans.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 0 | PERSIST-05 | T-02-01b | `SuppressedError` atom-set refinement (D-09); `EventLedgerImmutableError` + `TenancyError` registered in `Mailglass.Error` namespace | unit | `mix deps.get && mix compile --warnings-as-errors && mix test test/mailglass/error_test.exs --warnings-as-errors` | ✅ existing (`lib/mailglass/errors/*`, `test/mailglass/error_test.exs`) | ⬜ pending |
| 2-01-02 | 01 | 0 | PERSIST-05 | T-02-01a, T-02-03a | SQLSTATE 45A01 translation at single Repo facade point (transact/1 + insert/2 + update/2 + delete/2); telemetry span helpers scaffolded without PII keys | unit | `mix compile --warnings-as-errors && mix test test/mailglass/repo_test.exs test/mailglass/telemetry_test.exs --warnings-as-errors` | ✅ existing (`test/mailglass/repo_test.exs`, `test/mailglass/telemetry_test.exs`) | ⬜ pending |
| 2-01-03 | 01 | 0 | PERSIST-05 | T-02-05 (accept) | Test-only DB credentials in `config/test.exs` with env-var overrides; `TestRepo` + `DataCase` + `Generators` compile | infra | `mix compile --warnings-as-errors && mix test --warnings-as-errors` | ❌ W0 (creates `test/support/test_repo.ex`, `test/support/data_case.ex`, `test/support/generators.ex`, patches `config/test.exs`) | ⬜ pending |
| 2-02-01 | 02 | 1 | PERSIST-01, PERSIST-02, PERSIST-04, PERSIST-06, TENANT-01 | T-02-02, T-02-04, T-02-05, T-02-06 | Migration DDL: 3 tables, immutability trigger, idempotency UNIQUE partial index, suppression UNIQUE with `COALESCE(stream, '')`, CITEXT for case-insensitive address match, scope/stream CHECK constraint | unit (compile) | `mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors` | ❌ W0 (creates `lib/mailglass/migration.ex`, `lib/mailglass/migrations/postgres.ex`, `lib/mailglass/migrations/postgres/v01.ex`, `priv/repo/migrations/00000000000001_mailglass_init.exs`) | ⬜ pending |
| 2-02-02 | 02 | 1 | PERSIST-01, PERSIST-02, PERSIST-06 | T-02-02, T-02-02b | `mailglass_events_immutable_trigger` raises SQLSTATE 45A01 on UPDATE/DELETE; `Mailglass.Repo.transact/1` translates to `EventLedgerImmutableError`; migration `up/0` is idempotent | integration | `mix test test/mailglass/migration_test.exs test/mailglass/events_immutability_test.exs --warnings-as-errors` | ❌ W0 (creates `test/test_helper.exs` patch, `test/mailglass/migration_test.exs`, `test/mailglass/events_immutability_test.exs`) | ⬜ pending |
| 2-03-01 | 03 | 2 | PERSIST-01, PERSIST-04, TENANT-01 | T-02-08, T-02-09, T-02-10 | `Delivery` + `Event` Ecto schemas with hand-written typespecs (D-22); `Delivery.changeset/1` chainable with `optimistic_lock(:lock_version)`; `Event.changeset/1` uses `Ecto.Enum` for type atom set; `recipient_domain` denormalized from `recipient` | unit | `mix test test/mailglass/outbound/delivery_test.exs test/mailglass/events/event_test.exs --warnings-as-errors` | ❌ W0 (creates `lib/mailglass/outbound/delivery.ex`, `lib/mailglass/events/event.ex`, test files) | ⬜ pending |
| 2-03-02 | 03 | 2 | PERSIST-04, TENANT-01 | T-02-05a, T-02-05b | `Suppression.Entry` scope/stream coupling enforced by changeset (write-time) AND DB CHECK (safety net); address downcased on cast + stored CITEXT (defense-in-depth); `scope` required (no default per D-11) | unit | `mix test test/mailglass/suppression/entry_test.exs --warnings-as-errors` | ❌ W0 (creates `lib/mailglass/suppression/entry.ex`, `test/mailglass/suppression/entry_test.exs`) | ⬜ pending |
| 2-04-01 | 04 | 2 | TENANT-01, TENANT-02 | T-02-01a, T-02-01b, T-02-01c | `Mailglass.Tenancy` behaviour (single `scope/2` callback); `SingleTenant` default no-op resolver; `tenant_id!/0` fail-loud; `put_current/1` + `with_tenant/2` process-dict helpers; `DataCase` upgraded to call `put_current/1` | unit | `mix test test/mailglass/tenancy_test.exs --warnings-as-errors && mix compile --warnings-as-errors` | ❌ W0 (creates `lib/mailglass/tenancy.ex`, `lib/mailglass/tenancy/single_tenant.ex`, test file; patches `test/support/data_case.ex`) | ⬜ pending |
| 2-04-02 | 04 | 2 | TENANT-02 | T-02-01d, T-02-11 (accept) | `Mailglass.Oban.TenancyMiddleware` conditionally compiled (optional dep per D-33); middleware reads `job.args["mailglass_tenant_id"]` + wraps worker body in `with_tenant/2`; `mix compile --no-optional-deps --warnings-as-errors` passes | unit | `mix compile --no-optional-deps --warnings-as-errors && mix test test/mailglass/oban/tenancy_middleware_test.exs --warnings-as-errors && mix compile --warnings-as-errors` | ❌ W0 (patches `lib/mailglass/optional_deps/oban.ex`, creates `test/mailglass/oban/tenancy_middleware_test.exs`) | ⬜ pending |
| 2-05-01 | 05 | 3 | PERSIST-05 | T-02-02, T-02-03, T-02-04a | `Mailglass.Events.append/1` + `append_multi/3` are the ONLY public write path; idempotency replay returns the original row (not `id: nil`); telemetry `:stop` metadata contains `:tenant_id`, `:idempotency_key_present?`, `:inserted?` and NONE of `:recipient`, `:email`, `:to`, `:subject`, `:body`, `:html_body`, `:headers`, `:from` (T3 PII refute) | unit | `mix test test/mailglass/events_test.exs --warnings-as-errors` | ❌ W0 (creates `lib/mailglass/events.ex`, `test/mailglass/events_test.exs`) | ⬜ pending |
| 2-05-02 | 05 | 3 | PERSIST-03 | T-02-05, T-02-12 | `Reconciler.find_orphans/1` is pure-query, partial-index-backed, tenant-scopeable, bounded by `:limit` + `:max_age_minutes`; `attempt_link/2` pure query returning `{:ok, {%Delivery{}, %Event{}}}` or explicit error atoms; NO Oban dep per D-19 | unit | `mix test test/mailglass/events/reconciler_test.exs --warnings-as-errors` | ❌ W0 (creates `lib/mailglass/events/reconciler.ex`, `test/mailglass/events/reconciler_test.exs`) | ⬜ pending |
| 2-05-03 | 05 | 3 | PERSIST-03 | T-02-04a | StreamData 1000-iteration convergence property (ROADMAP §Phase 2 Success Criterion #2): apply-once row set == apply-N-replayed-shuffled row set, keyed by `idempotency_key` | property | `mix test test/mailglass/properties/idempotency_convergence_test.exs --warnings-as-errors` | ❌ W0 (creates `test/mailglass/properties/idempotency_convergence_test.exs`) | ⬜ pending |
| 2-06-01 | 06 | 3 | PERSIST-01, PERSIST-04 | T-02-01, T-02-02a | `Outbound.Projector.update_projections/2` is the single update path (D-14); app-enforced monotonic rule (D-15) — `terminal` never regresses, `*_at` timestamps set once; chains `optimistic_lock(:lock_version)` (D-18); late `:opened` after `:delivered` updates `last_event_at` only | unit | `mix test test/mailglass/outbound/projector_test.exs --warnings-as-errors` | ❌ W0 (creates `lib/mailglass/outbound/projector.ex`, `test/mailglass/outbound/projector_test.exs`) | ⬜ pending |
| 2-06-02 | 06 | 3 | PERSIST-01, TENANT-01 | T-02-05a, T-02-05b | `SuppressionStore` behaviour + `Ecto` default impl; `check/2` requires `tenant_id` in lookup_key (T5 cross-tenant mitigation); UPSERT `on_conflict` target matches the DDL UNIQUE `(tenant_id, address, scope, COALESCE(stream, ''))` character-for-character; persist-layer telemetry span emitted | unit | `mix test test/mailglass/suppression_store/ecto_test.exs --warnings-as-errors` | ❌ W0 (creates `lib/mailglass/suppression_store.ex`, `lib/mailglass/suppression_store/ecto.ex`, test files) | ⬜ pending |
| 2-06-03 | 06 | 3 | PERSIST-01, PERSIST-04, TENANT-01, TENANT-02 | T-02-01b, T-02-06, T-02-13 | End-to-end happy path: migrate → insert Delivery → `Events.append_multi` + `Projector.update_projections` in one `Ecto.Multi` under `Repo.transact/1` → reload + verify projection columns + event row. Two-tenant isolation test: 50 rows per tenant, zero cross-tenant reads | integration | `mix test test/mailglass/persistence_integration_test.exs --warnings-as-errors` | ❌ W0 (creates `test/mailglass/persistence_integration_test.exs`) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*File Exists legend: ✅ existing = file lands in Phase 1 or earlier Phase 2 task; ❌ W0 = file created by THIS task or by Plan 02-01 scaffolding (Wave 0).*

*Task IDs follow `<phase>-<plan>-<task#>` (e.g. `2-05-03` = Phase 2, Plan 05, Task 3).*

---

## Wave 0 Requirements

Wave 0 (Plan 02-01) lands the test scaffolding + library scaffolding every later plan consumes. Plan 02-01 is split into 3 tasks:

- [ ] `lib/mailglass/schema.ex` — `use Mailglass.Schema` macro (UUIDv7 PK, `:binary_id` FK, usec timestamps) per D-28
- [ ] `lib/mailglass/errors/event_ledger_immutable_error.ex` — pattern-matchable error with `pg_code: "45A01"` per D-06
- [ ] `lib/mailglass/errors/tenancy_error.ex` — fail-loud error for `tenant_id!/0` per D-30
- [ ] `lib/mailglass/errors/suppressed_error.ex` — patched atom set `[:address, :domain, :address_stream]` per D-09
- [ ] `lib/mailglass/error.ex` — extended `@type t` union + `@error_modules` registry
- [ ] `lib/mailglass/repo.ex` — SQLSTATE 45A01 translation at `transact/1` + `insert/2` + `update/2` + `delete/2`; read passthroughs `one/2` + `all/2` + `get/3`
- [ ] `lib/mailglass/telemetry.ex` — `events_append_span/2` + `persist_span/3` helpers; `@logged_events` extended
- [ ] `mix.exs` — `{:uuidv7, "~> 1.0"}` added to required deps
- [ ] `test/support/test_repo.ex` — `Mailglass.TestRepo` (Ecto.Adapters.Postgres) per D-37
- [ ] `test/support/data_case.ex` — sandbox checkout + tenant-stamp helpers (Plan 02-04 Task 1 upgrades to call `Mailglass.Tenancy.put_current/1`)
- [ ] `test/support/generators.ex` — StreamData attr-map generators consumed by Plans 02-03 + 02-05
- [ ] `config/test.exs` — wires `:repo` at `Mailglass.TestRepo`, `:tenancy` at `Mailglass.Tenancy.SingleTenant` (forward ref)
- [ ] `docs/api_stability.md` — documents `SuppressedError` pre-GA refinement + new error structs

*Wave 0 (Plan 02-01) MUST ship before any Wave 1+ plan begins. Plans 02-02 through 02-06 all `depends_on: ["02-01"]` transitively.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `mix mailglass.gen.migration` produces a runnable migration file in a fresh adopter app | PERSIST-06 | Requires integrator-level flow (new Phoenix app, add dep, run generator, run `mix ecto.migrate`) — not feasible inside unit test sandbox | Scripted in release checklist; CI `mix-test-adopter` lane (Phase 7) codifies this end-to-end; interim: manual smoke run on sibling scratch app |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all Plan 02-01 scaffolding referenced by later tasks
- [x] No watch-mode flags (CI lane uses `mix test`, not `mix test.watch`)
- [x] Feedback latency < 90s full / < 15s stale
- [x] `nyquist_compliant: true` — every task maps to an automated command
- [x] `wave_0_complete: true` — Plan 02-01 scaffolding enumerated above matches the committed plan

**Approval:** ready
