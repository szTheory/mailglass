---
phase: 36-deprecation-and-compatibility-contract
plan: 01
subsystem: docs
tags: [compatibility, deprecation, exdoc, docs]
requires:
  - phase: 35
    provides: stability inventories for core and admin contracts
provides:
  - canonical 1.x compatibility and deprecation guide
  - Tier 1 pointers from README, admin README, maintainer docs, and stability docs
  - ExDoc navigation for compatibility policy in core and admin packages
affects: [phase-37, docs-check, support-contract]
tech-stack:
  added: []
  patterns: [canonical guide plus narrow pointer pages, inventory docs point outward to lifecycle policy]
key-files:
  created: [guides/compatibility-and-deprecations.md, mailglass_admin/docs/compatibility-and-deprecations.md]
  modified: [README.md, mailglass_admin/README.md, MAINTAINING.md, docs/api_stability.md, mailglass_admin/docs/api_stability.md, mix.exs, mailglass_admin/mix.exs]
key-decisions:
  - "Kept compatibility policy separate from the Phase 35 stability inventories."
  - "Used an admin-local pointer page instead of duplicating canonical policy inside mailglass_admin."
patterns-established:
  - "Tier 1 docs point to one canonical compatibility guide."
requirements-completed: [COMPAT-01, COMPAT-02]
duration: 25min
completed: 2026-05-05
---

# Phase 36-01 Summary

**Published one canonical `1.x` compatibility and deprecation guide, then wired every Tier 1 docs entrypoint to that policy without collapsing the Phase 35 stability inventories into lifecycle prose.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-05T21:00:00Z
- **Completed:** 2026-05-05T21:25:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added `guides/compatibility-and-deprecations.md` as the canonical `1.x` policy and support matrix.
- Added a publish-safe `mailglass_admin` pointer page for compatibility policy exposure in admin HexDocs.
- Pointed README, admin README, maintainer docs, and both stability inventories at the canonical guide.
- Exposed the guide through core and admin ExDoc extras/groups.

## Task Commits

No task-specific commits were created in this run. The repository already had unrelated local modifications, so the phase was executed on the shared working tree and left uncommitted intentionally.

## Files Created/Modified

- `guides/compatibility-and-deprecations.md` - Canonical `1.x` compatibility, support-matrix, and deprecation policy
- `mailglass_admin/docs/compatibility-and-deprecations.md` - Admin-local pointer page to the canonical guide
- `README.md` - Root adopter pointers to compatibility and upgrade policy
- `mailglass_admin/README.md` - Matched-sibling compatibility pointers
- `MAINTAINING.md` - Maintainer linkage from verification/release posture to the canonical policy
- `docs/api_stability.md` - Outward compatibility-policy pointer while staying inventory-shaped
- `mailglass_admin/docs/api_stability.md` - Same outward pointer for admin inventory
- `mix.exs`, `mailglass_admin/mix.exs` - ExDoc extras/group wiring

## Decisions Made

- Kept the compatibility lifecycle guide separate from the Phase 35 stability inventories.
- Used a short admin pointer page instead of trying to reference a repo-root extra directly from `mailglass_admin`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- ExDoc initially failed because the compatibility guide linked to the not-yet-created `upgrading-to-v1_0.md`. The link was deferred until Plan 02 created the guide.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 36-02 can build the canonical `0.x -> 1.0` guide on top of the published compatibility policy and reuse its stable-lane versus compatibility-lane language.
