---
phase: 60-release-trust-gate-drift-prevention
plan: 03
subsystem: release-ci
tags: [github-actions, post-publish-smoke, trust-runner, ops-guard]
requires:
  - phase: 60-01
    provides: reference host Hex sibling pins for published/clean-baseline trust lanes
provides:
  - Published-version trust journey job in post-publish-smoke
  - OPS-01 live hackney/api_client guard in consumer-install
  - Automated publish-smoke tracker closeout after green post-publish evidence
affects: [post-publish-smoke, release-trust, v1.3-closeout]
tech-stack:
  added: []
  patterns:
    - Success-only GitHub Actions issue closeout gated on needs.*.result evidence
key-files:
  created:
    - test/mailglass/publish/post_publish_smoke_contract_test.exs
  modified:
    - .github/workflows/post-publish-smoke.yml
    - .planning/phases/60-release-trust-gate-drift-prevention/60-03-PLAN.md
key-decisions:
  - "Shifted issue #32 closeout from human-action UAT to a workflow-owned success-only job."
  - "Kept closeout scoped to the existing publish-smoke tracker title and label."
patterns-established:
  - "Post-publish smoke failures open/update the tracker; later green post-publish runs close it with run and artifact evidence."
requirements-completed: [EVID-03, OPS-01]
duration: 9 min
completed: 2026-05-31
---

# Phase 60 Plan 03: Published Trust Journey Summary

**Post-publish smoke now runs the published-version trust journey, guards fresh published installs against hackney regressions, and closes the smoke tracker automatically after green CI evidence.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-31T14:00:00Z
- **Completed:** 2026-05-31T14:09:09Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added the OPS-01 `consumer-install` guard immediately after `mix mailglass.install`.
- Added `published-trust-journey`, running the full trust journey from repo root against `reference/host_app` and uploading `trust-runner-published-${{ github.run_id }}`.
- Wired `notify-on-failure` so journey failures open/update the publish-smoke tracker.
- Replaced the former human-action closeout with `close-publish-smoke-tracker-on-success`, which comments and closes the tracker only after all post-publish proof jobs succeed.
- Added an ExUnit workflow contract test for the automated closeout graph and API behavior.

## Task Commits

1. **Task 1: Add the OPS-01 hackney/api_client live guard to consumer-install** - `c8f4cdf` (ci)
2. **Task 2: Add the EVID-03 published-trust-journey job and wire notify-on-failure** - `2be2b33` (ci)
3. **Task 3: Auto-close issue #32 after green post-publish evidence** - `668338b` (ci/test)

## Files Created/Modified

- `.github/workflows/post-publish-smoke.yml` - Added OPS-01 guard, published trust journey, failure wiring, and success closeout job.
- `test/mailglass/publish/post_publish_smoke_contract_test.exs` - New contract test for automated tracker closeout.
- `.planning/phases/60-release-trust-gate-drift-prevention/60-03-PLAN.md` - Updated the plan from human-action checkpoint to automated closeout.

## Decisions Made

- Automated issue #32 closeout is allowed only from the same workflow run after `consumer-install`, `published-trust-journey`, and the rest of the post-publish chain are green.
- The closeout job no-ops when no tracker issue is open, avoiding issue churn on healthy scheduled runs.

## Deviations from Plan

### User-directed Scope Change

**1. Human-action checkpoint replaced with CI-owned closeout**
- **Found during:** Task 3
- **Issue:** Original plan required manual observation and manual issue close.
- **Fix:** Added `close-publish-smoke-tracker-on-success` and a contract test so no human UAT is required.
- **Files modified:** `.github/workflows/post-publish-smoke.yml`, `test/mailglass/publish/post_publish_smoke_contract_test.exs`, `60-03-PLAN.md`
- **Verification:** Focused ExUnit contract, YAML parse, and `actionlint` pass.
- **Committed in:** `668338b`

---

**Total deviations:** 1 user-directed scope change.
**Impact on plan:** Positive; same live post-publish evidence is still required, but closeout is now automated and test-locked.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `MIX_ENV=test mix test test/mailglass/publish/post_publish_smoke_contract_test.exs` -> 1 test, 0 failures
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/post-publish-smoke.yml')); print('OK')"` -> OK
- `actionlint .github/workflows/post-publish-smoke.yml` -> exit 0
- Existing Task 1/Task 2 grep/YAML checks passed before commit.

## Next Phase Readiness

Phase 60 can now proceed to phase-level review and verification with no human-action checkpoint remaining in Plan 03.

---
*Phase: 60-release-trust-gate-drift-prevention*
*Completed: 2026-05-31*
