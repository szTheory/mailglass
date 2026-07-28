---
phase: 134-migration-entrypoint-raw-ddl-trigger-qualification
plan: 02
subsystem: migrations
tags: [schema-isolation, migration, postgres, ddl, trigger, immutability, citext, MIGR-03, MIGR-04, MIGR-05]
requires:
  - "134-01: Mailglass.Migration.up/down prefix injection + maybe_create_schema/maybe_drop_schema (CREATE/DROP SCHEMA lifecycle)"
  - "132: Mailglass.Identifier.validate!/2 unquoted-identifier chokepoint"
provides:
  - "V01.up/1: mailglass_raise_immutability() + trigger + stream_scope CHECK schema-qualified to <prefix>; SET search_path = '' on the function"
  - "V01.down/1: takes opts, threads opts[:prefix] into drop(table(prefix:)) + qualified raw DROP TRIGGER/FUNCTION; best-effort guarded DROP EXTENSION citext"
  - "V03.up/1 + V03.down/1: complaint CHECK qualified to <prefix>.mailglass_suppressions both directions"
  - "Mailglass.SchemaIsolationImmutabilityTest: MIGR-05 load-bearing 45A01-without-path-pin proof"
affects:
  - "135: inbound mirrors this raw-DDL qualification pattern"
  - "136-137: full-suite CI schema-isolation axis can now drop the search_path crutch (D-06 pin removal delivered)"
tech-stack:
  added: []
  patterns:
    - "inspect/1 double-quotes an already-Identifier-validated prefix at every raw #{q}. interpolation site (up and down)"
    - "SET search_path = '' on a plpgsql trigger function (CVE-2018-1058 defense-in-depth)"
    - "citext EXTENSION stays UNqualified in public — case-insensitive resolution needs no search_path pin once objects are schema-qualified"
    - "best-effort DROP EXTENSION guarded by a pg_attribute citext-column-usage probe (never CASCADE) so a coexisting install's :citext columns survive per-schema teardown"
    - "load-bearing proof self-contained: in-test refute assembles the forbidden path-pin needle at runtime so the literal never appears in source"
key-files:
  created:
    - test/mailglass/schema_isolation_immutability_test.exs
  modified:
    - lib/mailglass/migrations/postgres/v01.ex
    - lib/mailglass/migrations/postgres/v03.ex
decisions:
  - "[134-02] The immutability FUNCTION collision proof asserts per-schema coexistence (mailglass has its own copy AND the public baseline copy legitimately coexists as a distinct namespace row), NOT public-empty — the shared test DB is already migrated into public by the baseline suite, so 'must NOT exist in public' would be a false invariant."
  - "[134-02] v01.down/1's DROP EXTENSION citext is now GENUINELY best-effort: guarded by a DO-block probe over pg_attribute for any table column still using the citext type, skipping the drop (never CASCADE) when a coexisting install depends on it. This fixes the 2BP01 that the 134-01 SUMMARY flagged as blocking the down round-trip, without redesigning the drop-on-down opt-in (dossier §3.6 leaves that out of scope)."
  - "[134-02] The load-bearing test relies on 134-01's maybe_create_schema/1 own CREATE SCHEMA IF NOT EXISTS rather than a manual CREATE SCHEMA in setup (pre-clean is a DROP ... CASCADE only), proving the entrypoint stands the schema up end-to-end with no path pin."
metrics:
  duration: "~18 min"
  completed: 2026-07-03
  tasks: 3
  files: 3
status: complete
---

# Phase 134 Plan 02: Raw-DDL / Trigger Qualification + 45A01-Without-Path-Pin Proof Summary

Hand-qualified every raw-DDL object Ecto does not auto-prefix — the events immutability function + trigger, the v01 stream_scope CHECK, the v03 complaint CHECK, and all v01/v03 `down/N` raw drops — to the runtime schema prefix (`SET search_path = ''` on the function for CVE-2018-1058 defense), kept `citext` in `public`, and proved the milestone's load-bearing guarantee: the relocated immutability trigger raises SQLSTATE 45A01 under the `mailglass` schema with NO `search_path` crutch, citext still resolves case-insensitively, and the function name never collides across schemas (MIGR-03, MIGR-04, MIGR-05).

## What Was Built

- **MIGR-03 — schema-qualified immutability function + trigger.** `V01.up/1` now creates `CREATE OR REPLACE FUNCTION "<prefix>".mailglass_raise_immutability()` with a `SET search_path = ''` clause (defense-in-depth: the body references nothing unqualified, so an empty path immunizes it against a caller's ambient path — T-134-02 / CVE-2018-1058). The trigger targets `"<prefix>".mailglass_events` and `EXECUTE FUNCTION "<prefix>".mailglass_raise_immutability()`. Two installs in different schemas of one DB each get their own per-schema function and never fight over a global name. Rollback SQL is `DROP FUNCTION IF EXISTS "<prefix>".…` / `DROP TRIGGER … ON "<prefix>".mailglass_events`.
- **MIGR-04 — qualified CHECK constraints + prefix-threaded down.** The v01 `stream_scope` CHECK and the v03 `complaint_permanent` CHECK both name `"<prefix>".mailglass_suppressions` in their ADD and rollback DROP. `V01.down/0` became `down/1` — it reads `opts[:prefix]`, threads it into all three `drop(table(…, prefix: prefix))` structural drops, and hand-qualifies the raw `DROP TRIGGER`/`DROP FUNCTION`. `V03.down/1` qualifies its raw `DROP CONSTRAINT`.
- **MIGR-05 (load-bearing) — 45A01 under `mailglass` with no path pin.** New `Mailglass.SchemaIsolationImmutabilityTest` stands the `mailglass` schema up through `Mailglass.Migration.up(prefix: "mailglass")` with **no** `search_path` execute (relying entirely on the Task-1 qualification + 134-01's own `CREATE SCHEMA`). It proves: UPDATE and DELETE on `mailglass.mailglass_events` each raise SQLSTATE `45A01`; the immutability function is per-schema (mailglass has its own copy, coexisting distinctly with the public baseline — no global-name collision); a mixed-case `:citext` suppression address matches a lower-case lookup (citext stayed resolvable via `public`); and the down round-trip drops the `mailglass` schema. An in-test self-check refutes any path-pinning DDL clause in the source (needle assembled at runtime so the literal never appears).
- **citext stays public.** `CREATE EXTENSION IF NOT EXISTS citext` in `V01.up/1` remains UNqualified — installing into `public` is what makes case-insensitive resolution work with no path pin. Every new `"<prefix>".` interpolation site (up and down, v01 and v03) is gated by `Mailglass.Identifier.validate!/2` first (T-134-01 / WR-01 lineage).

## Key Links

- `V01.up/1` → `Identifier.validate!(prefix)` → `q = inspect(prefix)` → `execute(CREATE FUNCTION #{q}.mailglass_raise_immutability … SET search_path='')` → `execute(CREATE TRIGGER … ON #{q}.mailglass_events EXECUTE FUNCTION #{q}…)`
- `V01.down/1(opts)` → `opts[:prefix]` → validated → qualified `DROP TRIGGER`/`DROP FUNCTION` + `drop(table(…, prefix:))` + best-effort guarded `DROP EXTENSION citext`
- `V03.up/1` / `V03.down/1` → validated `q` → `ALTER TABLE #{q}.mailglass_suppressions ADD/DROP CONSTRAINT mailglass_suppressions_complaint_permanent_check`
- citext EXTENSION (unqualified, public) → `mailglass.mailglass_suppressions.address (:citext)` resolves case-insensitively via public with no path pin

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `V01.down/1`'s `DROP EXTENSION citext` aborted the per-schema down round-trip with 2BP01**
- **Found during:** Task 3
- **Issue:** The plan asked to keep `DROP EXTENSION IF EXISTS citext` UNqualified and best-effort. But a bare (non-CASCADE) `DROP EXTENSION` raises `2BP01 dependent_objects_still_exist` whenever another schema's table still uses the citext type — which is exactly the schema-isolation scenario: the shared test DB's `public.mailglass_suppressions.address` depends on citext, so migrating the `mailglass` schema down raised 2BP01 and aborted the teardown. (The 134-01 SUMMARY flagged this as a 134-02-owned hazard.)
- **Fix:** Made the drop GENUINELY best-effort — wrapped it in a `DO $$ … $$` block that runs `DROP EXTENSION IF EXISTS citext` ONLY when no table/partition column still uses the citext type (probed via `pg_attribute`/`pg_type`), never CASCADE. A coexisting install's `:citext` columns survive a per-schema teardown; the extension is only dropped once the last dependent is gone. Redesigning the drop-on-down opt-in stays out of scope (dossier §3.6).
- **Files modified:** `lib/mailglass/migrations/postgres/v01.ex`
- **Commit:** `4b667808`

**2. [Rule 2 - re-scoped assertion] The function-collision proof asserts per-schema coexistence, not public-empty**
- **Found during:** Task 3
- **Issue:** The plan's behavior draft said "assert exactly one `mailglass_raise_immutability` in the mailglass schema and ZERO in public." But the shared test DB is already migrated into `public` by the baseline suite, so `public.mailglass_raise_immutability` legitimately exists — a strict "ZERO in public" would be a false invariant and fail for reasons unrelated to the MIGR-03 guarantee.
- **Fix:** The test asserts the true MIGR-03 collision-avoidance guarantee: the `mailglass` install got ITS OWN copy (exactly one row in `mailglass`) and every schema's function is a distinct per-schema object (no global-name collision aborted the install). The public baseline coexisting is expected and proves the point.
- **Files modified:** `test/mailglass/schema_isolation_immutability_test.exs`
- **Commit:** `4b667808`

## Verification

- `mix test test/mailglass/schema_isolation_immutability_test.exs --warnings-as-errors` — 6 tests, 0 failures (load-bearing 45A01-without-path-pin proof).
- `mix test test/mailglass/schema_isolation_integration_test.exs test/mailglass/migration_test.exs test/mailglass/schema_isolation_immutability_test.exs` — 22 tests, 0 failures together.
- Determinism: `schema_isolation_immutability_test.exs + migration_test.exs` — 18 tests, 0 failures under seeds 0 and 42.
- `mix compile --warnings-as-errors` — clean.
- `mix format --check-formatted` on all three touched files — clean.
- `mix credo --strict lib/mailglass/migrations/postgres/v01.ex lib/mailglass/migrations/postgres/v03.ex` — no issues.
- Security acceptance (T-134-01, WR-01 lineage): every new `#{q}.` raw-DDL interpolation site (up + down, v01 + v03) is preceded by `Mailglass.Identifier.validate!/2`. No `high`-severity residual.
- citext baseline: `public.citext` extension intact after the down round-trip (best-effort guard skipped the drop because `public.mailglass_suppressions.address` still depends on it).
- Default (public) suite: `migration_test.exs` stays green (prefix "public" → DDL is `"public".mailglass_events` etc., functionally identical to the old unqualified public install).

## Threat Flags

None. All raw-DDL interpolation surface introduced by this plan is enumerated in the plan's `<threat_model>` (T-134-01/02/03) and gated by `Identifier.validate!/2`; no new network endpoints, auth paths, or unlisted trust boundaries were added.

## Self-Check: PASSED

- FOUND: lib/mailglass/migrations/postgres/v01.ex (modified)
- FOUND: lib/mailglass/migrations/postgres/v03.ex (modified)
- FOUND: test/mailglass/schema_isolation_immutability_test.exs (created)
- FOUND commit ac2a2e5b (feat 134-02 v01 qualification + prefix-threaded down)
- FOUND commit 63f54a3f (feat 134-02 v03 complaint CHECK qualification)
- FOUND commit 4b667808 (test 134-02 45A01-without-path-pin proof + best-effort citext drop)
