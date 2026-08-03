---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
reviewed: 2026-08-03T09:43:45Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - docs/api_stability.md
  - guides/compatibility-and-deprecations.md
  - guides/getting-started.md
  - guides/jobs.md
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/dispatch_outcome.ex
  - lib/mailglass/outbound/worker.ex
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/outbound/worker_test.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 151: Code Review Report

**Reviewed:** 2026-08-03T09:43:45Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Post-gap review of Plan 08 commits `69488de4..4c4706bd` confirms the legacy
metadata reconstruction helpers are removed, no-Payload rows do not fabricate
Payloads or call adapters, and the public docs now describe the fail-closed
contract. However, the new settlement path reports a terminal outcome even
when its Delivery+Event transaction rolls back. The worker therefore cancels
the job and strands a queued Delivery with no ledger fact.

## Critical Issues

### CR-01: Event/persistence failure cancels the job after rolling back missing-payload settlement

**File:** `lib/mailglass/outbound.ex:820-830`; `lib/mailglass/outbound/worker.ex:78-94`

**Issue:** `settle_missing_payload/1` calls `persist_outcome_multi/3`, which
atomically updates Delivery and appends the failed Event. On any `{:error,
_step, _reason, _changes}` result, it discards the error and returns the same
terminal `outcome_error/1` as a successful settlement. The worker classifies
that error as terminal and returns `{:cancel, :legacy_payload_missing}`. Thus
an Event insert failure (constraint, DB fault, stale entry, or tenant/prefix
write failure) rolls back both writes as intended but permanently cancels the
only job: the Delivery remains `:queued`, no terminal Event exists, and no
future attempt can settle it.

**Fix:** Preserve the all-or-nothing Multi, but return a retryable typed
persistence error when `persist_outcome_multi/3` fails, so Oban retries the
job. Return the terminal `legacy_payload_missing` error only after the Multi
commits (or when a freshly loaded Delivery already contains its committed
terminal projection). Add an integration test that forces the failed Event
insert and asserts the Delivery remains queued with no Event **and**
`Worker.perform/1` returns `{:error, ...}`, then remove the constraint and
assert the retry performs exactly one terminal settlement.

---

_Reviewed: 2026-08-03T09:43:45Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
