---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-11T01:43:23Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - .gitignore
  - /Users/jon/.local/bin/mailglass-finalize-phase
  - /Users/jon/.local/share/mailglass/checkpoints/164-23-install-approval.env
  - /Users/jon/.local/share/mailglass/checkpoints/164-27-install-approval.env
  - /Users/jon/.local/share/mailglass/checkpoints/164-27-install-proposal.env
  - /Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9
  - MAINTAINING.md
  - README.md
  - compose.toolchain.yml
  - config/test_exceptions.exs
  - dev/toolchain/Dockerfile
  - mailglass_admin/README.md
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_inbound/README.md
  - mix.exs
  - scripts/ci_monitor.cjs
  - scripts/closeout_repository_truth.sh
  - scripts/finalize_phase_164.sh
  - scripts/mailglass_finalize_phase_loader.mjs
  - scripts/scheduled_control_evidence.sh
  - scripts/validate_repository_truth.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/publish/maintaining_release_gate_contract_test.exs
  - test/scripts/ci_parity_drift_test.exs
  - test/scripts/phase_164_closeout_test.exs
  - test/scripts/phase_164_repository_truth_test.exs
  - test/scripts/scheduled_control_evidence_test.exs
  - test/scripts/suite_floor_contract_test.exs
  - test/support/suite_floor.ex
  - test_js/ci-monitor.test.cjs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-11T01:43:23Z
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

The installed-loader and private-authority implementation is generally defensive, but the new controlled-host test boundary is not wired to the authority it claims to prove and is not isolated from the repository's other full-suite entry points. As submitted, protected full-suite CI can fail solely because a maintainer-specific Node path does not exist, while the dedicated installed-boundary alias can pass without reading either the installed executable or its approval record. The repository-truth validator also has an avoidable crash path for a syntactically valid but incomplete authority directory.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The installed-boundary gate never verifies the installed executable or approval tuple

**File:** `/Users/jon/projects/mailglass/test/scripts/phase_164_closeout_test.exs:1269-1366`

**Issue:** The only tests selected by `verify.phase_164.installed_boundary` are the `phase 164 installed production boundary` describe block. Every test in that block calls `production_installed_fixture!/2`, which copies the tracked `scripts/mailglass_finalize_phase_loader.mjs` into a disposable fixture (`:2050-2057`), and `invoke_production_loader/3` executes that disposable copy (`:2060-2073`). The block never reads `/Users/jon/.local/bin/mailglass-finalize-phase`, `/Users/jon/.local/share/mailglass/checkpoints/164-27-install-approval.env`, or the approved digest/OID tuple. Consequently, the controlled-host alias can pass after the installed command has been deleted, replaced, downgraded, or detached from its approval record. This makes the named operational proof materially false and defeats the lifecycle separation introduced in `mix.exs:304-305`.

**Fix:** Add a test under `@describetag :phase_164_installed_production_boundary` that fails closed unless the real installed path and current approval record are regular non-symlink files with the required modes, parses the approval record with an exact key schema, verifies the installed SHA-256 against `source_sha256`, verifies the approved installation OID and ancestry, and runs the installed command's `--self-check` with that recorded OID. Keep source-derived disposable-loader tests in the repository-only group; they do not constitute installed-boundary evidence.

### CR-02: The host-only tests still execute in protected full-suite lanes

**File:** `/Users/jon/projects/mailglass/test/scripts/phase_164_closeout_test.exs:1270`

**Issue:** Phase 164 excludes `:phase_164_installed_production_boundary` only from `verify.ci_lane_contract` (`mix.exs:298-305`). The repository still has unfiltered full-suite commands, including `mix.exs:417` and the protected deterministic-core CI command `mix test --warnings-as-errors`. `test/test_helper.exs` does not exclude the new tag by default, so those full suites collect all five tests in this describe. Each test eventually calls `System.cmd("/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node", ...)` at lines 2060-2077. That executable is absent on GitHub-hosted Linux runners and in the supplied toolchain image, which installs Node as `/usr/bin/node`. Thus the new tests can crash the required full suite before making an assertion, blocking protected CI and local parity on every non-Jon environment.

**Fix:** Default-exclude `:phase_164_installed_production_boundary` in `test/test_helper.exs` and explicitly include it only in the controlled-host alias (verify that `--only` overrides the default exclusion), or add the exact exclusion to every repository-only full-suite invocation. Remove the hard-coded interpreter from disposable fixture tests and use a validated executable supplied by the test environment. Add a contract test that expands every full-suite CI/local alias and proves the host-only tag cannot run there.

## Warnings

### WR-01: An incomplete authority directory crashes the validator instead of returning a controlled error

**File:** `/Users/jon/projects/mailglass/scripts/validate_repository_truth.exs:419-429`

**Issue:** `audit_subjects/2` validates only that `authority_root` is a directory, then `ignore_subjects/1` calls `File.stream!/1` for six required ignore files (`:791-800`). A caller can provide an existing but incomplete authority directory and trigger an uncaught `File.Error`, bypassing the validator's documented `{:error, reason}` result and `main/1` diagnostic path. The installed loader currently materializes these files, so this is primarily a robustness defect in the standalone public script, but it makes malformed-boundary behavior inconsistent and harder to diagnose.

**Fix:** Read/stream required authority files with non-raising APIs and return a tagged error such as `{:error, {:authority_subject_missing, path}}`; thread that result through `audit_subjects/2`'s `with` chain. Add a CLI regression using an existing empty `--authority-root` and assert a stable diagnostic plus exit status 1.

---

_Reviewed: 2026-09-11T01:43:23Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
