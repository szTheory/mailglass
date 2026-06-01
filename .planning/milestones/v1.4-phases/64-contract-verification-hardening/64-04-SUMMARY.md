---
phase: 64-contract-verification-hardening
plan: 04
subsystem: testing
tags: [mailglass_inbound, docs-contract, stability-contract, release-truth]

requires:
  - phase: 63-inbound-contract-inventory-reconciliation
    provides: "Canonical inbound stable/testing/internal/deferred inventory and docs-contract sectioning"
provides:
  - "Exact ordered docs/code lock for stable inbound structured-error closed :type sets"
  - "Fail-closed inbound docs contract checks for release-line pin truth and over-claim boundaries"
affects: [phase-64, phase-65, proof-lanes, inbound-adoption-docs]

tech-stack:
  added: []
  patterns:
    - "Section-scoped docs assertions with deferred-language carve-outs"
    - "Structured dep-pin truth from Mix config and package mix.exs publish pin"

key-files:
  created:
    - .planning/phases/64-contract-verification-hardening/64-04-SUMMARY.md
  modified:
    - mailglass_inbound/docs/api_stability.md
    - mailglass_inbound/README.md
    - mailglass_inbound/docs/inbound-install.md
    - mailglass_inbound/CHANGELOG.md
    - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs

key-decisions:
  - "Kept docs canonical and compared them exactly to code (`__types__/0`) instead of generating either side."
  - "Scoped forbidden-claim checks to stable/adoption/current-release prose while preserving explicit deferred language."

patterns-established:
  - "Closed-set drift assertions parse module sections and compare ordered backticked tokens against runtime type contracts."
  - "Release-line truth checks derive expected pins from project version and publish pin source, not hardcoded strings."

requirements-completed: [PROOF-02, PROOF-03]

duration: 18min
completed: 2026-05-31
---

# Phase 64 Plan 04: Contract Verification Hardening Summary

**Inbound docs contract now fails closed on structured-error type-set drift, stale dep pins, and stable-surface over-claims while preserving explicit deferred-language mentions.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-31T20:14:00Z
- **Completed:** 2026-05-31T20:32:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added the missing canonical MIME closed `:type` set list in `api_stability.md`.
- Centralized exact ordered docs/code closed-set assertions for `MIMEError`, `SignatureError`, and `S3FetchError` in the package docs-contract lane.
- Refreshed README and install-guide dependency pins to current lines (`mailglass_inbound ~> 0.3`, `mailglass ~> 1.3`).
- Reframed `CHANGELOG.md` `Unreleased` prose around current `0.3.0` shipped truth and explicit `0.x` posture.
- Added structured dep-pin and section-scoped forbidden-claim assertions, with deferred-language carve-outs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the missing MIME closed-set docs and centralize exact docs/code comparison** - `29c9534` (test)
2. **Task 2: Refresh current release truth and section-scoped over-claim guards in the adoption docs** - `6fd61e9` (test)

## Files Created/Modified

- `mailglass_inbound/docs/api_stability.md` - Added explicit MIME closed `:type` set bullets.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - Added centralized closed-set comparison and release-truth/over-claim scoped assertions.
- `mailglass_inbound/README.md` - Updated install snippet pins to current release line.
- `mailglass_inbound/docs/inbound-install.md` - Updated install snippet pins to current release line.
- `mailglass_inbound/CHANGELOG.md` - Rewrote Unreleased lead to current `0.3.0` + `0.x` posture.

## Decisions Made

- Keep docs canonical and enforce exact parity from tests, not generated artifacts.
- Enforce over-claim rules by section so deferred references remain legal when clearly non-promissory.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Closed-set parser missed wrapped S3 bullet formatting**
- **Found during:** Task 1 verification
- **Issue:** Initial parser captured only the first S3 closed-set bullet when list entries contained wrapped continuation text.
- **Fix:** Switched to parsing the full `Closed :type set` block and extracting all bullet-leading backticked atom tokens via multiline scan.
- **Files modified:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
- **Verification:** `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/mime_error_test.exs test/mailglass_inbound/signature_error_test.exs test/mailglass_inbound/s3_fetch_error_test.exs --warnings-as-errors`
- **Committed in:** `29c9534`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** No scope expansion; fix was required for correctness of the closed-set proof lane.

## Issues Encountered

None beyond the auto-fixed parser bug noted above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 64 now has executable proof for closed-set and release-line/over-claim docs drift in the inbound package lane.

## Self-Check: PASSED

- Verified modified files exist on disk.
- Verified task commits `29c9534` and `6fd61e9` exist in git history.
