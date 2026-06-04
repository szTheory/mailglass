---
phase: 77-motion-and-microinteraction-polish
plan: "02"
subsystem: ci-conformance
tags:
  - ci
  - shell-gate
  - motion
  - conformance
  - grep
dependency_graph:
  requires:
    - "77-01: motion-reveal id-key fix (operator_live.ex + inbound_live.ex)"
  provides:
    - "scripts/check_motion_conformance.sh — CI-runnable motion conformance grep gate"
    - "ci.yml credo_strict job: Verify motion conformance (shell gate) step"
  affects:
    - ".github/workflows/ci.yml (credo_strict job)"
    - "Phase 79 full conformance check (reuses this script)"
tech_stack:
  added: []
  patterns:
    - "Two-pass bash grep gate: Pass A covers lib/ + app.css; Pass B scopes to lib/ only to avoid false positive on CSS custom property"
    - "Conventional shell gate structure mirroring check_credo_suppressions.sh"
key_files:
  created:
    - scripts/check_motion_conformance.sh
  modified:
    - .github/workflows/ci.yml
decisions:
  - "D-06: author check_motion_conformance.sh — two-pass structure avoids false positive on --ease-in-out CSS custom property at app.css:120"
  - "ease-in[^-] used instead of ease-in\\b for BSD/GNU grep portability (macOS + Ubuntu CI)"
  - "Pass B restricted to lib/ only; Pass A covers both lib/ and app.css (no false-positive risk for layout-thrashing tokens)"
metrics:
  duration: "109s"
  completed: "2026-06-04T16:10:18Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 1
---

# Phase 77 Plan 02: Motion Conformance Shell Gate Summary

Two-pass bash conformance grep gate for motion CSS tokens wired into the `credo_strict` CI job. Exits 0 against the current clean codebase; will exit 1 on any future addition of banned layout-thrashing or easing tokens.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author scripts/check_motion_conformance.sh | 9ce41bc0 | scripts/check_motion_conformance.sh (created) |
| 2 | Wire check_motion_conformance.sh into credo_strict CI job | b7abf613 | .github/workflows/ci.yml (modified) |

## What Was Built

**`scripts/check_motion_conformance.sh`** — A ~37-line bash grep gate following the exact `check_credo_suppressions.sh` convention (shebang, `set -euo pipefail`, `errors` counter, `exit 1` / `echo OK` pattern). Two-pass structure:

- **Pass A** greps both `mailglass_admin/lib/` and `mailglass_admin/assets/css/app.css` for layout-thrashing tokens: `transition-height`, `transition-max-height`, `transition-padding`, `transition-all`, `duration-300`, `duration-[4-9][0-9][0-9]`, `duration-[0-9]{4,}`.

- **Pass B** greps `mailglass_admin/lib/` ONLY for banned easing classes: `ease-in-out`, `ease-linear`, `ease-in[^-]`. The scope restriction avoids a false positive on the legitimate `--ease-in-out: cubic-bezier(...)` CSS custom property defined at `app.css:120`. Confirmed: app.css lines 117-120 would produce three hits if included in Pass B.

**`.github/workflows/ci.yml`** — One new step inserted in the `credo_strict` job immediately after the existing "Verify suppression docs (shell gate)" step. Mirrors the adjacent step's YAML format exactly (6-space indent, name/comment/run fields). Step ordering: `check_credo_suppressions.sh` (line 398) → `check_motion_conformance.sh` (line 402) → `Run Credo strict` (line 403).

## Verification Results

All three plan verification checks passed:

1. `bash scripts/check_motion_conformance.sh` → exits 0, prints `OK: motion conformance clean.`
2. `grep -n "check_motion_conformance" .github/workflows/ci.yml` → one match at line 402
3. Step ordering confirmed correct: credo_suppressions (398) < motion_conformance (402) < Run Credo strict (403)

False-positive protection verified: app.css contains three `ease-in-out` matches (lines 117-118 comment, line 120 CSS var). Script still exits 0 because Pass B excludes app.css.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The script is fully wired; no placeholder logic, no hardcoded empty values.

## Threat Flags

No new threat surface. The script is a read-only grep against repo-internal files; no external I/O, no secrets, no network access. Matches the T-77-02-01 / T-77-02-02 accept disposition in the plan's threat register.

## Self-Check: PASSED

- `scripts/check_motion_conformance.sh` exists and is executable (mode 100755)
- Commit 9ce41bc0 exists: `git log --oneline | grep 9ce41bc0`
- Commit b7abf613 exists: `git log --oneline | grep b7abf613`
- `bash scripts/check_motion_conformance.sh` exits 0
- `grep -n "check_motion_conformance" .github/workflows/ci.yml` returns line 402
