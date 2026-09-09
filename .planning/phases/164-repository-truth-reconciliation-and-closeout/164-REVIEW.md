---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-09T21:14:29Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - .gitignore
  - .gsd/extensions/finalize-phase/extension-manifest.json
  - .gsd/extensions/finalize-phase/index.ts
  - MAINTAINING.md
  - README.md
  - config/test_exceptions.exs
  - mailglass_admin/README.md
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_inbound/README.md
  - mix.lock
  - reference/demo_app/mix.lock
  - scripts/ci_monitor.cjs
  - scripts/closeout_repository_truth.sh
  - scripts/finalize_phase_164.sh
  - scripts/scheduled_control_evidence.sh
  - scripts/validate_repository_truth.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/publish/maintaining_release_gate_contract_test.exs
  - test/scripts/phase_164_closeout_test.exs
  - test/scripts/phase_164_repository_truth_test.exs
  - test/scripts/scheduled_control_evidence_test.exs
  - test_js/ci-monitor.test.cjs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-09T21:14:29Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

The review found one release-authority contradiction in the current maintainer guide and one fail-open CLI boundary in the repository-truth validator. The JavaScript command builder tests passed, and all three reviewed shell scripts passed `bash -n`, but those checks do not cover the defects below.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Current maintainer guidance still describes the obsolete hands-free release authority

**File:** `MAINTAINING.md:357-366`

**Issue (BLOCKER):** The newly added current release section says the only release boundary is a protected exact-candidate dispatch with fresh repository-admin authorization, but the still-current `Bus Factor & Continuity` section later says the pipeline is hands-free once repository gates pass and has no approval control. This section is before `Historical release procedures`, so readers are explicitly presented with two incompatible current authority models. The contract test only refutes hands-free wording inside the first section (`test/mailglass/publish/maintaining_release_gate_contract_test.exs:35-36`), allowing this contradictory release guidance to pass. A maintainer following the later section can incorrectly conclude that green gates alone authorize a release.

**Fix:** Update the bus-factor section to describe the protected exact-candidate/repository-admin boundary and the actual current release line, or move the obsolete v0.1/v0.5 text under `Historical release procedures`. Extend the contract test to inspect all non-historical content, for example by refuting `hands-free` and `at v0.1` in everything before the historical heading.

## Warnings

### WR-01: Invalid standalone validator invocations silently succeed without validating anything

**File:** `scripts/validate_repository_truth.exs:623-647`

**Issue (WARNING):** The CLI body runs only when any argument is literally `--repo` or `--ledger`. Invoking the executable with no arguments, a misspelled option such as `--ledgr`, or unrelated arguments skips the entire block and exits successfully without producing a verdict. This is a fail-open command-line boundary: an operator or automation typo can be interpreted as a successful repository-truth check. Existing tests exercise malformed ledgers only with both expected flags and do not cover missing or unknown CLI arguments.

**Fix:** Separate the reusable `Mailglass.RepositoryTruthLedger` module from an always-executed CLI wrapper. The wrapper should parse every direct invocation, print usage, and halt nonzero for missing or unknown arguments; tests should require the module file rather than the executable wrapper. Add subprocess tests for no arguments, one missing required option, and an unknown option.

---

_Reviewed: 2026-09-09T21:14:29Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
