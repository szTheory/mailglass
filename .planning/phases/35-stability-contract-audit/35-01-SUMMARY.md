---
phase: 35-stability-contract-audit
plan: 01
subsystem: docs
tags: [stability, contract, docs, exdoc, readme]
requires:
  - phase: 34
    provides: verification regressions closed before the v1.0 contract audit
provides:
  - canonical core v1.x stability inventory
  - README contract pointer and narrowed package posture
  - root Mailglass moduledoc alignment with the inventory
affects: [phase-35-plan-02, phase-35-plan-03, hexdocs, adopter-contract]
tech-stack:
  added: []
  patterns: [canonical-contract-page, explicit stable-internal-sibling classification]
key-files:
  created: []
  modified: [docs/api_stability.md, README.md, lib/mailglass.ex]
key-decisions:
  - "Kept docs/api_stability.md as the single core contract source instead of splitting the core inventory across multiple guides."
  - "Classified root exports as stable, internal, or sibling-package-only so Boundary reachability no longer implies public promise."
patterns-established:
  - "Public contract docs now start with a narrow inventory before deeper type and error details."
requirements-completed: [LOCK-01, LOCK-03]
duration: 20min
completed: 2026-05-05
---

# Phase 35 Plan 01 Summary

**Core `mailglass` v1.x contract inventory with explicit stable/internal classifications and aligned adopter entry docs**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-05T22:00:00Z
- **Completed:** 2026-05-05T22:30:51Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Reframed `docs/api_stability.md` from a stale `v0.2` freeze note into the canonical `v1.x` core contract inventory.
- Added explicit `stable`, `internal`, and `sibling-package-only` classifications for the reachable core surface.
- Pointed both `README.md` and `Mailglass` moduledoc readers to the same canonical contract page.

## Task Commits

No task commits were created during this execution run.

## Files Created/Modified

- `docs/api_stability.md` - added the front-door core contract inventory and root classification map
- `README.md` - added the API Stability section and removed stale package-surface wording
- `lib/mailglass.ex` - documented the root module as a narrow entrypoint with the contract page as source of truth

## Decisions Made

- Treated root exports as an audited inventory rather than an automatic public contract.
- Kept the existing deep error/type sections and layered the `v1.x` contract inventory above them.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can now define the `mailglass_admin` contract against the same stable/internal framing.

