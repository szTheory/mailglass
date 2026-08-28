---
phase: 164-repository-truth-reconciliation-and-closeout
status: diagnosed
diagnosed: 2026-08-28T19:33:04Z
requirements: [TRTH-03]
---

# Phase 164 Scheduled-Evidence Freshness Gap

## Observed failure

Protected `main` is `e5c4fc793d7504280298156da4d4652f09802482`, and normal push CI run `33101343477` completed successfully for that exact SHA. The daily `post-publish-smoke` and `repo-hygiene` scheduled controls later produced exact-SHA evidence, but the authoritative sweep still could not complete because the latest hourly `release-please` schedule had aged beyond its configured three-hour window before GitHub emitted another hourly run.

## Reproduction evidence

- At `2026-08-28T19:23:40Z`, `scripts/scheduled_control_evidence.sh sweep` failed with `Latest scheduled run for release-please.yml is stale.`
- `release-please` run `33184721818` was created at `2026-08-28T15:21:17Z` for the exact protected-main SHA.
- `post-publish-smoke` run `33188963406` was created at `2026-08-28T16:13:49Z` for the exact protected-main SHA.
- `repo-hygiene` run `33190831519` was created at `2026-08-28T16:37:14Z` for the exact protected-main SHA.
- `.github/scheduled-controls.json` declares `max_age_seconds: 10800` for hourly `release-please` and `129600` for both daily controls.
- `scripts/closeout_repository_truth.sh` independently imposes `updated_at >= now - 10800` on every control, overriding the two 36-hour registry windows.

## Root cause

The closeout consumer duplicates freshness policy with one hard-coded three-hour predicate instead of trusting the authoritative per-control `max_age_seconds` validation performed by `scripts/scheduled_control_evidence.sh`. GitHub schedule delays create periods where each control is individually current according to the registry but the closeout consumer can never accept their combined evidence.

## Required repair

1. Add a focused failing contract proving the closeout accepts a sweep whose controls are evidence-valid under their registry-specific age limits, including daily evidence older than three hours but younger than 36 hours.
2. Remove the duplicated blanket three-hour predicate from `scripts/closeout_repository_truth.sh`; retain exact SHA, event, branch, status, workflow SHA, evidence-valid, and allowed result-status checks.
3. Keep `scripts/scheduled_control_evidence.sh` and `.github/scheduled-controls.json` as the single freshness authority; do not broaden any configured maximum age.
4. Persist and require attempt-1 identity for normal push CI and every naturally scheduled control so a rerun cannot satisfy the final gate.
5. Install the project-local `/finalize-phase` boundary, integrate implementation through protected `main`, capture pre-verification evidence for the implementation SHA, then rerun terminal capture after tracked completion metadata reaches protected main.

## Prohibition

Do not use manual dispatch, rerun or attempt greater than 1, workflow-authority changes, a larger configured age, or a weakened provenance/identity check to manufacture a passing closeout.
