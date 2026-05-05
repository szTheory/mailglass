---
phase: "34"
plan: "01"
subsystem: "testing"
tags: ["support-contract", "citext-probe", "mix-aliases", "provider-compatibility"]
requires: ["MAT-03"]
provides:
  - "root-support-contract-core-alias"
  - "provider-compatibility-advisory-alias"
  - "honest-root-citext-probe-failure"
affects:
  - "mix.exs"
  - "test/support/citext_probe.ex"
  - "test/mailglass/test_support/citext_probe_test.exs"
tech_stack:
  added: []
  patterns:
    - "explicit file-list verification aliases"
    - "bounded probe retries with explicit exhaustion failure"
    - "focused probe regression tests"
key_files:
  created:
    - "test/mailglass/test_support/citext_probe_test.exs"
  modified:
    - "mix.exs"
    - "test/support/citext_probe.ex"
decisions:
  - "Keep the root support-contract gate explicit and separate from the broader root suite."
  - "Make citext probe exhaustion raise loudly instead of returning false-green :ok."
  - "Use unique probe addresses so concurrent local runs do not collide on the probe row."
metrics:
  completed_at: "2026-05-05T19:46:54Z"
  duration: "during Phase 34 execution"
  tasks_completed: 2
  files_touched: 3
---

# Phase 34 Plan 01: Root Verification Closure Summary

Root support-contract verification is now explicit and the root citext bootstrap probe fails honestly with regression coverage.

## Tasks Completed

### Task 1

- Added `verify.support_contract.core` to run the exact required root support-contract bundle in one invocation.
- Added `verify.provider_compatibility` as the deterministic advisory provider lane with an explicit file list.
- Registered both aliases in `preferred_envs` so they run cleanly under `MIX_ENV=test`.

### Task 2

- Refactored `Mailglass.TestSupport.CitextProbe` so retry exhaustion raises `citext probe exhausted for Mailglass.TestRepo after N attempts`.
- Extracted the probe body behind `probe_fun` injection so the behavior can be tested deterministically.
- Added `test/mailglass/test_support/citext_probe_test.exs` with one success-path assertion and one exhausted-retry assertion.

## Verification

- `mix test test/mailglass/test_support/citext_probe_test.exs --warnings-as-errors`
- `mix verify.support_contract.core`
- `mix verify.provider_compatibility`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Verification stability] Removed probe-row collisions during concurrent local runs**
- **Found during:** Wave 1 verification
- **Issue:** Parallel local Mix invocations collided on the shared `__probe__` suppression row and produced false-negative constraint failures.
- **Fix:** Switched the probe insert to a unique generated address while keeping the same package-local retry contract.
- **Files modified:** `test/support/citext_probe.ex`

## Issues Encountered

- No plan-scope blocker remained after the probe row was made unique.

## Self-Check: PASSED

- Verified the new aliases run successfully.
- Verified the probe tests cover both success and exhausted-retry behavior.

