---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-10T01:47:42Z
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
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-10T01:47:42Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

The repository-truth and finalization changes still contain four ship-blocking trust defects. Most importantly, the ledger accepts an unmerged multi-stage index entry as a single authoritative tracked file, while the privately materialized finalizer later executes additional scripts from the mutable checkout. Git's `assume-unchanged` mechanism makes those mutations invisible to the exact `status`/`diff` checks used here, so unauthenticated code can execute after the authenticated entry script passes. The dispatcher also authenticates a symlink target instead of the required lexical shim identity and accepts arbitrary phase numbers while always running Phase 164. Print-mode failures additionally bypass private-directory cleanup.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Multi-stage index conflicts are certified as one tracked artifact

**Classification:** BLOCKER
**File:** `scripts/validate_repository_truth.exs:424-445`
**Issue:** `git ls-files` without `--stage` collapses an unmerged path's stage-1, stage-2, and stage-3 entries into one pathname. Consequently, an index with `UU README.md` produces exactly `README.md\n`, and `tracked_subject_in_index/2` returns `:ok` even though there is no stage-0 index identity and the working file contains an unresolved merge. This contradicts the exact/sole Git-index identity guarantee and lets the standalone repository-truth validator certify conflicted proof.
**Fix:** Parse NUL-delimited staged output and require exactly one stage-0 regular-file entry for the exact subject. For example, invoke `git --literal-pathspecs ls-files --stage -z --error-unmatch -- <subject>`, parse the mode/object/stage prefix separately from the NUL-terminated path, reject every nonzero stage or multiple entry, and retain the existing `File.regular?/1` check. Add an unmerged-index regression, not only untracked/metacharacter cases.

### CR-02: The authenticated finalizer executes mutable transitive helpers

**Classification:** BLOCKER
**Files:** `.gsd/extensions/finalize-phase/index.ts:157-174`; `scripts/finalize_phase_164.sh:290-298`
**Issue:** The extension privately materializes only `scripts/finalize_phase_164.sh`, but that script executes `scripts/closeout_repository_truth.sh` directly from the checkout. That helper in turn executes other checkout scripts (`validate_repository_truth.exs`, `ci_monitor.cjs`, `scheduled_control_evidence.sh`, and workspace verification). The clean-tree gates do not close this boundary: a tracked file marked `assume-unchanged` can be modified while both `git status --porcelain` and `git diff --quiet -- <path>` return clean. Thus an attacker who can alter this checkout can hide a hostile `closeout_repository_truth.sh` and have it execute after the authenticated private script passes its initial gates.
**Fix:** Define the full executable/data dependency manifest for finalization, read every member from the authenticated `HEAD` tree, and materialize the executable chain into the same private directory (with fixed private paths passed to the entry script). At minimum this includes the closeout script and every script it launches; registry/ledger inputs should likewise be read from the authenticated tree or verified by exact blob OID immediately before use. Add a behavioral regression that marks the checkout helper `assume-unchanged`, mutates it, and proves its marker cannot execute.

### CR-03: A symlinked shim authenticates the target path instead of the required shim path

**Classification:** BLOCKER
**File:** `.gsd/extensions/finalize-phase/index.ts:123-156`
**Issue:** The code calls `realpathSync(finalizerCandidate)` and then derives `finalizerRelative` from the resolved target. Replacing `.planning/phases/<phase>/<phase>-FINALIZE.sh` in the working tree with a symlink to any clean tracked file inside the repository therefore causes authentication to run against the target path, not against the canonical shim path named by the command. The modified/missing lexical shim is never checked, defeating the claimed exact phase-shim identity. `statSync` follows the symlink, so it does not reject this case.
**Fix:** Keep the canonical lexical repository-relative shim path as the input to all Git authentication calls. Use `lstatSync` to require that both checkout candidates are regular files and not symbolic links, then use `realpathSync` only as an additional containment check. Add a real-handler fixture that replaces the committed shim with an in-repository symlink and asserts rejection before Bash dispatch.

### CR-04: Every accepted phase number dispatches the Phase 164 finalizer

**Classification:** BLOCKER
**File:** `.gsd/extensions/finalize-phase/index.ts:84-125`
**Issue:** The public command accepts any positive integer and locates that phase's directory/shim, but `downstreamCandidate` is unconditionally `scripts/finalize_phase_164.sh`. If a different phase has a matching `*-FINALIZE.sh`, `/finalize-phase 165` authenticates the Phase 165 shim and then runs the Phase 164 terminal gate. This is incorrect cross-phase behavior at a destructive lifecycle boundary and can report work against the wrong phase.
**Fix:** Either make this extension explicitly Phase-164-only by rejecting `phase !== "164"`, or derive a phase-specific downstream path such as `scripts/finalize_phase_${phase}.sh` and authenticate that exact mapping. The latter also needs a trusted shim-to-downstream mapping rather than merely proving both unrelated files exist.

## Warnings

### WR-01: Print-mode failure bypasses private materialization cleanup

**Classification:** WARNING
**File:** `.gsd/extensions/finalize-phase/index.ts:24-31,168-184`
**Issue:** When the materialized finalizer returns nonzero under `--print`, `commandError` calls `process.exit(1)` from inside the `try`. Immediate process termination does not run JavaScript `finally` blocks, so the mode-0700 temporary directory and mode-0500 finalizer remain on disk. The current harness only exercises caught exceptions and therefore cannot prove the stated cleanup guarantee in print mode.
**Fix:** Never call `process.exit` inside `commandError`. Set `process.exitCode`, throw, and let the handler's `finally` remove the directory; if the host requires an immediate print-mode exit, perform that exit only after cleanup at the outermost command boundary. Add a subprocess `--print` failure test that records the private path and verifies its parent no longer exists.

---

_Reviewed: 2026-09-10T01:47:42Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
