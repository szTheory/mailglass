---
phase: 150-private-envelope-and-atomic-durable-enqueue
verified: 2026-08-02T22:00:00-04:00
status: passed
score: 33/33 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 21/33
  gaps_closed:
    - "The versioned private envelope round-trips the documented supported surface without silent loss and rejects unsafe input before enqueue."
    - "Ordered address/header/tag/attachment collections retain documented order and duplicate values."
    - "Attachment bytes are materialized at enqueue and remain recoverable after source mutation/removal."
    - "V06 has a hostile-search-path, prefix-qualified, reversible, no-backfill lifecycle proof."
    - "A real queued Oban retry uses the immutable stored payload and persisted route after live state changes."
    - "An Oban-absent runtime invokes the public path, returns dependency_unavailable, and leaves no effects."
    - "jsonb finite floats, signed zero, V1 literal marker compatibility, and terminal legacy-digest mismatch behavior are covered."
  gaps_remaining: []
  regressions: []
---

# Phase 150: Private Envelope and Atomic Durable Enqueue Verification Report

**Phase Goal:** A durable async request either creates one private, complete, recoverable outbound envelope and its queue work atomically or reports no queued work at all.
**Verified:** 2026-08-02T22:00:00-04:00
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Durable sends keep the complete versioned envelope private; public delivery/event data and Oban args expose only public metadata and stable IDs. | ✓ VERIFIED | `enqueue_durable_oban/3` persists `Payload` in the same Multi and creates a job with only `delivery_id` and `mailglass_tenant_id`; privacy/atomic tests passed in the 150-test gate. |
| 2 | The envelope losslessly recovers every supported field and explicitly rejects unsupported/unsafe input. | ✓ VERIFIED | `Envelope` is an allowlisted V2 codec with required `adapter_ref`, ordered pair headers, materialized attachments, JSON depth/item/byte bounds, and finite-float encoding. The two focused envelope samplers passed (3 + 2 tests). |
| 3 | Enqueue renders and selects the route first; queued retries use only immutable persisted input. | ✓ VERIFIED | `do_deliver_later/2` prepares then resolves `adapter_ref` before `Envelope.dump/2`; the actual stored disabled-mode Oban job was performed after renderer/route state changed, with original rendered/attachment bytes sent to route A (2 focused tests passed). |
| 4 | Delivery, queued event, private payload, and real canonical Oban job commit atomically under independent prefixes; legacy reads are safe. | ✓ VERIFIED | The four ordered Multi steps are delivery → event → payload → `OptionalDeps.Oban.insert`; the Phase-150 integration gate passed. `Payload.fetch_for_delivery/2` is tenant scoped, digest checked, uses a terminal V1 mismatch path, and falls back only for genuinely pre-payload legacy rows. |
| 5 | `:oban` fails closed when unavailable/unusable, while explicit `:task_supervisor` is non-durable and excluded from production readiness. | ✓ VERIFIED | `ready?(:mailglass_outbound)` runs before dumping/transaction; an isolated no-optional-deps runtime invoked public `deliver_later/2`, observed typed `dependency_unavailable`, and proved unchanged delivery/event/payload/job/provider/task observations. |

**Score:** 33/33 must-haves verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/mailglass/outbound/envelope.ex` | Versioned, bounded, lossless envelope codec | ✓ VERIFIED | 498 substantive lines; explicit V1/V2 decode separation, strict schema, attachment materialization, resource bounds, finite IEEE-754 tags and reserved-string escaping. |
| `lib/mailglass/outbound/payload.ex` | Tenant/delivery private persistence boundary | ✓ VERIFIED | Stores version/digest/envelope; tenant-scoped fetch verifies digest and rejects tampering/ambiguous V1 float rows terminally. |
| `lib/mailglass/outbound.ex` | Atomic durable enqueue and payload-first dispatch | ✓ VERIFIED | Private payload is wired into the durable Multi; decoded payload and persisted route are used before legacy reconstruction. |
| `lib/mailglass/outbound/worker.ex` | Canonical queue worker | ✓ VERIFIED | Calls payload-first `dispatch_by_id/1` inside tenant middleware. |
| `lib/mailglass/optional_deps/oban.ex` | Optional-dependency gateway | ✓ VERIFIED | Readiness is fail-closed and unavailable transactional insertion is an `Ecto.Multi.error`. |
| `lib/mailglass/migrations/postgres/v06.ex` | Reversible, schema-prefixed payload DDL | ✓ VERIFIED | Explicit prefix on table, FK and all three indexes; focused lifecycle test passed. |
| `test/mailglass/outbound/envelope_test.exs` | Codec/TOCTOU/bounds coverage | ✓ VERIFIED | Covers complete field/duplicate order, nil semantics, source mutation/removal, malformed fields, resource limits. |
| `test/mailglass/outbound/worker_test.exs` | Queued immutable retry and compatibility coverage | ✓ VERIFIED | Covers actual stored job retry, route mismatch fail-close, jsonb finite-float and signed-zero bits, V1 literal markers, and terminal legacy mismatch. |
| `test/mailglass/v06_migration_test.exs` | Hostile-prefix lifecycle proof | ✓ VERIFIED | Covers V05→V06→down→up, catalog shape/predicate, decoys, no backfill and rollback behavior. |
| `scripts/no_optional_deps_runtime_smoke.sh` + `test/runtime/no_optional_deps_public_send.exs` | Genuine Oban-free runtime proof | ✓ VERIFIED | Builds isolated production graph without optional dependencies and launches a direct Elixir public-send probe. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `outbound.ex` | `envelope.ex` | prepare → route selection → dump | ✓ WIRED | `do_deliver_later/2` completes preparation and `resolve_async_adapter_ref/2` before `enqueue_oban/3` calls `Envelope.dump/2`. |
| `outbound.ex` | `payload.ex` | atomic Multi and dispatch reader | ✓ WIRED | `Payload.from_envelope/3` is the `:payload` step; `Payload.fetch_for_delivery/2` precedes legacy handling. |
| `payload.ex` | `envelope.ex` | digest then load | ✓ WIRED | `from_envelope/3` calls `Envelope.version/digest`; fetch rechecks digest then `Envelope.load/1`. |
| `outbound.ex` | `optional_deps/oban.ex` | readiness and same-Multi job insertion | ✓ WIRED | canonical readiness gates `:oban`; job construction is `OptionalDeps.Oban.insert/3` in the durable Multi without Mailglass-prefix override. |
| `worker.ex` | `outbound.ex` | tenant-restored payload dispatch | ✓ WIRED | `Worker.perform/1` wraps and calls `Outbound.dispatch_by_id/1`; focused queued-job test executes this link. |
| V06 test | `v06.ex` | direct guarded prefix lifecycle | ✓ WIRED | `t150_07_01` executed and passed; catalog assertions prove the target schema rather than ambient `search_path`. |
| Runtime smoke | public `deliver_later/2` | no-optional direct Elixir process | ✓ WIRED | `MIX_ENV=test mix verify.no_optional_runtime` passed independently. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Durable enqueue | `envelope` | Prepared `Message` after route selection | Stored in tenant/delivery Payload in the transaction | ✓ FLOWING |
| Worker dispatch | decoded message and `adapter_ref` | Digest-checked Payload fetch | Actual queued-job test observes original content and route after live-state mutation | ✓ FLOWING |
| Oban job | identifier args | Durable Multi job builder | Exact stable IDs only; real `oban_jobs` row retrieved and performed | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Codec fidelity, duplicate order and attachment TOCTOU | `mix test test/mailglass/outbound/envelope_test.exs --only phase_150_task:t150_06_01 --warnings-as-errors` | 3 tests, 0 failures | ✓ PASS |
| Codec resource/unsafe JSON rejection | `mix test test/mailglass/outbound/envelope_test.exs --only phase_150_task:t150_06_02 --warnings-as-errors` | 2 tests, 0 failures | ✓ PASS |
| Prefix-safe V06 lifecycle | `mix test test/mailglass/v06_migration_test.exs --only phase_150_task:t150_07_01 --warnings-as-errors` | 1 test, 0 failures | ✓ PASS |
| Real queued immutable retry | `mix test test/mailglass/outbound/worker_test.exs --only phase_150_task:t150_08_01 --warnings-as-errors` | 2 tests, 0 failures | ✓ PASS |
| Genuine Oban-free public send | `MIX_ENV=test mix verify.no_optional_runtime` | Isolated probe printed pass marker; before/after durable, queue, provider and Task observations unchanged | ✓ PASS |
| Phase integration regression | focused 11-file Phase-150 test command | 150 tests, 0 failures, 3 intentional skips | ✓ PASS |
| Support contract regression | `MIX_ENV=test mix verify.support_contract.core` | 202 tests, 0 failures, 1 intentional skip | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| ENVL-01 | 01, 02, 05 | Private versioned payload and identifier-only public/Oban surfaces | ✓ SATISFIED | Payload boundary, privacy projection and job-args tests pass. |
| ENVL-02 | 01, 02, 06 | Complete supported envelope recovery | ✓ SATISFIED | Focused complete-field, duplicate-order, nil, attachment, bounds, jsonb float and compatibility tests pass. |
| ENVL-04 | 01, 02, 03, 06, 08 | Render/route before boundary; immutable retry | ✓ SATISFIED | Real stored-job post-mutation behavioral proof passes. |
| ENVL-05 | 01, 02, 07 | Atomic four-part durable enqueue and prefix-safe migration | ✓ SATISFIED | Multi ordering/rollback regression plus V06 hostile-prefix lifecycle pass. |
| ENVL-06 | 03, 05, 09 | Selected Oban fails closed without fallback | ✓ SATISFIED | Isolated optional-dependency-free public runtime proof passes. |
| ENVL-07 | 04, 05 | Explicit Task.Supervisor remains non-durable | ✓ SATISFIED | Production readiness/docs contract coverage passed in Phase integration gate. |
| ENVL-08 | 03, 04, 05 | Canonical `mailglass_outbound` queue contract | ✓ SATISFIED | Worker/readiness/docs contract coverage passed in Phase integration gate. |

### Compatibility Regression Checks

| Concern | Result | Evidence |
|---|---|---|
| jsonb finite-float fidelity and signed zero | ✓ VERIFIED | V2 stores finite float bit patterns as tagged IEEE-754 bytes; worker regression compares both zero signs after persistence. |
| V1 marker-shaped strings | ✓ VERIFIED | V1 decoder leaves strings literal; regression test passed. |
| Legacy V1 numeric digest mismatch | ✓ VERIFIED | `Payload` returns `:legacy_integrity_unverifiable`; dispatch persists a terminal serialization outcome and Worker cancellation test passed. |
| V2 tampering | ✓ VERIFIED | Non-V1 digest mismatch remains `:integrity_failed`, not a legacy fallback. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| Phase source/test/runtime artifacts | — | No unreferenced `TBD`, `FIXME`, or `XXX`; no placeholder/empty implementation flowing to user behavior | ℹ️ Info | No blocker detected. |

## Gaps Summary

No blocking gaps remain. The former codec, migration, retry, optional-runtime and jsonb/legacy compatibility gaps all have source-level implementations and independently passing behavioral evidence. No later-phase deferral was used.

---

_Verified: 2026-08-02T22:00:00-04:00_
_Verifier: the agent (gsd-verifier)_
