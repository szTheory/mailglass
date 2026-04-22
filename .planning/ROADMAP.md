# Roadmap: mailglass

**Defined:** 2026-04-21
**Granularity:** standard (config.json)
**Milestone:** v0.1 (validation release — `mailglass` core + `mailglass_admin` dev preview only)
**Sibling package out of milestone:** `mailglass_inbound` (v0.5+, not roadmapped here)

## Overview

mailglass v0.1 ships in 7 phases tracing the 7-layer build order from `research/SUMMARY.md`. The spine is dependency-forced: zero-dep foundations and pure rendering first, then the immutable event ledger and multi-tenancy (which cannot be retrofitted per D-09), then the Fake adapter (built FIRST per D-13) plus the send pipeline, then webhook ingest (Postmark + SendGrid only per D-10), then the dev-only preview LiveView (`mailglass_admin` v0.1 per D-11), then custom Credo checks refined against real code, then the installer + CI/CD + docs (built last so installer goldens lock the public API). All 84 v1 REQ-IDs map to exactly one phase. Three phases are flagged for `/gsd-research-phase` before planning (Phase 2, 4, 5).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work.
- Decimal phases (2.1, 2.2): Urgent insertions (added later via `/gsd-insert-phase`, never planned upfront).

- [ ] **Phase 1: Foundation** - Zero-dep modules + pure HEEx renderer pipeline ("render an email from HEEx" milestone).
- [ ] **Phase 2: Persistence + Tenancy** - Append-only event ledger with SQLSTATE 45A01 trigger + multi-tenant schemas from day one.
- [ ] **Phase 3: Transport + Send Pipeline** - Fake adapter built first (D-13), then end-to-end Mailable → Outbound → Worker → Adapter → Multi(Delivery + Event) hot path.
- [ ] **Phase 4: Webhook Ingest** - Postmark + SendGrid HMAC-verified, idempotent, Anymail-normalized event ingest.
- [ ] **Phase 5: Dev Preview LiveView** - `mailglass_admin` sibling package with mailable sidebar, `preview_props/1` auto-discovery, device + dark toggles, HTML/Text/Raw/Headers tabs.
- [ ] **Phase 6: Custom Credo + Boundary** - Twelve domain-rule lint checks plus `boundary` enforcement, refined against real code.
- [ ] **Phase 7: Installer + CI/CD + Docs** - `mix mailglass.install` with golden-diff CI, full GHA pipeline, ExDoc with 9 guides + doctest contracts.

## Phase Details

### Phase 1: Foundation
**Goal**: Zero-dep modules every later layer depends on are in place, and a pure-function HEEx renderer pipeline can render `MyApp.UserMailer.welcome(user)` to inlined-CSS HTML + plaintext without persistence or transport.
**Depends on**: Nothing (first phase)
**Requirements**: CORE-01, CORE-02, CORE-03, CORE-04, CORE-05, CORE-06, CORE-07, AUTHOR-02, AUTHOR-03, AUTHOR-04, AUTHOR-05, COMP-01, COMP-02
**Success Criteria** (what must be TRUE):
  1. A developer can call `Mailglass.Renderer.render(message)` on a HEEx-based mailable and receive `{html_body, text_body}` with CSS inlined and plaintext auto-generated, in under 50ms for a typical template.
  2. `Mailglass.Components` (`<.container>`, `<.section>`, `<.row>`, `<.column>`, `<.heading>`, `<.text>`, `<.button>`, `<.img>`, `<.link>`, `<.hr>`, `<.preheader>`) render with MSO Outlook VML fallbacks and require zero Node toolchain at any point.
  3. `mix compile --no-optional-deps --warnings-as-errors` passes against the v0.1 required-deps-only set; optional deps (`oban`, `opentelemetry`, `mjml`, `gen_smtp`, `sigra`) route through `Mailglass.OptionalDeps.*` gateway modules.
  4. A `Mailglass.Error` raised by any v0.1 surface area is pattern-matchable by struct (`%SendError{}`, `%TemplateError{}`, `%SignatureError{}`, `%SuppressedError{}`, `%RateLimitError{}`, `%ConfigError{}`) without parsing the message string; the closed `:type` atom set is documented in `api_stability.md`.
  5. Every `:telemetry.execute/3` call emitted by mailglass uses the 4-level `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]` convention with metadata keys drawn only from the whitelisted set; a telemetry handler that raises does not break the pipeline.
**Pitfalls guarded against**: LIB-02 (compile-time dep explosion via `compile_env`), LIB-07 (only `Config` may use `compile_env`), OBS-01 (PII in telemetry — whitelist enforced from day one), OBS-04 (logger PII), DIST-04 (optional dep gateway pattern locked here so later phases cannot leak), MAINT-04 (Premailex flagged as MEDIUM-confidence "watch this dep").
**Plans**: 6 plans
Plans:
- [x] 01-01-PLAN.md — Project scaffold, deps, Boundary compiler, Wave 0 test stubs
- [x] 01-02-PLAN.md — Error hierarchy (6 defexception structs + namespace behaviour + api_stability.md)
- [x] 01-03-PLAN.md — Config (NimbleOptions), Telemetry (span helpers), Repo (transact/1), IdempotencyKey
- [x] 01-04-PLAN.md — Message struct + OptionalDeps gateway modules (Oban, OTel, MJML, GenSmtp, Sigra)
- [x] 01-05-PLAN.md — Components (11 HEEx components + Layout + golden VML fixture test)
- [ ] 01-06-PLAN.md — TemplateEngine behaviour + HEEx impl + Renderer pipeline + Compliance + Gettext
**UI hint**: no

### Phase 2: Persistence + Tenancy
**Goal**: The append-only event ledger exists, the SQLSTATE 45A01 immutability trigger fires on every UPDATE/DELETE attempt, and `tenant_id` lives on every mailglass-owned schema so multi-tenancy is structural rather than retrofitted.
**Depends on**: Phase 1
**Requirements**: PERSIST-01, PERSIST-02, PERSIST-03, PERSIST-04, PERSIST-05, PERSIST-06, TENANT-01, TENANT-02
**Success Criteria** (what must be TRUE):
  1. `assert_raise EventLedgerImmutableError, fn -> Repo.update(event) end` and the equivalent `Repo.delete/1` test both pass against the live `mailglass_events` schema (SQLSTATE 45A01 from `mailglass_raise_immutability` trigger).
  2. A StreamData property test generates 1000 sequences of `(webhook_event, replay_count_1..10)` and asserts that applying any sequence converges to the same final state as applying each event once (idempotency `UNIQUE` partial index on `idempotency_key WHERE idempotency_key IS NOT NULL` plus `on_conflict: :nothing`).
  3. `mailglass_deliveries`, `mailglass_events`, and `mailglass_suppressions` each have a `tenant_id` column (indexed; nullable for single-tenant mode), and `Mailglass.Tenancy.SingleTenant` is the default no-op resolver.
  4. Calling `Mailglass.Events.append/2` outside an `Ecto.Multi` raises `ArgumentError` — there is no other public path to write the event ledger.
  5. An adopter runs `mix mailglass.gen.migration` (or the migration block embedded in the installer) and `mix ecto.migrate` brings the three schemas + the immutability trigger into existence.
**Pitfalls guarded against**: MAIL-03 (idempotency), MAIL-07 (suppression `:scope` enum has no default), MAIL-09 (provider `message_id` collision — UNIQUE on `(provider, provider_message_id)`), PHX-04 (no FKs to adopter tables; polymorphic `(owner_type, owner_id)`), PHX-05 partial (tenant column lives everywhere — Credo enforcement comes in Phase 6).
**Research flag**: yes — `/gsd-research-phase` before planning. Open questions: `metadata jsonb` projection columns shape; orphan-webhook reconciliation worker cadence; whether to adopt `:typed_struct` / `:typed_ecto_schema` given Elixir 1.18+ set-theoretic types; status state machine app-enforced vs DB check constraint (recommend app-enforced — see SUMMARY.md Q6).
**Plans**: TBD
**UI hint**: no

### Phase 3: Transport + Send Pipeline
**Goal**: The Fake adapter (built FIRST per D-13) is the merge-blocking release gate, and the full hot path — `Mailable → Outbound → preflight (suppression + rate-limit + stream policy) → render → Multi(Delivery + Event(:queued) + Worker enqueue) → Adapter → Multi(Delivery update + Event(:dispatched))` — is testable end-to-end against Fake without any real provider.
**Depends on**: Phase 2
**Requirements**: AUTHOR-01, TRANS-01, TRANS-02, TRANS-03, TRANS-04, SEND-01, SEND-02, SEND-03, SEND-04, SEND-05, TRACK-01, TRACK-03, TEST-01, TEST-02, TEST-05
**Success Criteria** (what must be TRUE):
  1. An adopter writes `defmodule MyApp.UserMailer do; use Mailglass.Mailable; def welcome(user), do: ...; end`, calls `Mailglass.Outbound.deliver/2`, and the Fake adapter records the message; `Mailglass.TestAssertions.assert_mail_sent/1` asserts on it in fewer than 20 lines of test code.
  2. `Mailglass.Outbound.deliver_later/2` enqueues an Oban job when `:oban` is loaded; without Oban it falls back to `Task.Supervisor.async_nolink` and emits exactly one `Logger.warning` at boot — both code paths return `{:ok, %Delivery{}}`.
  3. `Mailglass.Outbound.deliver_many/2` survives partial failure: a batch where the third recipient errors records two successful `Delivery` rows + one `%SendError{}` and re-running the batch produces no duplicate deliveries (idempotency key replay).
  4. Open and click tracking are off by default — no tracking pixel injection or link rewriting unless `tracking: [opens: true, clicks: true]` is explicitly set per-mailable (the `NoTrackingOnAuthStream` Credo enforcement lands in Phase 6).
  5. `Mailglass.RateLimiter` enforces a per-`(tenant_id, recipient_domain)` ETS-backed token bucket; exceeding the configured limit returns `{:error, %RateLimitError{retry_after_ms: int}}` and the `mix verify.core_send` alias runs the full pipeline against Fake.
**Pitfalls guarded against**: LIB-01 (≤20-line `use` macro — Credo check lands Phase 6), LIB-03 (return-type stability locked in `api_stability.md`), LIB-04 (tuple returns for adapters), LIB-05 (no `name: __MODULE__` singletons; rate limiter is small supervisor child owning ETS), LIB-06 (renderer + Swoosh bridge are pure), MAIL-01 (tracking off by default), TEST-01 (Fake first, Mox not used for transport), TEST-06 (`Mailglass.Clock` injection point).
**Plans**: TBD
**UI hint**: no

### Phase 4: Webhook Ingest
**Goal**: A Postmark or SendGrid webhook arriving at `/webhooks/<provider>` is HMAC-verified, parsed to the Anymail event taxonomy verbatim, written through one `Ecto.Multi` (Event row + Delivery projection update + PubSub broadcast), and replayed N times converges to the same state as applying once.
**Depends on**: Phases 2 and 3
**Requirements**: HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05, HOOK-06, HOOK-07, TEST-03
**Success Criteria** (what must be TRUE):
  1. A real Postmark webhook payload (sample fixture) and a real SendGrid webhook payload pass HMAC verification (Basic Auth + IP for Postmark; ECDSA via OTP `:crypto` for SendGrid) and produce normalized `:queued | :sent | :rejected | :failed | :bounced | :deferred | :delivered | :autoresponded | :opened | :clicked | :complained | :unsubscribed | :subscribed | :unknown` events with `reject_reason ∈ :invalid | :bounced | :timed_out | :blocked | :spam | :unsubscribed | :other | nil`.
  2. A forged webhook signature raises `Mailglass.SignatureError` at the call site with no recovery path, returns 401, and records a telemetry event (the `Logger.warning` audit happens too).
  3. A duplicate webhook (same `idempotency_key`) returns 200 OK and produces zero new event rows; the StreamData property test on 1000 replay sequences passes (TEST-03).
  4. An orphan webhook (no matching `delivery_id`) inserts an event row with `delivery_id: nil` + `needs_reconciliation: true` rather than failing — orphan-rate is observable via telemetry.
  5. Per-provider mappers exhaustively case on the provider's event vocabulary; an unmapped event type falls through to `:unknown` only after a `Logger.warning` (no silent catch-all).
**Pitfalls guarded against**: MAIL-03 (idempotency end-to-end), MAIL-08 (Anymail taxonomy verbatim per D-14, no silent `_ -> :hard_bounce`), HOOK-04 (200 OK on replay, 401 only on actual signature mismatch), OBS-02 (webhook telemetry never logs raw payload), OBS-05 (signature failure logged without leaking payload).
**Research flag**: yes — `/gsd-research-phase` before planning. Open questions: SendGrid ECDSA verification using OTP 27 `:crypto` exact API; `Mailglass.Webhook.CachingBodyReader` interaction with Plug 1.18 body-reader chain; orphan reconciliation worker scope and cadence (need empirical Postmark + SendGrid orphan rates first).
**Plans**: TBD
**UI hint**: no

### Phase 5: Dev Preview LiveView
**Goal**: A Phoenix 1.8 adopter mounts `mailglass_admin_routes "/dev/mail"` in their `:dev` router pipeline and sees a mailable sidebar (auto-discovered via `preview_props/1`) with a live-assigns form, device width toggle (mobile/tablet/desktop), dark/light toggle, and HTML/Text/Raw/Headers tabs — the v0.1 killer demo.
**Depends on**: Phase 3
**Requirements**: PREV-01, PREV-02, PREV-03, PREV-04, PREV-05, PREV-06, BRAND-01
**Success Criteria** (what must be TRUE):
  1. An adopter mounts the preview LiveView in `:dev` only (per D-11), reloads the browser after editing a mailable file, and sees the rendered email refresh without a full page reload (LiveReload integration).
  2. Every `Mailglass.Mailable` module that defines a `preview_props/1` callback appears in the sidebar with one entry per preview function and a live-editable assigns form per `preview_props/1` field.
  3. The HTML / Text / Raw / Headers tabs each render the corresponding artifact of the same `Mailglass.Renderer` output the production pipeline produces — no placeholder shape divergence.
  4. The UI conforms to the brand book (Ink/Glass/Ice/Mist/Paper/Slate palette, Inter + Inter Tight + IBM Plex Mono, mobile-first responsive, no glassmorphism / lens flares / literal broken-glass visuals; WCAG AA contrast verified) and ships daisyUI 5 + Tailwind v4 with no Node toolchain required of adopters.
  5. `mailglass_admin/priv/static/` is a committed compiled bundle, `git diff --exit-code` after `mix mailglass_admin.assets.build` passes in CI, and the Hex tarball stays under 2MB.
**Pitfalls guarded against**: PHX-02 (mount path is the adopter's first arg, no default; relative routes throughout), PHX-03 (admin assets in `mailglass_admin/priv/static/` only — Hex tarball size CI gate <500KB core / <2MB admin), PHX-06 (PubSub topics namespaced `mailglass:` — `PrefixedPubSubTopics` Credo check lands Phase 6), DIST-01 (`mailglass_admin/mix.exs` declares `{:mailglass, "== <pinned_version>"}` — sibling versions never drift), DIST-02 (`git diff --exit-code` on `priv/static/` after asset build).
**Research flag**: yes — `/gsd-research-phase` before planning. Open questions: `MailglassAdmin.Router` macro signature should be prototyped against `~/projects/sigra/lib/sigra/admin/router.ex`; LiveView session cookie collision with adopter sessions; daisyUI 5 + Tailwind v4 ergonomics without a Node toolchain in adopter builds.
**Plans**: TBD
**UI hint**: yes

### Phase 6: Custom Credo + Boundary
**Goal**: Twelve domain-rule Credo checks plus `boundary` blocks per `ARCHITECTURE.md` §7 are operational, refined against the real code from Phases 1–5, and CI flags violations before merge.
**Depends on**: Phase 5
**Requirements**: TENANT-03, TRACK-02, LINT-01, LINT-02, LINT-03, LINT-04, LINT-05, LINT-06, LINT-07, LINT-08, LINT-09, LINT-10, LINT-11, LINT-12
**Success Criteria** (what must be TRUE):
  1. A PR that adds a raw `Swoosh.Mailer.deliver/1` call inside mailglass library code fails CI with `NoRawSwooshSendInLib`; a PR that adds `tracking: [opens: true]` to a mailable named `password_reset/1` fails CI with `NoTrackingOnAuthStream`.
  2. A PR that adds a literal `:to`, `:from`, `:body`, `:html_body`, `:subject`, `:headers`, `:recipient`, or `:email` key to a telemetry metadata map fails CI with `NoPiiInTelemetryMeta`; a PR that calls `Repo.all(Delivery)` without passing through `Mailglass.Tenancy.scope/2` fails CI with `NoUnscopedTenantQueryInLib` (bypass requires explicit `scope: :unscoped` opt with telemetry audit emit).
  3. A PR that calls `Oban.insert/2`, `OpenTelemetry.*`, or `Mjml.*` outside the `Mailglass.OptionalDeps.*` gateway modules fails CI with `NoBareOptionalDepReference`; `mix compile --no-optional-deps --warnings-as-errors` continues to pass.
  4. A PR that broadcasts a `Phoenix.PubSub` topic without the `mailglass:` prefix fails CI with `PrefixedPubSubTopics`; a PR that calls `DateTime.utc_now/0` outside `Mailglass.Clock` fails CI with `NoDirectDateTimeNow`.
  5. The multi-tenant property test (Phase 2) plus the boundary contract test (`Mailglass.Renderer` cannot depend on `Mailglass.Outbound`, `Mailglass.Repo`, or any process; `Mailglass.Events` cannot depend on `Mailglass.Outbound`) both pass.
**Pitfalls guarded against**: LIB-01 (oversized `use` injection), LIB-05 (singleton GenServers), LIB-07 (`compile_env` outside Config), LIB-09 (other-app env reads), MAIL-01 (tracking on auth-carrying messages — operationalized via `NoTrackingOnAuthStream`), OBS-01 (PII in telemetry), OBS-04 (full response in logs), OBS-05 (telemetry naming convention drift), PHX-01 (PubSub topic namespacing), PHX-05 (tenant scope leak), PHX-06 (PubSub prefix), DIST-04 (bare optional dep references), TEST-06 (direct `DateTime.utc_now/0`).
**Plans**: TBD
**UI hint**: no

### Phase 7: Installer + CI/CD + Docs
**Goal**: A Phoenix 1.8 host runs `mix mailglass.install` and goes from zero to first-preview-styled email in under 5 minutes; the full GHA pipeline (lint, test matrix, Dialyzer, golden install diff, admin smoke, dependency review, actionlint, Release Please, protected-ref Hex publish) is green; ExDoc with 9 guides + doctest contracts publishes to HexDocs.
**Depends on**: Phase 6
**Requirements**: TEST-04, INST-01, INST-02, INST-03, INST-04, CI-01, CI-02, CI-03, CI-04, CI-05, CI-06, CI-07, DOCS-01, DOCS-02, DOCS-03, DOCS-04, DOCS-05, BRAND-02, BRAND-03
**Success Criteria** (what must be TRUE):
  1. A new Phoenix 1.8 host app reaches "first preview-styled HEEx email rendered in the browser" in under 5 minutes from zero via `mix mailglass.install` + 5 lines of mailable code; an adopter migrating from raw Swoosh + `Phoenix.Swoosh` follows `guides/migration-from-swoosh.md` in a single afternoon with no production behavior change.
  2. A second run of `mix mailglass.install` on a host with no changes produces zero file modifications (`.mailglass_conflict_*` sidecars rather than clobbering); the golden-diff snapshot test in `test/example/` catches any installer behavior change in PRs.
  3. A coordinated release of `mailglass` and `mailglass_admin` produced by Release Please ships both packages to Hex with linked versions; `mailglass_admin/mix.exs` declares `{:mailglass, "== <new-version>"}`; the `mailglass` Hex tarball is <500KB and contains zero `priv/static/` assets; the `mailglass_admin` tarball is <2MB.
  4. CI on a PR runs format + compile (with `--warnings-as-errors`, separately with `--no-optional-deps --warnings-as-errors`) + ExUnit + Credo `--strict` (including the 12 custom checks) + Dialyzer with cached PLT + `mix docs --warnings-as-errors` + `mix hex.audit` + dependency-review + actionlint; real-provider sandbox tests (`@tag :provider_live`) run on daily cron + `workflow_dispatch` only and never block PRs.
  5. ExDoc publishes with `main: "getting-started"` plus 9 guides (getting-started, authoring-mailables, components, preview, webhooks, multi-tenancy, telemetry, testing, migration-from-swoosh), `llms.txt` ships automatically (ExDoc 0.40+), every README "Quick Start" snippet compiles, and `MAINTAINING.md` + `CONTRIBUTING.md` + `SECURITY.md` + `CODE_OF_CONDUCT.md` are present at the repo root with brand-voice-conformant copy throughout.
**Pitfalls guarded against**: DIST-01 (sibling version drift via Release Please linked-versions), DIST-03 (`mix mailglass.install` non-idempotent — `.mailglass_conflict_*` sidecars + second-rerun no-op test), DIST-05 (Hex publish from PR / forked branch — protected ref + GitHub Environment with required reviewers), DIST-06 (Hex tarball size enforcement), CI-01 through CI-06 (full GHA discipline), TEST-02 (real-provider sandbox tests advisory only), TEST-04 (doc-contract drift between README/guides and real APIs).
**Plans**: TBD
**UI hint**: no

## Phase Ordering Rationale

The 7-phase grouping matches `research/SUMMARY.md` "Implications for Roadmap" exactly and is the result of dependency analysis across Layer 0 → 7. Granularity is `standard` (5–8 phases) and 7 sits inside that band.

- **Layer 0 → 1 → 2 → 3 is dependency-forced.** Errors / Config / Telemetry are zero-dep. Renderer is pure (no DB). Schemas before send pipeline so `Multi` inserts are typed. Adapter behaviour + Fake before Mailable because `deliver/2`'s return shape comes from the adapter contract.
- **Webhook (Phase 4) follows Send (Phase 3)** so we can test webhook → event → projection update against an actually-written delivery row.
- **Preview (Phase 5) follows Send + Webhook** so the live-assigns form reflects the real `Message` struct, not a placeholder.
- **Custom Credo checks (Phase 6) follow implementation** because rules need real-code targets to refine against. Building Credo checks first would mean fighting an immature lint surface against immature library code — known time-sink across all 4 prior libs.
- **Installer + CI/CD + Docs (Phase 7) is last** because installer goldens lock the public API; building goldens against a churning API wastes work.
- **`mailglass_inbound` (v0.5+) is intentionally absent.** It shares webhook plumbing with v0.5 deliverability work; pulling forward to v0.1 would waste work that v0.5 will rewrite.

The granularity-standard band suggested 5–8; 7 phases is mid-band. No compression to 5 because Phases 4 (webhook), 5 (preview UI), and 6 (Credo) have orthogonal verification surfaces and merging any pair would obscure success criteria. No expansion to 8 because no phase has >18 requirements with mixed orthogonal concerns.

## Phases Flagged for `/gsd-research-phase`

Per `research/SUMMARY.md` "Research Flags," these three phases require a research pass before planning. The other four can plan directly from synthesis (patterns are 4-of-4 convergent across prior libs).

| Phase | Open questions | Reference impl |
|-------|----------------|----------------|
| **Phase 2** | `metadata jsonb` projection columns; orphan-webhook reconciliation worker cadence; `:typed_struct` adoption decision; status state machine app-enforced vs DB check | `~/projects/accrue/lib/accrue/events/` |
| **Phase 4** | SendGrid ECDSA verification API on OTP 27 `:crypto`; `CachingBodyReader` + Plug 1.18 chain interaction | `~/projects/lattice_stripe/lib/lattice_stripe/webhook/` |
| **Phase 5** | `MailglassAdmin.Router` macro signature; LiveView session cookie collision; daisyUI 5 + Tailwind v4 without Node | `~/projects/sigra/lib/sigra/admin/router.ex` |

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 4/6 | In progress | - |
| 2. Persistence + Tenancy | 0/TBD | Not started | - |
| 3. Transport + Send Pipeline | 0/TBD | Not started | - |
| 4. Webhook Ingest | 0/TBD | Not started | - |
| 5. Dev Preview LiveView | 0/TBD | Not started | - |
| 6. Custom Credo + Boundary | 0/TBD | Not started | - |
| 7. Installer + CI/CD + Docs | 0/TBD | Not started | - |

---
*Roadmap defined: 2026-04-21*
*Coverage: 84/84 v1 REQ-IDs mapped to exactly one phase. No orphans, no duplicates.*
