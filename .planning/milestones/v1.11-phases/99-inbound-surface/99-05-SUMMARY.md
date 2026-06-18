---
phase: 99-inbound-surface
plan: 05
subsystem: ui
tags: [inbound, conformance, ci, tailwind, playwright]

requires:
  - phase: 99-inbound-surface
    provides: Inbound overview, RoutingTrace/EvidenceCard uplift, empty-state coverage, and focused browser matrix from plans 99-01 through 99-04
provides:
  - Fail-closed large-type and arbitrary-tracking design-system gate
  - CI wiring that treats the former advisory gate as halt-on-failure
  - Minimal Preview heading token cleanup allowed by D-14
  - Rebuilt admin static CSS bundle and green final preview/browser gates
affects: [phase-99-closeout, phase-100-preview-surface, ci-conformance, operator-browser-gate]

tech-stack:
  added: []
  patterns:
    - Advisory shell gates use BASH_SOURCE-anchored paths plus counted errors before clean-path exit.
    - Shared browser reset/seed gate runs Playwright with one worker to avoid deterministic reseed collisions.

key-files:
  created:
    - test/scripts/conformance_advisory_test.exs
    - .planning/phases/99-inbound-surface/99-05-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/scripts/check-conformance-advisory.sh
    - .github/workflows/ci.yml
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/package.json

key-decisions:
  - "The TYPE-lg/xl and TRACK advisory arms now fail closed in both local shell execution and CI."
  - "Preview cleanup stayed limited to `text-xl` -> `text-heading`; Preview IA and dark-mode scope remain Phase 100-owned."
  - "The broad operator browser gate is serialized because the shared `/ops/browser-reset` seed is not worker-safe."

patterns-established:
  - "TDD coverage for shell gates copies the script into a temporary package-shaped directory and asserts both violation and clean-path exit contracts."
  - "CI conformance step blocks should be parsed by step block when asserting absence of `continue-on-error`."

requirements-completed: [GROUP-02, GROUP-03]

duration: 8 min
completed: 2026-06-15
---

# Phase 99 Plan 05: Conformance Gate Closeout Summary

**Fail-closed admin type/tracking conformance with a rebuilt CSS bundle and serialized browser gate**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-15T04:25:54Z
- **Completed:** 2026-06-15T04:34:19Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Replaced the final sanctioned Preview raw large type utility with `text-heading` while preserving the existing theme binding and named `tracking-tight`.
- Converted `check-conformance-advisory.sh` from logging warnings to counted failures for raw `text-lg/xl/2xl/3xl/4xl/5xl` and arbitrary `tracking-[...]` utilities.
- Removed CI `continue-on-error` from the advisory gate step and added regression coverage for both the shell script and workflow block.
- Rebuilt and committed `mailglass_admin/priv/static/app.css`, then ran the final Phase 99 preview and browser gates green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove the final Preview text-xl violation only** - `919c7e3c` (fix)
2. **Task 2 RED: Add failing advisory conformance regression test** - `ec57f586` (test)
3. **Task 2 GREEN: Flip advisory conformance arms to fail-closed** - `81ad1606` (feat)
4. **Task 3: Rebuild bundle and run final Phase 99 gates** - `bcf75963` (chore)
5. **Task 3 Rule 3 fix: Serialize operator browser gate** - `4fd2e9e7` (fix)

**Plan metadata:** pending in this commit.

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/preview_live.ex` - Replaces the selected Preview scenario heading `text-xl` with `text-heading`.
- `mailglass_admin/scripts/check-conformance-advisory.sh` - Adds `errors=0`, fail messages, counted TYPE/TRACK gates, and clean/failure exit behavior.
- `.github/workflows/ci.yml` - Removes `continue-on-error` from the advisory conformance step and documents the Phase 99 hard-fail contract.
- `test/scripts/conformance_advisory_test.exs` - Covers failure, clean-path, and CI halt-on-failure behavior for the advisory gate.
- `mailglass_admin/priv/static/app.css` - Rebuilt Tailwind/daisyUI output after Phase 99 class changes.
- `mailglass_admin/package.json` - Serializes the operator browser gate with `--workers=1`.

## Decisions Made

- Kept `tracking-tight` in `PreviewLive`; the hardened Phase 99 gate blocks arbitrary `tracking-[...]`, not named Tailwind tracking classes.
- Kept the CI step name stable while changing its execution contract to hard-fail, preserving workflow readability and existing references.
- Serialized `npm run test:operator-browser` because 99-04 already documented the browser reset/seed state as shared; the broad gate must match that runtime constraint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Serialized the broad operator browser gate**
- **Found during:** Task 3 (Rebuild bundle and run final Phase 99 gates)
- **Issue:** `npm run test:operator-browser` ran Playwright with the default 2 workers. Concurrent `/ops/browser-reset` requests deleted and reseeded the same deterministic rows, producing provider-message unique constraint and inbound replay foreign-key failures.
- **Fix:** Added `--workers=1` to `mailglass_admin/package.json` `test:operator-browser`, matching the shared-seed constraint already recorded by 99-04 focused browser evidence.
- **Files modified:** `mailglass_admin/package.json`
- **Verification:** `cd mailglass_admin && npm run test:operator-browser` passed with 45 tests, 0 failures.
- **Committed in:** `4fd2e9e7`

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** The fix makes the plan-required broad browser gate deterministic without changing product code, seed data, or route behavior.

## Issues Encountered

- The first broad browser run failed under two workers because the reset route is shared-state. After serializing the npm script, the same plan-required command passed 45/45.

## User Setup Required

None - no external service configuration required.

## Verification

- `bash -lc "! rg -n 'text-(lg|xl|2xl|3xl|4xl|5xl)\\b' mailglass_admin/lib/mailglass_admin/preview_live.ex"` - passed.
- `mix test test/scripts/conformance_advisory_test.exs` - 3 tests, 0 failures.
- `bash mailglass_admin/scripts/check-conformance-advisory.sh` - passed with `OK: advisory design-system conformance clean.`
- `cd mailglass_admin && mix mailglass_admin.assets.build` - passed.
- `cd mailglass_admin && bash scripts/check-conformance.sh` - passed.
- `cd mailglass_admin && bash scripts/check-conformance-advisory.sh` - passed.
- `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors` - 58 tests, 0 failures.
- `cd mailglass_admin && mix verify.preview` - 220 tests, 0 failures.
- `cd mailglass_admin && npm run test:operator-browser` - 45 tests, 0 failures.
- `cd mailglass_admin && git diff --exit-code priv/static/` - passed.

## Known Stubs

None.

## Self-Check: PASSED

- Found all modified/created key files.
- Found task commits `919c7e3c`, `ec57f586`, `81ad1606`, `bcf75963`, and `4fd2e9e7`.
- Unrelated `.planning/v1.11-MILESTONE-AUDIT.md` remains untracked and excluded.

## Next Phase Readiness

Phase 99 is closed out: the inbound surface, static bundle, conformance gates, and browser gate are green. Phase 100 can proceed with Preview-surface IA and dark-mode work knowing the large-type/tracking regression gate now blocks CI.

---
*Phase: 99-inbound-surface*
*Completed: 2026-06-15*
