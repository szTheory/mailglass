---
phase: 158-simplify-architecture-without-breaking-adopters
plan: 02
subsystem: architecture
tags: [elixir, runtime-config, persistent-term, compatibility, architecture-guard]
requires:
  - phase: 158-01
    provides: schema Runtime tracer and fail-closed cycle/package-edge guard
provides:
  - one fully validated immutable core Runtime configuration owner
  - stable Mailglass.Config compatibility accessors over Runtime
  - non-vacuous source contract for schema-backed and operational config ownership
affects: [158-04, 158-05, 158-06, outbound, webhook, tracking]
tech-stack:
  added: []
  patterns: [atomic persistent-term publication, thin compatibility facade, path-scoped operational exceptions]
key-files:
  created: [test/scripts/runtime_config_ownership_test.exs]
  modified: [lib/mailglass/runtime.ex, lib/mailglass/config.ex, lib/mailglass/application.ex]
key-decisions:
  - "Runtime validates the complete known config before atomically publishing it and the legacy schema/theme cache keys."
  - "Production configuration is boot-cached; test-scoped Application env changes refresh the whole validated Runtime rather than allowing consumers to read raw env."
  - "Non-schema operational hooks remain explicitly path-scoped, with the SES HTTP client read centralized in Runtime."
patterns-established:
  - "Schema-backed consumers call Mailglass.Config; only Runtime reads and validates the complete :mailglass environment."
  - "Operational exceptions require a named key, exact owner path, rationale, and negative-control coverage."
requirements-completed: [ARCH-02, ARCH-04]
coverage:
  - id: D1
    description: "Complete core configuration is validated once into an atomic immutable Runtime while Config preserves its public validation and accessor shapes."
    requirement: ARCH-02
    verification:
      - kind: unit
        ref: "mix test test/mailglass/runtime_test.exs test/mailglass/config_test.exs test/mailglass/application_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Schema-backed production consumers route through Runtime/Config and undeclared raw reads fail a non-vacuous ownership contract."
    requirement: ARCH-02
    verification:
      - kind: integration
        ref: "mix test test/mailglass/runtime_test.exs test/mailglass/config_test.exs test/mailglass/repo_test.exs test/mailglass/clock_test.exs test/mailglass/suppression_test.exs test/mailglass/tracking/endpoint_resolution_test.exs test/mailglass/tracking/config_validator_test.exs test/scripts/runtime_config_ownership_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Runtime migration preserves public v2 behavior and remains cycle-free with optional dependencies absent."
    requirement: ARCH-04
    verification:
      - kind: integration
        ref: "mix compile --no-optional-deps --warnings-as-errors && mix test test/scripts/architecture_boundary_test.exs --warnings-as-errors && mix xref graph --format cycles --label compile-connected && mix format --check-formatted"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-17
status: complete
---

# Phase 158 Plan 02: Authoritative Runtime Configuration Summary

**One atomic validated Runtime now owns core configuration while stable Config APIs and existing runtime/test override behavior remain compatible.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-08-17T11:26:00Z
- **Completed:** 2026-08-17T11:34:53Z
- **Tasks:** 2
- **Files modified:** 24

## Accomplishments

- Moved the full NimbleOptions schema, normalization, repository validation, and cache lifecycle behind `%Mailglass.Runtime{}` with all-or-nothing publication.
- Routed adapter, repository, clock, tenancy, rate-limit, suppression, tracking, compliance, webhook, retention, and async selections through stable `Mailglass.Config` accessors.
- Added an AST-based ownership contract that derives the schema key set, rejects synthetic forbidden reads, and permits only exact path-scoped operational hooks.

## Task Commits

1. **RED: Specify authoritative Runtime behavior** - `6d036b79` (test)
2. **Task 1: Make Runtime the single validated owner** - `8134416f` (feat)
3. **Task 2: Route core consumers through Runtime/Config** - `166c4ae5` (refactor)

## Files Created/Modified

- `lib/mailglass/runtime.ex` - Complete validated value, atomic cache lifecycle, typed accessors, and test-compatible refresh seam.
- `lib/mailglass/config.ex` - Runtime schema module plus stable compatibility delegates.
- `lib/mailglass/application.ex` - Bootstraps Runtime before supervisor children.
- `test/scripts/runtime_config_ownership_test.exs` - AST inventory with schema, undeclared-hook, wrong-owner, and allowed-owner controls.
- Core adapter/repo/outbound/rate-limit/suppression/tracking/webhook consumers - Replaced schema-backed raw env reads with Config accessors.

## Decisions Made

- Kept the schema and validator in `Mailglass.Runtime.Schema` so Runtime and Config share one definition without introducing a compile cycle.
- Preserved the old schema/theme persistent-term keys as compatibility caches, but made Runtime their only writer.
- Kept implementation/test knobs outside the adopter schema and enforced them through an exact path allowlist instead of turning them into public config.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve scoped test configuration overrides without raw consumer reads**
- **Found during:** Task 2 focused verification
- **Issue:** Existing clock, repository, suppression, and tracking tests intentionally mutate Application env inside scoped tests; a production-style immutable cache made those established façade tests stale.
- **Fix:** Runtime records its validated source and, only in the test environment, refreshes the entire validated value when that source changes. Production remains boot-cached, and consumers still never read raw env.
- **Files modified:** `lib/mailglass/runtime.ex`, `lib/mailglass/config.ex`
- **Verification:** Plan 88-test command and additional 145-test migrated-consumer suite passed.
- **Committed in:** `166c4ae5`

---

**Total deviations:** 1 auto-fixed (1 correctness bug). **Impact:** Preserved existing test/runtime compatibility without weakening production ownership or cache semantics.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Outbound and webhook/inbound extraction plans can depend on stable Config accessors and the enforced single-owner rule. No blockers remain; admin/operator UI was untouched.

## Self-Check: PASSED

- All created key files exist.
- Task commits `6d036b79`, `8134416f`, and `166c4ae5` are present.
- Both task verification commands passed.
- Root no-optional compile, architecture guard, zero-cycle xref, formatter, and diff checks passed.

---
*Phase: 158-simplify-architecture-without-breaking-adopters*
*Completed: 2026-08-17*
