---
phase: 144
fixed_at: 2026-07-31T21:35:50Z
review_path: /Users/jon/projects/mailglass/.planning/phases/144-signal-drift-integrity/144-REVIEW.md
iteration: 3
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 144: Code Review Fix Report

**Fixed at:** 2026-07-31T21:35:50Z
**Source review:** /Users/jon/projects/mailglass/.planning/phases/144-signal-drift-integrity/144-REVIEW.md
**Iteration:** 3

**Summary:**

- Findings in scope: 8
- Fixed: 8
- Skipped: 0

**Regression follow-up:** `9e4fe4f5` repaired the extracted-preflight test
harness and the dynamic-icon record separator. The direct focused ExUnit run
passed 11 tests; `mix verify.ci_lane_contract` passed 136 tests.

**Iteration 2 verification:** focused icon and repository-hygiene tests passed
(16 tests); `mix verify.ci_lane_contract` passed 137 tests; and
`mix verify.mix_tasks` passed 56 tests.

**Iteration 3 verification:** focused release-recovery tests passed (9 tests);
`mix verify.ci_lane_contract` passed 140 tests; and the release workflow YAML
validated successfully.

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

### BL-01: Dynamic icon expressions can bypass fail-closed validation

**Files modified:** `mailglass_admin/scripts/check-conformance.sh`, `test/scripts/icon_exists_gate_test.exs`
**Commits:** 57d4cc10, bd7bf625
**Applied fix:** Marked every feature-level `name={...}` expression that is not a supported finite literal, concatenation, or interpolation as unresolved. Added real-gate fixtures for assign, map-field, and helper-call expressions while preserving finite multiline fixtures. Generic component relays are scanned at their call sites.

### WR-04: Missing git upstream is incorrectly treated as clean

**Files modified:** `dev/mix/tasks/mailglass.repo.hygiene.ex`, `test/mix/tasks/mailglass.repo.hygiene_test.exs`
**Commits:** 314cf5a8, bd7bf625
**Applied fix:** Return an `unknown` git-state check when a clean repository has no resolvable upstream, while retaining a concrete blocked result for known dirty state. Clean fixtures now create and synchronize a real local upstream.

### CR-01: Release preflight can read no manifest before checkout

**Files modified:** `.github/workflows/release-please.yml`, `test/scripts/release_trigger_recovery_test.exs`
**Commit:** 0ffee31f
**Applied fix:** Added a pinned checkout before preflight, require a readable and valid non-empty manifest, and fail if it yields no expected tags. The execution harness now uses the checked-out repository manifest and proves a missing-manifest run fails without writing `should_run=true`.

### CR-02: Release and PR lookup failures can be treated as missing state

**Files modified:** `.github/workflows/release-please.yml`, `test/scripts/release_trigger_recovery_test.exs`
**Commit:** 0ffee31f
**Applied fix:** Query releases with `gh api --include`, treating only an explicit HTTP 404 as absent; 403, API, tool, and PR-label failures now stop the preflight without a run signal. Hermetic fake-`gh` cases cover each path.

---

_Fixed: 2026-07-31T21:35:50Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
