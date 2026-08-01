---
phase: 148-release-and-adoption-proof
plan: 01
subsystem: release-infrastructure
tags: [github-actions, hex, release-please, exunit]
requires:
  - phase: 147-live-solo-operator-admin
    provides: tenant-scoped LiveView release evidence
provides:
  - Core/admin-only protected release-event fan-out
  - Fail-closed 2.4.0 published-consumer smoke with inbound 2.1.1
  - Credential-free release evidence ledger
affects: [148-02, release-ceremony, published-consumer-proof]
tech-stack:
  added: []
  patterns: [workflow contract tests, fail-closed published dependency compatibility]
key-files:
  created:
    - .planning/phases/148-release-and-adoption-proof/148-RELEASE-PROOF.md
  modified:
    - .github/workflows/publish-hex.yml
    - .github/workflows/post-publish-smoke.yml
    - test/scripts/linked_release_concurrency_test.exs
    - test/mailglass/publish/post_publish_smoke_contract_test.exs
key-decisions:
  - "Release events publish only linked core/admin packages; inbound is explicit dispatch-only recovery."
  - "Published consumer proof pins inbound 2.1.1 and fails closed for unavailable or unrecognized compatibility."
requirements-completed: [PROOF-02, PROOF-03, REL-01]
coverage:
  - id: D1
    description: Protected core/admin release fan-out cannot make inbound release-eligible.
    requirement: REL-01
    verification:
      - kind: unit
        ref: mix test test/scripts/linked_release_concurrency_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical behavioral proof commands and separate published-hex evidence are recorded.
    requirement: PROOF-02
    verification:
      - kind: other
        ref: .planning/phases/148-release-and-adoption-proof/148-RELEASE-PROOF.md
        status: pass
    human_judgment: false
  - id: D3
    description: B2C documentation proof remains a canonical test in the release ledger.
    requirement: PROOF-03
    verification:
      - kind: other
        ref: .planning/phases/148-release-and-adoption-proof/148-RELEASE-PROOF.md
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-01
status: complete
---

# Phase 148 Plan 01: Protected Release Slice Summary

**Protected core/admin release fan-out with fail-closed inbound 2.1.1 consumer compatibility and a credential-free evidence ledger.**

## Performance

- **Duration:** 6 min
- **Completed:** 2026-08-01
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Release events now publish only `mailglass` and `mailglass_admin` after the protected CI gate; inbound remains a gated, explicit dispatch-only recovery path.
- The 2.4.0 Hex consumer smoke requires published `mailglass_inbound` 2.1.1 with a recognized compatible core constraint and includes it unconditionally.
- The release-proof ledger records canonical behavioral, path-mode, and pending protected Hex-mode evidence without credentials or PII.

## Task Commits

1. **Task 1: Prove protected core/admin release through published consumer path** — `dfd01da4` (test RED), `21515e08` (feat GREEN)
2. **Task 2: Establish canonical Phase 148 evidence ledger** — `45cf82f1` (docs)

## Files Created/Modified

- `.github/workflows/publish-hex.yml` — separates linked release-event publication from inbound recovery.
- `.github/workflows/post-publish-smoke.yml` — makes the 2.4.0/2.1.1 consumer path fail closed.
- `test/scripts/linked_release_concurrency_test.exs` — asserts protected release fan-out and secret/environment controls.
- `test/mailglass/publish/post_publish_smoke_contract_test.exs` — asserts exact consumer package inputs and shared smoke invocation.
- `.planning/phases/148-release-and-adoption-proof/148-RELEASE-PROOF.md` — records the pending evidence ledger.

## Decisions Made

- Release events are core/admin-only; inbound is never release-event eligible and retains manual recovery dispatches.
- A local path smoke is not accepted as published-package evidence; the Hex-mode proof remains pending until protected publication.

## Verification

- `mix test test/scripts/linked_release_concurrency_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors` — PASS (9 tests).
- Ledger file and required canonical terms — PASS.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale inline consumer-install contract expectations**
- **Found during:** Task 1
- **Issue:** Existing contract assertions expected inlined installer steps although the workflow correctly delegates to `scripts/consumer_install_smoke.sh`.
- **Fix:** Assert the shared-script invocation and Hex dependency mode instead.
- **Files modified:** `test/mailglass/publish/post_publish_smoke_contract_test.exs`
- **Verification:** Focused workflow contract suite passes.
- **Committed in:** `21515e08`

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** Preserved the intended shared consumer-smoke architecture without scope expansion.

## Issues Encountered

None.

## User Setup Required

None — protected publication and Hex-mode evidence remain explicitly pending until the release ceremony.

## Next Phase Readiness

The protected workflow graph and evidence ledger are ready for later release proof collection. External B2C launch gates and Crosswake remain out of scope.

## Self-Check: PASSED

- Created release-proof ledger exists on disk.
- Task commits `dfd01da4`, `21515e08`, and `45cf82f1` exist in git history.
