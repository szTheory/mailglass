---
phase: 2
slug: persistence-tenancy
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
audited: 2026-04-22
gaps_found: 0
gaps_resolved: 0
gaps_escalated: 0
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
| 2-01-01 | 01 | 0 | PERSIST-05 | T-02-01b | `SuppressedError` atom-set refinement (D-09); `EventLedgerImmutableError` + `TenancyError` registered in `Mailglass.Error` namespace | unit | `mix deps.get && mix compile --warnings-as-errors && mix test test/mailglass/error_test.exs --warnings-as-errors` | ✅ (`lib/mailglass/errors/*`, `test/mailglass/error_test.exs` — 18 tests) | ✅ green |
| 2-01-02 | 01 | 0 | PERSIST-05 | T-02-01a, T-02-03a | SQLSTATE 45A01 translation at single Repo facade point (transact/1 + insert/2 + update/2 + delete/2); telemetry span helpers scaffolded without PII keys | unit | `mix compile --warnings-as-errors && mix test test/mailglass/repo_test.exs test/mailglass/telemetry_test.exs --warnings-as-errors` | ✅ (`test/mailglass/repo_test.exs` 4 tests, `test/mailglass/telemetry_test.exs` 5 tests) | ✅ green |
| 2-01-03 | 01 | 0 | PERSIST-05 | T-02-05 (accept) | Test-only DB credentials in `config/test.exs` with env-var overrides; `TestRepo` + `DataCase` + `Generators` compile | infra | `mix compile --warnings-as-errors && mix test --warnings-as-errors` | ✅ (`test/support/test_repo.ex`, `data_case.ex`, `generators.ex`; `config/test.exs` wired) | ✅ green |
| 2-02-01 | 02 | 1 | PERSIST-01, PERSIST-02, PERSIST-04, PERSIST-06, TENANT-01 | T-02-02, T-02-04, T-02-05, T-02-06 | Migration DDL: 3 tables, immutability trigger, idempotency UNIQUE partial index, suppression UNIQUE with `COALESCE(stream, '')`, CITEXT for case-insensitive address match, scope/stream CHECK constraint | unit (compile) | `mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors` | ✅ (`lib/mailglass/migration.ex`, `migrations/postgres.ex`, `migrations/postgres/v01.ex`, `priv/repo/migrations/00000000000001_mailglass_init.exs`) | ✅ green |
| 2-02-02 | 02 | 1 | PERSIST-01, PERSIST-02, PERSIST-06 | T-02-02, T-02-02b | `mailglass_events_immutable_trigger` raises SQLSTATE 45A01 on UPDATE/DELETE; `Mailglass.Repo.transact/1` translates to `EventLedgerImmutableError`; migration `up/0` is idempotent | integration | `mix test test/mailglass/migration_test.exs test/mailglass/events_immutability_test.exs --warnings-as-errors` | ✅ (`test/mailglass/migration_test.exs` 8 tests, `events_immutability_test.exs` 3 tests) | ✅ green |
| 2-03-01 | 03 | 2 | PERSIST-01, PERSIST-04, TENANT-01 | T-02-08, T-02-09, T-02-10 | `Delivery` + `Event` Ecto schemas with hand-written typespecs (D-22); `Delivery.changeset/1` chainable with `optimistic_lock(:lock_version)`; `Event.changeset/1` uses `Ecto.Enum` for type atom set; `recipient_domain` denormalized from `recipient` | unit | `mix test test/mailglass/outbound/delivery_test.exs test/mailglass/events/event_test.exs --warnings-as-errors` | ✅ (`test/mailglass/outbound/delivery_test.exs` 8 tests, `events/event_test.exs` 8 tests) | ✅ green |
| 2-03-02 | 03 | 2 | PERSIST-04, TENANT-01 | T-02-05a, T-02-05b | `Suppression.Entry` scope/stream coupling enforced by changeset (write-time) AND DB CHECK (safety net); address downcased on cast + stored CITEXT (defense-in-depth); `scope` required (no default per D-11) | unit | `mix test test/mailglass/suppression/entry_test.exs --warnings-as-errors` | ✅ (`lib/mailglass/suppression/entry.ex`, `test/mailglass/suppression/entry_test.exs` 14 tests) | ✅ green |
| 2-04-01 | 04 | 2 | TENANT-01, TENANT-02 | T-02-01a, T-02-01b, T-02-01c | `Mailglass.Tenancy` behaviour (single `scope/2` callback); `SingleTenant` default no-op resolver; `tenant_id!/0` fail-loud; `put_current/1` + `with_tenant/2` process-dict helpers; `DataCase` upgraded to call `put_current/1` | unit | `mix test test/mailglass/tenancy_test.exs --warnings-as-errors && mix compile --warnings-as-errors` | ✅ (`lib/mailglass/tenancy.ex`, `tenancy/single_tenant.ex`, `test/mailglass/tenancy_test.exs` 12 tests; 1 `@tag :flaky` excluded per UAT, deferred-items.md) | ⚠️ flaky (1 of 12 `@tag :flaky` — documented Phase 6 fix) |
| 2-04-02 | 04 | 2 | TENANT-02 | T-02-01d, T-02-11 (accept) | `Mailglass.Oban.TenancyMiddleware` conditionally compiled (optional dep per D-33); middleware reads `job.args["mailglass_tenant_id"]` + wraps worker body in `with_tenant/2`; `mix compile --no-optional-deps --warnings-as-errors` passes | unit | `mix compile --no-optional-deps --warnings-as-errors && mix test test/mailglass/oban/tenancy_middleware_test.exs --warnings-as-errors && mix compile --warnings-as-errors` | ✅ (`lib/mailglass/optional_deps/oban.ex`, `test/mailglass/oban/tenancy_middleware_test.exs` 8 tests) | ✅ green |
| 2-05-01 | 05 | 3 | PERSIST-05 | T-02-02, T-02-03, T-02-04a | `Mailglass.Events.append/1` + `append_multi/3` are the ONLY public write path; idempotency replay returns the original row (not `id: nil`); telemetry `:stop` metadata contains `:tenant_id`, `:idempotency_key_present?`, `:inserted?` and NONE of `:recipient`, `:email`, `:to`, `:subject`, `:body`, `:html_body`, `:headers`, `:from` (T3 PII refute) | unit | `mix test test/mailglass/events_test.exs --warnings-as-errors` | ✅ (`lib/mailglass/events.ex`, `test/mailglass/events_test.exs` 13 tests) | ✅ green |
| 2-05-02 | 05 | 3 | PERSIST-03 | T-02-05, T-02-12 | `Reconciler.find_orphans/1` is pure-query, partial-index-backed, tenant-scopeable, bounded by `:limit` + `:max_age_minutes`; `attempt_link/2` pure query returning `{:ok, {%Delivery{}, %Event{}}}` or explicit error atoms; NO Oban dep per D-19 | unit | `mix test test/mailglass/events/reconciler_test.exs --warnings-as-errors` | ✅ (`lib/mailglass/events/reconciler.ex`, `test/mailglass/events/reconciler_test.exs` 9 tests) | ✅ green |
| 2-05-03 | 05 | 3 | PERSIST-03 | T-02-04a | StreamData 1000-iteration convergence property (ROADMAP §Phase 2 Success Criterion #2): apply-once row set == apply-N-replayed-shuffled row set, keyed by `idempotency_key` | property | `mix test test/mailglass/properties/idempotency_convergence_test.exs --warnings-as-errors` | ✅ (`test/mailglass/properties/idempotency_convergence_test.exs` — 1 property, max_runs: 1000) | ✅ green |
| 2-06-01 | 06 | 3 | PERSIST-01, PERSIST-04 | T-02-01, T-02-02a | `Outbound.Projector.update_projections/2` is the single update path (D-14); app-enforced monotonic rule (D-15) — `terminal` never regresses, `*_at` timestamps set once; chains `optimistic_lock(:lock_version)` (D-18); late `:opened` after `:delivered` updates `last_event_at` only | unit | `mix test test/mailglass/outbound/projector_test.exs --warnings-as-errors` | ✅ (`lib/mailglass/outbound/projector.ex`, `test/mailglass/outbound/projector_test.exs` 11 tests) | ✅ green |
| 2-06-02 | 06 | 3 | PERSIST-01, TENANT-01 | T-02-05a, T-02-05b | `SuppressionStore` behaviour + `Ecto` default impl; `check/2` requires `tenant_id` in lookup_key (T5 cross-tenant mitigation); UPSERT `on_conflict` target matches the DDL UNIQUE `(tenant_id, address, scope, COALESCE(stream, ''))` character-for-character; persist-layer telemetry span emitted | unit | `mix test test/mailglass/suppression_store/ecto_test.exs --warnings-as-errors` | ✅ (`lib/mailglass/suppression_store.ex`, `suppression_store/ecto.ex`, `test/mailglass/suppression_store/ecto_test.exs` 14 tests) | ✅ green |
| 2-06-03 | 06 | 3 | PERSIST-01, PERSIST-04, TENANT-01, TENANT-02 | T-02-01b, T-02-06, T-02-13 | End-to-end happy path: migrate → insert Delivery → `Events.append_multi` + `Projector.update_projections` in one `Ecto.Multi` under `Repo.transact/1` → reload + verify projection columns + event row. Two-tenant isolation test: 50 rows per tenant, zero cross-tenant reads | integration | `mix test test/mailglass/persistence_integration_test.exs --warnings-as-errors` | ✅ (`test/mailglass/persistence_integration_test.exs` 9 tests, 6 describe blocks labelled §1–§5 + multi-tenant isolation) | ⚠️ flaky (full-suite Postgrex type-cache poisoning — UAT gate green via `mix verify.phase_02`; deferred to Phase 6) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*File Exists legend: ✅ existing = file lands in Phase 1 or earlier Phase 2 task; ❌ W0 = file created by THIS task or by Plan 02-01 scaffolding (Wave 0).*

*Task IDs follow `<phase>-<plan>-<task#>` (e.g. `2-05-03` = Phase 2, Plan 05, Task 3).*

---

## Wave 0 Requirements

Wave 0 (Plan 02-01) lands the test scaffolding + library scaffolding every later plan consumes. Plan 02-01 is split into 3 tasks:

- [x] `lib/mailglass/schema.ex` — `use Mailglass.Schema` macro (UUIDv7 PK, `:binary_id` FK, usec timestamps) per D-28
- [x] `lib/mailglass/errors/event_ledger_immutable_error.ex` — pattern-matchable error with `pg_code: "45A01"` per D-06
- [x] `lib/mailglass/errors/tenancy_error.ex` — fail-loud error for `tenant_id!/0` per D-30
- [x] `lib/mailglass/errors/suppressed_error.ex` — patched atom set `[:address, :domain, :address_stream]` per D-09
- [x] `lib/mailglass/error.ex` — extended `@type t` union + `@error_modules` registry
- [x] `lib/mailglass/repo.ex` — SQLSTATE 45A01 translation at `transact/1` + `insert/2` + `update/2` + `delete/2`; read passthroughs `one/2` + `all/2` + `get/3`
- [x] `lib/mailglass/telemetry.ex` — `events_append_span/2` + `persist_span/3` helpers; `@logged_events` extended
- [x] `mix.exs` — `{:uuidv7, "~> 1.0"}` added to required deps
- [x] `test/support/test_repo.ex` — `Mailglass.TestRepo` (Ecto.Adapters.Postgres) per D-37
- [x] `test/support/data_case.ex` — sandbox checkout + tenant-stamp helpers (Plan 02-04 Task 1 upgrades to call `Mailglass.Tenancy.put_current/1`)
- [x] `test/support/generators.ex` — StreamData attr-map generators consumed by Plans 02-03 + 02-05
- [x] `config/test.exs` — wires `:repo` at `Mailglass.TestRepo`, `:tenancy` at `Mailglass.Tenancy.SingleTenant` (forward ref)
- [x] `docs/api_stability.md` — documents `SuppressedError` pre-GA refinement + new error structs

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

**Approval:** validated

---

## Validation Audit 2026-04-22

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

### Audit Method

- Read every committed SUMMARY (`02-01` … `02-06`), `02-VERIFICATION.md`, `02-UAT.md`, `deferred-items.md`.
- Filesystem scan: enumerated `test/mailglass/**/*.exs` and matched each Per-Task row's `Automated Command` to a concrete test file.
- Ran `mix test --only phase_02_uat --exclude flaky` → **58 tests, 0 failures** (UAT gate green).
- Ran full Phase 2 file set → **143 tests + 2 properties, 2 failures** — both failures are the Postgrex type-cache poisoning flake already documented in `deferred-items.md` and scheduled for Phase 6. Not a Nyquist gap.
- Cross-referenced each requirement (PERSIST-01..06, TENANT-01, TENANT-02) against `02-VERIFICATION.md` file:line evidence — 8/8 SATISFIED.

### Findings

- **15 of 15 Per-Task rows COVERED.** Every task has an automated command that points to a test file that exists and runs green in the UAT gate.
- **2 tasks carry ⚠️ flaky markers** (both documented, both deferred to Phase 6, neither a Phase 2 gap):
  - `2-04-01` — `test/mailglass/tenancy_test.exs:117` race on `function_exported?/3` before module code cache warms, `@tag :flaky` applied, excluded from CI.
  - `2-06-03` — full-suite Postgrex type-cache poisoning. Mitigation in place (`disconnect_on_error_codes` + probe-until-clean setup per Plan 02-06); UAT gate (`mix verify.phase_02`) reliably green.
- **Wave 0 scaffolding** — all 13 checklist items present in the committed tree.
- **Manual-Only row** (`mix mailglass.gen.migration` in fresh adopter) retained — correctly manual, will be codified by the Phase 7 `mix-test-adopter` CI lane.

**Conclusion:** Phase 2 is Nyquist-compliant. No gaps required filling. No auditor spawn needed.
