---
phase: 04-webhook-ingest
plan: 09
subsystem: webhook
tags: [stream_data, property_test, uat, phase_04_sign_off, guides, docs, hook_07, test_03, d27]

# Dependency graph
requires:
  - phase: 04-webhook-ingest
    plan: 01
    provides: "Mailglass.WebhookCase + WebhookFixtures + 7 fixture JSONs (payload-only, sig-at-build); verify.phase_04 mix alias that finally runs tests in this plan"
  - phase: 04-webhook-ingest
    plan: 02
    provides: "Postmark.verify!/3 + normalize/2 (+ :malformed_header / :bad_credentials atoms exercised by property test); SignatureError 7-atom closed set"
  - phase: 04-webhook-ingest
    plan: 03
    provides: "SendGrid.verify!/3 + normalize/2 (ECDSA P-256) used by UAT Criterion 1 SendGrid roundtrip"
  - phase: 04-webhook-ingest
    plan: 04
    provides: "Mailglass.Webhook.Plug + response code matrix (401/422/500) exercised by UAT Criterion 2"
  - phase: 04-webhook-ingest
    plan: 05
    provides: "Mailglass.Tenancy.SingleTenant + ResolveFromPath + formal @optional_callback resolve_webhook_tenant/1 — all three exercised by webhook_tenant_resolution_test property"
  - phase: 04-webhook-ingest
    plan: 06
    provides: "Ingest.ingest_multi/3 — the unit-of-work for HOOK-07 1000-replay convergence property"
  - phase: 04-webhook-ingest
    plan: 07
    provides: "Reconciler + Pruner (documented in guides/webhooks.md §5 + §6)"
  - phase: 04-webhook-ingest
    plan: 08
    provides: "Mailglass.Webhook.Telemetry 6-event catalog (documented in guides/webhooks.md §3 telemetry table)"
  - phase: 02-persistence-tenancy
    provides: "idempotency_convergence_test pattern (Sandbox :auto + TRUNCATE between iterations) — mirrored for HOOK-07"
provides:
  - "test/mailglass/properties/webhook_idempotency_convergence_test.exs — HOOK-07 1000-replay convergence property (~33s)"
  - "test/mailglass/properties/webhook_signature_failure_test.exs — TEST-03 D-27 #2 closed-atom property (5 mutations × 200 runs)"
  - "test/mailglass/properties/webhook_tenant_resolution_test.exs — TEST-03 D-27 #3 (SingleTenant/ResolveFromPath/BadTenancy dispatcher)"
  - "test/mailglass/webhook/core_webhook_integration_test.exs — @moduletag :phase_04_uat gate; 5 describe blocks mapping ROADMAP §Phase 4 success criteria 1:1; 11 tests"
  - "guides/webhooks.md — 433-line first adopter-facing guide (9 sections)"
  - "mix verify.phase_04 now exits 0 with 11 tagged tests — Phase 4 formal sign-off marker"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Webhook StreamData property test shape: use ExUnit.Case, async: false + ExUnitProperties + Sandbox.mode(TestRepo, :auto) + TRUNCATE CASCADE between iterations; mirrors Phase 2 idempotency_convergence_test. 1000 runs complete in ~33s on a typical dev laptop."
    - "Property test DB access uses Mailglass.TestRepo for aggregate/count — Mailglass.Repo is a deliberately narrow 9-function facade (no aggregate/2). Same convention as Plan 04-06's ingest_test.exs."
    - "Phase UAT gate pattern (Phase 3 template → Phase 4 extension): @moduletag :phase_04_uat on the full test module; one describe block per ROADMAP §Phase N success criterion; mix verify.phase_XX alias uses --only phase_XX_uat to pick up the moduletag across any file in the tree."
    - "Module-qualified fixture calls in new tests (Mailglass.WebhookFixtures.load_{postmark,sendgrid}_fixture/1) per the documented WebhookCase using-opts import-propagation workaround from Plan 04-02 SUMMARY."
    - "Closed-atom property assertion: `assert e.type in @valid_atoms` across generated mutation space — makes future atom-set extensions/removals immediately visible via failing property runs."
    - "Structural convergence invariant: `webhook_event_count == |unique provider_event_ids|` regardless of replay_count — UNIQUE(provider, provider_event_id) at the DB level enforces, the property verifies application code respects the constraint under every input shape."

key-files:
  created:
    - "test/mailglass/properties/webhook_idempotency_convergence_test.exs"
    - "test/mailglass/properties/webhook_signature_failure_test.exs"
    - "test/mailglass/properties/webhook_tenant_resolution_test.exs"
    - "test/mailglass/webhook/core_webhook_integration_test.exs"
    - "guides/webhooks.md"
  modified: []

key-decisions:
  - "CLAUDE'S DISCRETION — convergence property asserts a STRUCTURAL invariant (webhook_event_count == |unique provider_event_ids|), NOT a row-by-row snapshot equality. The Phase 2 idempotency_convergence_test uses a snapshot map keyed by idempotency_key because it's testing the mailglass_events partial UNIQUE index. This plan's HOOK-07 tests the UNIQUE(provider, provider_event_id) index on mailglass_webhook_events — structural cardinality is the right assertion shape. Document change: row-count equality captures the same convergence guarantee without the snapshot diffing overhead."
  - "CLAUDE'S DISCRETION — signature failure property restricted to Postmark (not SendGrid). SendGrid's verify!/3 is already exhaustively tested by test/mailglass/webhook/providers/sendgrid_test.exs (32 tests across 4 describe blocks covering all 7 SignatureError atoms). The property test's value is in exhausting Postmark's Basic-Auth mutation space with 5 orthogonal variants × 200 runs = 1000 synthetic attacker requests, which is harder to hand-enumerate. Scope decision documented in the test's @moduledoc."
  - "CLAUDE'S DISCRETION — tenant_resolution property includes 3 describe blocks (not 1 long property). StreamData generators don't compose cleanly across Tenancy modules (SingleTenant + ResolveFromPath + BadTenancy each have different callback semantics), so splitting into per-module properties keeps each generator focused + the failures interpretable. Plus one non-property `test` block locks the TenancyError.new/2 contract (the boundary the Plug rescues against)."
  - "BadTenancy stub inside a defmodule inside a describe block — keeps the stub colocated with its single usage and avoids polluting test/support/. Same pattern Plan 04-04 used for UnresolvedTenancy."
  - "UAT guide structure follows the Phase 3 core_send_integration_test.exs template: @moduletag at the top; one describe per ROADMAP criterion; happy-path tests reference the property files but don't re-run them (they're `@tag :property` elsewhere in the suite; avoiding duplication)."
  - "guides/webhooks.md intentionally includes a forward reference to v0.5 async ingest (§7) because CONTEXT D-11 already documents the :async reservation and adopters hitting >1s normalize latency need to know the v0.5 path. Other forward-refs (v0.5 first-class auto-suppression, v0.5 DLQ admin) stay light to avoid promising features we haven't finalized."
  - "Module-qualified fixture calls in core_webhook_integration_test.exs (Mailglass.WebhookFixtures.load_postmark_fixture/1) per Plan 04-02's documented WebhookCase using-opts import-propagation workaround. The `stub_postmark_fixture/1` shim in WebhookCase doesn't reliably land in the test module's scope when `use Mailglass.MailerCase, unquote(opts)` is in the same `quote do` block. This is a known limitation tracked for a future plan to debug."
  - "UAT test Criterion 4 includes a telemetry handler test asserting D-23 whitelist compliance (refute Map.has_key?(meta, :ip/:raw_payload/:recipient/:email)) — T-04-04 mitigation cross-validated at the phase gate in addition to the Plan 04-08 unit tests."
  - "Criterion 5 (unmapped → :unknown + Logger.warning) uses ExUnit.CaptureLog.with_log/1 rather than :telemetry handlers — Logger output is the human-readable audit surface the ROADMAP criterion specifies. The three sub-tests (Postmark unmapped RecordType, SendGrid unmapped event, Anymail closed set) cover both providers + the closed-atom contract."

patterns-established:
  - "Phase sign-off SUMMARY structure: three property test files (one per D-27 criterion) + one UAT integration test + one adopter-facing guide = the standard phase-closing plan shape. Phase 5+ plans close the same way."
  - "guides/ directory convention established by this plan — first guide ships here, not in docs/ (which is library-internal API stability lock), not in priv/ (which is runtime assets). Phase 7 DOCS-02 will consolidate/extend."

requirements-completed: [HOOK-07, TEST-03]

# Metrics
duration: 11min
completed: 2026-04-24
---

# Phase 4 Plan 9: Phase-Wide UAT + Property Tests + Adopter Guide Summary

**Three StreamData property tests closing HOOK-07 (1000-replay convergence) + TEST-03 D-27 (signature-failure closed-atom + tenant-resolution). One UAT integration test tagged `@moduletag :phase_04_uat` mapping 1:1 to ROADMAP §Phase 4's 5 success criteria — 11 tests, all green. First adopter-facing `guides/webhooks.md` (433 lines, 9 sections) covering install + multi-tenant + telemetry + IP allowlist + reconciliation + retention + statement_timeout runbook + response codes + testing helpers. `mix verify.phase_04` now exits 0 against real tagged tests — the Phase 4 formal sign-off marker.**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-04-24T02:19:59Z
- **Completed:** 2026-04-24T02:31:33Z
- **Tasks:** 2 (Task 1 = 3 property tests; Task 2 = UAT integration test + guide)
- **Commits:** 2 task commits (plus 1 metadata commit after this SUMMARY lands)
  - `33a0066` — test(04-09): 3 StreamData property tests for HOOK-07 + TEST-03
  - `5a673d7` — feat(04-09): Phase 4 UAT integration test + guides/webhooks.md
- **Files created:** 5 (3 property tests + 1 UAT test + 1 guide)
- **Files modified:** 0

## Accomplishments

### Task 1: Three StreamData property tests (commit `33a0066`)

- **`test/mailglass/properties/webhook_idempotency_convergence_test.exs` (NEW, 141 lines):** HOOK-07's 1000-replay convergence property (CONTEXT D-27 #1). Generator yields `(webhook_event, replay_count 1..10)` sequences of 1..10 events; the property asserts the structural invariant `webhook_event_count == |unique provider_event_ids|` regardless of replay_count. Uses `Sandbox.mode(TestRepo, :auto)` + `TRUNCATE ... CASCADE` between iterations (the Phase 2 idempotency_convergence_test pattern — DataCase's transaction wrapper deadlocks on 1000 iterations). Runs in ~33s on a typical dev laptop.

- **`test/mailglass/properties/webhook_signature_failure_test.exs` (NEW, 156 lines):** TEST-03 D-27 #2 — every Postmark signature failure raises exactly one of the seven `Mailglass.SignatureError.type` atoms (the 3 Phase 1 legacy atoms are retained in `@types` but are not reachable from `Postmark.verify!/3`). 5 mutation variants (`:missing_auth`, `:bearer_instead_of_basic`, `:malformed_base64`, `:wrong_user`, `:wrong_pass`) × `max_runs: 200` = 1000 synthetic attacker requests. Every iteration also asserts `TestRepo.aggregate(WebhookEvent, :count) == 0` — the verifier is pure; no partial DB writes regardless of which failure path raises.

- **`test/mailglass/properties/webhook_tenant_resolution_test.exs` (NEW, 147 lines):** TEST-03 D-27 #3 — tenant resolution property with three describe blocks:
  1. `SingleTenant.resolve_webhook_tenant/1` always returns `{:ok, "default"}` across 100 random context shapes.
  2. `ResolveFromPath.resolve_webhook_tenant/1` returns `{:ok, tid}` for any non-empty binary tenant_id (100 runs) and `{:error, :missing_path_param}` for absent/empty/other-key shapes (50 runs).
  3. A synthetic `BadTenancy` module returning `{:error, :always_broken}` flows through `Mailglass.Tenancy.resolve_webhook_tenant/1` cleanly (dispatcher contract); plus one non-property `test` pinning `TenancyError.new(:webhook_tenant_unresolved, ...)` message format.

### Task 2: Phase 4 UAT integration test + guides/webhooks.md (commit `5a673d7`)

- **`test/mailglass/webhook/core_webhook_integration_test.exs` (NEW, 327 lines):** The Phase 4 UAT gate. `@moduletag :phase_04_uat` makes `mix verify.phase_04` finally pick up real tests (the alias shipped in Plan 04-01 has been running zero-test passes through Plans 01-08). 5 describe blocks map 1:1 to ROADMAP §Phase 4 success criteria:
  - **§1 (verify + normalize):** Postmark delivered fixture passes Basic Auth + normalizes to `:delivered`; SendGrid single_event fixture ECDSA-verifies + every normalized event's `:type` is in the closed Anymail + internal 14-atom set.
  - **§2 (forged signature → 401):** Postmark wrong credentials → 401 + `Logger.warning` with `provider=postmark reason=bad_credentials` + T-04-04 PII-absence assertions (`refute log =~ body|"forgery"|"bad_pass"|"127.0.0.1"`). Plus a structural test asserting all 7 D-21 atoms are in `SignatureError.__types__()`.
  - **§3 (duplicate → 200):** Second `ingest_multi/3` call with same `provider_event_id` sets `duplicate: true` and does NOT insert a second `webhook_event` row or `event` row. Plus a pin on the HOOK-07 property file's `max_runs: 1000` string.
  - **§4 (orphan → needs_reconciliation):** Postmark bounce with no matching Delivery inserts `event` with `delivery_id: nil + needs_reconciliation: true`; `webhook_event.status` still flips to `:succeeded` (orphan is normal flow, not failure). Plus a telemetry handler test asserting `[:mailglass, :webhook, :orphan, :stop]` fires with D-23-whitelist-compliant metadata (no `:ip`, `:raw_payload`, `:recipient`, `:email`).
  - **§5 (unmapped → :unknown):** Postmark RecordType + SendGrid event both fall through to `:type = :unknown` with `Logger.warning`. Plus a closed-set assertion that every normalized event's type is in `Event.__types__()`.

  Total: **11 tests, 0 failures** in 1.6s.

- **`guides/webhooks.md` (NEW, 433 lines):** First adopter-facing webhook guide. 9 sections:
  1. **Install + endpoint wiring** — `Plug.Parsers` config with `CachingBodyReader`, router mount example, provider credential env setup. Includes the Plug.MULTIPART footgun note.
  2. **Multi-tenant patterns (D-12)** — all three strategies (SingleTenant default / ResolveFromPath URL-prefix sugar / custom behaviour callback) with example code + the ResolveFromPath composition requirement (T-04-08 mitigation).
  3. **Telemetry recipes** — table of all 6 webhook events + metadata keys per event; three recipes (signature-failure alerting, retry-storm detection, auto-suppression via telemetry handler chain — the D-25 recipe noting recipient-discovery via the ledger join because D-23 excludes PII from metadata).
  4. **IP allowlist (D-04)** — Postmark opt-in with trusted_proxies requirement + atom-keyed monitoring.
  5. **Orphan reconciliation (Oban cron)** — crontab example for Reconciler + Pruner; mix task fallback for Oban-less deploys.
  6. **Webhook event retention (Pruner)** — three-knob config with :infinity structural bypass + GDPR erasure pattern (raw SQL on `mailglass_webhook_events.raw_payload->>'to'`).
  7. **Statement timeout runbook (D-29)** — symptom → mitigation flow + v0.5 async escape hatch forward-reference.
  8. **Response code matrix** — 200/401/422/500 table + pattern-match-by-struct discipline note.
  9. **Testing helpers** — `Mailglass.WebhookCase` + `Mailglass.WebhookFixtures` usage example.

## Task Commits

Each task was committed atomically:

1. **Task 1: 3 StreamData property tests** — `33a0066` (test) — 3 files, 456 insertions.
2. **Task 2: UAT integration test + guide** — `5a673d7` (feat) — 2 files, 761 insertions.

**Plan metadata:** _pending final commit after SUMMARY.md + STATE.md + ROADMAP.md + REQUIREMENTS.md updates_.

## Files Created/Modified

### Created

- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` — HOOK-07 1000-replay convergence property
- `test/mailglass/properties/webhook_signature_failure_test.exs` — TEST-03 D-27 #2 closed-atom property
- `test/mailglass/properties/webhook_tenant_resolution_test.exs` — TEST-03 D-27 #3 tenant resolution property
- `test/mailglass/webhook/core_webhook_integration_test.exs` — Phase 4 UAT gate (5 describe blocks, 11 tests)
- `guides/webhooks.md` — 433-line adopter guide

### Modified

None.

## Decisions Made

(See `key-decisions` in frontmatter — full list of 9 decisions documented.)

Most load-bearing:

- **Structural-invariant convergence assertion** — `webhook_event_count == |unique provider_event_ids|` rather than snapshot-map diff. UNIQUE `(provider, provider_event_id)` on `mailglass_webhook_events` enforces the invariant at the DB level; the property verifies application code respects it under every input distribution. Simpler than the Phase 2 idempotency_convergence_test's per-key snapshot compare (which was testing a partial UNIQUE index on a different column set).
- **Signature failure property restricted to Postmark** — SendGrid's crypto path is already exhaustively tested by `sendgrid_test.exs` (32 tests); Postmark's Basic-Auth mutation space is harder to hand-enumerate, so 1000 StreamData runs per Postmark variant is where the property adds marginal value.
- **Module-qualified fixture calls** — per Plan 04-02's documented `ExUnit.CaseTemplate using opts do` import-propagation workaround. `Mailglass.WebhookFixtures.load_postmark_fixture/1` instead of the `stub_postmark_fixture/1` import shim. Cleaner test call-site + sidesteps a known CaseTemplate flake until a future plan debugs it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] `Mailglass.Repo.aggregate/2` doesn't exist**

- **Found during:** Task 1 first test run (both the signature_failure and idempotency_convergence tests).
- **Issue:** The plan's verbatim action text used `Repo.aggregate(WebhookEvent, :count)` in both property tests, but `Mailglass.Repo` is a deliberately narrow 9-function facade (transact/insert/update/delete/multi/one/all/get/query!/delete_all — no `aggregate/2`). Documented in Plan 04-06 SUMMARY decisions list ("tests reach around via TestRepo since they're not library code").
- **Fix:** Replaced `Repo.aggregate` with `TestRepo.aggregate` throughout both property tests. Same convention as Plan 04-06's `ingest_test.exs` + Phase 3's `core_send_integration_test.exs`.
- **Files modified:** `test/mailglass/properties/webhook_signature_failure_test.exs`, `test/mailglass/properties/webhook_idempotency_convergence_test.exs`.
- **Verification:** `mix test test/mailglass/properties/ --warnings-as-errors --exclude flaky` → 7 properties + 1 test, 0 failures.
- **Committed in:** `33a0066` (Task 1 commit — caught before the initial commit landed).

**2. [Rule 1 — Bug] `alias Mailglass.Webhook.{Plug, WebhookEvent}` shadows the canonical `Plug` module**

- **Found during:** Task 2 first test run (Criterion 2 401 test).
- **Issue:** The UAT test used `alias Mailglass.Webhook.{Plug, WebhookEvent}` and then called `Plug.Test.conn(...)` + `Plug.Conn.put_req_header(...)` expecting the built-in Plug. Elixir's alias rules map those calls to `Mailglass.Webhook.Plug.Test.conn/3` — a non-existent module.
- **Fix:** Changed to `alias Mailglass.Webhook.Plug, as: WebhookPlug` + updated the call sites. The conn construction then resolves `Plug.Test.conn/3` + `Plug.Conn.put_req_header/3` correctly against the top-level Plug library.
- **Files modified:** `test/mailglass/webhook/core_webhook_integration_test.exs` (alias + 2 call sites).
- **Verification:** All 11 UAT tests now pass.
- **Committed in:** `5a673d7` (Task 2 commit — caught before the commit landed).

**3. [Rule 1 — Bug] `with_log(fn -> {result, :ok} end)` shape confusion in Criterion 5 Postmark test**

- **Found during:** Task 2 first test run (Criterion 5 Postmark unmapped).
- **Issue:** I wrote `with_log(fn -> {Postmark.normalize(body, []), :ok} end)` expecting a tuple return, then tried to destructure `{[event], log}`. But `with_log/1` returns `{inner_fn_return, log_string}` — so the actual return was `{{[event], :ok}, log_string}`, and the outer destructure failed with `MatchError`.
- **Fix:** Simplified to `{events, log} = with_log(fn -> Postmark.normalize(body, []) end)` + `assert [event] = events` on the next line. Standard `with_log/1` contract.
- **Files modified:** `test/mailglass/webhook/core_webhook_integration_test.exs` (one test block).
- **Verification:** All 11 UAT tests pass.
- **Committed in:** `5a673d7`.

**4. [Rule 1 — Bug] Bogus `Map.get(%{sendgrid_keypair: :todo}, ...)` in Criterion 1 SendGrid test**

- **Found during:** Task 2 first test run.
- **Issue:** While sketching the SendGrid UAT test, I left in a placeholder `{pub_b64, _} = Map.get(%{sendgrid_keypair: :todo}, :sendgrid_keypair, {nil, nil})` line that always returned `:todo` — a MatchError when destructured as a tuple.
- **Fix:** Removed the placeholder. Use the test parameter's `%{sendgrid_keypair: {pub_b64, priv_key}}` destructure directly (WebhookCase setup provides the keypair via `{:ok, sendgrid_keypair: {pub_b64, priv_key}}`).
- **Files modified:** `test/mailglass/webhook/core_webhook_integration_test.exs`.
- **Verification:** All 11 UAT tests pass.
- **Committed in:** `5a673d7`.

---

**Total deviations:** 4 auto-fixed (4 × Rule 1 bug). All four were caught before the Task 2 commit landed — no deviation-fix commit needed. Scope unchanged; plan's architectural intent preserved.

## TDD Gate Compliance

Not applicable — this plan has `type: execute` (not `type: tdd`). Tasks use `type="auto"` shape with `<verify>` gates running `mix test`.

## Threat Flags

None. The plan adds test coverage + documentation only; no new runtime surface. The `threat_model` block in the PLAN (T-04-02 replay, T-04-04 info disclosure) is mitigated at the code sites Plans 04-01..08 shipped — this plan's property tests ASSERT those mitigations hold across the generated input space, and the UAT Criterion 4 telemetry test cross-validates the D-23 whitelist at the phase-gate.

## Issues Encountered

- **`ExUnit.CaseTemplate using opts do` import-propagation flake** — still unresolved since Plan 04-02 first documented it. The UAT integration test uses module-qualified `Mailglass.WebhookFixtures.load_postmark_fixture/1` calls instead of the WebhookCase-imported `stub_postmark_fixture/1` shim. Investigate in a future plan; out of scope here.
- **Pre-existing citext OID staleness in full-suite cold-start runs** — unchanged since Phase 2 Plan 06; tracked in `.planning/phases/02-persistence-tenancy/deferred-items.md`. Plan-level `mix verify.phase_04` passes clean (11/0); the UAT gate is isolated from the citext flake.
- **`mix verify.phase_04` requires `MIX_ENV=test`** — matches Plans 04-01..08 documentation; local invocation: `POSTGRES_USER=jon POSTGRES_PASSWORD='' MIX_ENV=test mix verify.phase_04`.

## User Setup Required

None. Phase 4 is library-only + documentation. Adopter config keys (`config :mailglass, :postmark, :sendgrid, :tenancy, :webhook_retention`) are documented in `guides/webhooks.md` and `docs/api_stability.md`.

## Next Phase Readiness

Plan 04-09 closes Phase 4. Downstream dependencies:

- **Phase 5 (Dev Preview LiveView)** — admin UI reads the PubSub broadcasts Phase 4 emits post-commit (`{:delivery_updated, delivery_id, event_type, meta}`). The Plug's `broadcast_post_commit/1` (Plan 04-04) is the contract; Phase 5 LiveView subscribes to `Mailglass.PubSub.Topics.events(tenant_id)` and renders the live delivery stream.
- **Phase 6 LINT checks** — three forward-references locked in Phase 4 SUMMARYs:
  - **LINT-02** (`NoPiiInTelemetryMeta`) — single target module `Mailglass.Webhook.Telemetry` (Plan 04-08) + its 3 callers (Plug, Reconciler, Ingest). Plan 04-08 SUMMARY documents the exact scan target.
  - **LINT-10** (single-emit whitelist) — locked to three paths: `[:mailglass, :webhook, :normalize | :orphan | :duplicate, :stop]`. Plan 04-08 SUMMARY documents the whitelist spec.
  - **LINT-12** (no direct `DateTime.utc_now/0`) — Plan 04-06's Ingest uses `Mailglass.Clock.utc_now/0` throughout; this phase contributes the final usage pattern.
- **Phase 7 DOCS-02** — `guides/webhooks.md` shipped in this plan is the first of 9 planned guides; Phase 7 extends/consolidates but does not replace.
- **v0.5 reserved for** first-class auto-suppression (DELIV-02), Mailgun/SES/Resend providers, `:webhook_ingest_mode: :async` + DLQ admin, and `mailglass_inbound` (Action Mailbox equivalent). All three are noted in the guide with forward-references.

**Blockers or concerns:** None. Phase 4 is fully shipped.

**Phase 4 progress:** 9 of 9 plans complete. **Phase 4 SHIPPED.**

## Self-Check: PASSED

Verified:

- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` — FOUND (141 lines; `max_runs: 1000` present)
- `test/mailglass/properties/webhook_signature_failure_test.exs` — FOUND (156 lines; `@valid_atoms` assertion present)
- `test/mailglass/properties/webhook_tenant_resolution_test.exs` — FOUND (147 lines; 3 describe blocks)
- `test/mailglass/webhook/core_webhook_integration_test.exs` — FOUND (327 lines; `@moduletag :phase_04_uat` present; 5 describe blocks)
- `guides/webhooks.md` — FOUND (433 lines; all 6 required grep terms present: `Mailglass.Webhook.Router`, `Mailglass.Webhook.CachingBodyReader`, `auto-suppress`, `ip_allowlist`, `statement_timeout`, `Mailglass.Tenancy.ResolveFromPath`)
- Commit `33a0066` (Task 1 — 3 property tests) — FOUND in `git log`
- Commit `5a673d7` (Task 2 — UAT test + guide) — FOUND
- `mix compile --warnings-as-errors --no-optional-deps` → exits 0
- `mix test test/mailglass/properties/ --warnings-as-errors --exclude flaky` → 7 properties + 1 test, 0 failures (51.3s)
- `mix test test/mailglass/webhook/core_webhook_integration_test.exs --warnings-as-errors` → 11 tests, 0 failures (0.4s)
- `mix test test/mailglass/webhook/ --warnings-as-errors --exclude flaky --include requires_oban` → 124 tests, 0 failures (1.4s)
- `mix verify.phase_04` → 11 tests, 0 failures (631 excluded) — **the Phase 4 UAT gate runs against real tests for the first time.**
- `mix verify.phase_03` → 62 tests, 0 failures, 2 skipped (unchanged)
- `mix verify.phase_02` → 59 tests, 0 failures (unchanged)
- `grep -c "describe " test/mailglass/webhook/core_webhook_integration_test.exs` → 5 (one per ROADMAP §Phase 4 success criterion)
- `wc -l guides/webhooks.md` → 433 (≥200 required)

---
*Phase: 04-webhook-ingest*
*Completed: 2026-04-24*
*Phase 4 SHIPPED — 9 of 9 plans complete.*
