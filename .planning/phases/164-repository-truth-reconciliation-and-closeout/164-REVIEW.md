---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-09T22:42:37Z
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
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-09T22:42:37Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

The refreshed review found two trust-boundary defects and one CLI robustness defect. The prior maintainer-guidance contradiction has been corrected, but the finalizer dispatcher can still execute code that is not the version tracked at `HEAD`, and the repository-truth validator accepts regular files whose ledger rows falsely claim they are tracked. The focused Elixir and Node suites passed, and all reviewed shell scripts passed syntax checking; the existing tests do not exercise these defects.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The finalizer dispatcher executes mutable working-tree code instead of the tracked HEAD version

**File:** `.gsd/extensions/finalize-phase/index.ts:88-101`

**Issue (BLOCKER):** The dispatcher describes and reports the finalizer as "tracked at HEAD", but `git ls-files --error-unmatch` only proves that the path is present in the index. It does not prove that the path exists at `HEAD` or that its current bytes match the committed blob. A newly staged finalizer or a locally modified tracked finalizer therefore passes this check and is executed directly from the working tree by `pi.exec("bash", [finalizer, ...])`. For Phase 164, changing the tracked shim to arbitrary shell code bypasses every clean-tree, GitHub-identity, and evidence check in `scripts/finalize_phase_164.sh`, because the untrusted shim runs before any of those checks. This breaks the protected-main authority boundary and permits arbitrary command execution under the extension process.

**Fix:** Resolve the blob from `HEAD` rather than trusting the index or working tree. At minimum, require `git cat-file -e HEAD:<relative-path>`, compare the file's bytes or blob ID with `HEAD:<relative-path>`, and reject any mismatch. Prefer materializing the verified `HEAD` blob into a private temporary file and executing that immutable copy, while separately rejecting a dirty repository when the command contract requires it. Add behavioral tests for a newly staged finalizer, an unstaged modification to a committed finalizer, and an unchanged committed finalizer.

### CR-02: Ledger rows marked tracked are accepted even when Git does not track their files

**File:** `scripts/validate_repository_truth.exs:570-576`

**Issue (BLOCKER):** `ensure_tracked_subjects_exist/2` validates a row whose state is `tracked` only with `File.regular?/1`. Any untracked regular file at the canonical subject path satisfies the validator, so the authoritative command can print `repository truth ledger: valid` while the ledger's tracked-state assertion is false. This directly violates TRTH-02's machine-enforced repository-truth contract. The test at `test/scripts/phase_164_repository_truth_test.exs:203-221` checks only the literal `state` field and repeats the same unsupported claim; it never queries Git.

**Fix:** For every `state == "tracked"` row, require both a regular file and successful exact-path Git membership, for example `System.cmd("git", ["ls-files", "--error-unmatch", "--", subject], cd: repo_root)`. Also reject paths whose tracked index entry is not a regular file when the contract requires files. Add a temporary-repository regression proving that an untracked regular file with a `tracked` ledger row fails while the same committed file passes.

## Warnings

### WR-01: Invalid standalone validator invocations silently succeed without validating anything

**File:** `scripts/validate_repository_truth.exs:623-647`

**Issue (WARNING):** The CLI body runs only when any argument is literally `--repo` or `--ledger`. Invoking the executable with no arguments, only misspelled options, or unrelated arguments skips the entire block and exits successfully without a verdict. An operator or automation typo can therefore be interpreted as a successful repository-truth check. Existing subprocess tests always include the expected flags and do not cover this boundary.

**Fix:** Split the reusable module from an always-executed CLI wrapper, or use an explicit load-mode sentinel for tests. Every direct CLI invocation should parse its full argument list, print usage, and halt nonzero for missing or unknown arguments. Add subprocess tests for no arguments, each missing required option, and unknown options.

---

_Reviewed: 2026-09-09T22:42:37Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
