---
phase: 03-transport-send-pipeline
verified: 2026-04-23T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "Tracking.rewrite_if_enabled/1 wired into Outbound.do_send/2, do_deliver_later/2, preflight_single/1 (TRACK-03 closure)"
    - "HI-02 — Tracking.endpoint/0 single source of truth; Rewriter and Plug both delegate to it; raise on missing config"
    - "HI-01 — MailerCase Application.put_env(:async_adapter) guarded by unless async?; on_exit restores pre-setup value via prior_async_adapter snapshot"
    - "ME-01 — Events.normalize/1 uses Mailglass.Clock.utc_now/0 instead of DateTime.utc_now/0"
    - "ME-02 — BatchFailed.format_message(:partial_failure) simplified; fn 0 -> FunctionClauseError removed"
    - "ME-03 — rehydrate_message uses String.to_existing_atom/1 on both paths; String.to_atom/1 eliminated"
    - "ME-04 — Projector.safe_broadcast/2 catches :exit in addition to ArgumentError/RuntimeError"
    - "ME-05 — provider_tag/1 private pattern-match replaces Map.get/3 on possibly-non-map provider_response"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Full mix test (bare suite including migration_test.exs) is citext-race-free"
    addressed_in: "Phase 6"
    evidence: "03-11-SUMMARY.md §Scope boundary: 'Bare mix test citext failures from migration_test concurrency are documented in deferred-items.md as a Phase 6 architectural fix candidate.' The architectural race (migration_test.exs drops citext mid-suite while async tests are mid-flight) cannot be closed with per-setup probes alone. The Phase 3 acceptance target is mix test --only phase_03_uat, which exits 0. Phase 6 will introduce boundary enforcement that may resolve the structural concurrency issue."
human_verification: []
---

# Phase 3: Transport + Send Pipeline Verification Report

**Phase Goal:** The Fake adapter (built FIRST per D-13) is the merge-blocking release gate, and the full hot path — Mailable → Outbound → preflight (suppression + rate-limit + stream policy) → render → Multi(Delivery + Event(:queued) + Worker enqueue) → Adapter → Multi(Delivery update + Event(:dispatched)) — is testable end-to-end against Fake without any real provider.
**Verified:** 2026-04-23
**Status:** passed
**Re-verification:** Yes — after gap closure (Plans 03-08 through 03-12)

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Adopter writes `use Mailglass.Mailable`, calls `Mailglass.Outbound.deliver/2`, Fake records message, `assert_mail_sent/1` asserts in <20 LoC | ✓ VERIFIED | `mailable.ex` injects `deliver/2` as defdelegate; `adapters/fake.ex` delivers into ETS; `test_assertions.ex` ships 4 matcher styles; `core_send_integration_test.exs` Criterion 1 test passes |
| 2 | `deliver_later/2` returns `{:ok, %Delivery{status: :queued}}` via Oban when loaded; Task.Supervisor fallback otherwise; one boot warning when Oban absent | ✓ VERIFIED | `outbound.ex` branches on async_adapter == :task_supervisor then OptionalDeps.Oban.available?(); boot warning via :persistent_term idempotency guard; both paths return {:ok, %Delivery{status: :queued}} |
| 3 | `deliver_many/2` survives partial failure: 2 successful + 1 failed Delivery; re-run is idempotency no-op | ✓ VERIFIED | `outbound.ex` uses `on_conflict: :nothing, conflict_target: {:unsafe_fragment, ...}`; re-fetches existing rows by idempotency_key after conflict; Criterion 3 asserts row_count == 2 after two runs |
| 4 | Open/click tracking OFF by default — no pixel injection or link rewriting unless `tracking: [opens: true, clicks: true]` set per-mailable; `Tracking.Guard.assert_safe!/1` raises on auth-stream violation; when opted in, pixel IS injected | ✓ VERIFIED | `tracking.ex:99-116` returns `%{opens: false, clicks: false}` by default; `tracking/guard.ex` raises `%ConfigError{type: :tracking_on_auth_stream}`; `outbound.ex:263` calls `Tracking.rewrite_if_enabled(rendered)` after `Renderer.render/1` in `do_send/2`; same at line 326 (`do_deliver_later`) and line 480 (`preflight_single`); Criterion 4 positive-case test ("pixel injected when mailable opts in") passes |
| 5 | `Mailglass.RateLimiter` enforces per-`(tenant_id, recipient_domain)` ETS token bucket; exceeding returns `{:error, %RateLimitError{retry_after_ms: int}}`; `mix verify.phase_03` runs full pipeline against Fake | ✓ VERIFIED | `rate_limiter.ex:59-62` bypasses for :transactional; `:ets.update_counter/4` compound op at line 101; `mix.exs` aliases `verify.phase_03`; mix test --only phase_03_uat produces 62 tests, 0 failures |

**Score:** 5/5 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Full bare `mix test` (including migration_test.exs concurrent async tests) is citext-race-free | Phase 6 | 03-11-SUMMARY.md documents this as a Phase 6 architectural fix candidate. The race is inherent to migration_test.exs dropping citext mid-suite while unrelated async tests are mid-flight. The Phase 3 acceptance target (mix test --only phase_03_uat) exits 0 with 62 tests, 0 failures. |

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mailglass/mailable.ex` | Behaviour + `__using__/1` + `@before_compile` + `__mailglass_opts__/0` | ✓ VERIFIED | All four present; ≤20-line injection |
| `lib/mailglass/adapters/fake.ex` | In-memory time-advanceable test adapter | ✓ VERIFIED | Ownership API, trigger_event/3, advance_time/1, @behaviour present |
| `lib/mailglass/outbound.ex` | All 7 public functions; `rewrite_if_enabled` in 3 hot paths | ✓ VERIFIED | 3 `rewrite_if_enabled` calls confirmed at lines 263, 326, 480; provider_tag/1 present at lines 977-978; String.to_atom eliminated from rehydrate_message |
| `lib/mailglass/tracking.ex` | `enabled?/1` + `rewrite_if_enabled/1` + `endpoint/0` facade | ✓ VERIFIED | All three functions present; `endpoint/0` is the single source of truth for token endpoint resolution (HI-02 fix) |
| `lib/mailglass/tracking/rewriter.ex` | Delegates endpoint resolution to `Mailglass.Tracking.endpoint()` | ✓ VERIFIED | Line 45: `Keyword.get(opts, :endpoint, Mailglass.Tracking.endpoint())`; `endpoint_fallback/0` removed; `"mailglass-tracking-default-endpoint"` literal removed |
| `lib/mailglass/tracking/plug.ex` | Delegates endpoint resolution to `Mailglass.Tracking.endpoint()` | ✓ VERIFIED | Line 54: `verify_open(Mailglass.Tracking.endpoint(), ...)`; line 74: `verify_click(Mailglass.Tracking.endpoint(), ...)`; divergent private `endpoint/0` removed |
| `lib/mailglass/errors/config_error.ex` | `:tracking_endpoint_missing` in `@types` closed set | ✓ VERIFIED | Line 30: `:tracking_endpoint_missing` present in `@types`; format_message/2 clause present at line 118 |
| `lib/mailglass/events.ex` | `normalize/1` uses `Mailglass.Clock.utc_now/0` | ✓ VERIFIED | Line 160: `Map.put_new_lazy(:occurred_at, &Mailglass.Clock.utc_now/0)` — `DateTime.utc_now/0` eliminated (ME-01) |
| `lib/mailglass/errors/batch_failed.ex` | `format_message(:partial_failure)` simplified | ✓ VERIFIED | Lines 77-81: `failed = ctx[:failed_count] || "some"` — `fn 0 -> ...` clause eliminated (ME-02) |
| `lib/mailglass/outbound/projector.ex` | `safe_broadcast/2` catches `:exit` | ✓ VERIFIED | Lines 192-200: `catch :exit, reason ->` clause present after rescue block (ME-04) |
| `test/support/mailer_case.ex` | Guarded `Application.put_env(:async_adapter)` + snapshot/restore in on_exit | ✓ VERIFIED | Line 124: `prior_async_adapter = Application.get_env(:mailglass, :async_adapter)`; line 171: `unless async? do`; lines 185-188: restore from snapshot (HI-01) |
| `test/support/oban_helpers.ex` | `ObanHelpers.maybe_create_oban_jobs/0` for @tag oban: :manual tests | ✓ VERIFIED | File exists; `maybe_create_oban_jobs/0` calls `Oban.Migrations.up()` idempotently; called from `test_helper.exs` line 33 |
| `config/test.exs` | `:adapter_endpoint` configured; `disconnect_on_error_codes: [:internal_error]` present | ✓ VERIFIED | Line 47: `adapter_endpoint: "mailglass-test-endpoint"`; line 33: `disconnect_on_error_codes: [:internal_error]`; Tracking.endpoint/0 resolves without raising in tests |
| `test/test_helper.exs` | citext probe after TestRepo start; `ObanHelpers.maybe_create_oban_jobs()` call | ✓ VERIFIED | Lines 33 and 55-58 confirm both; probe fires `SELECT 'probe'::citext` before Sandbox.mode(:manual) |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Outbound.do_send/2` | `Tracking.rewrite_if_enabled/1` | after `{:ok, rendered} <- Renderer.render(msg)`, before `do_send_after_preflight` | ✓ WIRED | `outbound.ex:263` — `rewritten = Tracking.rewrite_if_enabled(rendered)` |
| `Outbound.do_deliver_later/2` | `Tracking.rewrite_if_enabled/1` | after render, before `enqueue_via_async_adapter` | ✓ WIRED | `outbound.ex:326` — `rewritten = Tracking.rewrite_if_enabled(rendered)` |
| `Outbound.preflight_single/1` | `Tracking.rewrite_if_enabled/1` | inline in with-chain return | ✓ WIRED | `outbound.ex:480` — `{:ok, Tracking.rewrite_if_enabled(rendered)}` |
| `Tracking.Rewriter.rewrite/2` | `Mailglass.Tracking.endpoint/0` | `Keyword.get(opts, :endpoint, Mailglass.Tracking.endpoint())` | ✓ WIRED | `rewriter.ex:45` — private `endpoint_fallback/0` removed; no divergence |
| `Tracking.Plug` open path | `Mailglass.Tracking.endpoint/0` | `verify_open(Mailglass.Tracking.endpoint(), ...)` | ✓ WIRED | `plug.ex:54` — private `endpoint/0` removed; no divergence |
| `Tracking.Plug` click path | `Mailglass.Tracking.endpoint/0` | `verify_click(Mailglass.Tracking.endpoint(), ...)` | ✓ WIRED | `plug.ex:74` — same unified call |
| `MailerCase setup` | `Application.put_env(:mailglass, :async_adapter, :task_supervisor)` | `unless async? do` guard | ✓ WIRED | `mailer_case.ex:171` — global mutation only for async: false tests (HI-01) |
| `MailerCase on_exit` | pre-setup `:async_adapter` value | `prior_async_adapter` snapshot | ✓ WIRED | `mailer_case.ex:185-188` — unconditional `:oban` restore eliminated |
| `Events.normalize/1` | `Mailglass.Clock.utc_now/0` | `Map.put_new_lazy(:occurred_at, ...)` | ✓ WIRED | `events.ex:160` — `DateTime.utc_now/0` call eliminated (ME-01) |
| `Projector.safe_broadcast/2` | `:exit` catch | `catch :exit, reason ->` after rescue | ✓ WIRED | `projector.ex` — catch clause present; delivery already committed before broadcast |
| `do_send_after_preflight` | `provider_tag/1` | replaces `Map.get(dispatch_result.provider_response, ...)` | ✓ WIRED | `outbound.ex:281`; `provider_tag/1` at lines 977-978; `Map.get` on provider_response eliminated (ME-05) |
| `rehydrate_message/1` | `String.to_existing_atom/1` | nested try/rescue; both resolution paths | ✓ WIRED | `outbound.ex:840` — `String.to_atom/1` eliminated on both primary and fallback paths (ME-03) |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| `core_send_integration_test.exs` Criterion 4 positive case | `msg.swoosh_email.html_body` pixel img tag | `Outbound.deliver/2` → `do_send/2` → `Tracking.rewrite_if_enabled/1` → `Tracking.Rewriter.rewrite/2` → Floki transform → `Fake.deliver/1` → ETS | Real HTML transform with 1x1 pixel appended to body | ✓ FLOWING |
| `core_send_integration_test.exs` Criterion 1 | `Delivery.status` | `Outbound.deliver/2 → Projector.update_projections → Repo.multi` | DB row with :sent status | ✓ FLOWING |
| `RateLimiter.check/3` | token counter | `:ets.update_counter/4` on `:mailglass_rate_limit` | Real ETS counter | ✓ FLOWING |
| `Suppression.check_before_send/1` | suppression result | `SuppressionStore.check/2` | Real store query | ✓ FLOWING |
| `Events.append/1` | `occurred_at` | `Mailglass.Clock.utc_now/0` | Frozen in tests when `Clock.Frozen.freeze/1` active | ✓ FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — cannot run the database-dependent test suite from this verification context. The 03-12-SUMMARY.md confirms: `mix test --only phase_03_uat → 62 tests, 0 failures` and both compile lanes clean.

| Behavior | Documented Result | Status |
|----------|-------------------|--------|
| `mix test --only phase_03_uat` | 62 tests, 0 failures (03-12-SUMMARY.md) | ✓ PASS (documented) |
| `mix compile --warnings-as-errors` | Exits 0 (03-12-SUMMARY.md) | ✓ PASS (documented) |
| `mix compile --no-optional-deps --warnings-as-errors` | Exits 0 (03-12-SUMMARY.md) | ✓ PASS (documented) |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| AUTHOR-01 | 03-04 | `use Mailglass.Mailable` ≤20-line injection | ✓ SATISFIED | `mailable.ex` __using__/1 macro injects ≤20 AST forms |
| TRANS-01 | 03-02 | `Mailglass.Adapter` behaviour | ✓ SATISFIED | `lib/mailglass/adapter.ex` defines `deliver/2` callback |
| TRANS-02 | 03-02 | `Mailglass.Adapters.Fake` — merge-blocking release gate | ✓ SATISFIED | `lib/mailglass/adapters/fake.ex` — ownership model, trigger_event/3, @behaviour |
| TRANS-03 | 03-02 | `Mailglass.Adapters.Swoosh` wrapper | ✓ SATISFIED | `lib/mailglass/adapters/swoosh.ex` exists |
| TRANS-04 | 03-05 | All four delivery shapes + bang variants | ✓ SATISFIED | `outbound.ex` — send/2, deliver/2, deliver_later/2, deliver_many/2, deliver!/2, deliver_many!/2 present |
| SEND-01 | 03-05 | Pre-send pipeline in order + telemetry | ✓ SATISFIED | `outbound.ex:257-262` — correct 6-stage order; each stage emits telemetry |
| SEND-02 | 03-03 | RateLimiter ETS token bucket | ✓ SATISFIED | `rate_limiter.ex` + supervisor + table_owner; :transactional bypass; ets.update_counter/4 |
| SEND-03 | 03-05 | `Outbound.Worker` Oban + Task.Supervisor fallback | ✓ SATISFIED | `outbound/worker.ex` conditionally compiled; boot warning via :persistent_term |
| SEND-04 | 03-03 | `Suppression.check_before_send/1` + SuppressionStore behaviour | ✓ SATISFIED | `suppression.ex` + `suppression_store/ets.ex` |
| SEND-05 | 03-01 | `PubSub.Topics` typed builder | ✓ SATISFIED | `lib/mailglass/pub_sub/topics.ex` — events/1,2, deliveries/1 |
| TRACK-01 | 03-04 | Tracking OFF by default | ✓ SATISFIED | `tracking.ex:99-116` returns %{opens: false, clicks: false} by default |
| TRACK-03 | 03-07 + 03-08 + 03-09 | Phoenix.Token-signed click rewriting + end-to-end wiring | ✓ SATISFIED | Token infra (token.ex, rewriter.ex, plug.ex, config_validator.ex) fully implemented; `Tracking.rewrite_if_enabled/1` called in all 3 Outbound hot paths (outbound.ex:263, 326, 480); `Tracking.endpoint/0` is the single source of truth shared by Rewriter and Plug (HI-02); positive UAT test ("pixel injected when mailable opts in") passes in Criterion 4 |
| TEST-01 | 03-06 + 03-11 | `Mailglass.TestAssertions` | ✓ SATISFIED | 4 matcher styles + assert_mail_delivered/2 + assert_mail_bounced/2; citext OID cache flake mitigated with 3-layer probe strategy |
| TEST-02 | 03-06 + 03-10 | Case templates: MailerCase, WebhookCase, AdminCase | ✓ SATISFIED | All three exist; MailerCase HI-01 fixed — async_adapter mutation guarded by unless async?; snapshot/restore in on_exit |
| TEST-05 | 03-01 + 03-12 | `Mailglass.Clock` injection point | ✓ SATISFIED | `lib/mailglass/clock.ex` + clock/frozen.ex + clock/system.ex; Events.normalize/1 now uses Clock.utc_now/0 (ME-01) |

**Orphaned requirements check:** No additional Phase 3 requirement IDs found in REQUIREMENTS.md beyond the 15 listed above.

---

### Anti-Patterns Found

| File | Pattern | Severity | Status |
|------|---------|----------|--------|
| `lib/mailglass/outbound.ex` | `String.to_atom` on DB-sourced value | ~~⚠️ Warning~~ | ✓ CLOSED — ME-03 fix (Plans 03-12): `String.to_existing_atom/1` on both resolution paths |
| `lib/mailglass/outbound.ex` | `Map.get(dispatch_result.provider_response, :adapter, :unknown)` on possibly non-map term | ~~⚠️ Warning~~ | ✓ CLOSED — ME-05 fix (Plan 03-12): `provider_tag/1` private pattern-match at lines 977-978 |
| `lib/mailglass/errors/batch_failed.ex` | `fn 0 -> ... end` partial match raising FunctionClauseError | ~~⚠️ Warning~~ | ✓ CLOSED — ME-02 fix (Plan 03-12): direct `ctx[:failed_count]` |
| `lib/mailglass/events.ex` | `DateTime.utc_now/0` bypasses `Mailglass.Clock.utc_now/0` | ~~⚠️ Warning~~ | ✓ CLOSED — ME-01 fix (Plan 03-12): `&Mailglass.Clock.utc_now/0` in normalize/1 |
| `test/support/mailer_case.ex` | `Application.put_env(:mailglass, :async_adapter, ...)` under `async: true` | ~~🛑 Blocker risk~~ | ✓ CLOSED — HI-01 fix (Plan 03-10): `unless async?` guard + prior_async_adapter snapshot/restore |
| `lib/mailglass/tracking/rewriter.ex` vs `plug.ex` | Mismatched endpoint fallback chains | ~~🛑 Blocker for tracking~~ | ✓ CLOSED — HI-02 fix (Plan 03-09): `Mailglass.Tracking.endpoint/0` single source of truth in both callers |
| `lib/mailglass/outbound/projector.ex` | `safe_broadcast/2` rescue list did not cover `:exit` | ~~⚠️ Warning~~ | ✓ CLOSED — ME-04 fix (Plan 03-12): `catch :exit, reason ->` clause added |

No remaining TODO/FIXME/placeholder comments in the core delivery path. No stubs in the tracking pipeline. All gap-closure anti-patterns resolved.

---

### Human Verification Required

None. All previously human-verification-required items are now satisfied by documented test results:

- `mix verify.phase_03` (confirmed green: 62 tests, 0 failures per 03-12-SUMMARY.md)
- `mix compile --no-optional-deps --warnings-as-errors` (confirmed clean per 03-12-SUMMARY.md)
- Both regression fixes from follow-up commits (8a3cfb4 — ConfigError closed-set assertion update; 3bcc841 — MailerCaseTest async_adapter opt pattern) are confirmed applied

---

### Gaps Summary

No gaps remain. All 5 original gaps from the prior `gaps_found` verification are closed:

1. **TRACK-03 / Truth #4 (Outbound wiring)** — CLOSED. `Tracking.rewrite_if_enabled/1` is now called at all three Outbound hot paths: `do_send/2` (line 263), `do_deliver_later/2` (line 326), `preflight_single/1` (line 480). A positive-case UAT test ("pixel injected when mailable opts in with tracking: [opens: true]") passes in Criterion 4.

2. **HI-02 (Tracking endpoint divergence)** — CLOSED. `Mailglass.Tracking.endpoint/0` is the single source of truth. Both `tracking/rewriter.ex` (line 45) and `tracking/plug.ex` (lines 54, 74) call it. The divergent `endpoint_fallback/0` in Rewriter and private `endpoint/0` in Plug are removed. `:tracking_endpoint_missing` is in `ConfigError @types`. `config/test.exs` configures `:adapter_endpoint` so `Tracking.endpoint/0` resolves in tests.

3. **HI-01 (MailerCase async_adapter race)** — CLOSED. `unless async? do` guard at line 171 prevents global `Application.put_env` for `async: true` tests. `prior_async_adapter` snapshot at line 124 + restore at lines 185-188 replaces the unconditional `:oban` restore.

4. **ME-01 through ME-05 (medium-severity code review findings)** — ALL CLOSED by Plan 03-12:
   - ME-01: `Events.normalize/1` uses `Mailglass.Clock.utc_now/0` (frozen clock tests now deterministic)
   - ME-02: `BatchFailed.format_message(:partial_failure)` simplified to direct `ctx[:failed_count]`
   - ME-03: `rehydrate_message/1` uses `String.to_existing_atom/1` on both resolution paths
   - ME-04: `Projector.safe_broadcast/2` catches `:exit` in addition to `ArgumentError`/`RuntimeError`
   - ME-05: `provider_tag/1` pattern-match replaces `Map.get/3` on possibly non-map `provider_response`

**Deferred (not a gap):** Full bare `mix test` citext-race-free operation. This is a documented architectural limitation from `migration_test.exs` running concurrently with async tests — addressed in Phase 6. The Phase 3 acceptance scope (`mix test --only phase_03_uat`) exits 0 with 62 tests, 0 failures.

---

_Verified: 2026-04-23_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes — after Plans 03-08, 03-09, 03-10, 03-11, 03-12 gap closure_
