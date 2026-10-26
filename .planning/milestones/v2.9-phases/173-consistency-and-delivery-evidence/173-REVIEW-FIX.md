---
phase: 173
fixed_at: 2026-10-10T13:50:14Z
review_path: /Users/jon/projects/mailglass/.planning/phases/173-consistency-and-delivery-evidence/173-REVIEW.md
iteration: 4
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 173: Code Review Fix Report

**Fixed at:** 2026-10-10T13:50:14Z
**Source review:** `.planning/phases/173-consistency-and-delivery-evidence/173-REVIEW.md`
**Iteration:** 4

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-04: BLOCKER — Capture paths can alias files outside the captures directory

**Review-local finding ID:** `CR-01` (phase ledger ID `CR-04` avoids colliding with the earlier Phase 173 `CR-01`.)

**Files modified:** `scripts/check_phase173_candidate.sh`, `scripts/test_check_phase173_candidate.sh`
**Commit:** `49944421`
**Applied fix:** Candidate evidence validation now accepts only a top-level `captures/<run-id>-<capture-id>.png` path, restricts run IDs to ASCII letters, digits, and hyphens, and rejects reused capture paths before hashing. This prevents `captures/../<pinned-baseline>.png` and mismatched capture IDs from satisfying the fresh-render check.
**Regression evidence:** Added a synthetic `baseline-alias` mode. The test failed before the fix because the candidate gate accepted the pinned baseline as a current capture. After the fix, `bash -n scripts/check_phase173_candidate.sh scripts/test_check_phase173_candidate.sh` and `bash scripts/test_check_phase173_candidate.sh` passed. The fixture runs only under its disposable `/tmp` test directory.
**Review:** Independent standard-depth re-review completed with zero findings.

## Earlier Review Fixes

- Iteration 1: WR-01, real Git sparse-checkout contract — `04115f01`.
- Iteration 2: CR-01, held-descriptor parent traversal — `3b869044`.
- Iteration 3: CR-01, secure parent creation and exclusive PNG output — `273bc1c0`.
- Earlier reports also record JSON symlink hardening (`66c5b27f`) and the real sparse-checkout fixture (`04115f01`).

## Verification Boundary

The focused synthetic candidate contract passes. The full candidate delivery gate was not rerun for the post-fix HEAD because the active protected-path fence prohibits running its scan/build/test inputs. Exact-SHA required CI and owner acceptance remain unverified; the previously recorded full gate applies only to its earlier candidate SHA.

---
*Fixed: 2026-10-10T13:50:14Z*
*Fixer: the agent (Codex orchestrator)*
