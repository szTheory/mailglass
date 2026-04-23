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
| **Full suite command** | `mix verify.core_send` (alias: `mix test` + `mix compile --no-optional-deps --warnings-as-errors` + `mix credo`) |
| **Estimated runtime** | ~30 seconds (Phase 3 scope; excludes CI-only sandbox lanes) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale`
- **After every plan wave:** Run `mix test` (full async ExUnit suite)
- **Before `/gsd-verify-work`:** `mix verify.core_send` must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

*Filled by planner — see 03-PLAN.md files for task-level `<automated>` blocks. Template row for reference:*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | REQ-TRANS-01 | T-3-01 | Fake adapter records messages without network I/O | unit | `mix test test/mailglass/adapters/fake_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 tasks MUST land before any feature task in Phase 3. Planner: assign these to Plan 01 (or equivalent) at the top of Wave 1.

- [ ] `test/support/mailglass_case.ex` — shared ExUnit case template with `Mailglass.DataCase` + `Mailglass.Clock` stub + Fake adapter allow-list setup
- [ ] `test/support/factories.ex` — `%Mailable{}`, `%Message{}`, `%Delivery{}` factories with sane tenant defaults
- [ ] `test/mailglass/adapters/fake_test.exs` — stubs for SEND-01..SEND-05 (Fake adapter baseline)
- [ ] `test/mailglass/outbound_test.exs` — stubs for TRANS-01..TRANS-04 (hot path)
- [ ] `test/mailglass/mailable_test.exs` — stubs for AUTHOR-01 (macro budget + callbacks)
- [ ] `test/mailglass/rate_limiter_test.exs` — stubs for SEND-04 (ETS token bucket + Clock injection)
- [ ] `test/mailglass/render_test.exs` — stubs for TRANS-02 (pure Swoosh bridge)
- [ ] `test/mailglass/test_assertions_test.exs` — stubs for TEST-01/TEST-02 (assertion helpers)
- [ ] `test/verify/core_send_test.exs` — end-to-end pipeline test against Fake (gates `mix verify.core_send`)
- [ ] `lib/mix/tasks/verify.core_send.ex` — alias wiring for full-suite gate

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Boot-time `Logger.warning` when `:oban` absent fires exactly once | SEND-02 | Logger assertion across application restarts is flaky in async ExUnit; requires isolated release-style test | `ExUnit.CaptureLog.capture_log(fn -> Application.stop(:mailglass); Application.ensure_all_started(:mailglass); Application.stop(:mailglass); Application.ensure_all_started(:mailglass) end) =~ count one warning` — document in plan as `type: manual` task with runbook |
| `mix compile --no-optional-deps --warnings-as-errors` passes with Oban removed from deps | SEND-02, D-11 | Requires mutating mix.exs optional deps list; cannot run concurrently | Runbook: comment out `{:oban, "~> 2.x"}`, run the CI lane command, restore. Automated in CI via a dedicated lane; manual during local dev. |

---

## Coverage Gates

These are additional per-phase invariants the planner must encode as plan-level `must_haves`:

- [ ] **Every telemetry event** (`[:mailglass, :outbound, :deliver, :start|:stop|:exception]`, `[:mailglass, :preflight, :*]`, `[:mailglass, :rate_limit, :*]`, `[:mailglass, :adapter, :dispatch, :*]`, `[:mailglass, :events, :projected]`) fires in ≥1 test.
- [ ] **Zero PII in telemetry metadata** — a guard test inspects emitted metadata for forbidden keys (`:to`, `:from`, `:body`, `:html_body`, `:subject`, `:headers`, `:recipient`, `:email`) and fails if any appear.
- [ ] **Dispatch ≠ Delivered** — no test in Phase 3 asserts a `:delivered` event (that's Phase 4 webhook territory). A Credo check or a static assertion test confirms this.
- [ ] **`use Mailglass.Mailable` macro injects ≤20 lines** — a test uses `:code.get_object_code/1` or AST expansion to count injected functions.
- [ ] **Idempotency replay is a no-op** — a test runs the same `deliver_many/2` batch twice and asserts delivery row count is stable.
- [ ] **Tracking OFF by default** — a test asserts a plain mailable produces a `%Swoosh.Email{}` with no tracking pixel and no rewritten links.
- [ ] **Auth-stream tracking guard** — a test declares a mailable named `MagicLinkMailer` with `tracking: [opens: true]` and asserts it raises `%ConfigError{type: :tracking_on_auth_stream}`.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter
- [ ] Coverage gates above all map to at least one task acceptance_criteria

**Approval:** pending
