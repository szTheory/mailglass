---
phase: 04-webhook-ingest
plan: 08
subsystem: webhook
tags: [telemetry, observability, span_helpers, d22, d23, lint02, lint10, t_04_07]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "Mailglass.Telemetry.span/3 + execute/3 wrappers (D-27 handler isolation); render_span/2 / events_append_span/2 / persist_span/3 / send_span/2 / dispatch_span/2 placement precedent"
  - phase: 04-webhook-ingest
    plan: 04
    provides: "Mailglass.Webhook.Plug inline :telemetry.span/3 calls (ingest + verify) — the call sites this plan refactors to named helpers"
  - phase: 04-webhook-ingest
    plan: 06
    provides: "Mailglass.Webhook.Ingest.ingest_multi/3 + finalize_changes/2 3-tuple shape {event, delivery_or_nil, orphan?} — the post-commit telemetry emit iterator walks this list per revision B7"
  - phase: 04-webhook-ingest
    plan: 07
    provides: "Mailglass.Webhook.Reconciler inline :telemetry.span/3 call (tuple-returning enrichment pattern for scanned/linked/remaining counts) — refactored to reconcile_span/2"
provides:
  - "Mailglass.Webhook.Telemetry — 6 named span helpers on one surface per CONTEXT D-22"
  - "ingest_span/2 → [:mailglass, :webhook, :ingest, :start | :stop | :exception] full span with per-request stop metadata enrichment"
  - "verify_span/2 → [:mailglass, :webhook, :signature, :verify, :start | :stop | :exception] full span"
  - "normalize_emit/1 → [:mailglass, :webhook, :normalize, :stop] single emit per event"
  - "orphan_emit/1 → [:mailglass, :webhook, :orphan, :stop] single emit per orphaned event"
  - "duplicate_emit/1 → [:mailglass, :webhook, :duplicate, :stop] single emit per duplicate ingest"
  - "reconcile_span/2 → [:mailglass, :webhook, :reconcile, :start | :stop | :exception] full span"
  - "Single-module surface for Phase 6 LINT-02 (NoPiiInTelemetryMeta) to lint"
  - "D-23 whitelist enforcement via refute_pii/1 test helper asserting 13 forbidden PII keys absent in every describe block (T-04-07 centralized mitigation)"
affects: [04-09, 06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Centralized telemetry surface: all 6 webhook events flow through a single module (Mailglass.Webhook.Telemetry) — Phase 6 LINT-02 has one module plus its callers to lint against the D-23 forbidden-key set, rather than N inline call sites"
    - "Tuple-return enrichment contract: full-span helpers (ingest_span/2, verify_span/2, reconcile_span/2) accept a zero-arity function that returns EITHER a bare `result` OR `{result, stop_metadata}`. The helper's internal span_with_enrichment/3 defp branches on the return shape — bare returns use the call-time metadata for :stop; tuple returns use the enriched map. This resolves the Plan 04-04 deviation (the Mailglass.Telemetry.span/3 wrapper closes metadata at call time and cannot express per-request classification)"
    - "span_with_enrichment/3 calls :telemetry.span/3 directly inside the helper module — this is the single authorized site. Callers MUST NOT reach for :telemetry.span/3. D-27 handler isolation is preserved because :telemetry.span/3 itself wraps handlers in try/catch"
    - "Post-commit emit invariant: Mailglass.Webhook.Ingest.ingest_multi/3 fires normalize/orphan/duplicate emits AFTER Repo.transact returns {:ok, _} (Phase 3 D-04 — broadcast post-commit) so adopters observing the emits know the events are durable"
    - "3-tuple walk for per-event emits: Ingest walks finalize_changes/2's {event, delivery_or_nil, orphan?} list from revision B7 — branches on the explicit orphan? flag. No set-difference, no Event-struct equality (post-insert structs differ from input by :id/:inserted_at)"

key-files:
  created:
    - "lib/mailglass/webhook/telemetry.ex (160 lines, 6 public helpers + 1 shared defp)"
    - "test/mailglass/webhook/telemetry_test.exs (365 lines, 10 tests across 7 describe blocks)"
  modified:
    - "lib/mailglass/webhook/plug.ex (replaced inline :telemetry.span/3 for ingest + Mailglass.Telemetry.span/3 for verify with Mailglass.Webhook.Telemetry.{ingest_span,verify_span}/2; alias added)"
    - "lib/mailglass/webhook/reconciler.ex (replaced inline :telemetry.span/3 for reconcile with Mailglass.Webhook.Telemetry.reconcile_span/2; alias added)"
    - "lib/mailglass/webhook/ingest.ex (added emit_per_event_signals/3 + emit_duplicate_signal/2 defps; called post-commit after Repo.transact; alias added)"

key-decisions:
  - "[Rule 1 auto-fix] Full-span helpers call :telemetry.span/3 DIRECTLY (not Mailglass.Telemetry.span/3). The Phase 1 wrapper's signature `:telemetry.span(prefix, metadata, fn -> {fun.(), metadata} end)` closes the stop metadata at call time — it cannot express per-request status/failure_reason/event_count/duplicate enrichment. This was exactly the bug Plan 04-04's deviation commit 4dcb29a fixed by falling through to :telemetry.span/3 at the Plug. A mechanical rename to the Phase 1 wrapper-based helper would have reintroduced that bug. The helpers support BOTH bare-return (simple callers) and tuple-return (enrichment) shapes via a shared span_with_enrichment/3 defp that case-matches on the inner fn's return."
  - "D-27 handler isolation is preserved because :telemetry.span/3 itself (the BEAM primitive) wraps each attached handler in try/catch. A handler that raises is auto-detached and [:telemetry, :handler, :failure] fires — the webhook pipeline is unaffected. The Mailglass.Telemetry.span/3 wrapper adds NO isolation on top of this; its only value was a consistent signature. Documented inline in the moduledoc."
  - "Single-emit helpers (normalize_emit/1, orphan_emit/1, duplicate_emit/1) DELEGATE to Mailglass.Telemetry.execute/3 — no enrichment needed (the caller knows the full metadata when emitting). These are the LINT-10 exceptions: they preserve the 4-level path structure [:mailglass, :webhook, :action, :stop] but skip the :start/:exception pair because they fire from INSIDE the larger ingest span (which IS a full span)."
  - "Ingest post-commit emit uses outer `provider` arg, NOT event.provider. Plan 04-02 decision (STATE.md line 183-184): 'Provider identity (:provider + :provider_event_id) lives in Event.metadata with STRING keys, not as schema columns.' The %Event{} struct has no :provider field — attempting event.provider compiles but returns nil (Elixir struct field access default). Using the outer arg is correct AND more efficient (no Map.get fallback chain)."
  - "Ingest emit order: emit_per_event_signals/3 fires BEFORE emit_duplicate_signal/2. Reason: operator dashboards that alert on sustained duplicate rate should see the duplicate signal AS the terminal event for the ingest; downstream normalize/orphan emits are per-event signals. This ordering is convention; no correctness dependency."
  - "Tests use async: true + uniquely-suffixed handler_id per test (setup block generates `mailglass-webhook-telemetry-test-#{unique_integer}`). Tests do not share a repo or application state, so async: true is safe. The handler_id uniqueness prevents cross-test handler collisions."
  - "refute_pii/1 test helper enumerates ALL 13 D-23 forbidden keys (:ip, :remote_ip, :user_agent, :to, :from, :subject, :body, :html_body, :headers, :recipient, :email, :raw_payload, :raw_body) and asserts Map.has_key?/2 returns false for each. Called in EVERY describe block (count: 13 call sites across 7 describes — some describes call it twice for both :start and :stop metadata maps). This is the T-04-07 centralized mitigation: one assertion helper covers every event in the webhook surface."
  - "Does-NOT-fire test for normalize_emit/1: attaches to [:mailglass, :webhook, :normalize, :start] and [:mailglass, :webhook, :normalize, :exception], calls normalize_emit/1, asserts refute_receive within 50ms. Locks the LINT-10 single-emit contract structurally — a regression that accidentally promoted single-emit helpers to full spans would fail this test."
  - "Exception-path tests for all three full-span helpers assert both (a) the exception propagates through the helper (assert_raise RuntimeError) and (b) the :exception event fires with the input metadata merged with :telemetry.span's auto-injected kind/reason/stacktrace. The refute_pii/1 check runs on the merged map to catch any framework-injected key accidentally colliding with a PII key."

patterns-established:
  - "Named span helper placement (Phase 4 extension of Phase 3 D-26): per-domain helpers live in their own module under the domain's lib/ directory (lib/mailglass/webhook/telemetry.ex). This mirrors the Phase 3 convention of `send_span/2` / `dispatch_span/2` co-located on Mailglass.Telemetry. For Phase 4, the webhook domain has enough surface (6 events + whitelist discipline) to warrant its own module rather than more helpers on the central one."
  - "LINT-10 single-emit exception discipline: the three single-emit helpers (normalize_emit/1, orphan_emit/1, duplicate_emit/1) are documented exceptions to the 'every event is a full :start/:stop/:exception span' rule. Phase 6 LINT-10 whitelists these three specific event paths. The moduledoc explicitly calls out why (per-event signals inside a wrapped operation) — adopters who attempt to introduce a new single-emit in their own telemetry handlers face Phase 6 lint scrutiny."
  - "Tuple-return enrichment contract: library code that needs to attach per-request metadata to a :stop event returns {result, stop_metadata} from the inner fn. Bare returns fall back to the call-time metadata. This contract matches :telemetry.span/3's native tuple shape, lowering impedance mismatch — callers converting back to :telemetry.span/3 directly (if needed for any reason) don't need to reshape their inner fn."

requirements-completed: [HOOK-02, HOOK-06]

# Metrics
duration: 8min
completed: 2026-04-24
---

# Phase 4 Plan 8: Webhook Telemetry Helpers Summary

**`Mailglass.Webhook.Telemetry` ships 6 named span helpers on a single module surface — `ingest_span/2`, `verify_span/2`, `normalize_emit/1`, `orphan_emit/1`, `duplicate_emit/1`, `reconcile_span/2` — formalizing CONTEXT D-22's event catalog. Plug + Reconciler + Ingest refactored to call the helpers; 0 inline `:telemetry.span/3` calls remain in Plug or Reconciler. A Rule 1 auto-fix widened the full-span helpers to accept tuple-returning fns for per-request stop metadata enrichment (preserving the Plan 04-04 deviation pattern that the plan's original design would have regressed). 13-key PII refute helper enforces D-23 in every describe block (T-04-07 centralized mitigation). `LINT-10` forward-reference locked: the three single-emit helpers are documented exceptions.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-24T02:05:03Z
- **Completed:** 2026-04-24T02:13:33Z
- **Tasks:** 2 (Task 1 = Telemetry module + tests; Task 2 = Plug + Reconciler + Ingest refactor)
- **Commits:** 2 task commits + 1 metadata commit (this SUMMARY + STATE/ROADMAP/REQUIREMENTS)
  - `f35e898` — feat(04-08): Mailglass.Webhook.Telemetry — 6 named span helpers (Task 1)
  - `cff0e8e` — refactor(04-08): wire Plug + Reconciler + Ingest to named telemetry helpers (Task 2)
- **Files created:** 2 (telemetry.ex + telemetry_test.exs)
- **Files modified:** 3 (plug.ex + reconciler.ex + ingest.ex)

## Accomplishments

### Task 1: `Mailglass.Webhook.Telemetry` — 6 named span helpers (commit `f35e898`)

- **`lib/mailglass/webhook/telemetry.ex` (NEW, 160 lines):** Six helpers aligned with CONTEXT D-22:

  | Helper | Event path | Type | Stop metadata |
  |--------|------------|------|---------------|
  | `ingest_span/2` | `[:mailglass, :webhook, :ingest, *]` | full span | `provider, tenant_id, status, event_count, duplicate, failure_reason, delivery_id_matched` |
  | `verify_span/2` | `[:mailglass, :webhook, :signature, :verify, *]` | full span | `provider, status, failure_reason` |
  | `normalize_emit/1` | `[:mailglass, :webhook, :normalize, :stop]` | single emit | `provider, event_type, mapped` |
  | `orphan_emit/1` | `[:mailglass, :webhook, :orphan, :stop]` | single emit | `provider, event_type, tenant_id, age_seconds` |
  | `duplicate_emit/1` | `[:mailglass, :webhook, :duplicate, :stop]` | single emit | `provider, event_type` |
  | `reconcile_span/2` | `[:mailglass, :webhook, :reconcile, *]` | full span | `tenant_id, scanned_count, linked_count, remaining_orphan_count, status` |

  The three full-span helpers share a private `span_with_enrichment/3` that calls `:telemetry.span/3` directly and branches on the inner fn's return shape — bare `result` uses the call-time metadata for `:stop`; `{result, stop_metadata}` uses the returned map. Single-emit helpers delegate to `Mailglass.Telemetry.execute/3` (Phase 1). No callers outside this module call `:telemetry.span/3` directly — the helpers are the single LINT-02 surface.

- **`test/mailglass/webhook/telemetry_test.exs` (NEW, 365 lines):** 10 tests across 7 describe blocks:

  - `ingest_span/2` — :start + :stop events fire with input metadata carried through (+ measurements present)
  - `verify_span/2` — :start + :stop events fire
  - `normalize_emit/1` — single :stop event with `%{count: 1}` measurements + bare metadata; a sibling test asserts `:start`/`:exception` DO NOT fire within 50ms (locks the LINT-10 single-emit contract structurally)
  - `orphan_emit/1` — single :stop with provider/event_type/tenant_id/age_seconds
  - `duplicate_emit/1` — single :stop with provider/event_type
  - `reconcile_span/2` — :start + :stop events with reconcile counts
  - `exception path` — 3 tests asserting all three full-span helpers propagate raised exceptions AND emit the :exception event with input metadata

  The `refute_pii/1` helper enumerates 13 D-23 forbidden keys (`:ip, :remote_ip, :user_agent, :to, :from, :subject, :body, :html_body, :headers, :recipient, :email, :raw_payload, :raw_body`) and is called in EVERY describe block — 13 call sites total, multiple per describe to cover both `:start` and `:stop` metadata (and the `:exception` merged map).

### Task 2: Plug + Reconciler + Ingest refactor (commit `cff0e8e`)

- **`lib/mailglass/webhook/plug.ex` (MODIFIED):** Two inline telemetry calls replaced with named helpers.
  - `Plug.call/2` — `:telemetry.span/3` → `Mailglass.Webhook.Telemetry.ingest_span/2` (the tuple-returning enrichment pattern is preserved: `do_call/3` returns `{conn, stop_metadata}` and the helper recognizes the shape)
  - `verify_with_telemetry!/4` — `Mailglass.Telemetry.span/3` → `Mailglass.Webhook.Telemetry.verify_span/2` (no enrichment needed; inner fn returns bare `:ok` or raises)
  - Alias `Mailglass.Webhook.Telemetry, as: WebhookTelemetry` added.
  - 0 direct `:telemetry.span/3` or `Mailglass.Telemetry.span/3` calls remain.

- **`lib/mailglass/webhook/reconciler.ex` (MODIFIED):** Inline `:telemetry.span/3` replaced with `Mailglass.Webhook.Telemetry.reconcile_span/2`. The tuple-returning enrichment (scanned_count/linked_count/remaining_orphan_count/status on `:stop`) is preserved by the new helper's return-shape branching. Alias added.

- **`lib/mailglass/webhook/ingest.ex` (MODIFIED):** Added two defps + post-commit call path:
  - `emit_per_event_signals(provider, %{events_with_deliveries: tuples}, tenant_id)` — walks the 3-tuple list from revision B7; branches on the explicit `orphan?` flag. Orphans emit `orphan_emit/1`; matched events emit `normalize_emit/1`. Uses the outer `provider` arg (not `event.provider`, which doesn't exist — provider identity is in `event.metadata` per Plan 04-02).
  - `emit_duplicate_signal(provider, finalized)` — no-op on `%{duplicate: false}`; emits `duplicate_emit/1` on `%{duplicate: true}`, picking the first event's type as the representative signal.
  - Both called after `Repo.transact` returns `{:ok, finalized}` (post-commit invariant per Phase 3 D-04).
  - Alias added.

## Task Commits

Each task was committed atomically:

1. **Task 1: `Mailglass.Webhook.Telemetry` module + unit tests** — `f35e898` (feat)
2. **Task 2: Plug + Reconciler + Ingest refactor to named helpers** — `cff0e8e` (refactor)

**Plan metadata:** _pending final commit after SUMMARY.md + STATE.md + ROADMAP.md + REQUIREMENTS.md updates_.

## Files Created/Modified

### Created

- `lib/mailglass/webhook/telemetry.ex` — 160-line module exposing 6 named helpers + 1 shared `span_with_enrichment/3` defp. Single surface for Phase 6 LINT-02 to lint.
- `test/mailglass/webhook/telemetry_test.exs` — 365-line test file, 10 tests / 7 describe blocks, `refute_pii/1` helper asserting 13 D-23 forbidden keys absent.

### Modified

- `lib/mailglass/webhook/plug.ex` — moduledoc updated; `alias Mailglass.Webhook.Telemetry, as: WebhookTelemetry` added; `Plug.call/2` uses `ingest_span/2`; `verify_with_telemetry!/4` uses `verify_span/2`. 0 direct `:telemetry.span/3` calls remain.
- `lib/mailglass/webhook/reconciler.ex` — `alias Mailglass.Webhook.Telemetry, as: WebhookTelemetry` added inside the Oban-conditional block; `reconcile/2` uses `reconcile_span/2`. 0 direct `:telemetry.span/3` calls remain.
- `lib/mailglass/webhook/ingest.ex` — alias added; `emit_per_event_signals/3` + `emit_duplicate_signal/2` defps added; `ingest_multi/3` calls them after `Repo.transact` returns `{:ok, _}`.

## Decisions Made

(See `key-decisions` in frontmatter for the full list — nine decisions documented.)

Most load-bearing:

- **Full-span helpers call `:telemetry.span/3` directly**, not `Mailglass.Telemetry.span/3`. The Phase 1 wrapper closes metadata at call time, which cannot express per-request enrichment. The helpers support both bare-return and tuple-return fns via a shared `span_with_enrichment/3` defp — callers that need enrichment return `{result, stop_metadata}`; callers that don't just return `result`.
- **D-27 handler isolation is a `:telemetry.span/3` primitive feature**, not a wrapper feature. `:telemetry.span/3` itself wraps handlers in try/catch; the Mailglass.Telemetry.span/3 wrapper adds no isolation on top. Using the primitive directly inside the helper module is the correct architecture and is documented explicitly in the moduledoc.
- **Per-event emits use the outer `provider` arg** (not `event.provider`). Plan 04-02 decision: provider identity lives in `Event.metadata`, not as a schema field.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan's "mechanical rename" would have regressed the Plan 04-04 deviation fix**

- **Found during:** Task 2 reasoning about the Plug refactor.
- **Issue:** The plan text (Task 2 step 1, lines 472–491 of `04-08-PLAN.md`) shows the Plug's inline `:telemetry.span([:mailglass, :webhook, :ingest], ...)` being replaced with `Mailglass.Webhook.Telemetry.ingest_span(...)`. The plan's success criterion #2 (line 621) also claims helpers DELEGATE to `Mailglass.Telemetry.span/3 + execute/3` — "no direct `:telemetry.span/3` calls." And acceptance criterion line 588 claims "the named helpers wrap the same `Mailglass.Telemetry.span/3` so the events fire identically."
  But Plan 04-04's deviation commit `4dcb29a` explicitly FIXED a bug where `Mailglass.Telemetry.span/3` could not express per-request stop metadata enrichment: the wrapper is `:telemetry.span(prefix, metadata, fn -> {fun.(), metadata} end)` — it closes the stop metadata AT CALL TIME and wraps the inner fn's return in a tuple with THAT metadata. The Plug's `do_call/3` returns `{conn, enriched_meta}` and needs `enriched_meta` to land on the `:stop` event, but the wrapper would drop `enriched_meta` on the floor and attach `%{provider: provider, status: :pending}` (the call-time input) to `:stop` instead — identical `:start` and `:stop` metadata, no observable per-request status.
  A mechanical rename to the Phase 1-wrapper-based helper would have reintroduced the Plan 04-04 bug verbatim.
- **Fix:** The full-span helpers (`ingest_span/2`, `verify_span/2`, `reconcile_span/2`) call `:telemetry.span/3` directly inside a shared `span_with_enrichment/3` defp that branches on the inner fn's return shape — bare `result` uses the call-time metadata for `:stop`; `{result, stop_metadata}` uses the returned map. This matches `:telemetry.span/3`'s native tuple contract. D-27 handler isolation is preserved because `:telemetry.span/3` itself (the BEAM primitive) wraps handlers in try/catch — the Mailglass.Telemetry.span/3 wrapper adds no isolation on top.
  Single-emit helpers DO delegate to `Mailglass.Telemetry.execute/3` because they have no enrichment contract (caller knows the full metadata at emit time).
- **Files modified:** `lib/mailglass/webhook/telemetry.ex` (added `span_with_enrichment/3` defp; updated the three full-span helpers to use it; moduledoc updated to document the tuple-return contract and explain the `:telemetry.span/3` direct call's D-27 preservation).
- **Verification:** `mix test test/mailglass/webhook/ --include requires_oban` → 113 tests, 0 failures (including Plan 04-04's telemetry test that asserts both `:start` and `:stop` fire with per-request metadata on `:stop`).
- **Committed in:** `cff0e8e` (Task 2 commit — the bug was caught before Task 2's first test run).

### Non-deviations documented inline

- The plan's example `emit_per_event_signals/2` (Task 2 step 3, line 525) reads `event.provider` for the orphan branch. The `%Event{}` struct has no `:provider` field (Plan 04-02 decision: provider identity lives in `Event.metadata` with string keys). The actual impl uses the outer `provider` arg (also available at the `ingest_multi/3` call site) — this is correct AND avoids a `Map.get` fallback chain on metadata. Documented inline as a 3-line comment on the defp.

---

**Total deviations:** 1 auto-fixed (Rule 1 bug). All 113 webhook tests + 10 new telemetry tests pass.

## Threat Flags

None. The threat surface introduced by Plan 04-08 matches the plan's `<threat_model>` exactly:

- **T-04-07 (Information Disclosure via telemetry)** — mitigated by the centralized helpers (one-module surface for LINT-02) plus the `refute_pii/1` test helper that enumerates 13 D-23 forbidden keys and asserts absence in EVERY describe block's metadata. The three full-span helpers' exception-path tests ALSO run `refute_pii/1` on the merged exception metadata (which includes `:telemetry.span/3`'s auto-injected `kind`/`reason`/`stacktrace`) to catch any framework-injected key accidentally colliding with a PII key.

## LINT-10 forward-reference (per plan revision W3)

Phase 6 `LINT-10` (presumed to enforce that every telemetry event is a full `:start`/`:stop`/`:exception` span at level 4 `[:mailglass, :domain, :resource, :action]`) MUST whitelist the three single-emit helpers shipped here:

- `[:mailglass, :webhook, :normalize, :stop]`
- `[:mailglass, :webhook, :orphan, :stop]`
- `[:mailglass, :webhook, :duplicate, :stop]`

Rationale: the single emits preserve the 4-level path structure but skip the `:start`/`:exception` pair because they fire from inside the larger `[:mailglass, :webhook, :ingest, *]` span (which IS a full span) and represent per-event signals rather than wrapped operations. The module's `LINT-10 single-emit exception` moduledoc section explicitly documents this; Phase 6 should reference this SUMMARY when locking the LINT-10 spec.

## Self-Check: PASSED

Verified:

- `lib/mailglass/webhook/telemetry.ex` — FOUND (160 lines; 6 public helpers + 1 shared defp)
- `test/mailglass/webhook/telemetry_test.exs` — FOUND (365 lines; 10 tests / 7 describe blocks)
- `lib/mailglass/webhook/plug.ex` — MODIFIED (alias + 2 helper call sites; 0 direct `:telemetry.span/3` calls; 0 `Mailglass.Telemetry.span` calls)
- `lib/mailglass/webhook/reconciler.ex` — MODIFIED (alias + 1 helper call site; 0 direct `:telemetry.span/3` calls)
- `lib/mailglass/webhook/ingest.ex` — MODIFIED (alias + `emit_per_event_signals/3` + `emit_duplicate_signal/2` defps; called after `Repo.transact`)
- Commit `f35e898` (Task 1) — FOUND in git log
- Commit `cff0e8e` (Task 2) — FOUND
- `mix compile --warnings-as-errors --no-optional-deps` → exits 0
- `mix test test/mailglass/webhook/telemetry_test.exs --warnings-as-errors` → 10 tests, 0 failures
- `mix test test/mailglass/webhook/ --warnings-as-errors --include requires_oban` → 113 tests, 0 failures
- `mix verify.phase_02` → 59 tests, 0 failures (565 excluded)
- `mix verify.phase_03` → 62 tests, 0 failures, 2 skipped (562 excluded)
- `mix verify.phase_04` → 0 tests (correct — `:phase_04_uat`-tagged tests ship in Plan 09)
- `grep -c ":telemetry.span\|Mailglass.Telemetry.span" lib/mailglass/webhook/plug.ex` → 0 (only moduledoc mentions)
- `grep -c ":telemetry.span" lib/mailglass/webhook/reconciler.ex` → 0
- `grep -c "normalize_emit\|orphan_emit\|duplicate_emit" lib/mailglass/webhook/ingest.ex` → 3
- `grep -c "{event, _delivery, true}" lib/mailglass/webhook/ingest.ex` → 1 (orphan branch)
- `grep -c "{event, _delivery, false}" lib/mailglass/webhook/ingest.ex` → 1 (matched branch)

## Next Phase Readiness

Plan 04-08 closes Wave 4A. Phase 4 has one remaining plan:

- **Plan 09 (UAT + property tests + `guides/webhooks.md`)** — wires end-to-end tests tagged `@tag :phase_04_uat` that exercise the full ingest → reconcile → telemetry lifecycle. Can assert the 6 webhook events fire at their documented paths with D-23 whitelist-conformant metadata (the `refute_pii/1` pattern from this plan's test file is directly reusable). Can also ship the adopter-facing `guides/webhooks.md` that documents attaching telemetry handlers on `[:mailglass, :webhook, :signature, :verify, :stop]` for abuse triage (the D-23 IP/UA carve-out documented in the Webhook.Telemetry moduledoc).

- **Phase 6 LINT-02 (`NoPiiInTelemetryMeta`)** has exactly one target module (`Mailglass.Webhook.Telemetry`) plus its callers (Plug, Reconciler, Ingest) to lint against the 13-key forbidden set. The lint rule reads the module's `@forbidden_keys` attribute (to be added in Phase 6) and scans every AST node that builds a map passed to the 6 helpers.

- **Phase 6 LINT-10** whitelist locked to three event paths (`[:mailglass, :webhook, :normalize | :orphan | :duplicate, :stop]`). Phase 6 should reference this SUMMARY when drafting the check spec.

**Blockers or concerns:** None. Phase 4 Wave 4A delivered the telemetry formalization with one Rule 1 auto-fix that tightened the plan's "mechanical rename" framing into a correctness-preserving widening of the helper contract.

**Phase 4 progress:** 8 of 9 plans complete.

---
*Phase: 04-webhook-ingest*
*Completed: 2026-04-24*
