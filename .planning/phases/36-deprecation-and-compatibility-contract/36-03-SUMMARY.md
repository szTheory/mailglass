---
phase: 36-deprecation-and-compatibility-contract
plan: 03
subsystem: testing
tags: [docs-check, tests, compatibility, verification]
requires:
  - phase: 36
    provides: canonical compatibility guide and canonical upgrade guide
provides:
  - compatibility contract proof test
  - retargeted docs-check rules for compatibility and upgrade policy
  - alias wiring inside existing support-contract verification
affects: [phase-37, support-contract, docs-contract]
tech-stack:
  added: []
  patterns: [lightweight repo-native contract verification, no new CI bucket]
key-files:
  created: [test/mailglass/compatibility_contract_test.exs]
  modified: [lib/mix/tasks/mailglass.docs.check.ex, lib/mix/tasks/mailglass.stability.check.ex, test/mailglass/docs_contract_test.exs, mix.exs]
key-decisions:
  - "Folded compatibility proof into existing support-contract aliases instead of adding a new CI bucket."
  - "Kept the docs check deterministic and token-based, matching the Phase 35 enforcement style."
patterns-established:
  - "Every retained compatibility bridge gets replacement, warning-channel, strict-CI, support-until, and proof-artifact coverage."
requirements-completed: [COMPAT-01, COMPAT-02, COMPAT-03, COMPAT-04]
duration: 20min
completed: 2026-05-05
---

# Phase 36-03 Summary

**Extended the existing lightweight docs and support-contract checks so the new compatibility policy, upgrade authority, and retained-bridge inventory stay mechanically verifiable without introducing a heavier enforcement subsystem.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-05T21:55:00Z
- **Completed:** 2026-05-05T22:15:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `test/mailglass/compatibility_contract_test.exs` with an explicit retained-bridge inventory and support-matrix assertions.
- Retargeted `mix mailglass.docs.check` to cover the canonical compatibility and upgrade guides plus the new README/admin wiring.
- Updated `test/mailglass/docs_contract_test.exs` to verify the new Tier 1 links and compatibility wording.
- Folded the compatibility proof into `verify.support_contract.core`, `verify.docs.contract`, and `verify.docs.migration`.

## Task Commits

No task-specific commits were created in this run. The repository already had unrelated local modifications, so the phase was executed on the shared working tree and left uncommitted intentionally.

## Files Created/Modified

- `test/mailglass/compatibility_contract_test.exs` - Explicit compatibility inventory and support-matrix proof
- `lib/mix/tasks/mailglass.docs.check.ex` - Tier 1 docs rules for compatibility and upgrade guides
- `lib/mix/tasks/mailglass.stability.check.ex` - Updated exemption wording for compatibility-lane surfaces
- `test/mailglass/docs_contract_test.exs` - Tier 1 docs assertions for the new policy and guide wiring
- `mix.exs` - Existing verification aliases expanded to include the new compatibility proof

## Decisions Made

- Reused the existing support-contract and docs aliases instead of inventing a new required CI bucket.
- Kept enforcement repo-native and docs-driven so Phase 37 can build on it without redesign.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Two new compatibility assertions were initially too literal about wording (`PostgreSQL` versus `Postgres`, and the codemod’s exact ambiguous-case phrasing). The tests were normalized to the repo’s real wording before the final proof run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 37 can now build stronger contract enforcement and trust docs on top of a passing, lightweight compatibility proof baseline.
