---
phase: 152-atomic-one-click-suppression-convergence
verified: 2026-08-04T17:17:53Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 10/10
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 152: Atomic One-Click Suppression Convergence — Verification Report

**Phase Goal:** A valid RFC 8058 one-click POST reliably converges into one tenant-safe, stream-scoped suppression that immediately prevents future matching sends.
**Verified:** 2026-08-04T17:17:53Z
**Status:** passed
**Re-verification:** Yes — evidence rechecked after metadata-only commit `98e5d1f1` and documentation-only commit `f8ab8c14`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A valid built-in POST atomically creates or reuses exactly one canonical unsubscribe event and `address_stream` suppression for the stored Delivery tenant, address, and stream. | ✓ VERIFIED | `UnsubscribeConvergence` builds one `Ecto.Multi`; its event identity is `unsubscribe:<delivery_id>` and its suppression attrs come only from `Delivery` ([unsubscribe_convergence.ex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_convergence.ex:42)). The controller integration test asserts the empty `200`, exactly one event, and the canonical suppression fields ([unsubscribe_controller_test.exs](/Users/jon/projects/mailglass/test/mailglass/compliance/unsubscribe_controller_test.exs:221)). |
| 2 | Invalid, expired, tampered, and missing targets are indistinguishable empty-`200` privacy no-ops; genuine convergence failure is an empty `500` with no partial pair. | ✓ VERIFIED | Token resolution maps invalid/expired outcomes to `send_resp(200, "")`, while convergence errors map to `send_resp(500, "")` ([unsubscribe_controller.ex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_controller.ex:36)). Focused tests exercise expired/tampered no-write paths and injected failures after each Multi step with zero durable rows ([unsubscribe_controller_test.exs](/Users/jon/projects/mailglass/test/mailglass/compliance/unsubscribe_controller_test.exs:371)). |
| 3 | Event-only and suppression-only legacy states repair to a complete canonical pair; a complete pair is classified as already converged. | ✓ VERIFIED | Canonical refetch and temporary-suppression promotion remain inside the Multi ([unsubscribe_convergence.ex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_convergence.ex:100)); integration tests exercise both half-states and complete-pair classification ([unsubscribe_controller_test.exs](/Users/jon/projects/mailglass/test/mailglass/compliance/unsubscribe_controller_test.exs:419)). |
| 4 | Serial replays and real concurrent POSTs return empty `200`, converge to one pair, and emit at most one lifecycle/broadcast effect. | ✓ VERIFIED | The property test runs serial replays over 50 generated cases and starts four POSTs behind a barrier with `max_concurrency: 4`; it asserts four empty responses, one event/suppression, and one created effect ([unsubscribe_post_idempotency_property_test.exs](/Users/jon/projects/mailglass/test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs:134)). |
| 5 | The next same-tenant, normalized-address, origin-stream send is preflight-blocked while transactional, unrelated-stream, and other-tenant sends remain allowed. | ✓ VERIFIED | Both sync and async send paths call `Suppression.check_before_send/1` before persistence or dispatch ([outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:274)). The real `Outbound.send/1` integration test posts a signed token, proves the matching bulk send does not reach the adapter, and exercises all three isolation controls ([preflight_test.exs](/Users/jon/projects/mailglass/test/mailglass/outbound/preflight_test.exs:383)). |
| 6 | Lifecycle compatibility and broadcast execute only after a newly completed pair commits; their failure cannot undo durable success. | ✓ VERIFIED | Created-only effects receive a fresh `Ecto.Multi`, execute in a separate `Repo.multi`, and rescue failures; broadcast is likewise post-commit and best effort ([unsubscribe_controller.ex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_controller.ex:121)). Tests observe committed rows before lifecycle/broadcast messages and retain empty `200` after lifecycle failure ([unsubscribe_controller_test.exs](/Users/jon/projects/mailglass/test/mailglass/compliance/unsubscribe_controller_test.exs:258)). |
| 7 | Hostile `search_path` conditions cannot redirect writes or conflict refetches away from the configured schema. | ✓ VERIFIED | All convergence inserts, refetches, and promotion use `Repo.multi_opts` ([unsubscribe_convergence.ex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_convergence.ex:57)). The hostile-`search_path` test performs POST/replay and asserts one configured-schema event/suppression and zero public-schema rows ([schema_prefix_hardening_test.exs](/Users/jon/projects/mailglass/test/mailglass/schema_prefix_hardening_test.exs:231)). |
| 8 | Stored suppression metadata and post-commit attrs are bounded and omit token/private message content. | ✓ VERIFIED | Stored metadata is precisely `delivery_id`, `event_id`, and `event_type` ([unsubscribe_convergence.ex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_convergence.ex:200)); the public POST test asserts that exact map, while effect tests assert bounded attrs ([unsubscribe_controller_test.exs](/Users/jon/projects/mailglass/test/mailglass/compliance/unsubscribe_controller_test.exs:251)). |
| 9 | Published route, response, scope, lifecycle, and operator-verification guidance matches the implemented behavior. | ✓ VERIFIED | The guide describes Mailglass’s empty-`200`/empty-`500` contract, Delivery-derived scope, post-commit callback, and preflight verification ([unsubscribe.md](/Users/jon/projects/mailglass/guides/unsubscribe.md:70)); `docs/api_stability.md` states the same stable contract ([api_stability.md](/Users/jon/projects/mailglass/docs/api_stability.md:29)). Those documentation-contract tests are included in the passing focused suite. |
| 10 | Phase scope makes no unsupported generated-host or arbitrary-host exactly-once claim. | ✓ VERIFIED | The Phase 152 guide limits its claims to this library behavior and routes generated-host proof to Phase 153; the roadmap assigns generated-host proof to Phase 153. No source or guide asserts arbitrary-host exactly-once delivery. |

**Score:** 10/10 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mailglass/compliance/unsubscribe_convergence.ex` | Atomic, prefix-explicit convergence | ✓ VERIFIED | Exists; substantive 276-line service; controller invokes it; persisted Delivery data flows into a real event/suppression transaction. |
| `lib/mailglass/compliance/unsubscribe_controller.ex` | Trust classification, HTTP mapping, post-commit orchestration | ✓ VERIFIED | Exists; resolves opaque token to persisted Delivery, restores tenant context, maps empty responses, and runs created-only effects. |
| `test/mailglass/compliance/unsubscribe_controller_test.exs` | Public POST/privacy/repair/rollback/effect evidence | ✓ VERIFIED | Exists; substantive integration coverage executed in the passing focused suite. |
| `test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs` | Replay and true concurrency evidence | ✓ VERIFIED | Exists; generated serial replay and barrier-coordinated concurrent POST tests executed. |
| `test/mailglass/outbound/preflight_test.exs` | Real send-boundary enforcement/isolation | ✓ VERIFIED | Exists; calls real `Outbound.send/1`, verifies blocked adapter dispatch and isolation controls. |
| `test/mailglass/schema_prefix_hardening_test.exs` | Hostile-schema and conflict-refetch proof | ✓ VERIFIED | Exists; tests POST/replay under `search_path = public` and checks configured/public schemas. |
| `guides/unsubscribe.md`, `guides/production-go-live-checklist.md`, `docs/api_stability.md` | Public operational contract | ✓ VERIFIED | Exists; executable guide/docs/stability contract tests passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Controller | `UnsubscribeConvergence` | Trusted persisted Delivery after opaque-ID lookup and tenant restoration | WIRED | Alias/call at controller lines 13–14 and 100–101; public POST integration test traverses this path. |
| Convergence | `Events` + `Suppression.Entry` | One Multi, conflict-safe inserts, canonical refetches, promotion | WIRED | `Events.append_multi`, `Entry.changeset`, `repo.insert`, `repo.one`, and `repo.update_all` occur in the same Multi with explicit options. |
| Controller | Lifecycle + Projector | Created-only, post-commit separate Multi and broadcast | WIRED | `maybe_run_post_commit_effects/2` only matches `status: :created`; separate lifecycle `Repo.multi` precedes best-effort broadcast. |
| Outbound | Suppression | Preflight before persistence/provider dispatch | WIRED | Sync and async paths call `Suppression.check_before_send/1`; integration test demonstrates the block through `Outbound.send/1`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Convergence | tenant, recipient, stream, delivery ID | Verified token resolves persisted `Delivery` | Event/suppression DB rows | ✓ FLOWING |
| Preflight | tenant/address/stream key | Normalized outbound `Message` | Ecto suppression-store lookup | ✓ FLOWING |
| Post-commit effects | bounded tenant/delivery/event/scope/stream attrs | Created convergence event + persisted Delivery | Lifecycle Multi and PubSub broadcast | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 152 full behavioral matrix | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/outbound/preflight_test.exs test/mailglass/schema_prefix_hardening_test.exs test/mailglass/docs/unsubscribe_guide_test.exs test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs test/mailglass/compliance/unsubscribe_test.exs --warnings-as-errors` | `1 property, 123 tests, 0 failures, 1 skipped` (6.4 s; prior independent run) | ✓ PASS |
| Corrected controller documentation and documentation contracts | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs test/mailglass/docs/unsubscribe_guide_test.exs test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs test/mailglass/compliance/unsubscribe_test.exs --warnings-as-errors` | `89 tests, 0 failures, 1 skipped` (3.9 s) | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase 152 probe was declared and no `scripts/**/tests/probe-*.sh` file exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| UNSUB-07 | 152-01, 152-03 | Valid POST atomically creates/reuses canonical event and address-stream suppression from token Delivery. | ✓ SATISFIED | Multi/controller integration test and executed docs contracts. |
| UNSUB-08 | 152-01, 152-02, 152-03 | Replay/concurrent POSTs return empty success, converge to one pair, and avoid duplicate effects. | ✓ SATISFIED | 50-case replay property and barrier-coordinated concurrency/effect test. |
| UNSUB-09 | 152-02, 152-03 | After commit same stream blocks; transactional/unrelated streams are allowed. | ✓ SATISFIED | Real `Outbound.send/1` preflight isolation matrix. |
| UNSUB-10 | 152-02, 152-03 | DB pair commits before lifecycle/broadcast and effects cannot partially durable it. | ✓ SATISFIED | Created-only separate-Multi implementation plus commit-order and failure-isolation tests. |
| UNSUB-11 | 152-01, 152-02, 152-03 | Tenant/prefix safety under hostile `search_path`; failed transaction has no success/partial mutation. | ✓ SATISFIED | Explicit multi options, hostile-schema test, injected rollback/empty-500 tests. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `docs/api_stability.md` | 1512 | Existing unrelated “not yet implemented” v0.5 tracking-hook note | ℹ️ Info | Not a Phase 152 debt marker or one-click behavior. |

### Disconfirmation Pass

- **Partial-requirement check:** I tested the legacy half-state and temporary same-identity suppression paths rather than accepting only the happy path. The transaction repairs them and tests prove the permanent canonical outcome.
- **Misleading-test check:** I did not treat serial replay as concurrency proof. The passing test coordinates four independent tasks behind a barrier and asserts durable/effect cardinality.
- **Uncovered-error-path check:** Injected failures after each insert and a canonical-refetch exception produce the required empty `500`; rollback assertions prove the pair is not partially committed.

### Gaps Summary

No Phase 152 functional gaps found. Commit `98e5d1f1` changed only planning evidence metadata (`REQUIREMENTS.md` and Phase 152 summaries); `f8ab8c14` corrected the stale controller module documentation without changing behavior. The current code and independently executed focused suites substantiate all five roadmap criteria and all plan must-haves.

---

_Verified: 2026-08-04T17:17:53Z_
_Verifier: the agent (gsd-verifier)_
