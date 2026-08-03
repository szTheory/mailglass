---
phase: 151
fixed_at: 2026-08-03T03:46:00Z
review_path: .planning/phases/151-unified-dispatch-honest-outcomes-and-payload-lifecycle/151-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 151: Code Review Fix Report

**Fixed at:** 2026-08-03T03:46:00Z
**Source review:** `.planning/phases/151-unified-dispatch-honest-outcomes-and-payload-lifecycle/151-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Sync delivery now returns a non-error outcome struct, breaking the stable API

**Files modified:** `lib/mailglass/outbound.ex`, `test/mailglass/outbound_test.exs`
**Commit:** 27798aed
**Applied fix:** Kept `DispatchOutcome` internal, returns typed `Mailglass.SendError` values across public boundaries, and stores the stable `type`/`message`/`module` error projection.

### CR-02: Invalid modern payloads are claimed but never terminally settled

**Files modified:** `lib/mailglass/outbound.ex`, `lib/mailglass/outbound/payload.ex`, `lib/mailglass/outbound/dispatch_outcome.ex`, `test/mailglass/outbound/worker_test.exs`
**Commit:** 8b2e3087, 3cc7a249
**Applied fix:** Claimed modern payload hydration and route failures settle Delivery, Event, and Payload atomically with finite retention. Corrupt and unsupported versions remain distinct terminal reasons; repeated jobs see the retained terminal state. The follow-up preserves the original `serialization_failed/persisted_adapter_mismatch` error contract while still settling route mismatches, and proves retained corrupt content is the observed tampered evidence until pruning.

### CR-03: TaskSupervisor dispatch logs provider/private exception text

**Files modified:** `lib/mailglass/outbound.ex`, `test/mailglass/outbound/deliver_later_test.exs`
**Commit:** 45611e15
**Applied fix:** Replaced interpolated exception logging with fixed event names plus bounded classification metadata. The regression test raises a private sentinel and proves it is absent from captured logs.

## Re-review Follow-up

### CR-01: A terminal route-mismatch payload is retried indefinitely by the worker

**Files modified:** `lib/mailglass/outbound/worker.ex`, `test/mailglass/outbound/worker_test.exs`
**Commit:** 2cef16a4
**Applied fix:** The worker now recognizes both a first-attempt persisted adapter mismatch and the terminal lifecycle fact observed on a repeated claim, returning `{:cancel, :pre_dispatch_failure}` in both cases. The regression verifies no adapter I/O, finite terminal retention, and no extra event on the second attempt.

## Verification

- Worker/outbound/payload lifecycle/pruner sampler: passed (40 tests, 0 failures).
- `mix verify.support_contract.core`: passed (205 tests, 0 failures, 1 skipped).
- `mix compile --no-optional-deps --warnings-as-errors`: passed in the preceding fix run.
- The earlier complete-suite attempt had an unrelated reference-host smoke failure because `test/reference_host` dependencies were unavailable.

---

_Fixed: 2026-08-03T03:46:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
