---
phase: 150-private-envelope-and-atomic-durable-enqueue
verified: 2026-08-03T00:40:12Z
status: gaps_found
score: 21/33 must-haves verified
behavior_unverified: 4
overrides_applied: 0
gaps:
  - truth: "The private envelope round-trips every documented async-supported field without silent loss and rejects unsupported values before queueing."
    status: failed
    reason: "Envelope.load/1 drops the stored adapter_ref and normalizes persisted nil metadata/provider_options to empty maps; Envelope.json/1 has no recursive depth/item/byte bounds and accepts non-finite floats until Jason encoding can raise. The only Phase-150 envelope test checks subject, to, and tags."
    artifacts:
      - path: lib/mailglass/outbound/envelope.ex
        issue: "Incomplete V1 codec: adapter_ref is never loaded or validated, nil values are silently changed, and JSON safety limits/non-finite rejection are absent."
      - path: test/mailglass/outbound/envelope_test.exs
        issue: "One happy-path assertion does not exercise documented field fidelity or negative serialization cases."
    missing:
      - "Make envelope decoding preserve/validate adapter_ref and all documented optional values."
      - "Implement bounded JSON validation that explicitly rejects NaN/infinity and over-depth/over-size input before persistence."
      - "Add focused round-trip and rejection tests for every documented V1 field, attachment materialization, and limits."
  - truth: "Ordered address/header/tag/attachment collections and duplicate values retain documented order and multiplicity."
    status: failed
    reason: "The codec only has a shallow happy-path test and serializes Swoosh headers through a JSON map; no evidence proves header multiplicity/order or the full documented collection contract."
    artifacts:
      - path: lib/mailglass/outbound/envelope.ex
        issue: "Header representation is an unvalidated JSON map rather than an explicitly fidelity-tested ordered collection."
      - path: test/mailglass/outbound/envelope_test.exs
        issue: "No collection/duplicate fidelity coverage."
    missing:
      - "Specify and implement a lossless ordered header representation, then test duplicate and adjacent values for every collection."
behavior_unverified_items:
  - truth: "Attachment bytes are materialized at enqueue and remain byte-for-byte recoverable after their source changes or disappears."
    test: "Queue a readable path/upload-backed attachment, then modify/remove the source and load/dispatch the stored payload."
    expected: "The reconstructed attachment has the original bytes and attributes, with no path/upload term retained."
    why_human: "The code calls Swoosh.Attachment.get_content/1, but no existing test exercises this TOCTOU transition."
  - truth: "V06 creates/reverses the exact prefix-qualified payload table and indexes without legacy backfill under a hostile search path."
    test: "Run V05→V06, inspect V06 catalog objects and legacy metadata in a scratch schema with public decoys, then down→up."
    expected: "Only the supplied schema changes; all three indexes and predicate are exact; zero payload backfill occurs; rollback leaves no partial V06 state."
    why_human: "The tagged migration test only asserts current_version == 6; the claimed V06 lifecycle/prefix behavior is not exercised by a V06-specific test."
  - truth: "A retry uses the immutable stored durable input rather than process/template state or a newly selected route."
    test: "Queue through Oban, change template assigns and tenancy route, then invoke the worker job."
    expected: "The worker sends the stored rendered payload through the originally persisted route."
    why_human: "Payload-first dispatch and persisted adapter use are present; the named route test passed only through the Task.Supervisor path, not a real queued-worker retry."
  - truth: "An Oban-absent runtime returns the typed dependency_unavailable SendError and leaves no queued work."
    test: "Execute deliver_later/2 from an artifact/runtime where Oban is genuinely absent."
    expected: "It returns adapter_failure with reason_class dependency_unavailable and inserts no Delivery/Event/Payload/job."
    why_human: "A clean --no-optional-deps compile passes and source reaches the gateway using a literal queue identity, but no dependency-free runtime test invokes the public send path."
---

# Phase 150: Private Envelope and Atomic Durable Enqueue Verification Report

**Phase Goal:** A durable async request either creates one private, complete, recoverable outbound envelope and its queue work atomically or reports no queued work at all.

**Verified:** 2026-08-03T00:40:12Z  
**Status:** gaps_found  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Private payload; public metadata and Oban args have no rendered/provider payload. | ✓ VERIFIED | `base_delivery_attrs/3` drops stamped delivery id and retains public metadata; durable job builder contains only `delivery_id` and `mailglass_tenant_id`; tagged prefix/privacy test passed. |
| 2 | Every documented V1 field round-trips with explicit unsafe-input failure. | ✗ FAILED | `Envelope.load/1` ignores `adapter_ref`, changes nil metadata/provider options to `%{}`, and `json/1` lacks the specified bounds/non-finite rejection. |
| 3 | Rendering and route selection precede enqueue; retry uses immutable input. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Source orders preflight/render/prepare/route before `Envelope.dump`; payload-first read is wired. A real queued-worker retry changing live route/template state is not tested. |
| 4 | Delivery, queued event, private payload, and the real Oban job commit together under independent Mailglass/Oban prefixes. | ✓ VERIFIED | One `Ecto.Multi` orders delivery → event → payload → Oban job; payload/job constraint failures roll back in the tagged test; CR-01 isolated-prefix regression passed. |
| 5 | Selected Oban fails closed, while explicit Task.Supervisor is non-durable and rejected by production readiness. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Readiness gate precedes dump and uses always-compiled `:mailglass_outbound`; `mix clean && mix compile --no-optional-deps --warnings-as-errors` passed. No dependency-free runtime send test proves the typed public result. |

**Score:** 21/33 plan/roadmap must-haves verified (4 present but behavior-unverified).

### Plan Must-Have Coverage

All 28 plan truths were checked against source and the focused suite; the roadmap truths above remain the controlling contract.

| Plan | Verified | Failed | Behavior-unverified | Notes |
|---|---:|---:|---:|---|
| 150-01 | 1 | 4 | 2 | Payload/private persistence exists, but the V1 codec fails its complete fidelity/safety contract; V06 behavior lacks specific exercise. |
| 150-02 | 4 | 1 | 1 | Atomic single/batch enqueue is exercised; the full immutable retry assertion remains unexercised. |
| 150-03 | 4 | 0 | 1 | Payload-first and readiness wiring exist; no truly Oban-free public runtime test. |
| 150-04 | 4 | 0 | 0 | Tagged readiness, boot separation, and docs smoke tests pass. |
| 150-05 | 5 | 0 | 0 | Focused source/adopter contract test passes. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/mailglass/outbound/envelope.ex` | V1 allowlisted codec | ⚠️ INCOMPLETE | Exists (233 lines) and is wired through Payload, but loses/normalizes documented values and lacks bounded JSON validation. |
| `lib/mailglass/outbound/payload.ex` | Private tenant/delivery-scoped storage | ✓ VERIFIED | Tenant-and-delivery lookup, digest check, schema fields, and unique delivery constraint are wired. |
| `lib/mailglass/migrations/postgres/v06.ex` | Prefix-qualified reversible DDL | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | All table/reference/index operations pass `prefix`; no dedicated runtime V06 catalog/down/backfill test exists. |
| `lib/mailglass/outbound.ex` | Atomic durable enqueue/dispatch | ✓ VERIFIED | Multi orders delivery/event/payload/job; Oban step deliberately has no Mailglass prefix override (CR-01 fix). |
| `lib/mailglass/optional_deps/oban.ex` | Fail-closed readiness gateway | ✓ VERIFIED | `ready?/1` and transactional insertion are wired; source is compiled without optional dependencies. |
| `test/mailglass/outbound/envelope_test.exs` | Fidelity/safety tracer | ✗ STUB | Exists but has one minimal happy-path test and does not substantiate the stated fidelity/safety coverage. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `outbound.ex` | `envelope.ex` | prepare/route → dump | ✓ WIRED | `do_deliver_later/2` resolves the route before `enqueue_oban/3`, which dumps once. |
| `outbound.ex` | `payload.ex` | event → payload → job | ✓ WIRED | `Ecto.Multi.insert(:payload, ...)` is after `event_queued` and before `OptionalDeps.Oban.insert(:job, ...)`. |
| `payload.ex` | `envelope.ex` | version/digest/store/load | ✓ WIRED | `from_envelope/4` calls `Envelope.version/digest`; fetch validates digest then loads. |
| `worker.ex` | `outbound.ex` | tenant middleware → payload-first dispatch | ✓ WIRED | `perform/1` wraps and invokes `Outbound.dispatch_by_id/1`. |
| `config.ex` | `optional_deps/oban.ex` | production readiness | ✓ WIRED | `production_readiness/0` calls `OptionalDeps.Oban.ready?(:mailglass_outbound)`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Durable enqueue | `envelope` | `Envelope.dump(prepared, adapter_ref: ...)` | Inserted into tenant-scoped Payload inside the Multi | ⚠️ INCOMPLETE codec |
| Worker dispatch | `rendered` | `Payload.fetch_for_delivery(tenant_id, delivery_id)` | Digest-checked private envelope load before legacy branch | ✓ FLOWING |
| Oban job | job args | durable Multi job builder | `delivery_id`, `mailglass_tenant_id` only; Oban retains its own configured prefix | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase-specific automated contract | `mix test ... --only phase_150_task --warnings-as-errors` | 20 tests, 0 failures | ✓ PASS |
| Route persists across changed tenancy (existing named test) | `mix test test/mailglass/outbound/deliver_later_test.exs:305 --warnings-as-errors` | 1 test, 0 failures | ✓ PASS |
| No-optional-dependencies compilation | `mix clean && mix compile --no-optional-deps --warnings-as-errors` | 191 files compiled successfully | ✓ PASS |
| Oban-absent public send | dependency-free runtime invocation | No existing test/runner | ? SKIP |

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| ENVL-01 | 01, 02, 05 | ✓ SATISFIED | Private Payload, public projection, and ID-only job arguments are implemented and tested on the durable path. |
| ENVL-02 | 01, 02 | ✗ BLOCKED | Complete documented V1 fidelity/safety is not true; codec losses and unbounded JSON acceptance are observable. |
| ENVL-04 | 01, 02, 03 | ? NEEDS HUMAN | Ordering and payload-first wiring exist, but real queued-worker retry invariants lack behavioral coverage. |
| ENVL-05 | 01, 02 | ✓ SATISFIED | Ordered four-part Multi plus payload/job rollback test proves atomic failure behavior; CR-01 prefix separation is regression-tested. |
| ENVL-06 | 03, 05 | ? NEEDS HUMAN | Selected-Oban source is fail-closed and no-optional compile passes, but typed behavior is not invoked in an Oban-absent runtime. |
| ENVL-07 | 04, 05 | ✓ SATISFIED | Explicit Task.Supervisor path and `production_readiness/0` rejection are covered by tagged tests. |
| ENVL-08 | 03, 04, 05 | ✓ SATISFIED | Canonical `mailglass_outbound` identity is used by worker/readiness/docs and tagged contract tests. |

### Review-Fix Regression Checks

| Finding | Result | Evidence |
|---|---|---|
| CR-01: Mailglass prefix must not override Oban prefix | ✓ VERIFIED | `OptionalDeps.Oban.insert/3` receives no `Repo.multi_opts`; the tagged durable test finds the job in public `oban_jobs` while Mailglass data uses its configured schema. |
| CR-02: Oban absent must not call a conditional Worker first | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `outbound.ex` calls `ready?(:mailglass_outbound)` before any `Worker` use and clean no-optional compile passes. The required public runtime assertion is absent. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `test/mailglass/outbound/envelope_test.exs` | 7-30 | Minimal happy-path-only tracer | 🛑 Blocker | A nominal phase test leaves the contract's required field/safety/attachment cases unproven and the codec defects undetected. |
| Phase source files | — | No unreferenced `TBD`/`FIXME`/`XXX` markers found | ℹ️ Info | No debt-marker blocker. |

### Prohibition Review

The seven plan prohibitions are judgment-tier and remain explicitly unverified. Source paths do not expose `Payload` from the root facade or admin code, and current documentation says it is not an archive/viewer, but this remains a human judgment rather than a silent pass. The failed ENVL-02 codec is independently blocking.

## Gaps Summary

Phase 150 does implement a real payload-first atomic enqueue path and the two review fixes are present. It does **not** yet deliver the promised complete, recoverable V1 envelope: decoder fidelity is observably incomplete, and the encoder has no bounded JSON/non-finite validation. These are core phase requirements, not later-phase lifecycle work, so they are not deferred to Phase 151.

_Verified: 2026-08-03T00:40:12Z_  
_Verifier: the agent (gsd-verifier)_
