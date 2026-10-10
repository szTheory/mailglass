---
phase: 173
fixed_at: 2026-10-10T13:35:14Z
review_path: /Users/jon/projects/mailglass/.planning/phases/173-consistency-and-delivery-evidence/173-REVIEW.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 173: Code Review Fix Report

**Fixed at:** 2026-10-10T13:35:14Z  
**Source review:** `.planning/phases/173-consistency-and-delivery-evidence/173-REVIEW.md`  
**Iteration:** 3

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-01: BLOCKER — Callers create output directories through unchecked pathnames

**Files modified:** `scripts/check_phase173_candidate.sh`, `scripts/phase173_json_output.cjs`, `scripts/phase173_json_output.py`, `scripts/test_check_phase173_candidate.sh`  
**Commit:** `273bc1c0`  
**Applied fix:** Removed caller-side `mkdir -p` and recursive `fs.mkdirSync` before secure validation. Extended the Python standard-library helper to create missing parents relative to held, verified directory descriptors using directory-relative `mkdir` and `O_DIRECTORY | O_NOFOLLOW` opens. Routed PNG baseline output through the helper's descriptor-relative exclusive file creation while preserving baseline validation and hash checks. Added safe nested-parent and symlinked-parent tests, and source-contract checks that forbid the unsafe caller patterns.  
**Verification:** Python AST parsing, `node --check scripts/phase173_json_output.cjs`, `bash -n scripts/check_phase173_candidate.sh scripts/test_check_phase173_candidate.sh`, and `bash scripts/test_check_phase173_candidate.sh` passed in the main checkout. The focused script retained its direct symlink target-byte assertion and real Git sparse-checkout sentinels.  
**Review note:** The security and path-handling logic passed a focused symlink/parent contract, a synthetic real-Git sparse-checkout contract, and an independent standard-depth code review. These automated checks cover the implementation; owner acceptance remains a separate unverified phase gate.

## Previously Fixed Issues

The iteration 1 WR-01 and iteration 2 CR-01 fixes remain in their respective commits (`04115f01` and `3b869044`).

## Verification Boundary

Verification ran in the main checkout. Exact-SHA CI remains required, and `ownerAcceptance` remains `unverified`. This report is intentionally uncommitted.

---

_Fixed: 2026-10-10T13:35:14Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 3_
