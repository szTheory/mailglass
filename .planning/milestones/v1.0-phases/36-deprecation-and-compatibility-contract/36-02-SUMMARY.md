---
phase: 36-deprecation-and-compatibility-contract
plan: 02
subsystem: docs
tags: [upgrade, migration, compatibility, docs]
requires:
  - phase: 36
    provides: canonical compatibility and deprecation policy
provides:
  - canonical latest-0.x to 1.0 upgrade guide
  - subordinate legacy migration guides
  - source-level compatibility-lane docs for message and outbound surfaces
affects: [phase-37, docs-migration, support-contract]
tech-stack:
  added: []
  patterns: [single upgrade authority with subordinate focused guides]
key-files:
  created: [guides/upgrading-to-v1_0.md]
  modified: [guides/upgrading-from-v0_1.md, guides/migration-from-swoosh.md, lib/mailglass/message.ex, lib/mailglass/outbound.ex, lib/mix/tasks/mailglass.upgrade.v0_2.ex, test/mailglass/docs_migration_smoke_test.exs, README.md, mix.exs]
key-decisions:
  - "Made `upgrading-to-v1_0.md` the single upgrade authority and demoted older guides to subordinate references."
  - "Documented `send/2` as a compatibility bridge without changing runtime behavior."
patterns-established:
  - "Retained compatibility surfaces must name replacement, warning channel, strict-CI impact, support horizon, and proof artifact."
requirements-completed: [COMPAT-03, COMPAT-04]
duration: 30min
completed: 2026-05-05
---

# Phase 36-02 Summary

**Published a canonical latest-`0.x` to `1.0` upgrade guide, aligned the legacy migration guides beneath it, and clarified at the point of use which source-level paths are stable defaults versus retained compatibility bridges.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-05-05T21:25:00Z
- **Completed:** 2026-05-05T21:55:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `guides/upgrading-to-v1_0.md` as the single canonical `0.x -> 1.0` path.
- Rewrote `guides/upgrading-from-v0_1.md` and `guides/migration-from-swoosh.md` as subordinate references.
- Updated `Mailglass.Message.new/2`, `Mailglass.Outbound.send/2`, and the codemod task docs so the compatibility lane is explicit and honest.
- Extended `test/mailglass/docs_migration_smoke_test.exs` to prove canonical-versus-subordinate guide wiring.

## Task Commits

No task-specific commits were created in this run. The repository already had unrelated local modifications, so the phase was executed on the shared working tree and left uncommitted intentionally.

## Files Created/Modified

- `guides/upgrading-to-v1_0.md` - Canonical upgrade guide with compatibility inventory table
- `guides/upgrading-from-v0_1.md` - Subordinate codemod-focused guide
- `guides/migration-from-swoosh.md` - Subordinate raw-Swoosh migration guide
- `lib/mailglass/message.ex` - Point-of-use deprecation wording for `new/2`
- `lib/mailglass/outbound.ex` - Canonical `deliver/2` versus compatibility `send/2` wording
- `lib/mix/tasks/mailglass.upgrade.v0_2.ex` - Canonical guide URL and transitional-tooling framing
- `test/mailglass/docs_migration_smoke_test.exs` - Executable proof for the canonical guide and subordinate references
- `README.md`, `mix.exs` - Discoverability and ExDoc wiring

## Decisions Made

- The compatibility inventory is docs-driven and intentionally light; no new warning infrastructure was added.
- Raw `%Swoosh.Email{}` delivery remains supported as a compatibility bridge, not a preferred stable-lane authoring path.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first migration smoke assertion selected the legacy before-example instead of the stable-lane after-example. The test was tightened to select the canonical block by both module name and `attach/2`.
- ExDoc surfaced a stale link to a missing rate-limiting guide in the subordinate `v0.1 -> v0.2` doc. The stale link was replaced with plain wording.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 36-03 can now encode the published compatibility inventory into lightweight tests and docs checks without guessing at the canonical wording.
