---
phase: 152-atomic-one-click-suppression-convergence
verified: 2026-08-03T15:23:15Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 152: Atomic One-Click Suppression Convergence — Verification Report

**Phase Goal:** Make RFC 8058 POSTs atomically and immediately enforce stream-scoped suppression.
**Verified:** 2026-08-03T15:23:15Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Valid POST atomically creates or reuses one canonical unsubscribe event and one `address_stream` suppression from the persisted Delivery. | VERIFIED | `UnsubscribeConvergence` composes event insert, canonical refetch, suppression insert, canonical refetch, and promotion in one `Ecto.Multi` ([`unsubscribe_convergence.ex`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex)); the independently run phase matrix passed 120 tests. |
| 2 | Invalid, expired, tampered, and missing targets remain byte-empty 200 privacy no-ops; genuine convergence failures are byte-empty 500. | VERIFIED | Controller resolution maps invalid/expired to `send_resp(conn, 200, "")`, while convergence errors map to `500` with an empty body ([`unsubscribe_controller.ex`](../../../lib/mailglass/compliance/unsubscribe_controller.ex)). Controller tests in the matrix exercise both classifications and rollback. |
| 3 | Event-only and suppression-only legacy states repair to a complete pair, including permanent promotion of a same-identity temporary suppression. | VERIFIED | Classification marks any event/suppression insert or conditional promotion as `:created`; zero-row promotion losers refetch the permanent canonical row. Controller and four-way promotion tests passed. |
| 4 | Serial replays and true concurrent POSTs converge to one event and one active suppression, with at most one lifecycle/broadcast emission. | VERIFIED | Barrier-coordinated four-task test asserts four empty 200s, exactly one durable event, one active suppression, and exactly one effect; property testing also covers 1–10 serial replays × 50 generated inputs ([`unsubscribe_post_idempotency_property_test.exs`](../../../test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs)). |
| 5 | The immediate next matching same-tenant/address/origin-stream send is blocked in real Outbound preflight, while normalized unrelated-stream, transactional, and other-tenant sends pass. | VERIFIED | `Outbound.send/1` calls `Suppression.check_before_send/1` before persistence/dispatch; the integration test creates a Delivery, posts its signed token, asserts no Fake-adapter growth for the matching bulk send, and asserts all isolation controls pass ([`preflight_test.exs`](../../../test/mailglass/outbound/preflight_test.exs)). |
| 6 | Lifecycle compatibility and broadcast run only after a newly completed pair commits, under the Delivery tenant, and failures cannot undo success. | VERIFIED | Controller invokes effects only for `status: :created`; it restores tenant context, invokes `handle_event(Ecto.Multi.new(), attrs)`, executes returned work separately/best-effort, and rescues callback/broadcast failures. Matrix tests assert committed rows before observed effects, tenant restoration, and retained empty 200 after failure. |
| 7 | Convergence is tenant- and schema-prefix-safe under a hostile `search_path`; decoys cannot redirect writes or canonical conflict refetches. | VERIFIED | Every convergence insert/query/update uses `Repo.multi_opts`; hostile-search-path tests post/replay and assert one configured-schema event and zero public-schema events. `mix verify.schema_prefix`'s 4 schema tests passed. |
| 8 | Suppression source/metadata and post-commit attrs are bounded: no token, recipient, or private message content leaks. | VERIFIED | Stored metadata is exactly `delivery_id`, `event_id`, and `event_type`; effect attrs contain only tenant, delivery, event type, scope, and stream. No Phase-152 artifact has unresolved debt markers; docs prohibit token/content logging and docs contracts passed. |
| 9 | The public lifecycle/config, route, response, scope, isolation, and production-verification documentation match runtime behavior. | VERIFIED | Lifecycle and config documentation state the separate best-effort transaction; unsubscribe, production, and API-stability guides state exact empty 200/500 and scope rules. `mix verify.docs.contract` passed (41 executed, 1 skip) and `mix verify.stability_contract` passed (210 executed, 1 property, 1 skip). |
| 10 | The Phase 152 scope excludes generated-host/release proof and does not make arbitrary-host exactly-once claims. | VERIFIED | Roadmap assigns generated-host/release proof to Phase 153; Phase docs explicitly retain that boundary and the executable docs contracts pass. |

**Score:** 10/10 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/mailglass/compliance/unsubscribe_convergence.ex` | Flat, canonical, prefix-explicit atomic convergence | VERIFIED | Substantive 276-line service; imported by controller; `Ecto.Multi` holds both durable facts and their canonical refetches/promotion. |
| `lib/mailglass/compliance/unsubscribe_controller.ex` | Trust classification, HTTP mapping, post-commit orchestration | VERIFIED | Routes trusted Delivery through convergence under restored tenancy and maps outcomes; effects are created-only and failure-isolated. |
| `test/mailglass/compliance/unsubscribe_controller_test.exs` | Public POST, privacy, repair, rollback, effects evidence | VERIFIED | Exercises response bodies, pair rows, bounded metadata, rollback, and tenant-restored effects. |
| `test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs` | Serial and actual concurrent convergence proof | VERIFIED | Uses generated replays and a four-task barrier; asserts durable event/suppression/effect cardinality. |
| `test/mailglass/outbound/preflight_test.exs` | Real send-boundary enforcement/isolation | VERIFIED | Calls `Outbound.send/1`, not a store stub, and asserts no adapter dispatch on matching suppression. |
| `test/mailglass/schema_prefix_hardening_test.exs` | Hostile-search-path/decoy proof | VERIFIED | Exercises POST/replay with public search path and checks configured vs public schema rows. |
| `guides/unsubscribe.md`, `guides/production-go-live-checklist.md`, `docs/api_stability.md` | Accurate executable contract and privacy-safe operator guidance | VERIFIED | Locked by docs and stability contract tests; no Phase 153 promise introduced. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Controller | `UnsubscribeConvergence` | Trusted persisted Delivery after opaque-ID lookup and tenant restoration | WIRED | Direct alias/call in controller; controller integration tests exercise public POST through it. |
| Convergence | Events + Suppression Entry | One `Ecto.Multi`, conflict-safe inserts, canonical refetches | WIRED | `Events.append_multi`, `repo.insert`, `repo.one`, and `repo.update_all` all run inside the same Multi using explicit multi options. |
| Controller | Lifecycle + Projector | Created-only post-commit separate Multi and broadcast | WIRED | `maybe_run_post_commit_effects/2` is restricted to `:created`; tests prove ordering, one emission, tenant restoration, and failure isolation. |
| Outbound | Suppression | Preflight before persistence/provider dispatch | WIRED | Both synchronous and async paths call `Suppression.check_before_send/1`; real-Outbound integration test proves the matching block. |

### Data-Flow Trace

| Artifact | Data | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Convergence service | tenant, recipient, stream, delivery ID | Persisted `Delivery` resolved from verified opaque token | DB event/suppression transaction | FLOWING |
| Preflight gate | tenant/address/stream lookup key | Normalized outbound `Message` | Ecto suppression-store query | FLOWING |
| Post-commit effects | bounded domain attrs | Completed convergence event plus persisted Delivery | Lifecycle Multi / PubSub broadcast | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Full Phase 152 behavior matrix | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/outbound/preflight_test.exs test/mailglass/schema_prefix_hardening_test.exs test/mailglass/docs/unsubscribe_guide_test.exs test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs test/mailglass/compliance/unsubscribe_test.exs --warnings-as-errors` | 1 property, 120 tests, 0 failures, 1 skipped | PASS |
| Schema-prefix gate | `mix verify.schema_prefix` | Its 4 tagged schema tests and following 69 test gate passed; command later exits 28 only because pre-existing unrelated Credo findings remain in `lib/mailglass/outbound.ex`, `lib/mailglass/outbound/payload.ex`, `test/mailglass/v07_migration_test.exs`, and `test/runtime/no_optional_deps_public_send.exs`. | PASS (Phase 152 evidence); unrelated umbrella baseline retained |
| Documentation contract | `mix verify.docs.contract` | 41 executed, 0 failures, 1 skip; inbound 23 tests passed | PASS |
| Stability umbrella | `mix verify.stability_contract` | 1 property, 210 executed, 0 failures, 1 skip; admin 144 and inbound 30 tests passed | PASS |
| Format umbrella | `mix format --check-formatted` | Fails only on pre-existing `lib/mailglass/optional_deps/oban.ex`, outside Phase 152 ownership | UNRELATED BASELINE |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| UNSUB-07 | 152-01, 152-03 | Valid RFC 8058 POST atomically creates/reuses canonical event and address-stream suppression scoped from token Delivery. | SATISFIED | Flat Multi plus controller/public-row tests and docs contract. |
| UNSUB-08 | 152-01, 152-02, 152-03 | Replay/concurrent POSTs return empty success, converge to one pair, and avoid duplicate effects. | SATISFIED | Generated replay property, four-way barrier test, pair/effect cardinality assertions. |
| UNSUB-09 | 152-02, 152-03 | After commit, same stream is blocked; transactional and unrelated streams remain allowed. | SATISFIED | Real `Outbound.send/1` preflight integration, including normalized address and tenant control. |
| UNSUB-10 | 152-02, 152-03 | DB pair commits before callbacks/broadcast; external effects cannot partially durable it. | SATISFIED | Created-only post-commit controller path, separate `Repo.multi`, ordering and failure-isolation tests. |
| UNSUB-11 | 152-01, 152-02, 152-03 | Tenant/prefix safety under hostile search path; failed transaction has no success or partial mutation. | SATISFIED | Explicit `Repo.multi_opts`, hostile schema/decoy tests, injected rollback and empty-500 tests. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `docs/api_stability.md` | 1512 | Existing “not yet implemented” tracking-hook note | INFO | Explicitly scoped to a v0.5 tracking feature, not one-click suppression; no Phase 152 debt marker. |
| `lib/mailglass/optional_deps/oban.ex` | 56 | Formatting drift | INFO | Not Phase 152-owned; format umbrella failure does not affect one-click behavior. |
| Credo findings in non-152 files | various | Existing readability/refactoring/warning findings | INFO | `mix verify.schema_prefix` exits non-zero after Phase 152 schema tests pass; none is in a Phase 152 implementation artifact. |

### Disconfirmation Pass

- **Partial-requirement check:** I checked temporary same-identity suppressions, a common hole where a valid unsubscribe can later expire. The convergence transaction conditionally promotes exactly one row to permanent; a four-way concurrency test proves the winner/loser behavior and one effect pair.
- **Misleading-test check:** I did not accept serial replay evidence as concurrency proof. The retained test starts four tasks behind a shared barrier and asserts all responses, durable pair cardinality, and effect cardinality.
- **Uncovered-error-path check:** I checked database/refetch exceptions and transaction failure after both insert points. Controller tests inject these paths and prove byte-empty 500 with no partial mutation/effects.

### Metadata Note

`ROADMAP.md` currently marks Plan 03 as unchecked and Phase 152 as in progress even though `152-03-SUMMARY.md`, its commits, focused contracts, and this verification show it complete. This is workflow metadata drift, not a functional Phase 152 gap; update the roadmap completion metadata after bundling this report.

### Gaps Summary

No Phase 152 gaps found. The remaining strict format/Credo umbrella failures are observable, documented, and isolated to unrelated baseline files; they do not block the phase goal or any UNSUB-07..11 truth.

---

_Verified: 2026-08-03T15:23:15Z_
_Verifier: the agent (gsd-verifier)_
