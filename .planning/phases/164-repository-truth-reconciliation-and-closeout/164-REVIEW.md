---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-11T18:47:03Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - /Users/jon/.local/share/mailglass/checkpoints/164-32-install-approval.env
  - /Users/jon/.local/share/mailglass/checkpoints/164-32-install-proposal.env
  - /Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e
  - config/test_exceptions.exs
  - scripts/finalize_phase_164.sh
  - scripts/mailglass_finalize_phase_loader.mjs
  - scripts/validate_repository_truth.exs
  - test/mailglass/compliance_test.exs
  - test/mailglass/demo_data_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/publish/maintaining_release_gate_contract_test.exs
  - test/scripts/ci_parity_drift_test.exs
  - test/scripts/phase_164_closeout_test.exs
  - test/scripts/phase_164_repository_truth_test.exs
  - test/scripts/release_policy_contract_test.exs
  - test/scripts/scheduled_control_evidence_test.exs
  - test/scripts/suite_floor_contract_test.exs
  - test/scripts/verify_published_release_test.exs
  - test/support/suite_floor.ex
  - test/test_helper.exs
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-11T18:47:03Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The 01-34 reconciliation fixes the earlier installed-boundary and suite-isolation findings, but the approved installed command still cannot run the closeout toolchain it pins. The loader also loses its authenticated authority OID at the Bash boundary, leaving a race in which different commits can supply the authenticated code and the repository evidence. A purported moving-HEAD regression test does not exercise that race, and the standalone ledger validator still has an uncaught non-repository input path.

The full Elixir suite could not be executed on this host because the repository requires Elixir 1.18.4 while that asdf installation is absent. The toolchain blocker below was independently reproduced in the loader's exact child `PATH`: the approved Mix shim exits 127 with `asdf: not found`.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 (BLOCKER): The approved Mix and Elixir executables are unusable in the sanitized child environment

**Files:**

- `scripts/mailglass_finalize_phase_loader.mjs:26-33`
- `scripts/mailglass_finalize_phase_loader.mjs:132-160`
- `/Users/jon/.local/share/mailglass/checkpoints/164-32-install-approval.env:12-13`

**Issue:** The approved tuple pins `MIX` and `ELIXIR` to asdf shim scripts. Those scripts execute `asdf exec`, but `buildChildEnvironment/1` constructs `PATH` only from the pinned executables' directories plus `/usr/bin` and `/bin`; the actual asdf executable is `/opt/homebrew/bin/asdf`, and `/opt/homebrew/bin` is absent. Running the approved Mix path under that exact child `PATH` fails with exit 127 (`exec: asdf: not found`). Even if asdf were made reachable, `.tool-versions` requires Elixir 1.18.4, which is not installed on this host. The downstream closeout invokes bare `mix` and `elixir` (`scripts/closeout_repository_truth.sh:123,140`), so both pre-verification and terminal finalization are unable to reach their repository hygiene and ledger checks. `validateTrustedToolchain/1` only validates the shim files themselves and therefore approved an interpreter chain that cannot execute. Preserving caller-controlled `ASDF_DATA_DIR`, `ASDF_DIR`, and version overrides at lines 144-147 would also let the caller redirect that chain if asdf were merely added to `PATH`.

**Fix:** Pin real, runnable Mix and Elixir executables for the required versions (including their interpreter/runtime dependencies), remove or set the asdf override variables instead of inheriting them, and have the downstream script call `"$MAILGLASS_MIX"` and `"$MAILGLASS_ELIXIR"` rather than bare names. Before approving an installation, execute version probes inside the exact sanitized child environment and reject any nonzero result. For example:

```bash
"$MAILGLASS_MIX" --version >/dev/null
"$MAILGLASS_ELIXIR" --version >/dev/null
(cd "$repo" && "$MAILGLASS_MIX" mailglass.repo.hygiene --check --format json)
"$MAILGLASS_ELIXIR" "$authority_root/scripts/validate_repository_truth.exs" ...
```

### CR-02 (BLOCKER): The authenticated authority OID is discarded before Bash, allowing mixed-commit finalization

**Files:**

- `scripts/mailglass_finalize_phase_loader.mjs:408-427`
- `scripts/finalize_phase_164.sh:235-270`

**Issue:** The loader authenticates and materializes every dependency from `authorityOid`, then checks HEAD once at lines 419-420. It spawns the finalizer with only the repository and private authority-root paths; the authenticated OID is not passed. The shell subsequently fetches and independently captures whatever HEAD exists at lines 266-270 as `main_sha`. A fast-forward or other same-user checkout update after the loader's last check but before the shell captures HEAD is therefore accepted as long as it equals `origin/main`. The process can then validate new repository state and the live ledger (`scripts/finalize_phase_164.sh:311`) using scripts and policy material authenticated from the old commit. This violates the claimed single-authority-OID boundary and can produce a passing closeout assembled from two commits.

**Fix:** Pass `authorityOid` as an explicit required argument (or otherwise immutable authenticated input) to the shell. On entry and again after fetch, require both HEAD and `origin/main` to equal that exact OID; never recapture a replacement authority. Use the authority-root ledger rather than the mutable checkout copy. For example:

```javascript
spawnSync(tools.BASH, [finalizer, repo, privateRoot, authorityOid, ...modeArgs], options);
```

```bash
expected_oid=$3
current_oid=$("$MAILGLASS_GIT" -C "$repo" rev-parse HEAD)
[ "$current_oid" = "$expected_oid" ] || fail "authority commit changed before finalization"
```

## Warnings

### WR-01 (WARNING): The moving-HEAD regression test explicitly accepts success and never moves HEAD

**File:** `test/scripts/phase_164_closeout_test.exs:1096-1112`

**Issue:** The test named `rejects a moving HEAD` asserts `moving_status == 0` and that dispatch created its marker. Its fixture tries to advance HEAD through a `git` executable prepended to `PATH` (`:2419-2452`), but the loader invokes its absolute pinned Git path, so the shim is never called; the test even asserts that `git_log` does not exist. The test therefore proves that environment-path substitution is ignored, not that a checkout change between authentication and Bash dispatch is rejected. This materially masks CR-02.

**Fix:** Separate the environment-substitution assertion into its own test. Add a deterministic dispatch hook or a fixture finalizer that advances the fixture checkout precisely after authentication, pass the captured expected OID across the boundary, and assert a nonzero result, an authority-drift diagnostic, and no closeout marker.

### WR-02 (WARNING): An existing non-Git `--repo` crashes the ledger validator instead of returning a controlled error

**File:** `scripts/validate_repository_truth.exs:797-799,848-850`

**Issue:** `ensure_repository/1` accepts any directory. `audit_subjects/2` then calls `tracked_subjects/2`, which pattern-matches specifically on `{output, 0}` from `git ls-files`. For an existing directory that is not a Git worktree, Git returns a nonzero status and the public CLI raises a `MatchError` instead of reaching `main/1`'s stable `{:error, reason}` diagnostic and exit-status path. This makes malformed-boundary behavior inconsistent and exposes an avoidable stack trace.

**Fix:** Validate `git rev-parse --is-inside-work-tree` as part of `ensure_repository/1`, or make `tracked_subjects/2` return `{:ok, subjects} | {:error, reason}` and thread it through `audit_subjects/2`. Add a CLI regression with an empty temporary directory as `--repo` and assert exit status 1 plus a bounded `invalid_repository` diagnostic.

---

_Reviewed: 2026-09-11T18:47:03Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
