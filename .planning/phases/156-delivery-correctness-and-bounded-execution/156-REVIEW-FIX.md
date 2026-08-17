---
phase: 156-delivery-correctness-and-bounded-execution
fixed_at: 2026-08-17T05:25:00Z
review_path: .planning/phases/156-delivery-correctness-and-bounded-execution/156-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 156: Code Review Fix Report

**Fixed at:** 2026-08-17T05:25:00Z
**Source review:** `.planning/phases/156-delivery-correctness-and-bounded-execution/156-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### Iteration 3

#### CR-01 / CR-02: Durable route authority and tenant-bound job validation

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`, `mailglass_inbound/lib/mailglass_inbound/execution.ex`, `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex`, and focused inbound tests.
**Commit:** `512753de`
**Applied fix:** Persisted the selected route status, mailbox identity, and router identity under the internal `verification_facts["mailglass_execution_route"]` key in the same record/evidence transaction. Workers now load tenant-scoped evidence before validation, derive their route exclusively from that binding, reject selector mismatches, and rediscover the exact loaded router/module after registry restart without creating atoms. Replay uses the same binding and treats unbound legacy mailbox strings as non-executable.

### Iteration 2

#### CR-01: The mailbox allowlist breaks documented durable ingress configuration

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/application.ex`, `mailglass_inbound/lib/mailglass_inbound/execution.ex`, `mailglass_inbound/lib/mailglass_inbound/execution/router_registry.ex`, `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex`, `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`, `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs`, `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs`, `mailglass_inbound/test/mailglass_inbound/worker_test.exs`  
**Commit:** `85aad6eb`  
**Applied fix:** Added a supervised finite registry of trusted router route data. The Plug passes its configured router into dispatch; dispatch registers it before enqueueing a stable authority identity, and workers resolve mailbox strings only within that registered authority. Missing authority is returned as a retryable worker error rather than a permanent cancellation.

#### CR-02: Internal replay still invokes a mailbox selected from persisted data

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex`, `mailglass_inbound/test/mailglass_inbound/replay_test.exs`, `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs`  
**Commit:** `ea953926`  
**Applied fix:** Routed replay mailbox resolution through the same finite authority resolver, added explicit router support, and covered rejection of a loaded `process/1` sentinel without invocation.

### Iteration 1

#### CR-01: Replay still allocates an atom from a persisted provider string

**Files modified:** `lib/mailglass/webhook/replay.ex`, `test/mailglass/webhook/replay_test.exs`  
**Commit:** `ef2e6c36`  
**Applied fix:** Passed the finite-decoded provider atom through replay result construction and added outcome/source-scan regressions proving the replay path has no `String.to_atom/1` use.

#### CR-02: Inbound job data can select any already-loaded module as the mailbox

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/execution.ex`, `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex`, `mailglass_inbound/test/mailglass_inbound/worker_test.exs`, `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs`  
**Commits:** `ac3629ca`, `2dc107b1`  
**Applied fix:** Replaced job-string atom decoding with a configured-router finite mailbox allowlist, validated job route data before loader/execution, and added loaded non-mailbox plus contradictory-route cancellation regressions.

#### WR-01: A rate-limiter table-owner restart raises callers instead of failing closed

**Files modified:** `lib/mailglass/rate_limiter/atomic_bucket.ex`, `test/mailglass/rate_limiter_test.exs`, `mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs`  
**Commit:** `e1cf4b2e`  
**Applied fix:** Guarded ETS lookup and compare-and-swap operations against a missing table so restart races deny safely; core and inbound tests verify their normal rate-limit error is returned.

---

_Fixed: 2026-08-17T05:25:00Z_
_Fixer: gsd-code-fixer_
_Iteration: 3_
