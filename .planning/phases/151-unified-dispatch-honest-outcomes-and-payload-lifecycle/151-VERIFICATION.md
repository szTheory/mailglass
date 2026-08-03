---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
verified: 2026-08-03T09:51:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "No-Payload legacy deliveries are never reconstructed from Delivery.metadata before dispatch."
  gaps_remaining: []
  regressions: []
---

# Phase 151: Unified Dispatch, Honest Outcomes, and Payload Lifecycle Verification Report

**Phase Goal:** Sync and durable async delivery use the same prepared provider input, report outcomes honestly, and retain private queue content only as long as operationally necessary.
**Verified:** 2026-08-03T09:51:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Sync and real Oban paths provide wire-equivalent prepared provider input. | ✓ VERIFIED | `dispatch_prepared/4` remains the shared provider seam; durable work hydrates immutable Payload input before entering it. The actual queued-job capture oracle remains in `wire_equivalence_test.exs`. |
| 2 | Outcomes are structurally classified; only retryable failures retry while terminal and uncertain outcomes settle/cancel. | ✓ VERIFIED | `DispatchOutcome` is closed and uses structured evidence; `Worker.perform/1` returns an Oban error only for retryable outcomes and cancels terminal/uncertain results. |
| 3 | Published guidance accurately describes the at-least-once provider boundary and duplicate-risk mitigation. | ✓ VERIFIED | Jobs, getting-started, compatibility, and API-stability guidance are locked by `docs_contract_test.exs`; support-contract verification passed independently. |
| 4 | Successful durable dispatch atomically records success and scrubs private payload, with finite tenant/prefix-bounded lifecycle pruning. | ✓ VERIFIED | Success updates Delivery, appends Event, and scrubs Payload in one `Repo.multi`; V07 constraints and the explicit-tenant, configured-limit CAS pruner remain wired. |
| 5 | Invalid, absent, expired, unsupported, and scrubbed payloads fail closed, settle idempotently, remain actionable/pruneable, and are never rebuilt from public metadata. | ✓ VERIFIED | The former legacy rehydration path is absent. `Payload.claim/2` not-found becomes `:legacy_payload_missing`; `settle_missing_payload/1` atomically persists the bounded terminal fact before adapter/route work. First/repeat and rollback/retry behavioral tests pass. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Regression Closure: Previous Blocker

| Check | Evidence | Status |
| --- | --- | --- |
| No metadata reconstruction helpers/routes | `outbound.ex` has no `load_legacy_pre_v24_queued_message`, `rehydrate_message`, `build_rehydrated_message`, recipient, or header rehydrators; the worker regression source-contract asserts their absence. | ✓ VERIFIED |
| First missing-Payload job | `claim_payload/1` maps not-found to `:legacy_payload_missing`; it settles before adapter resolution and returns terminal cancellation. | ✓ VERIFIED |
| Repeat job | Existing bounded terminal `last_error` is detected; no second Event, Payload, envelope, Delivery mutation, or adapter I/O occurs. | ✓ VERIFIED |
| Sentinel privacy/provenance | Test seeds every former metadata field with a private sentinel, proves metadata byte-for-byte unchanged and proves sentinel absence from last error, Event, Fake adapter deliveries, and new Payload rows. | ✓ VERIFIED |
| Settlement persistence rollback | Forced Event constraint failure returns bounded retryable `adapter_failure/persistence_failed`, leaving Delivery queued and Event count zero; after removal, one retry settles exactly once. | ✓ VERIFIED |
| Documentation contract | Active guides promise terminal no-adapter behavior and explicit re-authoring from an authoritative private source; tests reject the retired narrow-reader promise. | ✓ VERIFIED |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mailglass/outbound.ex` | Canonical dispatch plus fail-closed no-Payload settlement | ✓ VERIFIED | `dispatch_by_id/1` maps absent Payloads to atomic `settle_missing_payload/1`; no legacy message construction remains. Provider I/O is still outside persistence transactions. |
| `lib/mailglass/outbound/dispatch_outcome.ex` | Closed structural outcomes | ✓ VERIFIED | Includes the distinct validated `:legacy_payload_missing` terminal reason and safe projection. |
| `lib/mailglass/outbound/worker.ex` | Retry/cancel mapping | ✓ VERIFIED | The new terminal reason reaches `worker_error_result/1`, is structurally classified, and returns the identical cancellation on first/repeat execution. |
| `test/mailglass/outbound/worker_test.exs` | Behavioral no-Payload oracle | ✓ VERIFIED | Exercises historic-shaped metadata, modern missing Payloads, zero-adapter/Payload controls, idempotence, source absence, and forced settlement rollback. |
| `guides/jobs.md`, `guides/getting-started.md`, `guides/compatibility-and-deprecations.md`, `docs/api_stability.md` | Corrected public compatibility/privacy contract | ✓ VERIFIED | Every guide removes the retired dispatch promise and states no-Payload terminal settlement. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Sync/durable prepared messages | Adapter callback | `dispatch_prepared` → `call_adapter` | ✓ WIRED | One canonical adapter handoff remains. |
| Payload absence | Terminal outcome | `claim_payload` → `settle_missing_payload` → `persist_outcome_multi` | ✓ WIRED | The outcome is created before route resolution or adapter I/O. |
| Terminal outcome | Oban result | `dispatch_by_id` → `Worker.worker_error_result` | ✓ WIRED | `legacy_payload_missing` deterministically maps to `{:cancel, :legacy_payload_missing}`. |
| Missing settlement | Delivery/Event persistence | one `Repo.multi` | ✓ WIRED | Event failure rolls back Delivery; a later retry writes one terminal fact. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase-151-08 named regression | `mix test test/mailglass/outbound/worker_test.exs --only phase_151_task:t151_08_01 --warnings-as-errors` | 1 test, 0 failures | ✓ PASS |
| Worker/docs regression set | `mix test test/mailglass/outbound/worker_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors` | 55 tests, 0 failures, 1 skipped | ✓ PASS |
| Optional runtime isolation | `MIX_ENV=test mix verify.no_optional_runtime` | proof passed | ✓ PASS |
| Support compatibility/docs contract | `MIX_ENV=test mix verify.support_contract.core` | 205 tests, 0 failures, 1 skipped | ✓ PASS |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| ENVL-03 | ✓ SATISFIED | Shared dispatch seam and actual queued-job wire-equivalence tracer. |
| DISP-01 | ✓ SATISFIED | Closed structural classifier without error-message matching. |
| DISP-02 | ✓ SATISFIED | Retryable-only Oban error mapping, including persistence-failure retry semantics. |
| DISP-03 | ✓ SATISFIED | Uncertain outcomes persist reconciliation state and are cancelled rather than resent. |
| DISP-04 | ✓ SATISFIED | Tested at-least-once/idempotency documentation. |
| PRIV-01 | ✓ SATISFIED | Atomic durable-success scrub with retained non-sensitive projection/ledger. |
| PRIV-02 | ✓ SATISFIED | Finite policy, bounded tenant/prefix-safe pruning, manual and optional worker routes. |
| PRIV-03 | ✓ SATISFIED | New public surfaces remain private-content-free; no-Payload sentinel test proves no new public leakage. |
| PRIV-04 | ✓ SATISFIED | All absent/invalid payload paths fail closed; no metadata reconstruction remains. |

### Anti-Patterns Found

None in Phase 151 implementation/docs artifacts. The prior metadata-reconstruction blocker was removed; final code review is clean.

---

_Verified: 2026-08-03T09:51:00Z_
_Verifier: the agent (gsd-verifier)_
