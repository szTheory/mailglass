---
phase: 173-consistency-and-delivery-evidence
plan: 06
subsystem: testing
tags: [exact-candidate, browser-evidence, ci, delivery]
requires:
  - phase: 173-consistency-and-delivery-evidence
    provides: committed candidate gate and retained synthetic evidence validation
provides:
  - exact-SHA incomplete delivery record with local check, CI, and owner-input failures
  - retained isolated review preview and clean detached candidate worktree
affects: [UIQ-03, phase-173-closeout]
actuals:
  tokens: 11653
  tasks: 1
  commits: 0
plan_head_before: d9402094723722efe3d73fef034334a7018b68c8
plan_head_after: d9402094723722efe3d73fef034334a7018b68c8
tech-stack:
  added: []
  patterns: [exact-SHA local delivery proof, path/status-only dirty workspace evidence]
key-files:
  created:
    - reference/demo_app/tmp/demo_browser_evidence/origin-dirty-paths.json (ignored runtime evidence)
    - /private/tmp/mailglass-phase173.0TyAl6gl/candidate/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json (ignored runtime evidence)
  modified: []
key-decisions:
  - "UIQ-03 remains Pending until required exact-SHA CI, clean acceptance inputs, local regression, and retained evidence all pass."
requirements-completed: []
coverage:
  - id: D1
    description: Exact candidate preview, local checks, retained evidence, and required CI disposition
    requirement: UIQ-03
    verification:
      - kind: integration
        ref: "bash scripts/check_phase173_candidate.sh (candidate d9402094723722efe3d73fef034334a7018b68c8)"
        status: fail
    human_judgment: true
    rationale: "The gate recorded required proof gaps; UIQ-03 must stay Pending."
duration: 25min
completed: 2026-10-10
status: complete
---

# Phase 173 Plan 06: Exact Candidate Delivery Evidence Summary

The committed gate evaluated candidate `d9402094723722efe3d73fef034334a7018b68c8` and preserved a retained review preview, but recorded an incomplete delivery result.

## Performance

- **Duration:** 25 min
- **Started:** 2026-10-10T10:01:38Z
- **Completed:** 2026-10-10T10:26:28Z
- **Tasks:** 1
- **Files modified:** 2 ignored JSON evidence records; no tracked task files

## Accomplishments

- Ran `bash scripts/check_phase173_candidate.sh` at the exact original workspace HEAD. The original path/status record reports 69 dirty paths without copying owner file contents.
- Verified the isolated preview was healthy at `http://127.0.0.1:65125/dev/mail`; all five required routes returned successfully, and served CSS SHA-256 `91c0b80fd5d2d9dd42d6501b615f3167b5f25a13beed92894e11fdfa1b6abff1` matched the candidate built CSS hash.
- Preserved the review project `mailglass-phase173-review-d9402094-20261010100217-88938-21579` on HTTP port `65125` and database port `65126`, with detached candidate worktree `/private/tmp/mailglass-phase173.0TyAl6gl/candidate` at the exact candidate SHA. Its tracked/untracked status is clean after restoring the single `mix.lock` change caused by Compose startup.
- Kept the earlier feedback preview project `mailglass-phase173-review-cc1da30c-20261010021410-75986-3730` running on ports `62253` and `62254`.
- Preserved path/status-only metadata at `reference/demo_app/tmp/demo_browser_evidence/origin-dirty-paths.json`. The candidate delivery record and its retained checkpoint/captures remain under `/private/tmp/mailglass-phase173.0TyAl6gl/candidate/reference/demo_app/tmp/demo_browser_evidence/`.

## Task Commits

Task 1 produced ignored runtime evidence. The GSD SDK rejected staging the explicitly named ignored metadata path (`staging_failed`); no force-staging was attempted and no task commit was created. The candidate SHA is an existing commit, not a task commit.

## Delivery Gate Result

**Status: incomplete. UIQ-03 remains Pending.** The exact-candidate record names these failures:

- The local regression gate could not run to completion because the clean checkout lacked required Mix dependencies; Mix reported it could not continue.
- No successful `CI Green` run was found for the exact SHA. The record has `runId: null` and `url: null`; no dispatch or rerun was attempted.
- The evidence wrapper reported six synthetic captures, but the retained checkpoint had `candidate_dirty: true`, so the independent retained evidence validator rejected it. The checkpoint records the exact SHA. The candidate worktree was restored clean after this capture; the retained checkpoint remains unchanged and incomplete.
- The owner-dirty acceptance-input set includes `reference/demo_app/README.md` and `reference/demo_app/assets/e2e/demo.spec.js`, plus the other exact paths listed in `requiredOwnerDirtyPaths` in the delivery record. Only their path/status metadata was recorded.

`previewAssets` is recorded as `not-run-unchanged`; source CSS SHA-256 is `218a8b6932504a29f92f21d1ac3518e6a5e0fac6f67a86e179defc2c1b958f05`, and the served bytes match the built CSS bytes. Browser capture remains synthetic and advisory.

## Evidence and Scoped Cleanup

- Origin dirty-path metadata: `reference/demo_app/tmp/demo_browser_evidence/origin-dirty-paths.json` (ignored).
- Incomplete exact-candidate record: `/private/tmp/mailglass-phase173.0TyAl6gl/candidate/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json` (ignored).
- Retained sanitized checkpoint and six current/baseline PNG pairs: `/private/tmp/mailglass-phase173.0TyAl6gl/candidate/reference/demo_app/tmp/demo_browser_evidence/retained/`.
- Preview URL: `http://127.0.0.1:65125/dev/mail`.
- Later scoped cleanup, after review: `docker compose -p "mailglass-phase173-review-d9402094-20261010100217-88938-21579" -f "/private/tmp/mailglass-phase173.0TyAl6gl/candidate/compose.demo.yml" down`; then `git worktree remove "/private/tmp/mailglass-phase173.0TyAl6gl/candidate"`; then `rmdir "/private/tmp/mailglass-phase173.0TyAl6gl"`. No cleanup was run.

## Decisions Made

- Preserve both preview services and the candidate worktree for owner review; do not infer delivery completion from preview readiness.
- Keep UIQ-03 Pending because required CI, local regression, clean retained evidence, and committed acceptance inputs are not all proven at the candidate SHA.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Restored gate-generated candidate lockfile mutation**
- **Found during:** Task 1
- **Issue:** Compose startup changed `reference/demo_app/mix.lock` in the otherwise isolated candidate worktree, leaving the retained checkout dirty.
- **Fix:** Restored only that candidate worktree file to the committed candidate SHA; the retained worktree is clean again. The original workspace lockfile was not changed by this cleanup.
- **Verification:** `git -C /private/tmp/mailglass-phase173.0TyAl6gl/candidate status --short` returned no paths and `HEAD` remained `d9402094723722efe3d73fef034334a7018b68c8`.

### Expected Incomplete Outcome

The task's documented incomplete path occurred because required exact-SHA CI and clean owner acceptance inputs were unavailable, local regression dependencies were missing, and the retained checkpoint did not prove a clean capture. The gate exited nonzero and persisted the precise reasons.

**Total deviations:** 1 auto-fixed blocking issue. No product or task-owned source files changed.

## Issues Encountered

- The first gate attempt could not create `.git/worktrees/candidate` under the sandbox. The same authorized gate succeeded with elevated filesystem access.
- The SDK staging attempt for ignored runtime metadata returned `staging_failed`; ignored evidence remains untracked by design.
- UIQ-03 is not complete and was not marked complete in REQUIREMENTS.md.

## Next Phase Readiness

Plan 06's exact-candidate evaluation is recorded. Phase 173 delivery remains unproven until the precise gate failures are resolved and the committed gate passes; UIQ-03 remains Pending.

## Self-Check: PASSED

- Summary file exists.
- Origin metadata, candidate delivery record, and retained checkpoint exist at the paths above.
- Candidate commit `d9402094723722efe3d73fef034334a7018b68c8` is present in current ancestry.
- Retained candidate worktree is clean and remains at that SHA.
- REQUIREMENTS.md still lists UIQ-03 as Pending.

---
*Phase: 173-consistency-and-delivery-evidence*
*Completed: 2026-10-10*
