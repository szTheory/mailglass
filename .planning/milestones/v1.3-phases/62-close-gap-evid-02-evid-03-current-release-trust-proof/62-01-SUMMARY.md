---
phase: 62-close-gap-evid-02-evid-03-current-release-trust-proof
plan: 01
subsystem: infra
tags: [release-trust, reference-host, hex, ci, exunit]
requires:
  - phase: 60-release-trust-gate-drift-prevention
    provides: clean-baseline and published-trust workflow topology
provides:
  - Current-release Hex lock proof for reference/host_app
  - Version-specific clean-baseline guard for mailglass sibling packages
  - Contract coverage for stale Hex-version failure behavior
affects: [v1.3, EVID-02, EVID-03, OPS-02, release-trust]
tech-stack:
  added: []
  patterns:
    - Script guard validates both dependency source and exact release version
    - Contract tests execute real release guard scripts against synthetic lock fixtures
key-files:
  created:
    - .planning/phases/62-close-gap-evid-02-evid-03-current-release-trust-proof/62-01-SUMMARY.md
  modified:
    - reference/host_app/mix.exs
    - reference/host_app/mix.lock
    - scripts/check_clean_baseline_hex_only.sh
    - test/mailglass/publish/ci_trust_lane_contract_test.exs
key-decisions:
  - "Kept workflow topology unchanged; Phase 62 only corrected release-line truth and guard strictness."
  - "Accepted resolver-required lock churn for decimal, phoenix_live_view, and swoosh after scoped sibling update."
patterns-established:
  - "Clean-baseline trust proof must validate sibling packages by Hex source and exact expected release version."
  - "Stale-version regressions are pinned by executing the production guard script against a synthetic lock copy."
requirements-completed: [EVID-02, EVID-03, OPS-02]
duration: 21 min
completed: 2026-05-31
---

# Phase 62 Plan 01: Current-Release Trust Proof Summary

**Reference host release-line proof now resolves the v1.3 sibling packages from Hex and fails closed on stale Hex versions.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-05-31T16:31:00Z
- **Completed:** 2026-05-31T17:00:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Updated `reference/host_app` constraints and lockfile from the stale 1.2.0/0.2.0 sibling line to `mailglass` 1.3.0, `mailglass_admin` 1.3.0, and `mailglass_inbound` 0.3.0.
- Hardened `scripts/check_clean_baseline_hex_only.sh` so a sibling must resolve from `:hex` at the exact expected version without evaluating lockfile contents.
- Added CI trust-lane contract tests that run the real guard script against stale, malformed, non-evaluated, and invalid-type synthetic locks.

## Task Commits

Each task was committed atomically:

1. **Task 1: Align the maintained reference host to the current sibling release line** - `d0c5520` (`chore(62-01)`)
2. **Task 2: Harden the clean-baseline guard and pin stale-version regression behavior** - `215b93e` (`test(62-01)`)

Review-driven follow-up commits:

- `b4b13aa` (`fix(62-01)`) - Replaced lockfile `Code.eval_string` parsing with literal AST reconstruction.
- `1d93b26` (`fix(62-01)`) - Classified short sibling lock tuples as malformed.
- `8d5dcda` (`fix(62-01)`) - Reported non-tuple sibling lock entries as deterministic violations.
- `99f352b` (`docs(62)`) - Added the clean Phase 62 code review report.

## Files Created/Modified

- `reference/host_app/mix.exs` - Bumped sibling constraints to `~> 1.3`, `~> 1.3`, and `~> 0.3`.
- `reference/host_app/mix.lock` - Refreshed Hex lock entries for current sibling releases; resolver also updated `decimal`, `phoenix_live_view`, and `swoosh`.
- `scripts/check_clean_baseline_hex_only.sh` - Enforces expected `:hex` source plus exact versions for all three siblings via non-evaluating literal lock parsing.
- `test/mailglass/publish/ci_trust_lane_contract_test.exs` - Adds stale-lock, malformed-tuple, non-evaluated-payload, and invalid-entry behavioral coverage for the guard.

## Decisions Made

- Followed the plan's narrow scope: no CI topology, post-publish workflow, branch-protection, or runner invocation changes.
- Accepted scoped resolver churn from `mix deps.update mailglass mailglass_admin mailglass_inbound`: `decimal` 3.1.0 -> 3.1.1, `phoenix_live_view` 1.1.30 -> 1.1.31, and `swoosh` 1.25.3 -> 1.26.0.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Security] Removed executable lockfile parsing**
- **Found during:** Advisory code review
- **Issue:** `Code.eval_string/1` evaluated raw `mix.lock` content in a CI guard.
- **Fix:** Replaced evaluation with `Code.string_to_quoted!` plus literal AST reconstruction and added malicious-payload coverage.
- **Files modified:** `scripts/check_clean_baseline_hex_only.sh`, `test/mailglass/publish/ci_trust_lane_contract_test.exs`
- **Verification:** Final code review status `clean`; targeted and full verification suites passed.
- **Committed in:** `b4b13aa`

**2. [Rule 2 - Robustness] Made malformed lock entries deterministic**
- **Found during:** Advisory code review
- **Issue:** Short tuples and non-tuple sibling lock entries could produce inconsistent or uncaught failures.
- **Fix:** Added explicit malformed tuple and invalid type branches with contract coverage.
- **Files modified:** `scripts/check_clean_baseline_hex_only.sh`, `test/mailglass/publish/ci_trust_lane_contract_test.exs`
- **Verification:** Final code review status `clean`; targeted and full verification suites passed.
- **Committed in:** `1d93b26`, `8d5dcda`

---

**Total deviations:** 2 auto-fixed (1 security, 1 robustness). **Impact:** The guard is stricter and safer without changing workflow topology or release-trust scope.

## Issues Encountered

None.

## Verification

- `rg -n '\{:mailglass, "~> 1\.3"\}|\{:mailglass_admin, "~> 1\.3"\}|\{:mailglass_inbound, "~> 0\.3"\}' reference/host_app/mix.exs` - passed.
- `rg -n '"mailglass": \{:hex, :mailglass, "1\.3\.0"|"mailglass_admin": \{:hex, :mailglass_admin, "1\.3\.0"|"mailglass_inbound": \{:hex, :mailglass_inbound, "0\.3\.0"' reference/host_app/mix.lock` - passed.
- `(cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` - passed for all three siblings at expected versions.
- `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` - passed, 13 tests, 0 failures.
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); yaml.safe_load(open('.github/workflows/post-publish-smoke.yml')); print('OK')"` - passed.
- `actionlint .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml` - passed.
- `.planning/phases/62-close-gap-evid-02-evid-03-current-release-trust-proof/62-REVIEW.md` - passed, status `clean`, 0 findings.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 62 is ready for verification. Remaining milestone audit residuals stay outside this local implementation scope: live branch-protection evidence for EVID-01 and a future green post-publish smoke artifact after the corrected release-line proof is exercised.

---
*Phase: 62-close-gap-evid-02-evid-03-current-release-trust-proof*
*Completed: 2026-05-31*
