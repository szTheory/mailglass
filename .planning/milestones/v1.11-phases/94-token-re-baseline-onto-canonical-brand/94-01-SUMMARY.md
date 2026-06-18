---
phase: 94
plan: "01"
subsystem: mailglass_admin
tags: [ci, shell-gates, conformance, design-system, ratchet]
dependency_graph:
  requires: []
  provides: [check-conformance-advisory.sh, ci.yml-conformance-steps, extended-THRASH_PATTERN]
  affects: [ci.yml credo_strict job, mailglass_admin/scripts, scripts/]
tech_stack:
  added: []
  patterns: [BASH_SOURCE-anchored shell gate, advisory-vs-hard-fail CI split, continue-on-error advisory step]
key_files:
  created:
    - mailglass_admin/scripts/check-conformance-advisory.sh
  modified:
    - scripts/check_motion_conformance.sh
    - .github/workflows/ci.yml
decisions:
  - "Advisory TYPE-lg/xl and TRACK-[ gates run in CI with continue-on-error until Phase 98/99 cleans known violations (D-08)"
  - "Hard conformance gates (BADGE/TYPE-base/BOLD/GAP/HEX) wired to ci.yml credo_strict job as fail-closed (D-06)"
  - "THRASH_PATTERN extended with layout-property transitions and JIT forms, exits 0 on current codebase (D-07)"
metrics:
  duration: "~10 minutes"
  completed: "2026-06-13"
  tasks: 2
  files: 3
---

# Phase 94 Plan 01: Wire + Tighten Design-System Conformance Gates

**One-liner:** Wired previously-DEAD check-conformance.sh into CI and added advisory typography/tracking gates with THRASH_PATTERN layout-property extension — gates-first before token re-baseline lands.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Create check-conformance-advisory.sh + extend THRASH_PATTERN | 07e228a6 | mailglass_admin/scripts/check-conformance-advisory.sh (new, chmod +x), scripts/check_motion_conformance.sh |
| 2 | Wire both scripts into ci.yml credo_strict job | f1c9b239 | .github/workflows/ci.yml |

## What Was Built

**check-conformance-advisory.sh** (new file, executable): Advisory conformance gate that logs WARN to stderr for TYPE-GATE violations (5 known `text-lg/xl` sites) and TRACK-GATE violations (~43 known `tracking-[0.08em]` sites). Always exits 0. BASH_SOURCE-anchored for cwd-independence. Phase 99 flip instructions embedded in header comments.

**check_motion_conformance.sh** (THRASH_PATTERN extended): Added layout-property named transitions `transition-(height|max-height|padding|width|spacing|margin|inset|top|right|bottom|left)\b` and arbitrary JIT form `transition-\[(width|height|margin|padding|inset|top|right|bottom|left)` to the existing pattern. Exits 0 on current codebase (no violations).

**ci.yml credo_strict job** (two new steps inserted): Hard-fail step runs `check-conformance.sh` (no continue-on-error); advisory step runs `check-conformance-advisory.sh` with `continue-on-error: true`. Both inserted between motion conformance step and `mix credo --strict` per D-10 commit-green order.

## Verification Results

```
bash mailglass_admin/scripts/check-conformance.sh
# OK: design-system conformance clean. (exit 0)

bash mailglass_admin/scripts/check-conformance-advisory.sh
# [WARN lines for 5 TYPE sites and ~44 TRACK sites] (exit 0)

bash scripts/check_motion_conformance.sh
# OK: motion conformance clean. (exit 0)

grep -c 'run:.*check-conformance' .github/workflows/ci.yml
# 2
```

## Deviations from Plan

None - plan executed exactly as written.

Note on `grep -c 'check-conformance' ci.yml`: the plan's validation table expected 2, but the result is 3 because grep also matches comment lines (not just `run:` lines). The intent is met: exactly 2 `run:` steps reference check-conformance scripts. The `continue-on-error: true` exists on the advisory step as intended; a pre-existing `continue-on-error: true` at line 1051 (branch protection verify step) was there before this plan.

## Known Stubs

None. All scripts are fully implemented and functional.

## Threat Flags

No new security-relevant surface introduced. Confirms the threat model assessment: LOW threat surface, pure file-I/O grep gates, no user input, no network, no PII.

## Self-Check: PASSED

- [x] mailglass_admin/scripts/check-conformance-advisory.sh exists and is executable
- [x] scripts/check_motion_conformance.sh THRASH_PATTERN extended
- [x] .github/workflows/ci.yml contains two new conformance steps
- [x] Commit 07e228a6 exists: `ci(admin): add advisory conformance script + extend THRASH_PATTERN`
- [x] Commit f1c9b239 exists: `ci(admin): wire + tighten design-system conformance gates`
- [x] All three scripts exit 0 on current codebase
