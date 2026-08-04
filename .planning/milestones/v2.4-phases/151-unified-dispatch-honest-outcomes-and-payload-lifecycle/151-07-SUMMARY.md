---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
plan: "07"
subsystem: documentation
tags: [elixir, docs-contract, outbound, payload-lifecycle, privacy, oban]
requires:
  - phase: 151-06
    provides: tenant-explicit bounded payload pruning operations
provides:
  - Executable public contract for the provider at-least-once boundary
  - Operator guidance for structural outcomes, finite retention, tenant pruning, and tombstones
  - Explicit private/public and legacy compatibility boundaries
affects: [phase-152, phase-153, outbound-operations, support-contract]
tech-stack:
  added: []
  patterns: [docs-first contract tests, non-overclaiming provider semantics]
key-files:
  created: []
  modified: [guides/jobs.md, guides/production-go-live-checklist.md, guides/compatibility-and-deprecations.md, docs/api_stability.md, test/mailglass/docs_contract_test.exs]
key-decisions:
  - "Provider idempotency and correlation reduce risk and enable reconciliation; they do not make delivery exactly-once."
  - "Private payload lifecycle operations remain internal while public guidance documents their operational limits."
patterns-established:
  - "Docs contracts assert both required safety wording and scoped prohibited promises."
requirements-completed: [DISP-04, PRIV-02, PRIV-03, PRIV-04]
coverage:
  - id: D1
    description: "Public guidance states the at-least-once provider boundary and closed retryable, terminal, and uncertain operator responses."
    requirement: DISP-04
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#public guidance locks bounded dispatch, privacy, retention, and legacy semantics"
        status: pass
    human_judgment: false
  - id: D2
    description: "Retention defaults, tenant-required one-batch pruning, tombstones, private boundary, and finite legacy cleanup are documented and locked."
    requirement: PRIV-02
    verification:
      - kind: integration
        ref: "mix mailglass.docs.check && MIX_ENV=test mix verify.no_optional_runtime && mix test --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-03
status: complete
---

# Phase 151 Plan 07: Honest Dispatch and Lifecycle Guidance Summary

**Executable adopter guidance now states Mailglass's at-least-once provider boundary, reconciliation-first uncertainty policy, and finite private-payload lifecycle.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-03T03:05:00Z
- **Completed:** 2026-08-03T03:10:08Z
- **Tasks:** 1/1
- **Files modified:** 5

## Accomplishments

- Published the at-least-once provider boundary, including idempotency/correlation limits and no automatic resend of uncertain acceptance.
- Documented retryable, terminal, and uncertain operational actions, the complete nine-state payload lifecycle, atomic durable success scrub, and sync/Task no-Payload behavior.
- Added exact finite retention defaults, one-tenant/one-batch manual and optional scheduled pruning, tombstone preservation, and legacy cleanup/recovery limits.
- Locked private content out of public Delivery metadata, Events, and job arguments, with stable adapter callback compatibility and fail-closed modern payload states.

## Task Commits

1. **Task 1 RED: Lock honest dispatch and payload lifecycle guidance** — `9b3e58be` (test)
2. **Task 1 GREEN: Lock honest dispatch and payload lifecycle guidance** — `a796ec6c` (docs)

## Files Created/Modified

- `guides/jobs.md` — provider-boundary, lifecycle matrix, privacy, retention, and pruning operations guide.
- `guides/production-go-live-checklist.md` — production retention/reconciliation and tenant-only prune readiness section.
- `guides/compatibility-and-deprecations.md` — finite forward-only legacy cleanup policy.
- `docs/api_stability.md` — internal private payload boundary and stable adapter compatibility facts.
- `test/mailglass/docs_contract_test.exs` — tagged positive and negative wording contract.

## Decisions Made

- At-least-once is the truthful external provider contract; local atomicity does not extend across provider acknowledgement.
- Uncertain outcomes must be reconciled, never automatically resent.
- Payload content stays private implementation state; tombstones preserve non-content operator evidence after scrub or expiry.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The first support-contract wrapper run exposed three unrelated core-runtime failures; the full final verification suite completed successfully after the repository's concurrent Phase 151 work settled. No Plan 07 documentation or contract-test failure remained.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 152 and Phase 153 can cite an executable public contract for honest outcomes, finite private retention, tenant-safe maintenance, and legacy non-reconstruction.

## Self-Check: PASSED

- Confirmed all five documented files and the docs contract test exist.
- Confirmed RED commit `9b3e58be` and GREEN commit `a796ec6c` exist in git history.
