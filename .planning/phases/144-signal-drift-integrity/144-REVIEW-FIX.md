---
phase: 144
fixed_at: 2026-07-31T21:24:00Z
review_path: /Users/jon/projects/mailglass/.planning/phases/144-signal-drift-integrity/144-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 144: Code Review Fix Report

**Fixed at:** 2026-07-31T21:24:00Z
**Source review:** /Users/jon/projects/mailglass/.planning/phases/144-signal-drift-integrity/144-REVIEW.md
**Iteration:** 1

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0

**Regression follow-up:** `9e4fe4f5` repaired the extracted-preflight test
harness and the dynamic-icon record separator. The direct focused ExUnit run
passed 11 tests; `mix verify.ci_lane_contract` passed 136 tests.

## Fixed Issues

### CR-01: Release-recovery preflight has no GitHub repository context

**Files modified:** `.github/workflows/release-please.yml`, `test/scripts/release_trigger_recovery_test.exs`
**Commit:** 20e35689
**Applied fix:** Bound preflight `gh` calls to `GH_REPO: ${{ github.repository }}` and added a hermetic fake-`gh` contract that records repository-qualified release and PR queries. Follow-up `9e4fe4f5` makes the extracted-script harness robust and executable on Bash 3.

### WR-01: Dynamic icon extraction only recognizes attributes on the opening-tag line

**Files modified:** `mailglass_admin/scripts/check-conformance.sh`, `test/scripts/icon_exists_gate_test.exs`
**Commit:** 65244f03
**Applied fix:** Collect complete `<.icon ... />` tags before parsing finite expressions, preserving literal concatenation and multi-line attributes. Follow-up `9e4fe4f5` restored real tab/record separators so the parser receives every tag.

### WR-02: The new icon contracts prove only rejection paths, not that a valid computed icon is accepted

**Files modified:** `mailglass_admin/scripts/check-conformance.sh`, `test/scripts/icon_exists_gate_test.exs`
**Commit:** 65244f03
**Applied fix:** Added positive fixtures for known vendored icons through literal concatenation and multi-line interpolation, retaining the negative fixtures and cleanup behavior.

### WR-03: Contributor instructions describe the old green/no-op behavior and wrong token identity

**Files modified:** `CONTRIBUTING.md`, `test/scripts/release_trigger_recovery_test.exs`
**Commit:** 44ea8bdc
**Applied fix:** Documented `RELEASE_PLEASE_PAT`-backed synchronization and `pull_request: synchronize`, plus the failed `cannot_check` branch-protection behavior, with contract assertions.

---

_Fixed: 2026-07-31T21:24:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
