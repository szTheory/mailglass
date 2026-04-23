---
phase: 4
slug: webhook-ingest
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: see `04-RESEARCH.md` §Validation Architecture (lines 921–981) for full per-REQ test map.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib) + StreamData 1.3 (property-based) |
| **Config file** | `test/test_helper.exs` (Phase 2 wired migration runner; Phase 3 wired Mox + ObanHelpers) |
| **Quick run command** | `mix test test/mailglass/webhook/ --warnings-as-errors --exclude flaky` |
| **Phase property suite** | `mix test test/mailglass/properties/ --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Phase UAT gate** | `mix verify.phase_04` (NEW alias — Wave 0 adds; mirror `verify.phase_03` in `mix.exs:116`) |
| **Estimated runtime** | Quick: ~5–15s. Wave: ~30–90s incl. 1000-replay property. UAT: ~2–3 min cold-start. |

---

## Sampling Rate

- **After every task commit:** `mix test test/mailglass/webhook/ --warnings-as-errors --exclude flaky` (~5–15s)
- **After every plan wave:** `mix test test/mailglass/webhook/ test/mailglass/properties/ --warnings-as-errors --exclude flaky` (~30–90s)
- **Before `/gsd-verify-work`:** `mix verify.phase_04` followed by `mix verify.cold_start` to ensure Phase 4 doesn't break the full suite from a fresh DB
- **Max feedback latency:** 90 seconds for wave-level sampling

---

## Per-Task Verification Map

> Task IDs assigned by gsd-planner during planning. This table seeds the planner with the per-REQ test bindings; planner extends with `<task_id>` columns mapped to plan/wave assignments.

| Req ID | Behavior | Test Type | Automated Command | File Exists | Threat Ref |
|--------|----------|-----------|-------------------|-------------|------------|
| HOOK-01 | CachingBodyReader preserves raw bytes across `{:more, _}` chunks; iodata flattens on final `{:ok, _}` | unit + integration | `mix test test/mailglass/webhook/caching_body_reader_test.exs -x` | ❌ W0 | T-04-01 |
| HOOK-01 | Adopter wiring snippet from `guides/webhooks.md` works in test endpoint | integration | `mix test test/mailglass/webhook/plug_test.exs -x` (named test) | ❌ W0 | T-04-01 |
| HOOK-02 | Router macro generates 2 routes per `mailglass_webhook_routes/2`; `:as` opt works | unit | `mix test test/mailglass/webhook/router_test.exs -x` | ❌ W0 | — |
| HOOK-02 | Plug response code matrix: 200 OK on replay; 401 on forged sig; 422 on tenant-unresolved; 500 on config error | integration | `mix test test/mailglass/webhook/plug_test.exs -x` | ❌ W0 | T-04-02 |
| HOOK-03 | Postmark Basic Auth + IP allowlist; `Plug.Crypto.secure_compare/2`; `Logger.warning` if `:trusted_proxies` unset | unit + property | `mix test test/mailglass/webhook/providers/postmark_test.exs -x` + `mix test test/mailglass/properties/webhook_signature_failure_test.exs -x` | ❌ W0 | T-04-03 |
| HOOK-04 | SendGrid ECDSA via `:public_key.der_decode/2` + `:public_key.verify/4`; 300s timestamp tolerance; pattern-match strictly on `true` | unit + property | `mix test test/mailglass/webhook/providers/sendgrid_test.exs -x` + `mix test test/mailglass/properties/webhook_signature_failure_test.exs -x` | ❌ W0 | T-04-04 |
| HOOK-05 | All 14 Anymail event types + `:unknown` fallthrough with `Logger.warning`; no silent `_ -> :hard_bounce` | unit | `mix test test/mailglass/webhook/providers/postmark_test.exs` + sendgrid equivalent | ❌ W0 | T-04-05 |
| HOOK-05 | `reject_reason` closed atom set | unit | `mix test test/mailglass/webhook/providers/postmark_test.exs -x` | ❌ W0 | T-04-05 |
| HOOK-06 | Ingest one-Multi: webhook_events insert + N events insert + Projector update + status flip; orphan path inserts events with `delivery_id: nil + needs_reconciliation: true`; PubSub broadcast post-commit | integration | `mix test test/mailglass/webhook/ingest_test.exs -x` | ❌ W0 | T-04-06 |
| HOOK-06 | `SET LOCAL statement_timeout = '2s'; lock_timeout = '500ms'` fires inside transact (uses `pg_sleep(3.0)`) | integration | `mix test test/mailglass/webhook/ingest_test.exs -x` | ❌ W0 | T-04-06 |
| HOOK-07 | StreamData 1000-replay convergence property: any sequence of (webhook_event, replay_count 1..10) converges to single-application state | property (1000 runs) | `mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors` | ❌ W0 | T-04-06 |
| TEST-03 | Property: signature failure raises EXACTLY ONE of 7 `SignatureError.type` atoms; no partial DB writes | property | `mix test test/mailglass/properties/webhook_signature_failure_test.exs -x` | ❌ W0 | T-04-04 |
| TEST-03 | Property: tenant resolution via SingleTenant + ResolveFromPath stamps correctly; bad strategy raises `%TenancyError{type: :webhook_tenant_unresolved}` | property | `mix test test/mailglass/properties/webhook_tenant_resolution_test.exs -x` | ❌ W0 | T-04-07 |
| Reconciler | Orphan event + later Delivery commit → Reconciler appends `:reconciled` event within 5 min cron tick | integration | `mix test test/mailglass/webhook/reconciler_test.exs -x` | ❌ W0 | — |
| Pruner | Daily cron deletes succeeded `mailglass_webhook_events` older than retention (D-15) | integration | `mix test test/mailglass/webhook/pruner_test.exs -x` | ❌ W0 | — |
| Telemetry | All 5 webhook spans emit; metadata is whitelist-conformant (zero PII keys) | integration | `mix test test/mailglass/webhook/plug_test.exs` + `test/mailglass/webhook/reconciler_test.exs` (named tests) | ❌ W0 | T-04-08 |
| Phase UAT | Combined Phase 4 success criteria pass | integration (UAT) | `mix verify.phase_04` (NEW alias) | ❌ W0 | — |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*W0 = file does not exist; Wave 0 plan creates it.*

---

## Wave 0 Requirements

All test infrastructure is NEW for Phase 4. Wave 0 setup includes:

- [ ] `test/support/webhook_case.ex` — extend Phase 3 stub with D-26 helpers (`mailglass_webhook_conn/3`, `assert_webhook_ingested/3`, `stub_postmark_fixture/1`, `stub_sendgrid_fixture/1`, `freeze_timestamp/1`)
- [ ] `test/support/webhook_fixtures.ex` — generate test ECDSA P-256 keypair via `:crypto.generate_key/2`; sign helpers per RESEARCH.md Pattern 2
- [ ] `test/support/fixtures/webhooks/postmark/*.json` — 5 fixtures (delivered, bounced, opened, clicked, spam_complaint)
- [ ] `test/support/fixtures/webhooks/sendgrid/*.json` — 2 fixtures (single event + batch of 5)
- [ ] `priv/repo/migrations/00000000000003_mailglass_webhook_events.exs` — 8-line wrapper that calls `Mailglass.Migration.up()`
- [ ] `lib/mailglass/migrations/postgres/v02.ex` — D-15 DDL: create `mailglass_webhook_events` table + UNIQUE + status partial index; drop `mailglass_events.raw_payload`
- [ ] `lib/mailglass/migrations/postgres.ex` — bump `@current_version` from 1 to 2
- [ ] `mix.exs` — add `:public_key` to `extra_applications`; add `verify.phase_04` alias mirroring `verify.phase_03`
- [ ] `lib/mailglass/repo.ex` — add `query!/2` passthrough delegate (no SQLSTATE translation; raw passthrough)
- [ ] `lib/mailglass/events/event.ex` — add `:reconciled` to `@mailglass_internal_types` (one-line change)
- [ ] `docs/api_stability.md` — extend §Error types (`SignatureError` 4→7 atoms; `TenancyError` +1; `ConfigError` +1) + §Tenancy behaviour + §Telemetry catalog + new §Webhook section

**Framework install:** None (StreamData 1.3 already in deps; ExUnit is stdlib).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Postmark webhook fixture from a real Postmark sandbox account passes verification end-to-end | HOOK-03, HOOK-05 | Requires live Postmark account credentials — out of CI scope | Capture a fixture from a Postmark dev sandbox; place under `test/support/fixtures/webhooks/postmark/_real/`; run `mix test --include real_provider`; mark `@tag :real_provider` so default suite skips |
| Real SendGrid webhook fixture from a real SendGrid sandbox account passes ECDSA verification | HOOK-04, HOOK-05 | Requires live SendGrid account + their actual signing keypair — out of CI scope | Same as Postmark; daily cron + `workflow_dispatch` per CLAUDE.md "real-provider sandbox tests are advisory only" |
| Phoenix endpoint integration in a host app (router import + endpoint body_reader wiring) | HOOK-01, HOOK-02 | Requires a real downstream Phoenix app — covered partially by integration tests using `Mailglass.TestEndpoint` | Documented in `guides/webhooks.md`; covered by Phase 7 installer smoke test |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
