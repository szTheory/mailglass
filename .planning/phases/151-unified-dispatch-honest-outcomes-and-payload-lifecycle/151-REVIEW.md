---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
reviewed: 2026-08-03T03:43:30Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/dispatch_outcome.ex
  - lib/mailglass/outbound/payload.ex
  - test/mailglass/outbound/deliver_later_test.exs
  - test/mailglass/outbound/worker_test.exs
  - test/mailglass/outbound_test.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 151: Code Review Report

**Reviewed:** 2026-08-03T03:43:30Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Re-review of remediation commits `27798aed..3f11e9fb` confirms that CR-01 now
keeps `%Mailglass.SendError{}` on the public sync boundary and serializes the
stable safe `last_error` shape; CR-03 now emits fixed, allowlisted
TaskSupervisor log metadata; and corrupt/unsupported payloads are settled,
retain their tampered evidence, become pruneable, and cancel on repeat.

One BLOCKER remains: a terminal persisted-adapter mismatch is returned to Oban
as retryable. It retries the job despite the already-settled terminal payload,
then keeps retrying on each repeat rather than cancelling with its terminal
lifecycle fact.

## Critical Issues

### CR-01: A terminal route-mismatch payload is retried indefinitely by the worker

**File:** `lib/mailglass/outbound.ex:680-687, 1038-1042`; `lib/mailglass/outbound/worker.ex:84-96`

**Issue:** A persisted adapter mismatch is correctly settled as a terminal
`:pre_dispatch_failure` at lines 680-682, but the method returns the original
`%SendError{type: :serialization_failed, reason_class: :persisted_adapter_mismatch}`.
`worker_error_result/1` has no branch for that reason or for a generic
`outcome_class: :terminal`, so it returns `{:error, err}` to Oban. On the next
attempt `Payload.claim/2` returns the stored `{:terminal, :pre_dispatch_failure}`;
that too falls through the worker's generic retry branch. This contradicts the
terminal route-failure contract and creates needless retries after the Delivery,
Event, and Payload have already been atomically settled.

**Fix:** Preserve the exact public `serialization_failed` mismatch error, but
teach `worker_error_result/1` to recognize terminal outcome metadata (including
the persisted `{:terminal, reason}` claim result) and return
`{:cancel, :pre_dispatch_failure}`. Add a regression test that invokes the
same mismatched job twice and asserts both calls cancel without provider I/O.

---

_Reviewed: 2026-08-03T03:43:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
