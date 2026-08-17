---
phase: 159-raise-and-simplify-engineering-gates
plan: 03
subsystem: test-governance
tags: [determinism, exceptions, async-tests]
requires: [159-01]
provides: [bidirectional test-exception registry, focused outbound acknowledgements]
affects: [159-04, 159-06]
key-files:
  created: [config/test_exceptions.exs, scripts/check_test_exceptions.sh, test/scripts/test_exceptions_contract_test.exs]
  modified: [test/mailglass/outbound/deliver_later_test.exs]
requirements-completed: [QUAL-09]
completed: 2026-08-17
---

# Phase 159 Plan 03: Test Exception Governance Summary

## Completed

- Added an expiring, owner/reason/category registry for every executable `@tag :skip` / `@tag :flaky`, `Process.sleep`, and `pg_sleep` site under the core and inbound test trees.
- Added a fail-closed validator that compares the registry to the source inventory bidirectionally and rejects missing fields, expired records, stale records, or unregistered sites.
- Added contract tests for the valid registry and an injected expired record.
- Replaced the bulk async delivery wait with the Fake adapter mailbox acknowledgement and removed the route-adapter wait in favor of its existing adapter acknowledgement.

## Verification

Passed:

```bash
bash scripts/check_test_exceptions.sh
mix test test/scripts/test_exceptions_contract_test.exs --warnings-as-errors
mix test test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors
cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs --warnings-as-errors
git diff --check
```

## Commits

- `1e4ed6e5 test(159-03): govern test exceptions bidirectionally`
- `fef58542 test(159-03): acknowledge async bulk delivery`

## Deviations from Plan

**[Rule 3 - Safe scope boundary] Remaining liveness waits are registered, not removed.** The outbound Task.Supervisor tenancy test has no test-visible completion acknowledgement for its default Fake adapter path; making one would require a runtime dispatch/configuration change. The inbound router-registry restart test likewise polls a process-registration lifecycle and has no safe event seam. Both are explicitly categorized `:liveness`, owned, reasoned, and expiring in the registry. Clock/TTL, database timeout, fixture, teardown, and optional-dependency waits are also categorized rather than misrepresented as readiness sleeps.

**Total deviations:** 1 bounded scope decision. **Impact:** no runtime or admin UI behavior changed; remaining exceptions are now executable governance debt rather than silent permissive state.

## Scope Confirmation

- No runtime/library source or admin/operator UI files changed.
- Core and inbound tests were run from their respective package roots.
