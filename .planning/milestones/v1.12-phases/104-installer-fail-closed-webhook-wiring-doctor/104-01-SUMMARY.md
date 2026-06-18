---
phase: 104-installer-fail-closed-webhook-wiring-doctor
plan: 01
subsystem: installer
tags: [tdd, tests-first, installer, fail-closed, webhook-wiring, doctor]
dependency_graph:
  requires: []
  provides: [INSTALL-01-contract-tests, INSTALL-02-contract-tests, INSTALL-03-contract-tests]
  affects: [104-02-PLAN.md]
tech_stack:
  added: []
  patterns: [fixture-harness, cd-scoped-test, tuple-pattern-match, byte-index-ordering]
key_files:
  created:
    - test/mailglass/install/install_fail_closed_test.exs
    - test/mailglass/install/mailglass_doctor_test.exs
  modified: []
decisions:
  - "Seed helper overwrites endpoint.ex via File.write! after new_fixture_root!/1 — mandatory because the bare host_endpoint/0 skeleton emits NO plug at all, so without this seed the conflict guard never fires (vacuous pass footgun)"
  - "INSTALL-01 tuple assertion uses Apply.run/2 directly — NOT run_install!/2 which re-raises a RuntimeError embedding only inspect(reason) in the message, forcing a DNA-forbidden message-string match"
  - "INSTALL-02 uses :binary.match/2 for byte-index ordering rather than String.starts_with? or string position — byte index is unambiguous even if whitespace differs"
  - "Doctor tests use fresh fixture root for each test case to avoid cross-test state contamination with async: false"
metrics:
  duration: "5 minutes"
  completed: "2026-06-17"
  tasks: 2
  files: 2
---

# Phase 104 Plan 01: Installer Fail-Closed + Doctor — RED Tests Summary

## One-Liner

Two failing ExUnit test files (5 failures on 6 tests) encoding the INSTALL-01/02/03 contracts — tuple error return, `--force` ordering, and doctor 0/1/2 exit mapping — before any implementation exists.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write failing install_fail_closed_test.exs | d631b56d | test/mailglass/install/install_fail_closed_test.exs |
| 2 | Write failing mailglass_doctor_test.exs | fa78adff | test/mailglass/install/mailglass_doctor_test.exs |

## What Was Built

### Task 1: install_fail_closed_test.exs

Three test cases for INSTALL-01 and INSTALL-02:

1. **INSTALL-01 tuple-level**: Calls `Apply.run/2` directly inside `File.cd!(fixture_root, ...)` and pattern-matches `{:error, {:unmanaged_parser_conflict, _path}}`. RED because `validate_preflight/1` currently only emits a warning (apply.ex:64-73) and the return value is discarded — Apply.run/2 returns `{:ok, ...}`.

2. **INSTALL-01 task-level exit**: Wraps `run_install!(fixture_root, [])` in `assert_raise RuntimeError` and asserts the message names `lib/example_web/endpoint.ex`. RED because no exception is raised (install currently succeeds with a warning).

3. **INSTALL-02 `--force` ordering**: Calls `run_install!(fixture_root, ["--force"])`, reads the patched endpoint, and asserts the managed start-marker byte index (`Mailglass.Installer.Templates.endpoint_webhook_block_start()`) is strictly less than the `plug Plug.Parsers` byte index via `:binary.match/2`. Then calls `assert_generated_artifacts_compile!/1`. This test PASSES because `--force` already appends the managed block — but the byte-index ordering assertion correctly verifies the managed block appears first.

Seed helper `seed_unmanaged_parser!/1` overwrites `lib/example_web/endpoint.ex` with a bare `plug Plug.Parsers` having NO `body_reader` key and NO managed markers — satisfying the seeding footgun discipline from 104-RESEARCH.md.

### Task 2: mailglass_doctor_test.exs

Three test cases for INSTALL-03:

1. **Wired → exit 0**: Runs installer on fresh fixture (wires managed CachingBodyReader block), then asserts `summary.fail == 0` and `cannot_diagnose == 0`.

2. **Unwired → exit 1**: Uses a fresh fixture WITHOUT running the installer (bare endpoint skeleton, no managed block), then asserts `summary.fail > 0` and `cannot_diagnose == 0`.

3. **Cannot-diagnose → exit 2**: Deletes `lib/example_web/endpoint.ex`, then asserts `summary.cannot_diagnose > 0`.

All three call the runner inside `File.cd!(fixture_root, fn -> Mailglass.Installer.Doctor.run([]) end)` so `detect_otp_app/0` resolves against the fixture (D-14). All three are RED with `UndefinedFunctionError` because `Mailglass.Installer.Doctor` does not exist yet.

## Verification Results

```
mix test test/mailglass/install/install_fail_closed_test.exs test/mailglass/install/mailglass_doctor_test.exs
6 tests, 5 failures
```

- `install_fail_closed_test.exs`: 2 failures (INSTALL-01 tests), 1 pass (INSTALL-02 `--force` ordering)
- `mailglass_doctor_test.exs`: 3 failures, all `UndefinedFunctionError` for `Mailglass.Installer.Doctor.run/1`
- Both files COMPILE (no syntax errors, no CompileError)
- Failure reasons are behavioral/module-missing — NOT test infrastructure bugs

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — these are pure test files with no data sources or rendering.

## Threat Flags

None — test-only plan, no new network endpoints, auth paths, or schema changes.

## Self-Check: PASSED

- [x] `test/mailglass/install/install_fail_closed_test.exs` exists
- [x] `test/mailglass/install/mailglass_doctor_test.exs` exists
- [x] Commit d631b56d exists (Task 1)
- [x] Commit fa78adff exists (Task 2)
- [x] `grep -c 'unmanaged_parser_conflict' ...install_fail_closed_test.exs` = 2 (≥ 1 ✓)
- [x] `:binary.match` and `assert_generated_artifacts_compile!` both present in fail_closed test
- [x] Seed body contains no `body_reader` key
- [x] `grep -c 'cannot_diagnose' ...mailglass_doctor_test.exs` = 12 (≥ 2 ✓)
- [x] Doctor tests use `File.cd!(fixture_root, ...)` for all runner calls
