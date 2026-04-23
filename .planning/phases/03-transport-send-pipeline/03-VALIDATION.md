---
phase: 3
slug: transport-send-pipeline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (OTP 27 / Elixir 1.18) |
| **Config file** | `test/test_helper.exs` + `config/test.exs` (Phase 1 Wave 0 installed) |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix verify.phase_03` (alias: `ecto.drop` + `ecto.create` + `test --only phase_03_uat` + `compile --no-optional-deps --warnings-as-errors`) |
| **Estimated runtime** | ~30 seconds (Phase 3 scope; excludes CI-only sandbox lanes) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale`
- **After every plan wave:** Run `mix test` (full async ExUnit suite)
- **Before `/gsd-verify-work`:** `mix verify.phase_03` must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

*Filled by planner during task execution. Representative rows below — see 03-NN-PLAN.md files for each task's authoritative `<automated>` command. Status column advances from ⬜ → ✅ / ❌ / ⚠️ as the executor commits.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | TEST-05 | T-3-01-04 | Clock three-tier resolution; per-process freeze isolation | unit | `mix test test/mailglass/clock_test.exs test/mailglass/tenancy_test.exs` | ❌ W0 | ⬜ pending |
| 3-01-02 | 01 | 1 | SEND-05 | T-3-01-01 | BatchFailed atom closure; PubSub topic prefix; Message.put_metadata/3 | unit | `mix test test/mailglass/pub_sub/topics_test.exs test/mailglass/errors/ test/mailglass/message_test.exs` | ❌ W0 | ⬜ pending |
| 3-01-03 | 01 | 1 | SEND-05 | T-3-01-03 | Telemetry spans PII-free; Application supervision tree; Repo.multi/1 public seam; Events.append_multi fn form | unit | `mix test test/mailglass/telemetry_phase_03_test.exs test/mailglass/application_test.exs test/mailglass/config_test.exs test/mailglass/repo_multi_test.exs test/mailglass/events_append_multi_fn_test.exs` | ❌ W0 | ⬜ pending |
| 3-02-01 | 02 | 2 | TRANS-01, TRANS-03 | T-3-02-02 | Adapter behaviour; Swoosh wrapper error normalization | unit | `mix test test/mailglass/adapter_test.exs test/mailglass/adapters/swoosh_test.exs` | ❌ W0 | ⬜ pending |
| 3-02-02 | 02 | 2 | TRANS-02 | T-3-02-03 | Fake ownership isolation (async: true safe); trigger_event writes through real Projector | unit + concurrency | `mix test test/mailglass/adapters/fake_test.exs test/mailglass/adapters/fake_concurrency_test.exs` | ❌ W0 | ⬜ pending |
| 3-03-01 | 03 | 2 | SEND-04 | T-3-03-01 | RateLimiter token-bucket ETS + supervisor-owned ETS | unit + supervision | `mix test test/mailglass/rate_limiter_test.exs test/mailglass/rate_limiter_supervision_test.exs` | ❌ W0 | ⬜ pending |
| 3-04-01 | 04 | 2 | AUTHOR-01 | T-3-04-01 | Mailable macro injects ≤20 lines; stream + tracking opts | unit | `mix test test/mailglass/mailable_test.exs` | ❌ W0 | ⬜ pending |
| 3-05-01 | 05 | 4 | TRANS-04 | T-3-05-04 | Delivery schema :status + :last_error (I-01); idempotency_key partial UNIQUE | unit + migration | `mix ecto.drop -r Mailglass.TestRepo --quiet && mix ecto.create -r Mailglass.TestRepo --quiet && mix test test/mailglass/outbound/delivery_idempotency_key_test.exs` | ❌ W0 | ⬜ pending |
| 3-05-02 | 05 | 4 | SEND-01, SEND-05 | T-3-05-03, T-3-05-02 | Outbound.send/2 preflight + Multi#1 + adapter OUTSIDE transaction + Multi#2; telemetry PII-free | integration | `mix test test/mailglass/outbound_test.exs test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| 3-06-01 | 06 | 5 | TEST-01, TEST-02 | n/a (test harness) | TestAssertions + MailerCase + core_send_integration_test.exs gate | integration | `mix verify.phase_03` | ❌ W0 | ⬜ pending |
| 3-07-01 | 07 | 4 | TRACK-03 | T-3-07-01, T-3-07-10 | Token sign/verify; open-redirect structurally impossible | unit + property | `mix test test/mailglass/tracking/token_test.exs test/mailglass/tracking/open_redirect_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 tasks MUST land before any feature task in Phase 3. Per Nyquist 8a, each plan's owning tests land with the plan that ships them — there is no single monolithic "test stubs file." Plan 01 Task 3 ships the shared fixtures module and the mix alias; the owning plan commits the first failing test of each ID cluster.

- [ ] `test/support/mailer_case.ex` — shared ExUnit case template wrapping `Mailglass.DataCase` + `Mailglass.Clock.Frozen` setup + `Mailglass.Adapters.Fake.checkout/0` per-test isolation (lands with **Plan 06**, which ships TestAssertions + MailerCase)
- [ ] `test/support/generators.ex` (Phase 2 shipped; **Plan 05 Task 1** extends for `idempotency_key`) + `test/support/fake_fixtures.ex` (**Plan 01 Task 3** ships the shared `%Mailable{}`, `%Message{}` stub fixtures)
- [ ] `test/mailglass/adapters/fake_test.exs` — ships with **Plan 02 Task 2** (baseline Fake adapter tests)
- [ ] `test/mailglass/outbound_test.exs` + `test/mailglass/outbound/preflight_test.exs` + `test/mailglass/outbound/telemetry_test.exs` — ship with **Plan 05 Task 2** (hot path)
- [ ] `test/mailglass/mailable_test.exs` — ships with **Plan 04 Task 1** (macro budget + callbacks)
- [ ] `test/mailglass/rate_limiter_test.exs` — ships with **Plan 03 Task 1** (ETS token bucket)
- [ ] `test/mailglass/test_assertions_test.exs` — ships with **Plan 06 Task 2** (assertion helpers)
- [ ] `test/mailglass/core_send_integration_test.exs` — end-to-end pipeline test against Fake (**Plan 06**; gates `mix verify.phase_03` via `@tag :phase_03_uat`)
- [ ] `mix verify.phase_03` alias — **Plan 01 Task 3** ships this in `mix.exs aliases/0` (under the INST-04 naming convention — not a dedicated `lib/mix/tasks/*.ex` file; it's a Mix alias)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Boot-time `Logger.warning` when `:oban` absent fires exactly once | SEND-02 | Logger assertion across application restarts is flaky in async ExUnit; requires isolated release-style test | `ExUnit.CaptureLog.capture_log(fn -> Application.stop(:mailglass); Application.ensure_all_started(:mailglass); Application.stop(:mailglass); Application.ensure_all_started(:mailglass) end) =~ count one warning` — Plan 01 Test 5 automates this via `ExUnit.CaptureLog` (no longer manual; keeping row for historical reference). |
| `mix compile --no-optional-deps --warnings-as-errors` passes with Oban removed from deps | SEND-02, D-11 | Requires mutating mix.exs optional deps list; cannot run concurrently | Runbook: comment out `{:oban, "~> 2.x"}`, run the CI lane command, restore. Automated in CI via a dedicated lane; manual during local dev. |

---

## Coverage Gates

These are additional per-phase invariants the planner encoded as plan-level `must_haves`:

- [ ] **Every Phase 3 telemetry event** (see Plan 01 Task 3's `@logged_events` additions — `[:mailglass, :outbound, :send, :stop]`, `[:mailglass, :outbound, :dispatch, :stop]`, `[:mailglass, :outbound, :suppression, :stop]`, `[:mailglass, :outbound, :rate_limit, :stop]`, `[:mailglass, :persist, :outbound, :multi, :stop]`, etc.) fires in ≥1 test.
- [ ] **Zero PII in telemetry metadata** — Plan 05 Task 2's Test 13 property-tests 100 generated sends asserting no metadata key in `(:to, :from, :body, :html_body, :subject, :headers, :recipient, :email)`.
- [ ] **Dispatch ≠ Delivered** — no Phase 3 test asserts a `:delivered` event (that's Phase 4 webhook territory). A Credo check or static assertion test confirms.
- [ ] **`use Mailglass.Mailable` macro injects ≤20 lines** — Plan 04's macro-expansion test uses `:code.get_object_code/1` or AST walk to count injected functions.
- [ ] **Idempotency replay is a no-op** — Plan 05 Task 4's Test 4 runs the same `deliver_many/2` batch twice and asserts delivery row count is stable.
- [ ] **Tracking OFF by default** — Plan 04's test asserts a plain mailable produces a `%Swoosh.Email{}` with no tracking pixel and no rewritten links.
- [ ] **Auth-stream tracking guard** — Plan 04's test declares a mailable named `MagicLinkMailer` with `tracking: [opens: true]` and asserts it raises `%ConfigError{type: :tracking_on_auth_stream}`.
- [ ] **Delivery :status field is public API** (I-01 revision) — Plan 05 Task 1 Test 8 asserts `Delivery.__schema__(:fields)` contains `:status` and `:last_error`; Plan 05 Task 2 Test 1 asserts the canonical return shape `{:ok, %Delivery{status: :sent}}`.
- [ ] **Repo.multi/1 public seam used** (I-02 revision) — Plan 01 Task 3 ships `Mailglass.Repo.multi/1`; Plan 05's acceptance criterion greps that `Mailglass.Outbound` uses it (never `Repo.repo().transaction`).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter (executor flips after all per-plan test files land)
- [ ] `wave_0_complete: true` set in frontmatter (executor flips after Plan 01 Task 3 ships fake_fixtures.ex + mix alias)
- [ ] Coverage gates above all map to at least one task acceptance_criteria

**Approval:** pending
