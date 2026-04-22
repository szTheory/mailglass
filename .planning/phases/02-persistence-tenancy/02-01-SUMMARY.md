---
phase: 02-persistence-tenancy
plan: 01
subsystem: persistence
tags: [ecto, uuidv7, telemetry, errors, postgres, scaffolding]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "Mailglass.Error behaviour + 6 error structs, Mailglass.Telemetry.span/3 + render_span/2, Mailglass.Repo.transact/1 facade with :repo config lookup, Mailglass.Config NimbleOptions schema, :persistent_term theme cache, Mailglass.OptionalDeps.Oban gateway"
provides:
  - "Mailglass.Schema DRY macro (UUIDv7 PK + :binary_id FK + utc_datetime_usec timestamps) consumed by Plan 03 schemas"
  - "Mailglass.EventLedgerImmutableError + Mailglass.TenancyError error structs registered in Mailglass.Error namespace"
  - "Mailglass.SuppressedError pre-GA patch — @types now [:address, :domain, :address_stream]"
  - "Mailglass.Repo facade with SQLSTATE 45A01 translation active on transact/1, insert/2, update/2, delete/2 (+ passthrough one/2, all/2, get/3)"
  - "Mailglass.Telemetry.events_append_span/2 + persist_span/3 helpers (consumed by Plan 05 Events writer + Plan 06 Projector)"
  - "Mailglass.TestRepo + Mailglass.DataCase + Mailglass.Generators test infrastructure (consumed by Plans 02-06)"
  - ":ecto_sql + :postgrex + :uuidv7 required deps"
affects: [02-persistence-tenancy plans 02-06, 03-outbound, 04-webhook, 05-admin]

# Tech tracking
tech-stack:
  added: [":uuidv7 ~> 1.0 (required, consumed by Mailglass.Schema)", ":ecto ~> 3.13 (required, was transitive)", ":ecto_sql ~> 3.13 (required, was transitive)", ":postgrex ~> 0.22 (required, needed for %Postgrex.Error{} pattern at compile time)"]
  patterns: ["SQLSTATE 45A01 translation centralized in single translate_postgrex_error/2 defp per D-06", "Error struct shape — 8 steps per structure (behaviour, @types, @derive, defexception, @type t, __types__/0, callbacks, new/2) — replicates config_error.ex verbatim", "Schema macro stamps three module attributes, no magic — consistent with Phase 1's 'pluggable behaviours over magic' DNA"]

key-files:
  created:
    - "lib/mailglass/schema.ex — DRY macro for schema conventions (D-28)"
    - "lib/mailglass/errors/event_ledger_immutable_error.ex — SQLSTATE 45A01 translation target (D-06)"
    - "lib/mailglass/errors/tenancy_error.ex — fail-loud error for tenant_id!/0 (D-30)"
    - "test/support/test_repo.ex — mailglass's own test Ecto Repo (D-37)"
    - "test/support/data_case.ex — ExUnit case template with sandbox + tenant helpers"
    - "test/support/generators.ex — StreamData attr-map generators for Plan 03/05"
  modified:
    - "mix.exs — added :uuidv7 (D-25) + :ecto/:ecto_sql/:postgrex (closed the transitive-deps gap so Plan 01's SQLSTATE translation compiles)"
    - "lib/mailglass/errors/suppressed_error.ex — D-09 pre-GA atom-set refinement :tenant_address → :address_stream"
    - "lib/mailglass/error.ex — @type t union + @error_modules list extended with two new structs"
    - "lib/mailglass/repo.ex — activated SQLSTATE 45A01 translation + added insert/2, update/2, delete/2, one/2, all/2, get/3 passthroughs"
    - "lib/mailglass/telemetry.ex — added events_append_span/2 + persist_span/3; extended @logged_events"
    - "docs/api_stability.md — documented SuppressedError refinement + the two new error structs"
    - "test/mailglass/error_test.exs — updated SuppressedError atom-set assertion for D-09"
    - "config/test.exs — wired :repo → Mailglass.TestRepo, :tenancy → Mailglass.Tenancy.SingleTenant, Postgres credentials"

key-decisions:
  - "Added :ecto, :ecto_sql, :postgrex as explicit required deps. PROJECT.md declared them required from v0.1 but Phase 1 left them transitive-only. SQLSTATE translation cannot compile without Postgrex.Error at compile time — closed the gap here rather than in Plan 02."
  - "Mailglass.Repo facade grew from transact-only to a six-function surface (transact/1, insert/2, update/2, delete/2 with SQLSTATE translation + passthrough one/2, all/2, get/3). Single translate_postgrex_error/2 helper is the one translation point; adding new write functions means wiring the same rescue clause."
  - "DataCase stamps tenant_id directly via Process.put(:mailglass_tenant_id, ...) as a forward reference. Plan 04 ships Mailglass.Tenancy.put_current/1 under the same process-dict key and updates the setup to use it."
  - "EventLedgerImmutableError.new/2 infers :update_attempt as the default immutability type. Postgrex error messages are not a stable API (Pitfall 3) — callers that care about UPDATE vs DELETE walk :cause to the raw Postgrex error or read ctx.pg_code."

patterns-established:
  - "Pattern 1: Error struct — @behaviour Mailglass.Error + @types [...] closed atom set + @derive Jason.Encoder (excludes :cause) + defexception + @type t + __types__/0 + type/1 + retryable?/1 + message/1 + new/2. Replicates config_error.ex verbatim."
  - "Pattern 2: SQLSTATE translation — every Repo write function wraps the delegate call in try/rescue %Postgrex.Error{}, routes through translate_postgrex_error/2, which pattern-matches pg_code: \"45A01\" and reraises Mailglass.EventLedgerImmutableError."
  - "Pattern 3: Named telemetry span helpers — wrap span/3 with [:mailglass, :<domain>, :<resource>, :<action>] prefix + metadata map + zero-arity fun. Extends @logged_events for attach_default_logger/1."
  - "Pattern 4: Test infrastructure as forward references — TestRepo/DataCase/Generators compile standalone in Plan 01; Plan 02 adds migration runs, Plan 03 adds schemas the generators target, Plan 04 replaces raw Process.put with Tenancy.put_current/1."

requirements-completed: [PERSIST-05]

# Metrics
duration: 7min
completed: 2026-04-22
---

# Phase 02 Plan 01: Scaffolding Summary

**Mailglass.Schema macro, two new pattern-matchable error structs (EventLedger + Tenancy), activated SQLSTATE 45A01 translation on Repo facade, two new telemetry span helpers, and Wave 0 test infrastructure (TestRepo + DataCase + Generators) — Phase 2 scaffolding complete.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-22T17:54:47Z
- **Completed:** 2026-04-22T18:01:45Z
- **Tasks:** 3
- **Files created:** 6
- **Files modified:** 8

## Accomplishments

- `Mailglass.Schema` DRY macro stamps UUIDv7 PK + `:binary_id` FK + `utc_datetime_usec` timestamps per D-28 — three module attributes, no behaviour injection, consistent with Phase 1's "pluggable behaviours over magic" DNA
- Two new pattern-matchable error structs (`Mailglass.EventLedgerImmutableError`, `Mailglass.TenancyError`) registered in `Mailglass.Error` namespace; `is_error?/1`, `retryable?/1`, `root_cause/1` all work against them
- `Mailglass.SuppressedError` pre-GA atom-set refinement (D-09) from `[:address, :domain, :tenant_address]` to `[:address, :domain, :address_stream]` to match the forthcoming `mailglass_suppressions.scope` column
- `Mailglass.Repo` facade now translates `%Postgrex.Error{pg_code: "45A01"}` into `Mailglass.EventLedgerImmutableError` at every write site (`transact/1`, `insert/2`, `update/2`, `delete/2`) — one translation point, six new passthroughs
- `Mailglass.Telemetry.events_append_span/2` + `persist_span/3` land on the 4-level event-path convention; `@logged_events` extended
- `Mailglass.TestRepo` + `Mailglass.DataCase` + `Mailglass.Generators` compile standalone so Plans 02-06 can consume them
- `docs/api_stability.md` documents the SuppressedError refinement and the two new error structs
- 95 existing tests still pass under `mix test --warnings-as-errors`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add :uuidv7 dep, Schema macro, EventLedgerImmutableError, TenancyError, SuppressedError patch, Error registry update, api_stability.md edits** — `6859034` (feat)
2. **Task 2: SQLSTATE 45A01 translation in Mailglass.Repo + Telemetry spans** — `c82fffa` (feat)
3. **Task 3: TestRepo + DataCase + Generators + config/test.exs DB wiring** — `b058da7` (feat)

## Files Created/Modified

**Created (6):**
- `lib/mailglass/schema.ex` — `use Mailglass.Schema` macro per D-28
- `lib/mailglass/errors/event_ledger_immutable_error.ex` — SQLSTATE 45A01 translation target per D-06
- `lib/mailglass/errors/tenancy_error.ex` — fail-loud error for `tenant_id!/0` per D-30
- `test/support/test_repo.ex` — mailglass's own test Ecto Repo per D-37
- `test/support/data_case.ex` — sandbox-checkout ExUnit case template with tenant helpers
- `test/support/generators.ex` — StreamData attr-map generators for Plans 03 + 05

**Modified (8):**
- `mix.exs` — `:uuidv7 ~> 1.0` added per D-25; `:ecto ~> 3.13`, `:ecto_sql ~> 3.13`, `:postgrex ~> 0.22` added to close the transitive-deps gap
- `mix.lock` — resolved new deps
- `lib/mailglass/errors/suppressed_error.ex` — D-09 pre-GA patch
- `lib/mailglass/error.ex` — `@type t` union + `@error_modules` list extended
- `lib/mailglass/repo.ex` — SQLSTATE 45A01 translation activated + 6 new passthrough functions
- `lib/mailglass/telemetry.ex` — two new span helpers + 6 new `@logged_events` entries
- `docs/api_stability.md` — SuppressedError refinement documented + two new error sections
- `test/mailglass/error_test.exs` — SuppressedError atom-set assertion updated
- `config/test.exs` — `:repo` + `:tenancy` + Postgres credentials wired

## Decisions Made

- **Required deps gap closure:** PROJECT.md line 142 declares `:ecto_sql`, `:postgrex` as required from v0.1; Phase 1 left them as transitive deps (via phoenix). Plan 01's SQLSTATE translation code references `%Postgrex.Error{}` at compile time, which fails to expand if postgrex isn't directly in deps. Added `:ecto`, `:ecto_sql`, `:postgrex` as explicit required deps in Task 2 (see Deviations). `:uuidv7 ~> 1.0` was added per the plan.
- **Repo facade surface expansion:** Plan 01 grew `Mailglass.Repo` from the Phase 1 `transact/1`-only facade to six functions (`transact/1`, `insert/2`, `update/2`, `delete/2` with SQLSTATE translation + passthrough `one/2`, `all/2`, `get/3`). One `translate_postgrex_error/2` defp is the single translation point — Phase 6 `NoRawEventInsert` (deferred) will enforce no raw `Repo.insert(%Event{})` at lint time; this plan provides the facade the check will target.
- **DataCase tenant shortcut:** DataCase stamps `Process.put(:mailglass_tenant_id, ...)` directly as a forward reference. Plan 04 ships `Mailglass.Tenancy.put_current/1` under the same process-dict key; the DataCase setup will be updated then to use the public function. This avoids Plan 01 shipping a stub `Tenancy` module that Plan 04 would have to replace.
- **Immutability type default:** `EventLedgerImmutableError.new/2` defaults to `:update_attempt` because Postgrex error messages are not a stable API (Pitfall 3 in RESEARCH.md). Callers that care about UPDATE vs DELETE walk `:cause` to the raw Postgrex error or read `ctx.pg_code`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added :ecto, :ecto_sql, :postgrex as required deps**
- **Found during:** Task 2 (Mailglass.Repo SQLSTATE translation)
- **Issue:** The plan's Task 2 code literally does not compile without `Postgrex.Error` being a real struct at compile time. Phase 1 left postgrex as a transitive dep via phoenix — `deps/postgrex/` was not installed. Compile error:
  ```
  error: Postgrex.Error.__struct__/1 is undefined, cannot expand struct Postgrex.Error.
  ```
- **Fix:** Added `{:ecto, "~> 3.13"}`, `{:ecto_sql, "~> 3.13"}`, `{:postgrex, "~> 0.22"}` to the required-deps block in `mix.exs`. These match the versions PROJECT.md line 142 has declared required since v0.1 (`:ecto_sql`, `:postgrex`, etc. — "Hard required from v0.1"). The gap existed because Phase 1's scope didn't touch Postgres directly. Closing the gap in Plan 01 (rather than Plan 02 migrations) is the correct place because Plan 01's SQLSTATE translation is the first code that can't be written without them.
- **Files modified:** `mix.exs`, `mix.lock`
- **Verification:** `mix deps.get` + `mix compile --warnings-as-errors` + `mix compile --no-optional-deps --warnings-as-errors` all exit 0; full test suite (95 tests) still green.
- **Committed in:** `c82fffa` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The deviation closes a latent Phase 1 gap that the plan assumed was already closed. Matches PROJECT.md's declared requirements exactly — no scope creep. Plan 02 (migrations) would have hit the same gap; landing it here means Plan 02 is unblocked.

## Issues Encountered

None beyond the deviation above. The plan was dense with exact code bodies and reference analogs, which made execution straightforward — each file had a verbatim-or-near-verbatim source in either Phase 1 code (error structs), accrue (test helpers), or Oban (migration patterns, not yet consumed).

## Downstream Landmines Flagged for Future Plans

- **Plan 02** consumes `Mailglass.Migration.up/0` (not yet defined). DataCase + test_helper.exs changes for migration-run land in Plan 02 — this plan only stamps the TestRepo module so Plan 02 can extend `test_helper.exs` without redefining the module.
- **Plan 03** consumes `use Mailglass.Schema` in `Delivery`, `Events.Event`, `Suppression.Entry`. The macro is final — no further edits needed.
- **Plan 04** consumes `Mailglass.TenancyError` from `tenant_id!/0`; also replaces the raw `Process.put(:mailglass_tenant_id, ...)` in `DataCase.setup/1` + `DataCase.with_tenant/2` with the public `Mailglass.Tenancy.put_current/1`/`with_tenant/2` API. The process-dict key `:mailglass_tenant_id` is stable — Plan 04 must use the same key.
- **Plan 05** consumes `Mailglass.EventLedgerImmutableError` (raised by SQLSTATE 45A01 translation when an adopter mis-writes) + `Mailglass.Telemetry.events_append_span/2` for the `Events.append/1` write path. The span emits `:stop` with `inserted?: boolean` and `idempotency_key_present?: boolean` per D-04.
- **Plan 06** consumes `Mailglass.Telemetry.persist_span/3` for `Mailglass.Outbound.Projector.update_projections/2` (`[:mailglass, :persist, :delivery, :update_projections]`) and for the reconciler's `attempt_link/2` (`[:mailglass, :persist, :reconcile, :link]`).

## Threat Surface Scan

No new security-relevant surface was introduced that isn't documented in the plan's `<threat_model>`. T-02-01a (SQLSTATE translation centralization), T-02-01b (SuppressedError atom-set patch), T-02-03a (telemetry metadata whitelist), T-02-05 (test-config credentials) all hold as documented.

## Next Phase Readiness

- All 3 Wave 0 scaffolding tasks complete; Plan 02 (Migration DDL) is unblocked.
- `mix compile --warnings-as-errors` passes.
- `mix compile --no-optional-deps --warnings-as-errors` passes (no new optional deps introduced).
- `mix test --warnings-as-errors` passes (95 tests, 1 skipped property test).
- `:uuidv7`, `:ecto_sql`, `:postgrex` installed; ready for Plan 02 DDL consumption.

## Self-Check: PASSED

All 6 created files exist on disk:
- `lib/mailglass/schema.ex`
- `lib/mailglass/errors/event_ledger_immutable_error.ex`
- `lib/mailglass/errors/tenancy_error.ex`
- `test/support/test_repo.ex`
- `test/support/data_case.ex`
- `test/support/generators.ex`

All 3 task commits present in `git log --oneline`:
- `6859034` (Task 1 feat)
- `c82fffa` (Task 2 feat)
- `b058da7` (Task 3 feat)

---
*Phase: 02-persistence-tenancy*
*Completed: 2026-04-22*
