---
phase: 132-config-mailglass-identifier-foundation
plan: 01
subsystem: config
tags: [postgres, schema-isolation, persistent_term, nimble_options, identifier-validation, config]

# Dependency graph
requires:
  - phase: 132-config-mailglass-identifier-foundation
    provides: 132-CONTEXT decisions D-01..D-11 and 132-PATTERNS analog map
provides:
  - "Mailglass.Identifier shared validator (validate!/2) — the single Postgres unquoted-identifier chokepoint"
  - "Mailglass.Config :schema NimbleOptions key (default \"mailglass\", \"public\" opt-out)"
  - "Mailglass.Config.schema/0 — boot-validated, :persistent_term-cached, O(1) hot-path accessor"
  - "Mailglass.Config.warm_schema/0 — sentinel-miss self-heal helper (:__miss__)"
  - "persistent_term key {Mailglass.Config, :schema} — written at boot + on cold-miss self-heal"
  - "Migrations.Postgres.validate_identifier!/2 — now a one-line delegate onto the shared validator"
affects: [133-repo-facade, 134-migrations, mailglass_inbound-config-mirror]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared identifier validator promoted from a private migration function into a public Mailglass.Identifier module (D-06/D-11)"
    - "persistent_term sentinel-miss self-heal (:__miss__ → warm_schema/0) instead of the silent empty-default idiom (D-03)"
    - "Validate ONCE at the cache-write boundary, never per read (D-04); no config_change/3, no cache invalidation (D-05)"

key-files:
  created:
    - lib/mailglass/identifier.ex
    - test/mailglass/identifier_test.exs
    - test/mailglass/config_schema_test.exs
  modified:
    - lib/mailglass/config.ex
    - lib/mailglass/migrations/postgres.ex

key-decisions:
  - "Reused the closed ConfigError :invalid type — no IdentifierError, no new :type atom (D-08); semantic detail lives in context.key/context.reason"
  - "63-byte NAMEDATALEN guard added at promotion, checked before the regex; migration path inherits it for free (strictly stricter, D-10)"
  - "schema/0 caches the validated string from the boot pipeline (boot + cache can never disagree) and self-heals cold-miss contexts via warm_schema/0 (D-03)"
  - "Zero runtime behavior change: no prefix: injection, no Mailglass.Repo facade wiring (deferred to Phase 133)"

patterns-established:
  - "Mailglass.Identifier.validate!/2 is the single source of truth for Postgres unquoted-identifier validation — all schema/prefix checks delegate here"
  - "persistent_term key shape {Module, :schema} with :__miss__ sentinel self-heal — to be mirrored identically in MailglassInbound.Config (Plan 02)"

requirements-completed: [SCHEMA-01, SCHEMA-02, SCHEMA-03]

coverage:
  - id: D1
    description: "Mailglass.Identifier.validate!/2 returns the validated string; rejects malformed, over-63-byte, and non-binary values with %ConfigError{type: :invalid}"
    requirement: "SCHEMA-03"
    verification:
      - kind: unit
        ref: "test/mailglass/identifier_test.exs (8 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Migrations.Postgres.validate_identifier!/2 delegates to Mailglass.Identifier.validate!/2; @identifier_regex removed; call-sites unchanged; migration suite byte-identical"
    requirement: "SCHEMA-03"
    verification:
      - kind: unit
        ref: "test/mailglass/migration_test.exs (9 tests)"
        status: pass
      - kind: other
        ref: "grep -c '@identifier_regex' lib/mailglass/migrations/postgres.ex == 0 (REGEX_REMOVED)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Mailglass.Config :schema key (default \"mailglass\", \"public\" opt-out) and boot-validated, persistent_term-cached schema/0 with sentinel self-heal"
    requirement: "SCHEMA-01, SCHEMA-02"
    verification:
      - kind: unit
        ref: "test/mailglass/config_schema_test.exs (6 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Zero runtime behavior change — no prefix: injection, no Mailglass.Repo facade wiring anywhere in the diff"
    requirement: "SCHEMA-02"
    verification:
      - kind: other
        ref: "git diff lib/ | grep '+.*prefix:' == NONE; grep '+.*Mailglass.Repo' == NONE"
        status: pass
    human_judgment: false

# Metrics
duration: 6min
completed: 2026-07-02
status: complete
---

# Phase 132 Plan 01: Config + Mailglass.Identifier Foundation Summary

**Shared `Mailglass.Identifier` Postgres-identifier validator (regex + 63-byte NAMEDATALEN guard), a boot-validated `:persistent_term`-cached `Config.schema/0` accessor with `:__miss__` sentinel self-heal, and a one-line delegate collapse of the migration-layer identifier check — pure-additive, zero runtime behavior change.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-07-02T21:22:00Z
- **Completed:** 2026-07-02T21:28:50Z
- **Tasks:** 3
- **Files modified:** 5 (3 created, 2 modified)

## Accomplishments
- `Mailglass.Identifier.validate!/2` — the single Postgres unquoted-identifier chokepoint: `\A[a-zA-Z_][a-zA-Z0-9_]*\z` regex + 63-byte NAMEDATALEN guard, returns the validated string (pipe-friendly), raises `%Mailglass.ConfigError{type: :invalid}` with semantic detail in `context.key`/`context.reason`.
- `Mailglass.Config` `:schema` NimbleOptions key (`type: :string`, `default: "mailglass"`, `"public"` opt-out documented), boot-warm in `validate_at_boot!/0`, and O(1) hot-path `schema/0` reading from `:persistent_term` with a `:__miss__` sentinel self-heal via `warm_schema/0`.
- `Migrations.Postgres.validate_identifier!/2` collapsed to a one-line delegate onto the shared validator — `@identifier_regex` and both raise clauses removed; three call-sites unchanged; raised `ConfigError` stays byte-identical; the 63-byte guard is inherited for free.

## Task Commits

Each task committed atomically (TDD tasks: test → feat):

1. **Task 1: Create Mailglass.Identifier shared validator** — `c67bc0db` (test) → `9c4aedc4` (feat)
2. **Task 2: Refactor Migrations.Postgres.validate_identifier!/2 to a delegate** — `6e74359e` (refactor)
3. **Task 3: Add :schema config key, schema/0 accessor, boot-warm** — `c44b7692` (test) → `3ab6978a` (feat)

_TDD tasks 1 and 3 each produced a RED `test(...)` commit followed by a GREEN `feat(...)` commit; no refactor commit was needed (implementations were clean at GREEN)._

## Files Created/Modified
- `lib/mailglass/identifier.ex` — NEW. Shared Postgres unquoted-identifier validator; `validate!/2`; regex + 63-byte NAMEDATALEN guard; reuses `ConfigError :invalid`.
- `test/mailglass/identifier_test.exs` — NEW. 8 tests: valid identifiers, regex rejection, 63-byte boundary/over-limit, non-binary; all pattern-match the struct, never the message string.
- `test/mailglass/config_schema_test.exs` — NEW. 6 tests: default/override/`"public"`, persistent_term caching, boot-warm on valid, `%ConfigError{type: :invalid}` on malformed boot; `async: false` with `on_exit` env + persistent_term restore.
- `lib/mailglass/config.ex` — MODIFIED. Added `:schema` NimbleOptions key, `@schema_key` attribute, boot-warm alongside `:theme`, `schema/0` + private `warm_schema/0`, moduledoc note.
- `lib/mailglass/migrations/postgres.ex` — MODIFIED. Replaced `@identifier_regex` + both `validate_identifier!/2` clauses with a single delegate.

## Decisions Made
None beyond the plan — followed the locked decisions D-01..D-11 and 132-PATTERNS analog map as specified. Sentinel atom `:__miss__` and helper name `warm_schema/0` kept exactly as the plan mandates (Plan 02 depends on them). No Boundary declaration added — the direct analogs (`config.ex`, `migrations/postgres.ex`) do not declare one, so the new module matches sibling shape.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None. The `mix credo --strict` run emitted a pre-existing "redefining module Mailglass.Credo.TelemetryEventConvention" compile warning (a credo_checks artifact unrelated to this diff, out of scope per the deviation scope boundary); credo itself reported **no issues** across 462 files.

## Verification Results
- `mix test test/mailglass/identifier_test.exs test/mailglass/config_schema_test.exs test/mailglass/migration_test.exs --seed 0` — **23 tests, 0 failures**.
- `mix credo --strict` — **no issues** (3568 mods/funs, 74 checks, 462 files).
- `mix compile --warnings-as-errors` — **clean**.
- Zero runtime behavior change confirmed: diff grep shows **no** `prefix:` injection and **no** `Mailglass.Repo` facade edits.

## Known Stubs
None. All shipped functions are fully wired to real config/env sources; no placeholder returns.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `Config.schema/0` and `Mailglass.Identifier.validate!/2` are the load-bearing symbols for Plan 02 (inbound mirror) and Phases 133 (facade) / 134 (migrations). Both exist, are validated once at the cache-write boundary, and are green.
- Plan 02 must reuse `Mailglass.Identifier.validate!/2` (D-13) and keep the `:__miss__` sentinel + `warm_schema/0` names identical.
- No blockers. The `Mailglass.Repo` facade is intentionally unwired here (Phase 133).

## Self-Check: PASSED

All created files present on disk and all 5 task commits verified in git history.

---
*Phase: 132-config-mailglass-identifier-foundation*
*Completed: 2026-07-02*
