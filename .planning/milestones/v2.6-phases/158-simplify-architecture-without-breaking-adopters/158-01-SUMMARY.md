---
phase: 158-simplify-architecture-without-breaking-adopters
plan: 01
subsystem: architecture
tags: [elixir, xref, runtime-config, nimble-options, boundary]
requires: []
provides:
  - Compile-connected cycle and core-to-inbound direction guard with negative controls
  - Opaque Runtime schema cache behind the compatible Config facade
affects: [158-02, 158-03, architecture-boundaries]
tech-stack:
  added: []
  patterns: [fail-closed xref guard, runtime cache with explicit test reset]
key-files:
  created:
    - lib/mailglass/runtime.ex
    - test/mailglass/runtime_test.exs
    - test/scripts/architecture_boundary_test.exs
  modified:
    - lib/mailglass/config.ex
    - test/mailglass/config_test.exs
key-decisions:
  - "Keep the established Config schema persistent_term key while Runtime owns its lifecycle, preserving existing reset seams."
  - "Guard only lib/mailglass runtime production modules; Mix generators and documentation strings are not package imports."
patterns-established:
  - "Architecture guards must execute xref and prove parser/package-edge negative controls."
  - "Migrate Config slices through Runtime one validated cache boundary at a time."
requirements-completed: [ARCH-01, ARCH-02, ARCH-04]
coverage:
  - id: D1
    description: "Compile-connected cycles and reverse core-to-inbound package edges fail a checked-in guard."
    requirement: ARCH-01
    verification:
      - kind: unit
        ref: "test/scripts/architecture_boundary_test.exs"
        status: pass
      - kind: other
        ref: "mix xref graph --format cycles --label compile-connected (core and inbound)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Schema validation and caching flow through Mailglass.Runtime while Mailglass.Config.schema/0 stays compatible."
    requirement: ARCH-02
    verification:
      - kind: unit
        ref: "test/mailglass/runtime_test.exs"
        status: pass
      - kind: unit
        ref: "test/mailglass/config_schema_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Config defaults and public schema accessor behavior remain characterized after the tracer migration."
    requirement: ARCH-04
    verification:
      - kind: unit
        ref: "test/mailglass/config_test.exs"
        status: pass
    human_judgment: false
completed: 2026-08-17
status: complete
---

# Phase 158: Simplify Architecture Without Breaking Adopters Summary

**A fail-closed architecture guard and validated Runtime schema tracer now remove the live core SCC without changing the Config façade.**

## Performance

- **Duration:** 3 min
- **Completed:** 2026-08-17
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Replaced Config's direct compile-time implementation defaults with deferred module resolution, eliminating the observed five-module compile SCC.
- Added a checked-in architecture test that runs both xref cycle graphs and proves its package-edge and cycle parser negative controls.
- Added an opaque Runtime cache for the schema slice, retaining Config.schema/0 and the legacy cache-reset behavior.

## Task Commits

1. **Task 1: Characterize architecture contracts, add a non-vacuous guard, and remove the live core cycle** - `1b946880` (test)
2. **Task 2: Introduce the first validated Runtime-to-Config compatibility path** - `cd42db6c` (feat)

## Files Created/Modified

- `lib/mailglass/runtime.ex` - Opaque validated schema runtime value and explicit reset seam.
- `lib/mailglass/config.ex` - Delegates the schema slice to Runtime while retaining public behavior.
- `test/scripts/architecture_boundary_test.exs` - Compile-cycle and package-direction contract with negative controls.
- `test/mailglass/runtime_test.exs` - Runtime cold-cache, override, and invalid-value coverage.
- `test/mailglass/config_test.exs` - Default suppression-store compatibility characterization.

## Decisions Made

- Retained `{Mailglass.Config, :schema}` as the externally established cache key; Runtime manages it so existing test/support invalidation remains valid.
- Scanned `lib/mailglass` for reverse runtime imports. Mix generators and documentation strings can mention inbound APIs without creating a package dependency.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 158-02 and 158-03 can extend the Runtime and package-boundary work from the cycle-free baseline.

## Verification

- `mix format --check-formatted` — passed
- `mix test test/scripts/architecture_boundary_test.exs test/mailglass/runtime_test.exs test/mailglass/config_test.exs test/mailglass/config_schema_test.exs --warnings-as-errors` — passed (35 tests)
- `mix xref graph --format cycles --label compile-connected` — passed (no cycles)
- `(cd mailglass_inbound && mix xref graph --format cycles --label compile-connected)` — passed (no cycles)
- `mix compile --no-optional-deps --warnings-as-errors` — passed
- `(cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors)` — passed

## Self-Check: PASSED

---
*Phase: 158-simplify-architecture-without-breaking-adopters*
*Completed: 2026-08-17*
