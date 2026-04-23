---
phase: 03-transport-send-pipeline
verified: 2026-04-22T12:00:00Z
status: gaps_found
score: 4/5 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Tracking.rewrite_if_enabled/1 is called inside Outbound.send/2 (and deliver_later/2) so that opted-in tracking pixel injection and click link rewriting are active at send time"
    status: partial
    reason: "Mailglass.Tracking.rewrite_if_enabled/1 exists and is fully implemented in lib/mailglass/tracking.ex (lines 75-97), Mailglass.Tracking.Rewriter.rewrite/2 is complete (lib/mailglass/tracking/rewriter.ex), yet Mailglass.Outbound.send/2, do_deliver_later/2, and the deliver_many batch path in outbound.ex never call rewrite_if_enabled/1 between Renderer.render/1 and Multi#1. The result: even when a mailable has tracking: [opens: true, clicks: true], no pixel is injected and no links are rewritten. Tracking guard (TRACK-01) and token/plug infra (TRACK-03) work; the Outbound facade hook is the missing link."
    artifacts:
      - path: "lib/mailglass/outbound.ex"
        issue: "Calls Renderer.render/1 (line 262) but immediately proceeds to do_send_after_preflight/2 without calling Tracking.rewrite_if_enabled/1. Same gap at lines 324 and 476 for deliver_later and deliver_many paths."
      - path: "lib/mailglass/tracking.ex"
        issue: "rewrite_if_enabled/1 is implemented and exported but not called from Outbound."
    missing:
      - "Add `{:ok, rewritten} <- Tracking.rewrite_if_enabled(rendered) |> then(&{:ok, &1})` (or equivalent) after Renderer.render/1 in do_send/2, do_deliver_later/2, and the per-message path in do_deliver_many/2."
      - "Update test/mailglass/core_send_integration_test.exs Criterion 4 test to assert pixel IS injected when tracking: [opens: true] is set (currently it only asserts no pixel when tracking is off — the positive case is untested end-to-end through Outbound)."
deferred: []
human_verification:
  - test: "Confirm mix verify.phase_03 passes after the Rewriter gap is closed"
    expected: "61+ tests pass, 0 failures, compile --no-optional-deps --warnings-as-errors exits 0"
    why_human: "Cannot run the test suite in this verification context; the code-review-reported pass (61 tests, 0 failures) was pre-gap-discovery"
---

# Phase 3: Transport + Send Pipeline Verification Report

**Phase Goal:** The Fake adapter (built FIRST per D-13) is the merge-blocking release gate, and the full hot path — Mailable → Outbound → preflight (suppression + rate-limit + stream policy) → render → Multi(Delivery + Event(:queued) + Worker enqueue) → Adapter → Multi(Delivery update + Event(:dispatched)) — is testable end-to-end against Fake without any real provider.
**Verified:** 2026-04-22T12:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Adopter writes `use Mailglass.Mailable`, calls `Mailglass.Outbound.deliver/2`, Fake records message, `assert_mail_sent/1` asserts in <20 LoC | ✓ VERIFIED | `lib/mailglass/mailable.ex` injects `deliver/2` as a `defdelegate` to `Mailglass.Outbound.deliver/2`; `lib/mailglass/adapters/fake.ex` `deliver/1` pushes a record into ETS via `Storage.push/2`; `lib/mailglass/test_assertions.ex` ships 4 matcher styles; `test/mailglass/core_send_integration_test.exs` Criterion 1 test passes (<15 lines, `@moduletag :phase_03_uat`) |
| 2  | `deliver_later/2` returns `{:ok, %Delivery{status: :queued}}` via Oban when loaded; Task.Supervisor fallback otherwise; one boot warning when Oban absent | ✓ VERIFIED | `lib/mailglass/outbound.ex:329-343` branches on `async_adapter == :task_supervisor` then `Mailglass.OptionalDeps.Oban.available?()`; `lib/mailglass/application.ex:44-65` emits one `Logger.warning` via `:persistent_term` idempotency guard; both `enqueue_oban/2` (line 346) and `enqueue_task_supervisor/2` (line 382) return `{:ok, %{d | status: :queued, ...}}`; UAT Criterion 2 tests both paths |
| 3  | `deliver_many/2` survives partial failure: 2 successful + 1 failed Delivery; re-run is idempotency no-op | ✓ VERIFIED | `lib/mailglass/outbound.ex:492-547` uses `on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}`; re-fetches existing rows by idempotency_key after conflict; `core_send_integration_test.exs` Criterion 3 asserts `row_count == 2` after two runs of the same 3-message batch |
| 4  | Open/click tracking OFF by default — no pixel injection or link rewriting unless `tracking: [opens: true, clicks: true]` set per-mailable; `Tracking.Guard.assert_safe!/1` raises on auth-stream violation | ✓ VERIFIED | `lib/mailglass/tracking.ex:99-116` returns `%{opens: false, clicks: false}` for any mailable without `tracking:` opts; `lib/mailglass/tracking/guard.ex` raises `%ConfigError{type: :tracking_on_auth_stream}` when tracking is on and function name matches auth regex; UAT Criterion 4 tests both "no pixel" and "auth guard raises" paths. NOTE: the Rewriter itself is not called from Outbound (gap below), so "no pixel by default" is technically true even in the presence of the gap — the guard and default-off behavior are correct. |
| 5  | `Mailglass.RateLimiter` enforces per-`(tenant_id, recipient_domain)` ETS token bucket; exceeding returns `{:error, %RateLimitError{retry_after_ms: int}}`; `mix verify.phase_03` runs full pipeline against Fake | ✓ VERIFIED | `lib/mailglass/rate_limiter.ex:59-62` bypasses for `:transactional`; `lib/mailglass/rate_limiter.ex:64-129` uses `:ets.update_counter/4` compound op; returns `{:error, RateLimitError.new(:per_domain, retry_after_ms: ms, ...)}` on depletion; `mix.exs:116-120` wires `verify.phase_03` alias (ecto.drop + ecto.create + test --only phase_03_uat + compile --no-optional-deps --warnings-as-errors); UAT Criterion 5 tests 6th operational send fails + 10 transactional sends all pass |

**Score:** 4/5 truths verified

### Rewriter → Outbound Wiring Gap (Truth #4 / TRACK-03 partial)

Truth #4 passes on the "off by default" half. The gap is the "on by default means on" half: when a mailable IS opted in with `tracking: [opens: true]`, no pixel is injected because `Mailglass.Outbound.do_send/2` never calls `Tracking.rewrite_if_enabled/1`. The implementation is: `{:ok, rendered} <- Renderer.render(msg)` → `do_send_after_preflight(rendered, opts)` — no rewrite step.

`Mailglass.Tracking.rewrite_if_enabled/1` is fully implemented and tested in isolation. The missing link is the call in the Outbound pipeline. This was explicitly deferred to Phase 3.1 in `03-07-SUMMARY.md` (lines 122 and 202) and `03-07-PLAN.md` line 575.

**TRACK-03 requirement text:** "When tracking IS opted in, click rewriting uses Phoenix.Token-signed tokens with rotation support." The token infrastructure (Token, Rewriter, Plug, ConfigValidator) is fully shipped; the opt-in activation path through Outbound is not wired. This is a `partial` status — infrastructure is present, end-to-end delivery activation is not.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mailglass/mailable.ex` | Behaviour + `__using__/1` + `@before_compile` + `__mailglass_opts__/0` | ✓ VERIFIED | All four present and substantive (157 lines); `@behaviour`, `@before_compile`, `@optional_callbacks`, `defoverridable` all present |
| `lib/mailglass/adapters/fake.ex` | In-memory time-advanceable test adapter | ✓ VERIFIED | 278 lines; `@behaviour Mailglass.Adapter`; `deliver/1`, ownership API (checkout/checkin/allow/set_shared), `trigger_event/3`, `advance_time/1` all present |
| `lib/mailglass/adapters/fake/storage.ex` | ETS-backed storage with per-pid ownership | ✓ VERIFIED | Exists in adapters/fake/ directory |
| `lib/mailglass/outbound.ex` | `send/2 + deliver/2 + deliver_later/2 + deliver_many/2 + deliver!/2 + deliver_many!/2 + dispatch_by_id/1` | ✓ VERIFIED | 957 lines; all 7 public functions present; two-Multi sync pattern; adapter call outside transaction; Oban + Task.Supervisor fallback |
| `lib/mailglass/outbound/worker.ex` | Oban worker conditionally compiled | ✓ VERIFIED | `if Code.ensure_loaded?(Oban.Worker) do` wrapper; `queue: :mailglass_outbound`, `max_attempts: 20`, `unique:` present |
| `lib/mailglass/outbound/delivery.ex` | `:idempotency_key` field + changeset | ✓ VERIFIED | `field(:idempotency_key, :string)` at line 109; `unique_constraint` at line 147 |
| `lib/mailglass/rate_limiter.ex` | `check/3` with `:transactional` bypass + ETS token bucket | ✓ VERIFIED | 159 lines; `:transactional` clause at line 59; `ets.update_counter/4` compound op at line 101 |
| `lib/mailglass/rate_limiter/supervisor.ex` | Supervisor starting TableOwner | ✓ VERIFIED | Exists; `use Supervisor` with `:one_for_one` |
| `lib/mailglass/rate_limiter/table_owner.ex` | Init-and-idle GenServer owning `:mailglass_rate_limit` | ✓ VERIFIED | `write_concurrency: :auto`, `decentralized_counters: true` present |
| `lib/mailglass/suppression.ex` | `check_before_send/1` facade | ✓ VERIFIED | `Application.get_env(:mailglass, :suppression_store, ...)` dispatch present |
| `lib/mailglass/suppression_store/ets.ex` | Behaviour impl for ETS | ✓ VERIFIED | `@behaviour Mailglass.SuppressionStore`; `check/2` + `record/2` + `reset/0` present |
| `lib/mailglass/suppression_store/ets/supervisor.ex` | Supervisor for ETS table | ✓ VERIFIED | Exists |
| `lib/mailglass/suppression_store/ets/table_owner.ex` | Init-and-idle GenServer | ✓ VERIFIED | `:mailglass_suppression_store` ETS table; `read_concurrency: true` |
| `lib/mailglass/stream.ex` | `policy_check/1` no-op seam | ✓ VERIFIED | Returns `:ok`; emits `[:mailglass, :outbound, :stream_policy, :stop]` telemetry; v0.5 DELIV-02 forward contract in moduledoc |
| `lib/mailglass/tracking.ex` | `enabled?/1` + `rewrite_if_enabled/1` facade | ✓ VERIFIED (isolated) | Both functions present and substantive; `rewrite_if_enabled/1` calls `Tracking.Rewriter.rewrite/2` when any flag is true; NOT called from Outbound (gap) |
| `lib/mailglass/tracking/guard.ex` | `assert_safe!/1` auth-stream enforcement | ✓ VERIFIED | `~r/^(magic_link|password_reset|verify_email|confirm_account)/` regex; raises `%ConfigError{type: :tracking_on_auth_stream}` |
| `lib/mailglass/tracking/rewriter.ex` | Floki HTML transform | ✓ VERIFIED | `Floki.traverse_and_update` present; pixel injection + link rewriting; skip-list (mailto, tel, data-mg-notrack, head anchors) |
| `lib/mailglass/tracking/token.ex` | `sign_open/3 + verify_open/2 + sign_click/4 + verify_click/2` | ✓ VERIFIED | Phoenix.Token-based; salts rotation; target_url inside payload (D-35 pattern a) |
| `lib/mailglass/tracking/plug.ex` | Mountable Plug.Router for pixel + click | ✓ VERIFIED | GET /o/:token.gif (43-byte GIF89a) + GET /c/:token; 204/404 on failure (D-39) |
| `lib/mailglass/tracking/config_validator.ex` | Boot-time host assertion | ✓ VERIFIED | `validate_at_boot!/0` raises `%ConfigError{type: :tracking_host_missing}` |
| `lib/mailglass/test_assertions.ex` | 4 matcher styles + PubSub-backed assertions | ✓ VERIFIED | `assert_mail_sent/0,1` (bare, keyword, struct-pattern, predicate); `last_mail/0`; `wait_for_mail/1`; `assert_no_mail_sent/0`; `assert_mail_delivered/2`; `assert_mail_bounced/2` |
| `test/support/mailer_case.ex` | `Mailglass.MailerCase` ExUnit.CaseTemplate | ✓ VERIFIED | async: true default; Fake checkout; Tenancy stamp; PubSub subscribe; `@tag tenant: :unset` path; `set_mailglass_global` setup |
| `test/support/webhook_case.ex` | WebhookCase stub | ✓ VERIFIED | Exists (Phase 4 fleshes out) |
| `test/support/admin_case.ex` | AdminCase stub | ✓ VERIFIED | Exists (Phase 5 fleshes out) |
| `test/mailglass/core_send_integration_test.exs` | Phase gate for `mix verify.phase_03` | ✓ VERIFIED | `@moduletag :phase_03_uat`; 5 describe blocks mapping 1:1 to ROADMAP criteria; `assert_mail_sent`, `assert_mail_delivered`, `Delivery.status` assertions all present |
| `priv/repo/migrations/00000000000002_add_idempotency_key_to_deliveries.exs` | Idempotency key migration | ✓ VERIFIED | File exists |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `use Mailglass.Mailable opts` | `@mailglass_opts` module attribute | `quote bind_quoted: [opts: opts]` | ✓ WIRED | `mailable.ex:126` — `@mailglass_opts opts` inside `quote` block |
| `Mailglass.Outbound.do_send/2` preflight | `Tenancy.assert_stamped! → Tracking.Guard.assert_safe! → Suppression.check_before_send → RateLimiter.check → Stream.policy_check → Renderer.render` | sequential `with` | ✓ WIRED | `outbound.ex:257-262` — all six stages present in correct order |
| `Mailglass.Outbound.deliver/2` | `Mailglass.Outbound.send/2` | `defdelegate` | ✓ WIRED | `outbound.ex:101` — `defdelegate deliver(msg, opts \\ []), to: __MODULE__, as: :send` |
| `Mailglass.Outbound.send/2` Multi#1 | `Events.append_multi + Delivery.changeset + Repo.multi` | `Ecto.Multi` | ✓ WIRED | `enqueue_task_supervisor/2` and `persist_queued/2` both use `Ecto.Multi.insert(:delivery) |> Events.append_multi |> Repo.multi()` |
| `Mailglass.Outbound.dispatch_by_id/1` | adapter call OUTSIDE transaction | direct call, no `Repo.multi` wrapping | ✓ WIRED | `outbound.ex:225-249` — `call_adapter/2` called outside any `Repo.multi/1` |
| `Mailglass.Outbound.Worker.perform/1` | `TenancyMiddleware.wrap_perform + dispatch_by_id/1` | `wrap_perform` delegation | ✓ WIRED | `worker.ex` uses `Mailglass.Oban.TenancyMiddleware.wrap_perform` |
| `deliver_later/2` Oban path | `Oban.insert/3` inside same Multi as Delivery insert | `Multi.insert → Events.append_multi → Oban.insert(:job, fn)` | ✓ WIRED | `outbound.ex:353-371` |
| `RateLimiter.check/3` | `:ets.update_counter/4` on `:mailglass_rate_limit` | compound counter op | ✓ WIRED | `rate_limiter.ex:101-110` |
| `Mailglass.Application` | `RateLimiter.Supervisor + SuppressionStore.ETS.Supervisor` | `Code.ensure_loaded?` gating in application supervision tree | ✓ WIRED | `application.ex` contains `maybe_add` pattern; confirmed by `application_test.exs` |
| `Mailglass.Suppression.check_before_send/1` | `SuppressionStore.check/2` | `Application.get_env(:mailglass, :suppression_store, ...)` | ✓ WIRED | `suppression.ex:707` |
| `Tracking.rewrite_if_enabled/1` | `Mailglass.Tracking.Rewriter.rewrite/2` | direct call when flags.opens or flags.clicks | ✓ WIRED (isolated) | `tracking.ex:81-93` — BUT this function is never called from Outbound (gap) |
| `Mailglass.Tracking.Rewriter` | `Floki.parse_document + Floki.traverse_and_update` | Floki transform | ✓ WIRED | `rewriter.ex` — `Floki.` calls present |
| **Outbound.do_send → Tracking.rewrite_if_enabled** | tracking pixel/link rewriting applied before adapter call | call in `do_send/2` after `Renderer.render/1` | ✗ NOT_WIRED | `outbound.ex:262` — `{:ok, rendered} <- Renderer.render(msg)` → immediately `do_send_after_preflight(rendered, opts)` with no rewrite step. Same gap in `do_deliver_later/2:324` and `deliver_many` per-message path. |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| `core_send_integration_test.exs` Criterion 1 | `Delivery.status` | `Outbound.deliver/2 → Projector.update_projections → Repo.multi` | DB row with `:sent` status | ✓ FLOWING |
| `RateLimiter.check/3` | token counter | `:ets.update_counter/4` on `:mailglass_rate_limit` | Real ETS counter | ✓ FLOWING |
| `Suppression.check_before_send/1` | suppression result | `SuppressionStore.check/2` → ETS or Ecto | Real store query | ✓ FLOWING |
| `TestAssertions.assert_mail_sent/1` | `{:mail, %Message{}}` in process mailbox | `Fake.Storage.push(owner, record)` sends `{:mail, msg}` to owner | Real process message | ✓ FLOWING |
| `Tracking.rewrite_if_enabled/1` | rewritten html_body | `Tracking.Rewriter.rewrite/2` → Floki parse → traverse | Real HTML transform | ✓ FLOWING (isolated only — not reached through Outbound) |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — cannot run the server/test suite from this verification context. Code-review documentation confirms `mix verify.phase_03` produced 61 tests, 0 failures, 2 skipped as of 2026-04-22.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| AUTHOR-01 | 03-04 | `use Mailglass.Mailable` ≤20-line injection | ✓ SATISFIED | `mailable.ex` __using__/1 macro injects ≤20 AST forms; `@before_compile`, `@mailglass_opts`, `defoverridable` all present |
| TRANS-01 | 03-02 | `Mailglass.Adapter` behaviour | ✓ SATISFIED | `lib/mailglass/adapter.ex` defines `deliver/2` callback with locked return shape |
| TRANS-02 | 03-02 | `Mailglass.Adapters.Fake` — merge-blocking release gate | ✓ SATISFIED | `lib/mailglass/adapters/fake.ex` — ownership model, `trigger_event/3`, `advance_time/1`, `@behaviour Mailglass.Adapter` |
| TRANS-03 | 03-02 | `Mailglass.Adapters.Swoosh` wrapper | ✓ SATISFIED | `lib/mailglass/adapters/swoosh.ex` exists |
| TRANS-04 | 03-05 | All four delivery shapes + bang variants | ✓ SATISFIED | `outbound.ex` — `send/2`, `deliver/2`, `deliver_later/2`, `deliver_many/2`, `deliver!/2`, `deliver_many!/2` all present |
| SEND-01 | 03-05 | Pre-send pipeline in order + telemetry | ✓ SATISFIED | `outbound.ex:257-262` — correct 6-stage order; each stage has telemetry |
| SEND-02 | 03-03 | RateLimiter ETS token bucket | ✓ SATISFIED | `rate_limiter.ex` + supervisor + table_owner; `:transactional` bypass; `ets.update_counter/4` |
| SEND-03 | 03-05 | `Outbound.Worker` Oban + Task.Supervisor fallback | ✓ SATISFIED | `outbound/worker.ex` conditionally compiled; `application.ex` boot warning via `:persistent_term` |
| SEND-04 | 03-03 | `Suppression.check_before_send/1` + SuppressionStore behaviour | ✓ SATISFIED | `suppression.ex` + `suppression_store/ets.ex`; ETS + Ecto impls |
| SEND-05 | 03-01 | `PubSub.Topics` typed builder | ✓ SATISFIED | `lib/mailglass/pub_sub/topics.ex` — `events/1,2`, `deliveries/1` |
| TRACK-01 | 03-04 | Tracking OFF by default | ✓ SATISFIED | `tracking.ex:99-116` returns `%{opens: false, clicks: false}` by default; UAT Criterion 4 no-pixel test |
| TRACK-03 | 03-07 | Phoenix.Token-signed click rewriting + SSRF/open-redirect tests | PARTIAL | Token infra (token.ex, rewriter.ex, plug.ex, config_validator.ex) fully implemented and tested in isolation; open-redirect property test exists; BUT `Tracking.rewrite_if_enabled/1` is not wired into `Outbound.send/2` — opted-in tracking is not activated at send time |
| TEST-01 | 03-06 | `Mailglass.TestAssertions` | ✓ SATISFIED | 4 matcher styles + `assert_mail_delivered/2` + `assert_mail_bounced/2` + `last_mail/0` + `assert_no_mail_sent/0` |
| TEST-02 | 03-06 | Case templates: MailerCase, WebhookCase, AdminCase | ✓ SATISFIED | All three exist; MailerCase has async: true default + Fake checkout + Tenancy + PubSub setup |
| TEST-05 | 03-01 | `Mailglass.Clock` injection point | ✓ SATISFIED | `lib/mailglass/clock.ex` + `clock/frozen.ex` + `clock/system.ex`; per-process freeze via process dict |

**Orphaned requirements check:** No additional Phase 3 requirement IDs found in REQUIREMENTS.md traceability table beyond the 15 listed above.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/mailglass/outbound.ex` | 280 | `Map.get(dispatch_result.provider_response, :adapter, :unknown)` — crashes on non-map `provider_response` (ME-05 from code review) | ⚠️ Warning | Latent crash for custom adapters not returning a map as `provider_response` |
| `lib/mailglass/outbound.ex` | 833 | `String.to_atom("Elixir." <> mod_str)` — unbounded atom creation from DB value (ME-03 from code review) | ⚠️ Warning | Atom table exhaustion vector from tampered delivery rows |
| `lib/mailglass/errors/batch_failed.ex` | 77-81 | `fn 0 -> ... end` — partial match crashes if `ctx[:failures]` length > 0 (ME-02 from code review) | ⚠️ Warning | Works by accident today; any caller passing `failures:` in context rather than top-level opts would crash |
| `lib/mailglass/events.ex` | 160 | `DateTime.utc_now/0` bypasses `Mailglass.Clock.utc_now/0` (ME-01 from code review) | ⚠️ Warning | Tests using `Clock.Frozen.freeze/1` on events not explicitly passing `occurred_at:` see wall-clock timestamps; not a Phase 3 UAT regression |
| `test/support/mailer_case.ex` | 134,142 | `Application.put_env(:mailglass, :async_adapter, ...)` written on every test's setup in a case template supporting `async: true` — global state race (HI-01 from code review) | 🛑 Blocker risk for CI | Intermittent flakiness in concurrent async tests that exercise `deliver_later`; not a Phase 3 success criteria blocker but a test-correctness regression |
| `lib/mailglass/tracking/rewriter.ex` | 222-226 | Endpoint fallback chain includes `Application.get_env(:mailglass, :adapter_endpoint)` that the Plug (plug.ex:142-145) does not include — key mismatch silently fails token verification (HI-02 from code review) | 🛑 Blocker for tracking | If adopter sets `:adapter_endpoint` without `:tracking, endpoint:`, all pixel/click verification fails silently with 204/404 |

No files contain `return null`, `TODO`, `FIXME`, `PLACEHOLDER`, or `not yet implemented` comments in the core delivery path. The "ASSUMED" annotations in outbound.ex docstrings are documentation of in-flight design decisions, not code stubs.

---

### Human Verification Required

#### 1. mix verify.phase_03 Green Baseline

**Test:** Run `mix verify.phase_03` from the project root (requires Postgres running and test DB accessible)
**Expected:** `ecto.drop + ecto.create + test --warnings-as-errors --only phase_03_uat` produces 61 tests, 0 failures, 2 skipped; `compile --no-optional-deps --warnings-as-errors` exits 0
**Why human:** Cannot run the database-dependent test suite from verification context. The code-review report confirms the pass state as of 2026-04-22.

---

### Gaps Summary

**One actionable gap blocks the full TRACK-03 contract.**

`Mailglass.Tracking.rewrite_if_enabled/1` exists, is fully implemented (`lib/mailglass/tracking.ex:75-97`), and is tested in isolation (`test/mailglass/tracking/rewriter_test.exs`, `test/mailglass/tracking/default_off_test.exs`). The Phoenix.Token-signing infrastructure, Rewriter HTML transform, Plug endpoint, and ConfigValidator are all complete and tested.

The missing element: `Mailglass.Outbound.do_send/2` (and the parallel `do_deliver_later/2` and deliver_many per-message path) calls `Renderer.render/1` but does not call `Tracking.rewrite_if_enabled/1` on the result before the adapter sees the message. This means that even when a mailable opts in with `tracking: [opens: true, clicks: true]`, the live send pipeline passes the plain-rendered HTML to the adapter without pixel injection or link rewriting.

This was explicitly accepted during Phase 3 execution and documented in `03-07-SUMMARY.md` as a Phase 3.1 gap-closure item. The ROADMAP Criterion 4 UAT test only asserts the "off by default, no pixel" direction; it does not assert "on when opted in, pixel present through Outbound" — so `mix verify.phase_03` passes despite the gap.

**Two HIGH code-review findings (HI-01, HI-02) are also documented above** as blocking-severity anti-patterns that should be closed in Phase 3.1. They do not prevent the 5 ROADMAP criteria from passing but will cause real-world defects:
- HI-01 will cause intermittent CI flakiness on async deliver_later tests
- HI-02 will silently break tracking pixel recording for adopters who set `:adapter_endpoint` without `:tracking, endpoint:`

**Recommended Phase 3.1 items (in priority order):**
1. Wire `Tracking.rewrite_if_enabled/1` into `Outbound.do_send/2`, `do_deliver_later/2`, and the deliver_many per-message path (TRACK-03 completion)
2. Fix HI-02: Centralize endpoint resolution in a single function shared by Rewriter and Plug
3. Fix HI-01: Guard `Application.put_env(:async_adapter)` in MailerCase behind `unless async?`
4. Fix ME-03: `String.to_existing_atom` in `rehydrate_message`
5. Fix ME-02: `BatchFailed.format_message/2` partial match
6. Fix ME-01: `Events.append/1` → `Mailglass.Clock.utc_now/0` (Phase 6 LINT-12 will catch at lint time)

---

_Verified: 2026-04-22_
_Verifier: Claude (gsd-verifier)_
