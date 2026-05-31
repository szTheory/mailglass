---
phase: 60-release-trust-gate-drift-prevention
plan: 04
subsystem: release-ops
tags: [release, trust-runner, branch-protection, docs, exunit]
requires: []
provides:
  - MAINTAINING.md release runbook aligned to hands-free publish and green trust evidence
  - Doc-contract test for release-gate trust evidence and stale approval-gate prose
  - REQUIRED_CHECKS refute for clean-baseline branch-protection drift
affects: [release-runbook, branch-protection, v1.3-closeout]
tech-stack:
  added: []
  patterns:
    - ExUnit doc-contract tests using literal string assertions against maintainer docs
key-files:
  created:
    - test/mailglass/publish/maintaining_release_gate_contract_test.exs
  modified:
    - MAINTAINING.md
    - test/scripts/required_checks_test.exs
key-decisions:
  - "Keep clean-baseline trust lane out of REQUIRED_CHECKS while documenting it as release trust evidence."
  - "Document publish as hands-free after gate-ci-green rather than a manual hex-publish approval."
patterns-established:
  - "Release trust evidence is guarded by local doc-contract tests, not prose alone."
requirements-completed: [OPS-02, EVID-02]
duration: 1 min
completed: 2026-05-31
---

# Phase 60 Plan 04: Release Trust Gate Runbook Summary

**Maintainer release docs now require green trust evidence, describe hands-free publish accurately, and have deterministic tests preventing stale gate drift.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-31T14:00:00Z
- **Completed:** 2026-05-31T14:01:14Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Reconciled `MAINTAINING.md` Required Checks with `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`.
- Added release-gate trust evidence language for repo-head, clean-baseline, and published trust-runner artifacts.
- Replaced stale manual `hex-publish` approval language with the current hands-free publish fan-out flow.
- Added a doc-contract test for release-gate language and stale approval-gate absence.
- Hardened `test/scripts/required_checks_test.exs` so clean-baseline cannot silently become a branch-protection required check.

## Task Commits

1. **Task 1: Reconcile MAINTAINING.md to the hands-free, trust-evidence-gated release flow** - `6926913` (docs)
2. **Task 2: Add the OPS-02 doc-contract test and the D-04 REQUIRED_CHECKS refute** - `ae8e30e` (test)

## Files Created/Modified

- `MAINTAINING.md` - Release runbook and Required Checks now match the trust-evidence-gated, hands-free publish flow.
- `test/mailglass/publish/maintaining_release_gate_contract_test.exs` - New doc-contract test for trust evidence and stale approval-gate text.
- `test/scripts/required_checks_test.exs` - Added D-04 refute for clean-baseline REQUIRED_CHECKS drift.

## Decisions Made

- Kept `Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)` out of branch protection per D-04 while still documenting clean-baseline evidence as release-gate proof.
- Preserved the five-step release runbook shape and replaced the false manual approval step with publish fan-out monitoring.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `grep -q 'Trust Lane Repo Head (Elixir 1.18 / OTP 27)' MAINTAINING.md && grep -qE 'trust-runner-(repo-head|clean-baseline|published)' MAINTAINING.md && ! grep -q 'requires manual approval in the GitHub Actions UI' MAINTAINING.md && ! grep -q 'Approve the `hex-publish` deployment' MAINTAINING.md && ! grep -q 'single required reviewer' MAINTAINING.md && ! grep -q '~> 0.2' MAINTAINING.md && echo OK` -> OK
- `MIX_ENV=test mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs` -> 4 tests, 0 failures

## Next Phase Readiness

Plan 60-03 can now wire the published trust journey and OPS-01 live guard with the maintainer-facing release trust gate already documented and locally guarded.

---
*Phase: 60-release-trust-gate-drift-prevention*
*Completed: 2026-05-31*
