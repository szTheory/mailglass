---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
verified: 2026-08-03T03:52:00Z
status: gaps_found
score: 4/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Missing, corrupt, expired, unsupported-version, or already-scrubbed payloads fail closed with an operator-actionable state and are never rebuilt from public metadata."
    status: failed
    reason: "The legacy no-Payload branch reconstructs and sends a Message from Delivery.metadata, including subject, rendered HTML/text, headers, and recipient placement. This contradicts the required no-legacy-metadata-reconstruction safety boundary."
    artifacts:
      - path: "lib/mailglass/outbound.ex"
        issue: "claim_payload/1 returns :legacy when no Payload exists; load_legacy_pre_v24_queued_message/1 then rehydrate_message/1 and build_rehydrated_message/2 assemble adapter input from public metadata."
    missing:
      - "Replace the legacy metadata rehydration/send path with an atomic terminal, actionable, finite-retention lifecycle settlement (or obtain an explicit roadmap override for the compatibility exception)."
---

# Phase 151: Unified Dispatch, Honest Outcomes, and Payload Lifecycle Verification Report

**Phase Goal:** Sync and durable async delivery use the same prepared provider input, report outcomes honestly, and retain private queue content only as long as operationally necessary.
**Verified:** 2026-08-03T03:52:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Sync and real Oban paths provide wire-equivalent prepared provider input. | ✓ VERIFIED | `dispatch_prepared/4` is the shared provider seam; durable work hydrates the immutable Payload then reaches it. `wire_equivalence_test.exs` inserts a real ID-only Oban job and compares captured message/options, including headers, attachments, tags, metadata, and provider options. The independent focused run passed. |
| 2 | Outcomes are structurally classified; only retryable work retries, while terminal and uncertain work settles/cancels. | ✓ VERIFIED | `DispatchOutcome` admits only retryable/terminal/uncertain classifications without text matching. `Worker.perform/1` returns `{:error, outcome}` only for retryable results and `{:cancel, reason}` for terminal/uncertain; persistence records deferred reconciliation for uncertain outcomes. Focused worker/outcome tests passed. |
| 3 | Published guidance honestly describes the at-least-once provider boundary and idempotency/correlation limits. | ✓ VERIFIED | `guides/jobs.md`, production checklist, compatibility guide, and `docs_contract_test.exs` contain and test the at-least-once, reconciliation, and non-exactly-once language. `mix verify.support_contract.core` passed independently (205 tests, 0 failures, 1 skipped). |
| 4 | Successful durable dispatch atomically records success and scrubs private payload; terminal/uncertain/legacy retention is finite and bounded by tenant/prefix. | ✓ VERIFIED | `persist_dispatched_multi/3` updates Delivery, appends Event, and calls `Payload.scrub_changeset/1` in one `Repo.multi`; provider I/O occurs earlier in `dispatch_prepared`. V07 has closed lifecycle constraints; `PayloadPruner.prune/1` requires a nonblank tenant, scopes queries, limits by configured batch, and CAS-expires tombstones. Manual Mix and optional Oban worker both call the core pruner. |
| 5 | Invalid and scrubbed payload states fail closed, settle idempotently, remain pruneable, and are never rebuilt from public metadata. | ✗ FAILED | Modern Payload states are distinct, terminal/cancelled, and tested. But the no-Payload legacy branch explicitly calls `rehydrate_message/1` and builds a Message from `Delivery.metadata` before adapter I/O. |

**Score:** 4/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mailglass/outbound.ex` | Canonical dispatch, durable settlement, privacy boundary | ⚠️ PARTIAL | Substantive and wired. Canonical seam, atomic scrub, CAS-backed durable flow are present, but its legacy branch reconstructs metadata into adapter input. |
| `lib/mailglass/outbound/dispatch_outcome.ex` | Closed conservative outcome contract | ✓ VERIFIED | 169 lines; validates fixed classes/reasons, uses structured evidence only, and emits an allowlisted projection. |
| `lib/mailglass/outbound/worker.ex` | Retry/cancel decision wiring | ✓ VERIFIED | Only `:retryable` reaches `{:error, outcome}`; terminal/uncertain return cancellation. Repeated terminal payload facts preserve cancellation. |
| `lib/mailglass/outbound/payload.ex` | Lifecycle claims/scrub/settlement | ✓ VERIFIED | Tenant-scoped CAS claim, digest/version checks, scrub and finite settlement changesets are substantive and used. |
| `lib/mailglass/outbound/payload_pruner.ex` | Tenant-bounded tombstone pruning | ✓ VERIFIED | Explicit tenant validation, prefix scoping, deterministic configured limit, and per-row CAS update. |
| `lib/mailglass/migrations/postgres/v07.ex` | Prefix-safe finite lifecycle schema | ✓ VERIFIED | All nine states, reason/content/claim constraints and prefix-qualified DDL; downgrade preflight refuses before destructive DDL. |
| `lib/mailglass/outbound/payload_pruner_worker.ex` and `lib/mix/tasks/mailglass.outbound.payloads.prune.ex` | Optional/manual prune routes | ✓ VERIFIED | Conditional Oban worker has exact tenant-only args; universal Mix task requires `--tenant` and calls the same pruner. |
| `guides/jobs.md` and `test/mailglass/docs_contract_test.exs` | Executable operations/privacy guidance | ✓ VERIFIED | Guidance is wired to contract assertions and support-contract gate. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Sync and durable dispatch | Adapter callback | `dispatch_prepared` → `call_adapter` | ✓ WIRED | Both flows use the same helper; actual queued-job oracle passes. |
| Adapter result | Worker retry decision | `DispatchOutcome.classify` → `Worker.worker_result` | ✓ WIRED | Class—not error text—selects retry/cancel. |
| Durable success | Delivery/Event/Payload | one `Repo.multi` | ✓ WIRED | Success projection/event/scrub are assembled into the same Multi after provider I/O. |
| Manual and optional scheduled prune | `PayloadPruner.prune/1` | tenant-explicit entrypoints | ✓ WIRED | Both call the same bounded core exactly once. |
| Missing Payload | Adapter dispatch | `claim_payload` → legacy rehydration | ✗ UNSAFE | The legacy compatibility branch builds provider input from public metadata. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Canonical dispatch | prepared `Message` | sync preparation / immutable Payload envelope | Yes | ✓ FLOWING |
| Payload pruning | scoped payload rows | `Repo.all` tenant/prefix query | Yes | ✓ FLOWING |
| Legacy dispatch | reconstructed `Message` | `Delivery.metadata` | Public metadata is transformed into send input | ✗ DISALLOWED FLOW |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 151 runtime contracts | `mix test` over the nine Phase-151 focused files | 116 tests, 0 failures, 1 skipped | ✓ PASS |
| Optional-dependency isolation | `MIX_ENV=test mix verify.no_optional_runtime` | runtime proof passed | ✓ PASS |
| Support compatibility/docs contract | `MIX_ENV=test mix verify.support_contract.core` | 205 tests, 0 failures, 1 skipped | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| ENVL-03 | 151-01 | Sync/Oban wire equivalence | ✓ SATISFIED | Shared seam plus actual queued-job capture oracle. |
| DISP-01 | 151-02 | Closed structural outcomes | ✓ SATISFIED | Validated closed classifier and structured Swoosh evidence. |
| DISP-02 | 151-04 | Only retryable retries | ✓ SATISFIED | Worker mapping and focused tests. |
| DISP-03 | 151-04 | Uncertain reconciliation/no resend | ✓ SATISFIED | Deferred event, reconciliation flag, finite uncertain state, cancel result. |
| DISP-04 | 151-07 | Honest at-least-once guidance | ✓ SATISFIED | Docs contract/support gate. |
| PRIV-01 | 151-03/04 | Atomic successful scrub | ✓ SATISFIED | One success Multi includes projection, ledger, and payload scrub. |
| PRIV-02 | 151-03/05/06/07 | Finite bounded retention/prune | ✓ SATISFIED | V07 lifecycle, finite config, CAS/pruner, manual/optional routes. |
| PRIV-03 | 151-01/04/05/07 | Public metadata privacy/legacy policy | ✓ SATISFIED | New durable writes use `normalized_payload: %{}` and ID-only args; docs and sentinels cover public surfaces. |
| PRIV-04 | 151-03/04/05 | Fail-closed invalid payload/no reconstruction | ✗ BLOCKED | Modern states satisfy this, but `outbound.ex` retains a metadata rehydration route for absent Payloads. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/mailglass/outbound.ex` | 982–1157 | Legacy public-metadata message reconstruction | 🛑 BLOCKER | Can send content reconstructed from the public Delivery metadata surface, violating the fail-closed/no-reconstruction contract. |

### Gaps Summary

The phase has strong automated evidence for canonical dispatch, outcome classification, atomic success scrub, retention, pruning, optional-runtime behavior, and documentation. Those tests do not falsify the central privacy failure: `Payload.claim/2` returning `:not_found` deliberately selects a legacy branch which reconstructs a provider `Message` from `Delivery.metadata` and dispatches it.

This is not a stub or a test gap—the behavior is explicit and exercised by legacy worker tests. It requires an implementation decision: remove/terminally settle the rehydration path, or obtain an explicit developer override that narrows the roadmap's no-reconstruction language to modern rows only.

---

_Verified: 2026-08-03T03:52:00Z_
_Verifier: the agent (gsd-verifier)_
