---
phase: 71-inbound-release-truth-preflight
plan: 01
subsystem: release
tags: [inbound, release-truth, publish-check, docs-contract, hex]

requires:
  - phase: 66-release-position-decision
    provides: inbound 1.0.0 release-position decision and evidence gate
provides:
  - Exact inbound 1.0.0 source/package/publish-summary truth assertions
  - Root README and maintainer runbook blocker corrections
  - Phase-local blocker versus deferred stale-claim verification map
affects: [phase-72-contract-docs, phase-73-publish-evidence, release-runbook]

tech-stack:
  added: []
  patterns:
    - Existing mix mailglass.publish.check lane remains canonical release preflight
    - Root docs-contract tests pin only Phase 71 blocker claims

key-files:
  created:
    - .planning/phases/71-inbound-release-truth-preflight/71-VERIFICATION.md
  modified:
    - test/mailglass/stability_contract_test.exs
    - README.md
    - MAINTAINING.md
    - test/mailglass/docs_contract_test.exs

key-decisions:
  - "Kept mix mailglass.publish.check --package mailglass_inbound as the only package preflight lane."
  - "Resolved root README and MAINTAINING release-truth blockers while deferring reference/demo Hex pins to Phase 73."
  - "Deferred broad compatibility-guide stale-claim guard expansion to Phase 72."

patterns-established:
  - "Exact current release truth is asserted by comparing manifest, source, changelog, README, and publish-summary values."
  - "Required release proof is deterministic repo/package/workflow evidence; provider-live and ecosystem canaries stay advisory unless a release claim depends on them."

requirements-completed: [REL-01, PROOF-01]

duration: 5 min
completed: 2026-06-02
---

# Phase 71 Plan 01: Inbound Release Truth Preflight Summary

**Exact inbound 1.0.0 release-truth proof with blocker-only root docs/runbook corrections**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-02T07:17:51Z
- **Completed:** 2026-06-02T07:22:51Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added exact Phase 71 assertions that prove `mailglass_inbound` `1.0.0` agrees across release-please manifest, source version, changelog, inbound README install pin, root README package status, publish dependency pin, and publish-summary output.
- Corrected root README and maintainer runbook blocker claims from stale `v0.5+` / `~> 0.3` / core-only fallback wording to inbound stable `1.0` truth.
- Recorded an auditable Phase 71 blocker/deferred map so Phase 72 owns broad contract docs/guards and Phase 73 owns post-publish Hex smoke pins.

## Task Commits

1. **Task 1: Tighten exact inbound release-truth proof on the existing preflight seam** - `c63e27bb`
2. **Task 2: Correct only Phase 71-blocking root docs and runbook release claims** - `38948f22`
3. **Task 3: Record blocker versus deferred stale-claim disposition for the release preflight** - `005ff6c1`

## Files Created/Modified

- `test/mailglass/stability_contract_test.exs` - Adds exact inbound 1.0 source/package/publish-summary parity assertions.
- `README.md` - Describes inbound as its own stable 1.0 package line.
- `MAINTAINING.md` - Pins deterministic required release proof, advisory provider-live scope, inbound smoke pin, and inbound-only fallback tag shape.
- `test/mailglass/docs_contract_test.exs` - Guards the corrected root README and runbook blocker claims.
- `.planning/phases/71-inbound-release-truth-preflight/71-VERIFICATION.md` - Records command evidence and blocker/deferred classification.

## Decisions Made

- Kept `mix mailglass.publish.check --package mailglass_inbound` as the canonical preflight instead of adding a second verifier.
- Deferred `reference/host_app` and `reference/demo_app` published-Hex inbound pins to Phase 73 because inbound `1.0.0` is not published yet.
- Deferred broad `guides/compatibility-and-deprecations.md` stale-claim expansion to Phase 72.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion.

## Issues Encountered

- The configured `gsd-executor` subagent could not start because its model is unavailable on this Codex account. Execution continued inline using the documented fallback.
- The first docs-contract run failed on a line-wrapped assertion token. The MAINTAINING sentence was adjusted to expose the exact guard phrase, then the test passed.

## Verification

- `mix mailglass.publish.check --package mailglass_inbound` - PASS
- `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` - PASS, 6 tests, 0 failures
- `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` - PASS, 24 tests, 0 failures, 1 skipped
- `rg -n "Phase 71 blocker|Phase 72|Phase 73|mailglass.publish.check --package mailglass_inbound" .planning/phases/71-inbound-release-truth-preflight/71-VERIFICATION.md` - PASS

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 72 can focus on broad public contract wording and stale-claim guards without re-opening Phase 71 source/package truth. Phase 73 should update and prove reference/demo published-Hex inbound pins after `mailglass_inbound` `1.0.0` is actually published.

---
*Phase: 71-inbound-release-truth-preflight*
*Completed: 2026-06-02*
