---
phase: 132-config-mailglass-identifier-foundation
plan: 02
subsystem: config
tags: [postgres, schema-isolation, persistent_term, nimble_options, identifier-validation, config, mailglass_inbound]

# Dependency graph
requires:
  - phase: 132-config-mailglass-identifier-foundation
    provides: "Plan 01 shipped Mailglass.Identifier.validate!/2 (shared validator) and Mailglass.Config schema/0 + warm_schema/0 + :__miss__ sentinel + {Mailglass.Config, :schema} persistent_term key — reused here for family coherence"
provides:
  - "MailglassInbound.Config :schema NimbleOptions key (type: :string, default \"mailglass\", \"public\" opt-out) read from :mailglass_inbound env only"
  - "MailglassInbound.Config.schema/0 — boot-validated, :persistent_term-cached, O(1) hot-path accessor reusing core Mailglass.Identifier"
  - "MailglassInbound.Config.warm_schema/0 — private :__miss__ sentinel self-heal helper (same name/shape as core Plan 01)"
  - "persistent_term key {MailglassInbound.Config, :schema} — warmed at boot + on cold-miss self-heal"
  - "MailglassInbound.Application.start/2 now invokes validate_at_boot!/0 (pre-existing never-called gap closed)"
affects: [135-inbound-migrations, 133-repo-facade, mailglass_inbound-ddl-query-builder]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inbound mirrors core's persistent_term sentinel-miss self-heal (:__miss__ → warm_schema/0) identically for family coherence"
    - "Inbound REUSES core's Mailglass.Identifier.validate!/2 — no inbound-local regex, no new inbound error type (D-13)"
    - "Only :schema cached in persistent_term; retention/0 and rate_limit/0 stay on the uncached validated/0 cold path (D-14)"
    - "validate_at_boot!/0 wired as the FIRST statement of start/2 so a bad identifier fails the node at boot, not mid-request (D-15)"

key-files:
  created:
    - mailglass_inbound/test/mailglass_inbound/config_schema_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/config.ex
    - mailglass_inbound/lib/mailglass_inbound/application.ex

key-decisions:
  - "Reused core's Mailglass.Identifier.validate!/2 (path-override dep makes it available in dev/test); no inbound-local regex or IdentifierError — one validator across the family (D-13)"
  - "schema/0 caches the validated string from the boot pipeline (boot + cache never disagree) and self-heals cold-miss contexts via warm_schema/0 reading the :mailglass_inbound env ONLY (D-12 boundary law)"
  - "validate_at_boot!/0 now warms :schema AND still runs _ = validated() so retention/rate_limit continue to validate; only :schema is cached (D-14)"
  - "Wired validate_at_boot!/0 as the first statement of start/2 with a direct (unguarded) call — inbound owns its own app env, no core-style load-order guard needed (D-15)"
  - "Zero runtime behavior change beyond boot validation now firing: no facade wiring, no prefix: injection"

patterns-established:
  - "MailglassInbound.Config.schema/0 is family-coherent with Mailglass.Config.schema/0 — identical accessor name, default \"mailglass\", validator, %ConfigError{type: :invalid} error, {Module, :schema} key shape, :__miss__ sentinel, warm_schema/0 helper"
  - "Future inbound DDL/query builders (Phase 135) must interpolate MailglassInbound.Config.schema/0 (already validated at the cache-write boundary) rather than re-reading raw app env"

requirements-completed: [SCHEMA-04]

coverage:
  - id: D1
    description: "MailglassInbound.Config.schema/0 returns \"mailglass\" by default, honors :mailglass_inbound override + \"public\" opt-out, self-heals from :persistent_term after warm, reads :mailglass_inbound env only (never core :mailglass)"
    requirement: "SCHEMA-04"
    verification:
      - kind: unit
        ref: "test/mailglass_inbound/config_schema_test.exs#schema/0 default + override (5 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "validate_at_boot!/0 warms {MailglassInbound.Config, :schema} with the validated string on a valid identifier and raises %Mailglass.ConfigError{type: :invalid} on a malformed identifier"
    requirement: "SCHEMA-04"
    verification:
      - kind: unit
        ref: "test/mailglass_inbound/config_schema_test.exs#validate_at_boot!/0 warms + validates :schema (2 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Inbound reuses core Mailglass.Identifier.validate!/2 (no inbound-local regex/error); only :schema cached — retention/0 and rate_limit/0 stay uncached"
    requirement: "SCHEMA-04"
    verification:
      - kind: unit
        ref: "test/mailglass_inbound/config_schema_test.exs#retention/0 and rate_limit/0 remain uncached (2 tests)"
        status: pass
      - kind: other
        ref: "grep 'Mailglass.Identifier.validate!' config.ex == 4 refs; no inbound-local regex or new error type"
        status: pass
    human_judgment: false
  - id: D4
    description: "MailglassInbound.Application.start/2 invokes validate_at_boot!/0 as its first statement (pre-existing never-called gap closed); no facade / no prefix: injection in the diff"
    requirement: "SCHEMA-04"
    verification:
      - kind: other
        ref: "grep 'MailglassInbound.Config.validate_at_boot!' application.ex (first stmt); git diff grep 'prefix:|Repo|facade' == NONE"
        status: pass
    human_judgment: false

# Metrics
duration: 3min
completed: 2026-07-02
status: complete
---

# Phase 132 Plan 02: Config + Mailglass.Identifier Foundation (Inbound Mirror) Summary

**Mirrored the core schema-config contract onto `mailglass_inbound` — a `:schema` config key and a boot-validated, `:persistent_term`-cached `MailglassInbound.Config.schema/0` reusing core's `Mailglass.Identifier`, plus wiring inbound's previously-uncalled `validate_at_boot!/0` into `application.ex` — family-coherent and pure-additive.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-07-02T21:31:20Z
- **Completed:** 2026-07-02T21:33:32Z
- **Tasks:** 2
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- `MailglassInbound.Config` `:schema` NimbleOptions key (`type: :string`, `default: "mailglass"`, `"public"` opt-out documented), read from the `:mailglass_inbound` app env only (boundary law — never core `:mailglass`).
- `MailglassInbound.Config.schema/0` — O(1) hot-path accessor reading `:persistent_term.get({MailglassInbound.Config, :schema}, :__miss__)` with a `:__miss__` sentinel self-heal via private `warm_schema/0`, reusing core's `Mailglass.Identifier.validate!/2` at the cache-write boundary. Same accessor name, default, validator, error type, key shape, sentinel, and helper name as core Plan 01.
- `validate_at_boot!/0` extended to warm `{MailglassInbound.Config, :schema}` (validated once via the core validator) while keeping the existing `validated()` call so `retention`/`rate_limit` still validate; only `:schema` is cached.
- `MailglassInbound.Application.start/2` now calls `MailglassInbound.Config.validate_at_boot!/0` as its first statement — closing the pre-existing gap where `validate_at_boot!/0` was defined but never invoked, and failing fast at boot on a bad identifier.

## Task Commits

Each task was committed atomically (Task 1 was TDD: test → feat):

1. **Task 1: Add :schema key, schema/0 accessor, boot-warm to MailglassInbound.Config** — `ff660aad` (test/RED) → `344230e0` (feat/GREEN)
2. **Task 2: Wire validate_at_boot!/0 into application start/2** — `90647119` (feat)

_Task 1 produced a RED `test(...)` commit followed by a GREEN `feat(...)` commit; no refactor commit was needed (implementation was clean at GREEN)._

## Files Created/Modified
- `mailglass_inbound/test/mailglass_inbound/config_schema_test.exs` — NEW. 9 tests: default/override/`"public"`, `:mailglass_inbound`-env-only boundary, persistent_term caching, boot-warm on valid, `%ConfigError{type: :invalid}` on malformed boot, and two guards proving `retention/0`/`rate_limit/0` stay uncached. `async: false` with `on_exit` env + persistent_term restore; malformed boot asserted via struct field `type: :invalid`, never message text.
- `mailglass_inbound/lib/mailglass_inbound/config.ex` — MODIFIED. Added `:schema` NimbleOptions key (before `@moduledoc`), `@schema_key` attribute, `schema/0` + private `warm_schema/0`, boot-warm inside `validate_at_boot!/0`, and updated the moduledoc/`validate_at_boot!` doc note (no longer "not called automatically").
- `mailglass_inbound/lib/mailglass_inbound/application.ex` — MODIFIED. Inserted `:ok = MailglassInbound.Config.validate_at_boot!()` as the first statement of `start/2`, before `maybe_warn_fallback_mode/0`.

## Decisions Made
None beyond the plan — followed locked decisions D-12..D-15 and the 132-PATTERNS analog map. Sentinel atom `:__miss__` and helper name `warm_schema/0` kept byte-identical to core Plan 01 for family coherence. Direct (unguarded) boot call used per D-15 (inbound owns its own app env). Added one extra boundary-law test asserting `schema/0` never leaks a core `:mailglass` schema (T-132-05 mitigation) and two uncached-path guards (D-14) — additive test coverage, not a behavior deviation.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
The plan's `mix credo --strict` verification command is **not runnable in the `mailglass_inbound` package** — inbound has no `credo` dependency and no `.credo.exs` (credo is a core-only dev tool; the inbound `mix.exs` declares no `:credo` dep). This is a plan/reality mismatch, not a code defect: there is no lint to fail. The enforceable style gates that DO exist for this package pass clean:
- `mix compile --warnings-as-errors` — clean.
- `mix format --check-formatted` on all three touched files — clean.

No `mix.lock` transitive drift introduced; working tree clean after each commit.

## Verification Results
- `cd mailglass_inbound && mix test test/mailglass_inbound/config_schema_test.exs --seed 0` — **9 tests, 0 failures** (scoped per-file to avoid the known inbound full-suite DB-pool flake).
- `cd mailglass_inbound && mix compile --warnings-as-errors` — **clean**.
- `mix credo --strict` — **N/A** (no credo dep in the inbound package; see Issues Encountered). Substituted `mix format --check-formatted` — **clean**.
- Family coherence confirmed: `schema/0`, default `"mailglass"`, shared `Mailglass.Identifier`, `%Mailglass.ConfigError{type: :invalid}`, key `{MailglassInbound.Config, :schema}`, sentinel `:__miss__`, `warm_schema/0` — all identical to core Plan 01.
- No facade wiring / no `prefix:` injection in the diff (grep of the 4-commit range for `prefix:|Repo|facade` on added lines == NONE).

## Known Stubs
None. All shipped functions are fully wired to real config/env sources; no placeholder returns.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `MailglassInbound.Config.schema/0` is the load-bearing symbol for the inbound DDL/query builder (Phase 135) and mirrors `Mailglass.Config.schema/0` exactly. It is validated once at the cache-write boundary, warmed at boot, and green.
- Both halves of Design Phase A (core Plan 01 + inbound Plan 02) now ship the identical schema-config contract on their respective version lines. No blockers.
- No facade / `prefix:` wiring exists yet by design — deferred to the repo facade (core Phase 133) and inbound migrations (Phase 135).

## Self-Check: PASSED

All created files present on disk and all 3 task commits verified in git history.

---
*Phase: 132-config-mailglass-identifier-foundation*
*Completed: 2026-07-02*
