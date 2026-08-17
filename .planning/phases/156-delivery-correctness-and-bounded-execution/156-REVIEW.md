---
phase: 156-delivery-correctness-and-bounded-execution
reviewed: 2026-08-17T04:44:00Z
depth: deep
files_reviewed: 34
files_reviewed_list:
  - docs/api_stability.md
  - lib/mailglass/adapters/swoosh.ex
  - lib/mailglass/application.ex
  - lib/mailglass/errors/send_error.ex
  - lib/mailglass/optional_deps/oban.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/async_adapter.ex
  - lib/mailglass/outbound/async_adapter/task_supervisor.ex
  - lib/mailglass/outbound/worker.ex
  - lib/mailglass/rate_limiter.ex
  - lib/mailglass/rate_limiter/atomic_bucket.ex
  - lib/mailglass/rate_limiter/table_owner.ex
  - lib/mailglass/tracking/plug.ex
  - lib/mailglass/webhook/provider_name.ex
  - lib/mailglass/webhook/replay.ex
  - mailglass_inbound/lib/mailglass_inbound/application.ex
  - mailglass_inbound/lib/mailglass_inbound/execution.ex
  - mailglass_inbound/lib/mailglass_inbound/execution/worker.ex
  - mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex
  - mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex
  - mailglass_inbound/test/mailglass_inbound/async_execution_test.exs
  - mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs
  - mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs
  - mailglass_inbound/test/mailglass_inbound/worker_test.exs
  - test/mailglass/adapters/swoosh_test.exs
  - test/mailglass/application_test.exs
  - test/mailglass/error_test.exs
  - test/mailglass/outbound/deliver_later_test.exs
  - test/mailglass/outbound/deliver_many_test.exs
  - test/mailglass/outbound/telemetry_test.exs
  - test/mailglass/outbound/worker_test.exs
  - test/mailglass/rate_limiter_test.exs
  - test/mailglass/tracking/plug_test.exs
  - test/mailglass/webhook/replay_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 156: Code Review Report

**Reviewed:** 2026-08-17T04:44:00Z
**Depth:** deep
**Files Reviewed:** 34
**Status:** issues_found

## Summary

The atomic bucket, transactional Oban insertion, bounded task admission, and Swoosh/tracking paths were traced with their caller/worker boundaries. Focused core and inbound suites passed (93 tests total), but that does not cover two remaining untrusted-string boundaries. The phase cannot claim EXEC-08 or its closed/fail-closed security posture while those paths remain.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Replay still allocates an atom from a persisted provider string

**File:** `lib/mailglass/webhook/replay.ex:366`

**Issue:** The new `ProviderName.decode/1` correctly validates the stored provider before normalization, but `build_success_result/4` converts the original persisted `webhook_event.provider` with `String.to_atom/1`. A valid provider is only reached after validation today, yet this is still an unbounded atom-conversion sink on a database value and directly violates EXEC-08 / D-12. A future added provider, bypassed caller, or refactor that reaches the result builder before the current validation reintroduces atom-table exhaustion; the supplied atom-count test only exercises invalid values that fail before this line.

**Fix:** Carry the already-decoded `provider` atom through `run_replay/5` into `build_success_result/5` and set `provider: provider`. Delete the `String.to_atom/1` call. Add a regression assertion (and a repository scan test if appropriate) proving no `String.to_atom/1` remains in the replay path.

### CR-02: Inbound job data can select any already-loaded module as the mailbox

**File:** `mailglass_inbound/lib/mailglass_inbound/execution.ex:316-327`

**Issue:** `Execution.load/2` accepts the `"mailbox"` value from the Oban job, converts it with `String.to_existing_atom/1`, and later `classify_mailbox_result/3` invokes `mailbox.process(message)` (lines 277-280). `to_existing_atom/1` avoids atom growth but is not the required finite/authorized decoder: a tampered persisted job can select any already-loaded module that exports `process/1`, rather than the mailbox the router authorized for the stored inbound record. This crosses the job-JSON trust boundary as arbitrary module dispatch and lets corrupt job data produce execution outside the matched route.

**Fix:** Do not use the job-supplied module name as authority. Persist/rehydrate the matched route from a trusted record, or resolve the string through an application-configured allowlist of registered mailbox modules and verify it matches that record's route. Return `{:error, :invalid_job_args}` before `Execution.execute/2` for unknown or mismatched values. Add a worker test using a loaded non-mailbox `process/1` module and assert it is cancelled without invocation.

## Warnings

### WR-01: A rate-limiter table-owner restart raises callers instead of failing closed

**File:** `lib/mailglass/rate_limiter/atomic_bucket.ex:21-23,40-42`

**Issue:** Both admission and consume start with bare `:ets.lookup/2`. If the supervised `TableOwner` has crashed and its named ETS table has not yet been recreated, that call raises `ArgumentError`/`badarg`; only the subsequent `GenServer.call/2` is caught. A transient owner restart can therefore crash outbound callers rather than returning the documented denied/fail-closed result. Inbound uses this same shared engine and has the same failure mode.

**Fix:** Wrap ETS access in a small safe lookup helper that maps a missing table to `[]`/a denied result, and ensure the retry/admission path catches both ETS and owner unavailability. Add a deterministic owner-restart test asserting core and inbound limit checks return their normal rate-limit error rather than exiting.

---

_Reviewed: 2026-08-17T04:44:00Z_
_Reviewer: gsd-code-reviewer_
_Depth: deep_
