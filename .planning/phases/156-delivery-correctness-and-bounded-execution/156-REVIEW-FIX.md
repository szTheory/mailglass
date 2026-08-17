---
phase: 156-delivery-correctness-and-bounded-execution
fixed_at: 2026-08-17T05:00:00Z
review_path: .planning/phases/156-delivery-correctness-and-bounded-execution/156-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 156: Code Review Fix Report

**Fixed at:** 2026-08-17T05:00:00Z  
**Source review:** `.planning/phases/156-delivery-correctness-and-bounded-execution/156-REVIEW.md`  
**Iteration:** 1

**Summary:**

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Replay still allocates an atom from a persisted provider string

**Files modified:** `lib/mailglass/webhook/replay.ex`, `test/mailglass/webhook/replay_test.exs`  
**Commit:** `ef2e6c36`  
**Applied fix:** Passed the finite-decoded provider atom through replay result construction and added outcome/source-scan regressions proving the replay path has no `String.to_atom/1` use.

### CR-02: Inbound job data can select any already-loaded module as the mailbox

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/execution.ex`, `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex`, `mailglass_inbound/test/mailglass_inbound/worker_test.exs`, `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs`  
**Commits:** `ac3629ca`, `2dc107b1`  
**Applied fix:** Replaced job-string atom decoding with a configured-router finite mailbox allowlist, validated job route data before loader/execution, and added loaded non-mailbox plus contradictory-route cancellation regressions.

### WR-01: A rate-limiter table-owner restart raises callers instead of failing closed

**Files modified:** `lib/mailglass/rate_limiter/atomic_bucket.ex`, `test/mailglass/rate_limiter_test.exs`, `mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs`  
**Commit:** `e1cf4b2e`  
**Applied fix:** Guarded ETS lookup and compare-and-swap operations against a missing table so restart races deny safely; core and inbound tests verify their normal rate-limit error is returned.

---

_Fixed: 2026-08-17T05:00:00Z_  
_Fixer: gsd-code-fixer_  
_Iteration: 1_
