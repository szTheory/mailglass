# Project Research Summary

**Project:** mailglass
**Domain:** Phoenix-native transactional email framework (3 sibling Hex packages, OSS, MIT)
**Researched:** 2026-04-21
**Confidence:** HIGH

> *Synthesized from STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md. Locked decisions D-01..D-20 from PROJECT.md constrain this synthesis and are not re-litigated. Read this single page to plan; reach into the four research files for detail.*

---

## Executive Summary

**mailglass** is the missing framework layer between Swoosh's `compose → adapter → deliver` primitive and the production transactional-email needs of senior Phoenix teams in 2026. It composes on top of Swoosh (never replaces it) and ships everything Swoosh deliberately doesn't: a HEEx-native component library with MSO Outlook fallbacks, a LiveView preview-then-admin dashboard with no Node toolchain, normalized webhook events using the Anymail taxonomy verbatim, a Postgres append-only event ledger protected by a SQLSTATE 45A01 trigger, idempotent webhook replay via partial UNIQUE indexes, signed-token RFC 8058 unsubscribe (v0.5), suppression auto-add on bounce/complaint, message-stream separation, multi-tenancy from day one, and `mix mail.doctor` deliverability checks. Three sibling Hex packages (`mailglass`, `mailglass_admin`, `mailglass_inbound` — last lands v0.5+) ship under a Release Please linked-version pipeline so they can never drift.

**The recommended approach is opinionated and concrete.** Stack: Phoenix 1.8.5 + LiveView 1.1.28 + Ecto 3.13.5 + Postgres 16 + Swoosh 1.25.0, with `oban`, `opentelemetry`, `mjml` (the Rust-NIF Hex package — *not* the bare `:mrml` package, which does not exist on Hex), `gen_smtp`, and `sigra` as `optional: true` deps gated by `Code.ensure_loaded?/1`. Architecture is **almost entirely functional** — exactly one GenServer (an ETS-backed rate-limit token bucket), one Registry (per-tenant adapter cache), and `Task.Supervisor` as the Oban-fallback path; everything else is pure code in a Layer 0 → 7 build order anchored on the immutable event ledger. The Fake adapter is the merge-blocking test gate; real-provider tests are advisory cron only.

**The risks worth pre-empting are deliverability churn, multi-tenant data leaks, and macro/optional-dep discipline.** Yahooglesoft (Gmail+Yahoo+Microsoft) bulk-sender enforcement escalated since the prompts were written: Gmail moved to permanent 550-class rejections in Nov 2025 and Microsoft formally joined the requirements in May 2025 — v0.5 RFC 8058 work is non-optional, not nice-to-have. Multi-tenancy must be retrofittable-from-never (PROJECT.md D-09 forbids retrofit) which means `tenant_id` lands on every schema in v0.1 and a custom Credo check `NoUnscopedTenantQueryInLib` enforces scope at lint time. Optional deps must route through gateway modules with `@compile {:no_warn_undefined, ...}` or `mix compile --no-optional-deps --warnings-as-errors` will catch the leak in CI. The single MEDIUM-confidence required dep is `premailex` (last release Jan 2025, no credible replacement) — flag for "watch this dep" maintenance and treat contributor pickup as a v0.5 milestone task.

---

## Key Findings

### Recommended Stack

Phoenix 1.8 + LiveView 1.1 + Ecto 3.13 + Postgres + Swoosh 1.25 + the standard library set (`nimble_options`, `telemetry`, `gettext`, `floki`, `premailex`, `plug`), with five optional deps. Test stack is ExUnit + StreamData + Mox + a stateful in-process Fake adapter (the release gate). CI is GitHub Actions with `setup-beam`, Release Please from a protected ref, SHA-pinned third-party actions, two-tier matrix, and `boundary` library enforcing the module dependency graph.

| Layer | Pick | Version (Apr 2026) | Confidence |
|---|---|---|---|
| Runtime | Elixir / OTP | 1.18+ / 27+ | HIGH (D-06) |
| Web framework | `phoenix` | `~> 1.8` (1.8.5) | HIGH |
| LiveView | `phoenix_live_view` | `~> 1.1` (1.1.28) | HIGH |
| ORM | `ecto` + `ecto_sql` | `~> 3.13` (3.13.5) | HIGH |
| DB driver | `postgrex` | `~> 0.22` (0.22.0) | HIGH |
| Plug | `plug` | `~> 1.18` (1.19.1) | HIGH |
| Mailer transport | `swoosh` | `~> 1.25` (1.25.0) | HIGH (D-07) |
| HTML→text + parser | `floki` | `~> 0.38` (0.38.1) | HIGH |
| CSS inliner | `premailex` | `~> 0.3` (0.3.20) | **MEDIUM** — slow cadence, no replacement |
| Option validation | `nimble_options` | `~> 1.1` (1.1.1) | HIGH (feature-complete) |
| Telemetry | `telemetry` | `~> 1.4` (1.4.1) | HIGH |
| i18n | `gettext` | `~> 1.0` (1.0.2) | HIGH |
| Background jobs (optional) | `oban` | `~> 2.21` (2.21.1) | HIGH (D-07) |
| MJML renderer (optional) | **`mjml`** *(not `:mrml`)* | `~> 5.3` (5.3.1) | HIGH — Rust NIF, precompiled |
| Tracing (optional) | `opentelemetry` | `~> 1.7` (1.7.0) | HIGH |
| SMTP server (optional, v0.5+) | `gen_smtp` | `~> 1.3` (1.3.0) | HIGH |
| Auth adapter (optional) | `sigra` | `~> 0.2` (0.2.0) | MEDIUM — pre-1.0, single-dev |
| Property tests | `stream_data` | `~> 1.3` (1.3.0) | HIGH |
| Behaviour mocks | `mox` | `~> 1.2` (1.2.0) | HIGH |
| Linter | `credo` | `~> 1.7` (1.7.18) | HIGH |
| Static type analysis | `dialyxir` | `~> 1.4` (1.4.7) | HIGH (keep through v0.x) |
| Docs | `ex_doc` | `~> 0.40` (0.40.1) | HIGH — ships `llms.txt` automatically |
| Boundary enforcement | `boundary` | latest | HIGH — from Layer 0 |

**Explicit DON'Ts (full list in STACK.md §6):** Bamboo (maintenance mode), MJML as the *default* renderer (D-18), ExMachina (Map.merge fixtures instead per 4-of-4 prior-libs convergence), `Application.compile_env!` for runtime settings, raw HTTP libraries (Tesla/HTTPoison — Swoosh handles HTTP via Finch internally), MySQL/SQLite at v0.1 (Postgres-only is load-bearing), pre-Phoenix-1.8 / pre-LiveView-1.0 support matrix, AMP for Email (Cloudflare sunsetted Oct 2025), open core / paid Pro tier (MIT forever).

**One correction crystallized in research:** PROJECT.md and prompts/ originally referenced an optional `:mrml` dep. The actual Hex package is **`:mjml`** (Rust NIF wrapping the underlying `mrml` Rust crate). The bare `:mrml` package does not exist on Hex. PROJECT.md D-18 has been corrected; downstream phases must use `{:mjml, "~> 5.3", optional: true}`.

See [STACK.md](STACK.md) for full version verification, lane structure, optional-dep discipline pattern, and stack patterns by adopter variant.

### Expected Features

20 table-stakes features make v0.1 a credible alternative to "rebuild ActionMailer + Anymail by hand on top of Swoosh." 12 differentiators give it a moat. 16 anti-features are documented to prevent re-litigation. v0.5 adds 10 deliverability features that bring Yahooglesoft compliance. v0.5+ adds 6 inbound-routing features as a separate sibling.

**Must have — table stakes (v0.1, all P1, all ship-blocking):**

- **TS-01** `Mailglass.Mailable` behaviour with `deliver/2`, `deliver_later/2`, `deliver_many/2` (Oban optional → Task.Supervisor fallback) — closes the #1 cited Swoosh gap
- **TS-02** HEEx component library with MSO Outlook VML fallbacks — the "no Node" promise made concrete
- **TS-03** Render pipeline: HEEx → Premailex CSS inlining → minify → Floki auto-plaintext
- **TS-05** `Mailglass.Adapter.Fake` — stateful, time-advanceable, the release-blocking test target (D-13)
- **TS-06** Append-only `mailglass_events` Postgres table with SQLSTATE 45A01 immutability trigger (D-15)
- **TS-07** Idempotency keys via `UNIQUE` partial index — replay-safe webhooks
- **TS-08** First-class multi-tenancy: `tenant_id` on every record (D-09 — cannot retrofit)
- **TS-09** `Mailglass.Error` struct hierarchy with closed `:type` atom set
- **TS-10** Telemetry spans on `[:mailglass, :domain, :resource, :action, :start|:stop|:exception]` (4-level convention; PII-free)
- **TS-11** Webhook normalization for Postmark + SendGrid, Anymail event taxonomy verbatim (D-10, D-14)
- **TS-12** Webhook signature verification (Postmark Basic Auth + IP, SendGrid ECDSA) — `SignatureError` raises at call site
- **TS-13** Dev-mode preview LiveView with `preview_props/1` auto-discovery, device toggle, dark toggle, HTML/Text/Raw/Headers tabs (D-11)
- **TS-14** `Mailglass.TestAssertions` extending Swoosh's
- **TS-15** Open/click tracking off by default (D-08)
- **TS-16** `mix mailglass.install` with `--no-admin` flag, `.mailglass_conflict_*` sidecars, golden-diff CI against `test/example/` Phoenix host (D-12)
- **TS-19** ExDoc with `main: "getting-started"` + full guide set + doc-contract tests
- **TS-20** CI/CD with custom Credo checks (`NoRawSwooshSendInLib`, `RequiredListUnsubscribeHeaders`, `NoPiiInTelemetryMeta`, `NoUnscopedTenantQueryInLib`) + Fake adapter merge gate

**Should have — differentiators (v0.1 + v0.5; the moat):**

- **DF-01** LiveView preview dashboard with live-assigns form + hot reload — *the* killer demo
- **DF-04** Append-only event ledger with trigger immutability — replays, audits, analytics, timeline from one schema
- **DF-07** `mix mail.doctor` (v0.5) — unique in the Elixir ecosystem
- **DF-08** `mailglass_admin` mountable in adopters' Phoenix apps (sigra/Oban Web pattern), not standalone
- **DF-09** Custom Credo checks enforcing domain rules at lint time
- **DF-10** `preview_props/1` colocation — fixes the Rails ActionMailer::Preview footgun via compile-time alignment
- **DV-01..DV-04** RFC 8058 + suppression + stream separation + Mailgun/SES/Resend webhooks (v0.5) — Yahooglesoft compliance
- **DV-05** Prod-mountable admin LiveView with sent-mail browser + per-delivery event timeline + suppression UI + replay (v0.5)
- **DV-07** Per-tenant adapter resolver (v0.5) — Stripe-Connect-style multi-tenancy
- **DV-08** Per-domain rate limiting (v0.5)

**Defer (v0.5+ sibling package `mailglass_inbound`):**

- IB-01..IB-06 — ActionMailbox-equivalent (Router DSL, Mailbox behaviour, ingress plugs for 5 providers + SMTP relay via gen_smtp, raw MIME storage with LocalFS+S3 adapters, async routing via Oban with incineration, dev Conductor LiveView)

**Permanently out of scope (D-03, D-04, others; full list in FEATURES.md AF-01..AF-16):** Marketing email; multi-channel notifications; hosted SaaS dashboard; AMP for Email; MJML as default renderer; Bamboo backwards-compat; tracking on by default (D-08); MySQL/SQLite; open core / paid Pro tier; LLM-powered "AI subject line optimizer."

See [FEATURES.md](FEATURES.md) for full feature catalog, dependency graph, prioritization matrix, and competitor feature comparison across ActionMailer/ActionMailbox/Anymail/Mailcoach/React Email/Bamboo/Swoosh.

### Architecture Approach

Three sibling Hex packages sharing a planning repo and Release Please cadence: `mailglass` (core), `mailglass_admin` (mountable LiveView UI — preview at v0.1, prod admin at v0.5), `mailglass_inbound` (v0.5+, Action Mailbox equivalent). The core is a **functional pipeline** — `Mailable → Message → Renderer → Compliance → preflight (suppression + rate-limit + stream policy) → one Ecto.Multi (Delivery + Event(:queued) + Oban job) → Worker dispatches → Adapter → Multi(Delivery update + Event(:dispatched))`. The append-only event ledger is the keystone: every state change flows through a Multi that writes a row; a Postgres trigger raising SQLSTATE 45A01 on UPDATE/DELETE makes immutability structural, not policy. Webhooks ingest through a CachingBodyReader (raw bytes preserved for HMAC) → per-provider verifier → per-provider Anymail-taxonomy normalizer → idempotent insert (`on_conflict: :nothing` on the unique idempotency key). Adopt `boundary` library from Layer 0 to enforce the module dependency graph at compile time.

**Major components (refined catalog; full table in ARCHITECTURE.md §1):**

1. **`Mailglass`** (top-level facade) + **`Mailglass.Mailable`** (behaviour + thin macro) + **`Mailglass.Message`** (struct wrapping `%Swoosh.Email{}`) — public surface
2. **`Mailglass.Outbound`** (facade) + **`Mailglass.Outbound.Delivery`** (Ecto schema) + **`Mailglass.Outbound.Worker`** (Oban or Task.Supervisor fallback) — send pipeline
3. **`Mailglass.Renderer`** + **`Mailglass.TemplateEngine`** (behaviour, default HEEx, optional MJML) + **`Mailglass.Components`** — pure rendering pipeline
4. **`Mailglass.Events`** (writer context) + **`Mailglass.Events.Event`** (immutable schema with trigger) + **`Mailglass.IdempotencyKey`** — append-only ledger
5. **`Mailglass.Webhook.{Plug, CachingBodyReader, Event, Handler, Providers.{Postmark,SendGrid,...}}`** — HMAC-verified, idempotent, normalized event ingest
6. **`Mailglass.Suppression`** + **`Mailglass.SuppressionStore`** (behaviour, default Ecto) — pre-send guard + auto-add on bounce/complaint
7. **`Mailglass.Tenancy`** (behaviour, default SingleTenant) + **`Mailglass.AdapterRegistry`** — multi-tenancy + per-tenant adapter cache
8. **`Mailglass.Adapter`** (behaviour) + **`Mailglass.Adapters.Fake`** (release gate, built first) + **`Mailglass.Adapters.Swoosh`** (wraps any Swoosh adapter) — transport
9. **`Mailglass.Telemetry`** (4-level wrapper) + **`Mailglass.PubSub.Topics`** (typed builder) + **`Mailglass.Error`** (struct hierarchy) + **`Mailglass.Config`** (NimbleOptions, runtime-validated) + **`Mailglass.Repo`** (`transact/1` wrapper) — cross-cutting
10. **`Mailglass.Compliance`** — RFC 8058 unsubscribe headers, Feedback-ID, physical-address auto-injection per stream, DKIM signing helper (v0.5)
11. **`MailglassAdmin.{Router, PreviewLive, Components}`** — sibling package, mountable router macro
12. **`Mailglass.Credo.*`** — domain rules enforced at lint time

**Process architecture is nearly stateless.** One ETS-only token bucket (small supervisor child that owns the table; *not* a serialization GenServer). One `Registry` (per-tenant adapter cache). One `Task.Supervisor` (Oban-absent fallback + fire-and-forget broadcasts). `Phoenix.PubSub` for delta updates to admin LiveViews. Adopters supervise their own Repo/Endpoint/Oban — mailglass does not.

**The 7-layer build order is the spine of the v0.1 roadmap** (full table in ARCHITECTURE.md §6):

| Layer | Components | Why this order |
|---|---|---|
| **0. Foundations** | `Error`, `Config` (NimbleOptions), `Telemetry` primitives, `Repo` (transact wrapper), `IdempotencyKey` | Zero-dep; every later layer depends on these. |
| **1. Pure rendering** | `Message`, `Components` (HEEx), `TemplateEngine` behaviour + `.HEEx` impl, `Renderer` | All pure; testable with `assert render(...) == expected_html`. The "demo on day one" milestone. |
| **2. Persistence schemas** | `Outbound.Delivery`, `Events.Event` (with immutability trigger migration + `assert_raise EventLedgerImmutableError` test), `Suppression.Entry`, `Events` writer, `SuppressionStore` behaviour | Must come before adapter/mailable so the send pipeline can be wired end-to-end. |
| **3. Transport** | `Adapter` behaviour, **`Adapters.Fake` first**, then `Adapters.Swoosh` (wraps any `Swoosh.Adapter`) | D-13: Fake first means the whole pipeline can be validated against Fake before depending on a real adapter. |
| **4. Send pipeline** | `Tenancy` + SingleTenant default, `RateLimiter` (ETS), `Suppression.check_before_send/1`, `Mailable` behaviour + macro, `Outbound` facade, `Outbound.Worker` (Oban + Task.Supervisor fallback), `PubSub.Topics` | The hot path. **End-to-end testable with Fake adapter at the close of this layer.** |
| **5. Webhook ingest** | `Webhook.CachingBodyReader`, `Webhook.Event`, `Webhook.Providers.{Postmark,SendGrid}`, `Webhook.Plug`, `Webhook.Handler`, partial `Compliance` (RFC-required headers) | Depends on Events writer + Adapter being stable. |
| **6. mailglass_admin (preview only)** | `MailglassAdmin.Router` macro, `MailglassAdmin.PreviewLive`, `MailglassAdmin.Components` | Sibling Hex package. Dev-only mount per D-11. Prod admin is a v0.5 milestone. |
| **6.5 Custom Credo checks** | `NoRawSwooshSendInLib`, `NoPiiInTelemetryMeta`, `NoUnscopedTenantQueryInLib`, etc. | Build *between* implementation and installer so rules can be refined against real code. |
| **7. Installer + golden-diff** | `mix mailglass.install` task, `priv/templates/`, `test/example/` host, golden-diff snapshot test, `mix verify.phase<NN>` aliases | Build only after public API is stable, otherwise goldens churn. |

**Layer 0 + Layer 1 = "demo day" milestone.** Layers 2–4 = "we have a working core" milestone. Layers 5–7 = "v0.1 release-ready" milestone.

See [ARCHITECTURE.md](ARCHITECTURE.md) for full module catalog with verdicts, end-to-end data flow diagrams, failure modes/race conditions, supervision tree, behaviour boundaries (8 pluggable seams), full DDL for the 3 v0.1 schemas, and `boundary` enforcement blocks.

### Critical Pitfalls

42 pitfalls across 8 categories (LIB / MAIL / DIST / PHX / OBS / TEST / CI / MAINT). The 5 most load-bearing for the v0.1 roadmap:

1. **MAIL-01: Open/click tracking on auth-carrying messages** — Auto-rewriting magic-link or password-reset URLs through a tracking host is a security catastrophe AND a GDPR/ePrivacy liability. **Avoid:** D-08 locks tracking off by default; per-mailable opt-in via `tracking: [opens: true, clicks: true]`; custom Credo check `NoTrackingOnAuthStream` raises at compile time when tracking is set on a `:transactional` mailable with a `magic_link` / `reset_token` field.

2. **MAIL-03: Webhook idempotency missing — double-counted events** — Provider replay processes the same event twice; suppression is no-op but ledger/analytics/admin UI corrupt silently. **Avoid:** v0.1 `mailglass_events` has a `UNIQUE` partial index on `idempotency_key WHERE idempotency_key IS NOT NULL`. Every webhook event sets `idempotency_key = "#{provider}:#{provider_event_id}"`. Insert via `Ecto.Multi` with `on_conflict: :nothing`. StreamData property test asserts replay-N converges to apply-once. Webhook plug returns 200 OK on replays.

3. **PHX-05: Multi-tenant scope leak in admin LiveView** — `Mailglass.Suppressions.list/0` (no tenant scope) shows tenant B's data to tenant A's admin. Catastrophic, invisible, lives in adopter's app under their auth. **Avoid:** Custom Credo check `NoUnscopedTenantQueryInLib` flags every Repo query on a tenanted schema that doesn't pass through `Mailglass.Tenancy.scope/2`. Multi-tenant property test spawns 2 tenants and asserts zero cross-leak. Bypass requires explicit `scope: :unscoped` audited via telemetry.

4. **DIST-04: Optional deps not gated with `Code.ensure_loaded?/1`** — Direct `Oban.insert/2` reference; user without Oban gets `UndefinedFunctionError` at runtime; `mix compile --no-optional-deps` warns noisily. **Avoid:** Single gateway per optional dep (`Mailglass.OptionalDeps.{Oban, OpenTelemetry, MJML}`) with `@compile {:no_warn_undefined, ...}` declared once + `available?/0` + degraded fallback. CI lane `mix compile --no-optional-deps --warnings-as-errors` is mandatory. `NoBareOptionalDepReference` Credo check enforces.

5. **OBS-01: PII in telemetry metadata** — Telemetry stop event includes `meta.to: "alice@example.com"`. Adopter wires telemetry to OpenTelemetry; PII flows to a SaaS observability vendor. GDPR violation discovered months later. **Avoid:** Hard rule (D-08, D-17): telemetry meta is counts/statuses/IDs/latencies ONLY. Custom Credo check `NoPiiInTelemetryMeta` flags any literal `:to`/`:from`/`:body`/`:html_body`/`:subject`/`:headers`/`:recipient`/`:email` keys. Whitelisted: `:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`. Property test enumerates emit sites and asserts subset of whitelist.

See [PITFALLS.md](PITFALLS.md) for full 42-pitfall catalog organized by category, technical-debt patterns table, integration gotchas, performance traps, and security mistakes.

---

## Watch Out For — Top 15 Cross-Cutting Risks

| # | Risk | Cite | Phase | Prevention |
|---|---|---|---|---|
| 1 | Open/click tracking on auth-carrying messages | MAIL-01 | v0.1 outbound + v0.5 tracking | D-08 default-off; `NoTrackingOnAuthStream` Credo check |
| 2 | Webhook idempotency missing → double-counted events | MAIL-03 | v0.1 schema + v0.5 webhooks | UNIQUE partial index; `on_conflict: :nothing`; property test |
| 3 | Multi-tenant scope leak in admin LiveView | PHX-05 | v0.1 tenancy + v0.5 admin | `NoUnscopedTenantQueryInLib`; multi-tenant property test |
| 4 | Optional deps not gated → runtime `UndefinedFunctionError` | DIST-04 | v0.1 foundations | OptionalDeps gateway modules; `--no-optional-deps --warnings-as-errors` lane |
| 5 | PII in telemetry metadata → GDPR exposure via OTel | OBS-01 | v0.1 telemetry | `NoPiiInTelemetryMeta`; whitelisted meta keys; property test |
| 6 | List-Unsubscribe without RFC 8058 `-Post` → permanent 550 | MAIL-02 | v0.5 deliverability | `Compliance.add_unsubscribe_headers/1` emits both atomically; both in DKIM `h=` |
| 7 | Bounce classification wrong (soft/hard) | MAIL-08 | v0.5 webhooks | Anymail taxonomy verbatim (D-14); per-provider mapper exhaustive case; configurable soft-bounce escalation |
| 8 | Provider `message_id` collision across providers | MAIL-09 | v0.1 schema | UNIQUE on `(provider, provider_message_id)` |
| 9 | Sibling version drift | DIST-01 | v0.1 CI/CD + every release | Release Please linked-versions; `mailglass_admin` uses `==` not `~>` |
| 10 | `mix mailglass.install` non-idempotent → clobbers customizations | DIST-03 | v0.1 installer | `.mailglass_conflict_*` sidecars; second golden test asserts rerun is no-op |
| 11 | Compile-time dep explosion via macros / `compile_env` | LIB-02 + LIB-07 | v0.1 foundations | Forbid `compile_env` outside `Mailglass.Config`; `Macro.expand_literals/2`; `mix xref graph` CI gate |
| 12 | Hidden singleton (`name: __MODULE__`) blocks multi-tenancy | LIB-05 | v0.1 supervision tree | No singletons; `NoDefaultModuleNameSingleton` Credo check |
| 13 | Hex publish from PR / forked branch (supply-chain) | DIST-05 + CI-03 | v0.1 CI/CD | Publish only from protected ref; `HEX_API_KEY` is GitHub Environment secret with required reviewers; SHA-pinned actions |
| 14 | Real-provider tests in PR-blocking CI → flaky, slow, expensive | TEST-02 | v0.1 CI/CD | Tag `@tag :provider_live` excluded from PR CI; daily cron + `workflow_dispatch` only; Fake is the merge gate |
| 15 | Yahooglesoft compliance churn (Gmail Nov 2025 perm-550, MSFT May 2025 join) | MAINT-03 + MAIL-02 | v0.5 + continuous | Budget 20–30% maintenance time forever; subscribe to Postmaster Tools; quarterly `mix mail.doctor` against own dogfood |

---

## Implications for Roadmap

The 7-layer build order from ARCHITECTURE.md §6 is the spine. Below: suggested phase grouping for v0.1, mapping each phase to feature IDs from FEATURES.md and pitfalls to verify in `VERIFICATION.md`.

### Phase 1: Foundation (Layer 0 + 1) — "Render an email from HEEx"

**Rationale:** Zero-dep modules every later layer depends on. Layer 1 lands the renderer pipeline as pure functions. This phase is the "demo on day one" milestone — at the close, you can render `MyApp.UserMailer.welcome(user)` to inlined-CSS HTML+text without persistence or transport.

**Delivers:** `Mailglass.Error` hierarchy (TS-09), `Mailglass.Config` (NimbleOptions, runtime-validated), `Mailglass.Telemetry` 4-level wrapper (TS-10), `Mailglass.Repo.transact/1`, `Mailglass.IdempotencyKey`, `Mailglass.Message` struct, `Mailglass.Components` HEEx library with MSO VML fallbacks (TS-02), `Mailglass.TemplateEngine` behaviour + HEEx impl, `Mailglass.Renderer` pipeline (TS-03), `Mailglass.Compliance.add_*_headers/1` stubs.

**Addresses:** TS-02, TS-03, TS-04 (Gettext), TS-09, TS-10, DF-02 (no Node), DF-09 partial.
**Avoids:** LIB-02, LIB-07, OBS-01, OBS-04, DIST-04 (gateway pattern locked here).
**Boundary contract:** `Mailglass.Renderer` cannot depend on `Outbound`, `Repo`, or any process — pure functions only.

### Phase 2: Persistence + Immutability (Layer 2) — "The event ledger trigger fires"

**Rationale:** The append-only event ledger is the keystone. Building schemas + the SQLSTATE 45A01 trigger before adapter/send means immutability is structural before any code attempts to violate it. Multi-tenancy lands here because `tenant_id` cannot be retrofitted (D-09).

**Delivers:** `Mailglass.Outbound.Delivery` schema with `(provider, provider_message_id)` UNIQUE index, `Mailglass.Events.Event` schema + `mailglass_raise_immutability` trigger (D-15), `Mailglass.Events.append/2` writer that refuses calls outside `Ecto.Multi`, `Mailglass.Suppression.Entry` schema with `:scope` enum (no default), `Mailglass.SuppressionStore` behaviour + Ecto impl, `Mailglass.Tenancy` behaviour + SingleTenant default, integration test `assert_raise EventLedgerImmutableError`.

**Addresses:** TS-06, TS-07, TS-08, DF-04, foundations for DV-03.
**Avoids:** MAIL-09, MAIL-07 (suppression `:scope` enum has no default), PHX-04 (no FKs to adopter tables; polymorphic `(owner_type, owner_id)`), PHX-05 partial.
**Research flag:** **MEDIUM** — schema details for `metadata jsonb` projection columns; reconciliation worker for orphan webhooks; `:typed_struct` adoption decision.

### Phase 3: Transport + Send Pipeline (Layer 3 + 4) — "Fake delivery → event row"

**Rationale:** Build Fake adapter **first** (D-13). It's the release gate; every other test depends on it. Once Fake exists, the whole `Mailable → Outbound → Worker → Adapter → Multi(Delivery + Event)` pipeline is testable end-to-end without any real provider. This is the "we have a working core" milestone.

**Delivers:** `Mailglass.Adapter` behaviour, `Mailglass.Adapters.Fake` (stateful, time-advanceable, JSON-compatible state machine — DF-11), `Mailglass.Adapters.Swoosh` (wraps any `Swoosh.Adapter`, normalizes errors), `Mailglass.Mailable` behaviour + thin `use` macro (≤20 lines), `Mailglass.Outbound` facade with `send/2`, `deliver/2`, `deliver_later/2`, `deliver_many/2` (TS-01), `Mailglass.Outbound.Worker` (Oban + `Task.Supervisor` fallback with `Logger.warning`), `Mailglass.RateLimiter` (ETS-only token bucket), `Mailglass.Suppression.check_before_send/1`, `Mailglass.PubSub.Topics`, `Mailglass.TestAssertions` (TS-14), per-domain Case templates.

**Addresses:** TS-01, TS-05, TS-14, TS-15, DF-11, DF-12.
**Avoids:** LIB-01 (≤20 line macro; `NoOversizedUseInjection` check), LIB-03 (return-type stability locked in `api_stability.md`), LIB-04 (tuple returns), LIB-05 (no singletons), LIB-06 (renderer + Swoosh bridge are pure), TEST-01 (Mox not used for adapters), TEST-06 (`Mailglass.Clock` injection).
**Marker for end of phase:** `mix verify.core_send` runs the full pipeline against Fake.

### Phase 4: Webhook Ingest (Layer 5) — "Postmark/SendGrid → normalized event row"

**Rationale:** Depends on Events writer (Phase 2) and Adapter (Phase 3). PROJECT.md D-10 limits v0.1 to Postmark + SendGrid; Mailgun/SES/Resend land in v0.5.

**Delivers:** `Mailglass.Webhook.CachingBodyReader`, `Mailglass.Webhook.Event` normalized struct, `Mailglass.Webhook.Providers.{Postmark, SendGrid}`, `Mailglass.Webhook.Plug`, `Mailglass.Webhook.Handler` behaviour + Default impl, idempotent `Multi` insert with `on_conflict: :nothing`, suppression auto-add for `:bounced`/`:complained`/`:unsubscribed`, orphan-webhook handling with `delivery_id = nil` + `needs_reconciliation = true`, partial `Mailglass.Compliance`.

**Addresses:** TS-11, TS-12, DF-05.
**Avoids:** MAIL-03 (idempotency UNIQUE + `on_conflict: :nothing` + property test), MAIL-08 (Anymail taxonomy verbatim, no `_ -> :hard_bounce` catch-all without `Logger.warning`), TEST-03 (StreamData property tests on signature + idempotency are v0.1 release gate, not v0.2 polish), OBS-02, OBS-05.
**Research flag:** **MEDIUM** — SendGrid ECDSA verification using OTP 27 `:crypto`; CachingBodyReader interaction with Plug 1.18.

### Phase 5: Dev Preview LiveView (Layer 6) — "The killer demo"

**Rationale:** Depends on Mailable + Renderer being stable. Sibling Hex package `mailglass_admin` v0.1 ships **dev-only** preview per D-11 — prod admin is v0.5. Even shipped alone, the preview LiveView is the v0.1 differentiator vs Rails ActionMailer::Preview, React Email, and Mailing.dev.

**Delivers:** `MailglassAdmin.Router` macro (mount path is adopter's first arg, no default), `MailglassAdmin.PreviewLive` with mailable sidebar + `preview_props/1` auto-discovery (DF-10), device toggle, dark/light toggle, HTML/Text/Raw/Headers tabs, live-assigns form (DF-01), LiveReload integration, `MailglassAdmin.Components` (daisyUI 5 + Tailwind v4).

**Addresses:** TS-13, DF-01, DF-08, DF-10.
**Avoids:** PHX-02 (mount path first arg, never hardcoded; relative routes), PHX-03 (admin assets in `mailglass_admin/priv/static/` only; Hex package size CI gate <500KB core / <2MB admin), PHX-06 (PubSub topics namespaced), DIST-02 (`git diff --exit-code` on `priv/static/`).
**Research flag:** **MEDIUM** — `MailglassAdmin.Router` macro signature should be prototyped against `~/projects/sigra/lib/sigra/admin/router.ex` reference impl.

### Phase 6: Custom Credo Checks + Boundary (Layer 6.5) — "Domain rules at lint time"

**Rationale:** Build *between* implementation and installer so rules refine against real code. Per D-17 + engineering DNA §2.8: convergent across all 4 prior libs as the highest-leverage single-investment lint pattern.

**Delivers:** `NoRawSwooshSendInLib`, `NoPiiInTelemetryMeta`, `NoUnscopedTenantQueryInLib`, `NoBareOptionalDepReference`, `NoOversizedUseInjection`, `PrefixedPubSubTopics`, `NoDefaultModuleNameSingleton`, `NoCompileEnvOutsideConfig`, `NoOtherAppEnvReads`, `TelemetryEventConvention`, `NoFullResponseInLogs`, `NoDirectDateTimeNow`. `boundary` blocks per ARCHITECTURE.md §7.

**Addresses:** DF-09; enforcement layer for TS-08, TS-10, TS-15.
**Avoids:** Whole categories — operationalizes LIB-01, LIB-05, LIB-07, MAIL-01, OBS-01, OBS-04, OBS-05, PHX-01, PHX-05, PHX-06, DIST-04, TEST-06.

### Phase 7: Installer + CI/CD + Docs (Layer 7) — "v0.1 release-ready"

**Rationale:** Build only after public API stabilizes, otherwise goldens churn. Installer = "batteries-included" brand promise made concrete; CI/CD = operational floor; docs = adoption ramp.

**Delivers:** `mix mailglass.install` task with `--no-admin` flag matrix, `priv/templates/`, `test/example/` Phoenix host app, golden-diff snapshot test, `.mailglass_conflict_*` sidecar logic, `.mailglass.toml` install manifest, `mix verify.phase<NN>` aliases. CI lanes per STACK.md §4.1: lint, test matrix (1 required cell, wider nightly), Dialyzer with cached PLT, golden install, admin smoke, dependency-review + actionlint, Release Please, publish-hex (protected ref only). ExDoc with `main: "getting-started"` + 16 guides + doc-contract tests + `llms.txt`. `MAINTAINING.md` + `CONTRIBUTING.md` + `SECURITY.md` + `CODE_OF_CONDUCT.md`.

**Addresses:** TS-16, TS-17, TS-18, TS-19, TS-20.
**Avoids:** DIST-01, DIST-03, DIST-05, DIST-06, CI-01, CI-02, CI-03, CI-04, CI-05, CI-06, TEST-04.

### Phase Ordering Rationale

- **Layer 0 → 1 → 2 → 3 is dependency-forced.** Errors/Config/Telemetry zero-dep. Renderer pure (no DB). Schemas before send pipeline so Multi inserts are typed. Adapter behaviour + Fake before Mailable because `deliver/2`'s return shape comes from the adapter contract.
- **Webhook (Phase 4) follows Send (Phase 3)** so we can test webhook → event → projection update against an actually-written delivery row.
- **Preview (Phase 5) follows Send + Webhook** so the live-assigns form reflects the real Message struct, not a placeholder.
- **Custom Credo checks (Phase 6) follow implementation** because rules need real-code targets to refine against.
- **Installer + CI/CD + Docs (Phase 7) is last** because installer goldens lock the public API.
- **`mailglass_inbound` (v0.5+) cannot ship at v0.1** — it shares webhook plumbing with v0.5 deliverability work; pulling forward wastes work v0.5 will rewrite.

### Research Flags

**Needs `/gsd-research-phase` during planning:**

- **Phase 2:** `metadata jsonb` projections, reconciliation worker cadence, `:typed_struct` adoption.
- **Phase 4:** SendGrid ECDSA verification using OTP 27 `:crypto`; CachingBodyReader + Plug 1.18 chain.
- **Phase 5:** `MailglassAdmin.Router` macro signature; LiveView session cookie collision; daisyUI 5 + Tailwind v4 without Node.
- **v0.5 RFC 8058 + suppression + DKIM:** Re-verify Yahooglesoft contract at v0.5 planning time; compliance escalating.
- **v0.5 per-domain rate limiting evolution:** ETS-only may need promotion to `:pg`-based or Postgres-row-bucket; defer with real benchmark.

**Standard patterns (skip research-phase, plan from synthesis):**

- **Phase 1:** Premailex + Floki + HEEx well-documented; MSO VML fallback set finite.
- **Phase 3:** Mailable/Outbound/Adapter pattern is 4-of-4 convergent; Fake-first locked from accrue DNA.
- **Phase 6:** Custom Credo checks mechanical; lift from prior libs.
- **Phase 7:** Installer + Release Please + CI/CD patterns 4-of-4 convergent; lift verbatim.

---

## Anti-Patterns to Avoid

Curated from PITFALLS.md. The 7 most load-bearing for v0.1 → v1.0:

| Anti-pattern | Looks like | Why fatal | Correct path |
|---|---|---|---|
| Skip Fake adapter, use Mox for transport | Faster v0.1 ship | Mock/real shape drift; the "release gate" disappears | Fake is the merge gate (D-13). Mox only for behaviours where stateful mocking adds no value. |
| One giant `use Mailglass` macro | Less adopter boilerplate (Rails feel) | Compile times balloon; opaque stack traces; bus-factor risk | Narrow `@behaviour`. `use Mailglass.Mailable` injects ≤20 lines. `NoOversizedUseInjection` check enforces. |
| Default tracking on (match ESP industry default) | Feature parity with Postmark/SendGrid | Legal liability on auth messages; GDPR risk; security catastrophe on magic links | Off by default forever (D-08). `NoTrackingOnAuthStream` raises at compile time. |
| `Application.compile_env!` for adapter / webhook secrets | Compile-time validation feels safe | Releases need rebuild on rotation; bakes config into `.beam` | Only `Mailglass.Config` may use `compile_env`. Runtime values via `get_env/2` + NimbleOptions at boot. |
| Single-tenant in v0.1, retrofit later | Faster validation; smaller v0.1 surface | Tenant boundary bugs across every query; full-rewrite migration | Multi-tenancy first-class from v0.1 (D-09). `tenant_id` on every record. `NoUnscopedTenantQueryInLib` check. |
| Real-provider tests as PR-blocking CI | "Realistic" coverage; high confidence | Flaky; costs $; blocks contributors when sandbox is down | Advisory only. Daily cron + `workflow_dispatch`. Fake is the merge gate. |
| Hex publish on push to any branch including "release" | Easy release ergonomics | Supply-chain attack via PR-named-`release-fix-typo` | Publish only from protected tag ref + GitHub Environment with required reviewers. PR jobs never see `HEX_API_KEY`. |

---

## Success Criteria Hints (for v0.1 — Roadmapper Input)

User-observable, externally testable, avoid implementation language.

**Adoption / DX:**

- A new Phoenix 1.8 app reaches "first preview-styled HEEx email rendered in the browser" in **under 5 minutes from zero** via `mix mailglass.install` + 5 lines of mailable code.
- An adopter sends their first `deliver/2` against the Fake adapter and asserts on it via `Mailglass.TestAssertions.assert_mail_sent` in **fewer than 20 lines of test code**.
- An adopter migrates from raw Swoosh + `Phoenix.Swoosh` + manual Premailex following `guides/migration-from-swoosh.md` in **a single afternoon** with no production behavior change.

**Correctness / safety:**

- The Postgres trigger on `mailglass_events` raises SQLSTATE 45A01 on every attempted UPDATE or DELETE (`assert_raise EventLedgerImmutableError`).
- A property test (StreamData) generates 1000 sequences of (webhook event, replay-count) and asserts that applying the same event N times produces the same final state as applying it once.
- A multi-tenant property test spawns 2 tenants, writes 100 records each, and asserts zero tenant B records appear in any of 50 admin LiveView assigns paths queried from tenant A.
- `mix compile --no-optional-deps --warnings-as-errors` passes against a fresh Phoenix host with only the v0.1 required deps installed.

**Release infrastructure:**

- A coordinated release of `mailglass` and `mailglass_admin` produced by Release Please ships both packages to Hex with linked versions; `mailglass_admin/mix.exs` declares `{:mailglass, "== <new-version>"}`.
- The published `mailglass` Hex tarball is **<500KB** and contains zero `priv/static/` assets; the published `mailglass_admin` Hex tarball is **<2MB**.
- A second run of `mix mailglass.install` on a host app with no changes produces zero file modifications.
- CI on a 1-line schema field addition triggers recompilation of fewer than 50 files in the example host app.

**Observability:**

- Every `:telemetry.execute/3` call emitted by mailglass passes a metadata map whose keys are a subset of `{:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count}` — verified by an automated test.
- A telemetry handler that always raises does not break the send pipeline (handler failures are isolated).

---

## Open Questions for Roadmap Phase

| # | Question | Resolve at | Notes |
|---|---|---|---|
| 1 | Exact NimbleOptions schema for `Mailglass.Config` | Phase 1 | Depends on optional-dep gateway final shape. |
| 2 | Whether `Mailglass.Tenancy` should auto-detect Phoenix 1.8 `%Scope{}` | Phase 3 | Auto-detect tempting; weigh against hidden coupling. |
| 3 | Reconciliation worker schedule + scope for orphan webhook events | Phase 4 + v0.5 | Provider-dependent; need empirical baseline. |
| 4 | `MailglassAdmin.Router` macro signature | Phase 5 | Prototype against `~/projects/sigra/lib/sigra/admin/router.ex`. |
| 5 | Whether to adopt `:typed_struct` / `:typed_ecto_schema` | Phase 2 | Set-theoretic types at Elixir 1.18+ may obviate. |
| 6 | Status state machine: app-enforced vs DB check constraint | Phase 2 | **Recommend app-enforced.** Anymail event ordering non-monotonic in practice. Revisit v1.0+. |
| 7 | Rate limiter: ETS-only vs GenServer wrapper | Phase 3 for v0.1 | **Recommend ETS-only for v0.1.** Promote only if cluster-coordinated limits required v0.5+. |
| 8 | Watch-this-dep maintenance plan for `premailex` | v0.5 retro | No credible replacement; contributor pickup is action item; vendoring is fallback. |
| 9 | When to recruit a co-maintainer | v0.5 milestone | Bus factor (PROJECT.md L145, MAINT-02). |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | All core deps verified live on Hex.pm Apr 2026; `mjml` not `mrml` correction materially improves PROJECT.md fidelity. Premailex flagged MEDIUM. |
| Features | **HIGH** | v0.1 / v0.5 / v0.5+ scope locked in D-01..D-20; FEATURES.md adds prioritization, complexity, 7-ecosystem competitor matrix. Anymail taxonomy canonical. |
| Architecture | **HIGH** | Aggregate boundaries verbatim from `mailer-domain-language-deep-research.md` §13; event-ledger schema verbatim from accrue DNA; supervision tree verbatim from `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §2. Two refinements (rate-limiter ETS-only; status state machine app-enforced) flagged MEDIUM. |
| Pitfalls | **HIGH** | 42 pitfalls grounded in 4 prior libs + prompts/ + 2026 ecosystem realities. Each has citable source + lint-time enforceable prevention. Yahooglesoft timeline verified across 5 industry sources. |

**Overall confidence: HIGH.** Most decisions locked upstream; this synthesis adds operational grounding without re-litigating scope.

### Gaps to Address

- **Premailex long-term maintenance.** No credible replacement; flag as "watch this dep" in v1.0 maintenance plan. Revisit at v0.5 retro.
- **Per-tenant rate limiting at cluster scale.** ETS-only correct for v0.1 single-node; if v0.5+ needs cluster coordination, evaluate `:pg` vs Postgres-row-bucket vs Oban Pro `unique:` against a real benchmark.
- **Reconciliation worker design for orphan webhooks.** Mentioned but not specified; defer to Phase 4 / v0.5; need empirical Postmark+SendGrid orphan rates first.
- **`mailglass_admin` LiveView routing macro.** Need to prototype against `~/projects/sigra/lib/sigra/admin/router.ex` before locking.
- **Yahooglesoft compliance contract drift.** Microsoft "softer" than Gmail/Yahoo on RFC 8058 today; may have tightened by v0.5.

---

## Sources

### Primary (HIGH confidence)

- `/Users/jon/projects/mailglass/.planning/PROJECT.md` — locked decisions D-01..D-20
- `/Users/jon/projects/mailglass/.planning/research/{STACK,FEATURES,ARCHITECTURE,PITFALLS}.md`
- `/Users/jon/projects/mailglass/prompts/Phoenix needs an email framework not another mailer.md`
- `/Users/jon/projects/mailglass/prompts/mailglass-engineering-dna-from-prior-libs.md`
- `/Users/jon/projects/mailglass/prompts/mailer-domain-language-deep-research.md`
- `/Users/jon/projects/mailglass/prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md`
- `/Users/jon/projects/mailglass/prompts/elixir-{opensource-libs,oss-lib-ci-cd,plug-ecto-phoenix-system-design}-best-practices-deep-research.md`
- RFC 8058 — https://datatracker.ietf.org/doc/html/rfc8058
- Anymail event taxonomy — https://anymail.dev/en/stable/sending/tracking/

### Secondary (MEDIUM confidence)

- Cloudflare AMP & Signed Exchanges deprecation (Oct 20, 2025 sunset)
- 2026 Bulk email sender requirements — Red Sift, Mailmodo, Google sender requirements FAQ — cross-verified across 5 industry sources Apr 2026
- Hex.pm version pages for all listed deps — verified live 2026-04-21
- GitHub Releases for all third-party CI actions — verified live 2026-04-21

---
*Research completed: 2026-04-21*
*Ready for roadmap: yes*
