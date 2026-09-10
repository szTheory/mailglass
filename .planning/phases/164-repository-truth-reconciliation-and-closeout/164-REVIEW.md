---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-10T15:07:40Z
depth: standard
files_reviewed: 20
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
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-10T15:07:40Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The stage-aware Git-index parser now correctly requires one complete NUL-delimited stage-0 record with byte-exact path identity. The surrounding finalization boundary still has three ship-blocking trust defects: it resolves every dependency against a moving `HEAD`, it treats whatever numbered artifacts remain at `HEAD` as the complete phase history, and the worktree-loaded extension that establishes the private authority root is itself outside that authentication root. The new documentation contract also embeds release-version literals that will make the suite fail on the next package-line change.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Dependency authentication is not bound to one immutable HEAD

**Classification:** BLOCKER
**File:** `.gsd/extensions/finalize-phase/index.ts:119-159,169-207,296-325`
**Issue:** Every `cat-file`, `ls-tree`, `diff`, and `show` invocation resolves the symbolic name `HEAD` independently. Authentication spans dozens of awaited subprocesses, so a concurrent checkout, reset, or ref update can move `HEAD` between enumeration, cleanliness checks, and blob reads. The resulting private tree can contain an authenticated-looking mixture of files from different commits; the downstream finalizer only observes the final checkout SHA and cannot detect that earlier dependencies came from another tree. This breaks the core guarantee that the executed dependency chain represents one exact repository state.
**Fix:** Resolve and validate one full commit OID once (for example, `git rev-parse --verify HEAD^{commit}`), pass that OID into all authentication/enumeration helpers, use `${headOid}:${path}` and `ls-tree <headOid>`, and re-check that checkout `HEAD` still equals the captured OID immediately before dispatch. Prefer comparing each index/worktree path against the captured blob OID rather than rerunning diffs against symbolic `HEAD`. Add a harness case that changes `HEAD` between two mocked Git calls and requires rejection.

### CR-02: Removing a complete plan/summary pair shrinks the trusted manifest without failing

**Classification:** BLOCKER
**Files:** `.gsd/extensions/finalize-phase/index.ts:162-186`; `scripts/finalize_phase_164.sh:98-105`
**Issue:** `numberedPhaseDependencies` accepts any nonempty set of matching files, and the terminal gate checks only that each plan still present has a summary. If a commit deletes both `164-NN-PLAN.md` and `164-NN-SUMMARY.md`, neither check notices: enumeration simply returns a smaller authenticated set and the shell loop never visits the missing number. The validator likewise derives phase subjects from the plans that remain. A phase can therefore finalize after losing an entire numbered unit of its implementation/provenance history.
**Fix:** Validate an exact authoritative artifact manifest before materialization. At minimum require one PLAN and one SUMMARY for every contiguous number through a separately anchored terminal plan number, with no gaps or unmatched files. For Phase 164, persist the expected terminal set (currently through Plan 20) in an authenticated manifest or terminal verification field rather than deriving completeness from the directory being checked. Add regressions that remove both members of a middle pair and the terminal pair.

### CR-03: The root extension executes from mutable worktree bytes before authentication begins

**Classification:** BLOCKER
**File:** `.gsd/extensions/finalize-phase/index.ts:222-358`
**Issue:** The extension is the component that authenticates and materializes the remaining chain, but GSD imports this file directly from the worktree. It never proves its own bytes against `HEAD`, and self-checking after import would not establish trust because modified code can omit or forge that check. An `assume-unchanged` mutation of `index.ts` is invisible to the downstream stable-porcelain gates and can dispatch arbitrary code or substitute arbitrary materialized inputs. Tests cover hidden mutations of transitive helpers/data but omit the root that enforces those protections.
**Fix:** Move the trust bootstrap outside this extension: the extension loader (or a separately installed trusted command) must resolve a commit OID, read this module from that commit, verify the worktree module byte-for-byte before importing it, or execute a committed/materialized entry point without evaluating mutable repository TypeScript first. If the loader cannot provide that guarantee, document this command as trusting local extension bytes and do not claim an authenticated end-to-end chain. Add a subprocess regression with an `assume-unchanged` mutation of the extension itself.

## Warnings

### WR-01: Documentation contracts hardcode the current package version

**Classification:** WARNING
**File:** `test/mailglass/docs_contract_test.exs:48-58`
**Issue:** The adjacent compatibility test derives package major/minor values from each manifest, but this test hardcodes `~> 2.5` four times. A legitimate minor-line release will update manifests and documentation while these assertions remain stale, causing a false CI failure and undermining the stated manifest-derived contract.
**Fix:** Reuse `package_major_minor!/1` to construct the expected core/admin constraints, then assert preview-only versus production-capable option shape around those dynamic values. This keeps the environment distinction checked without coupling the test to one release number.

---

_Reviewed: 2026-09-10T15:07:40Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
