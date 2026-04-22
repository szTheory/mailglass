# mailglass

> *Mail you can see through.*

## What This Is

**mailglass** is a batteries-included transactional email framework for Phoenix — the layer that sits on top of [Swoosh](https://hex.pm/packages/swoosh) and ships everything Swoosh deliberately doesn't: HEEx-native components, a LiveView preview/admin dashboard, normalized webhook events, signed unsubscribe tokens with RFC 8058 List-Unsubscribe headers, message-stream separation, suppression lists, an append-only event ledger, multi-tenant routing, and `mix mail.doctor` deliverability checks. It's for senior Phoenix teams shipping production transactional email (welcome flows, password resets, magic links, receipts, notifications) who today rebuild 40% of ActionMailer + Anymail + ActionMailbox by hand on every project.

It is shipped as three sibling Hex packages: `mailglass` (core), `mailglass_admin` (mountable LiveView dashboard), and `mailglass_inbound` (Action Mailbox equivalent — v0.5).

## Core Value

**Email you can see, audit, and trust before it ships.** Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure — without leaving Phoenix or bolting on Node.

If everything else fails, the preview dashboard, normalized event ledger, and one-line `Mailglass.deliver/2 → deliver_later/2` ergonomics must work flawlessly.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

**Foundation (Phase 1 complete — 2026-04-22):**

- [x] HEEx-native component library (`Mailglass.Components`: container, section, row, column, heading, text, button, img, link, hr, preheader) with MSO VML fallbacks for Outlook — Premailex VML preservation guarded by a golden-fixture regression test (D-14)
- [x] Render pipeline: HEEx → Premailex CSS inlining → `data-mg-*` strip → auto-plaintext (Floki walker, preheader excluded per D-15) — 4.3ms on a 10-component template, 12× below the 50ms AUTHOR-03 target
- [x] `Mailglass.Error` struct hierarchy (`SendError`, `TemplateError`, `SignatureError`, `SuppressedError`, `RateLimitError`, `ConfigError`) with closed `:type` atom sets locked in `docs/api_stability.md`; pattern-match by struct, `:cause` excluded from `Jason.Encoder`
- [x] Zero-dep foundation modules: `Mailglass.Config` (NimbleOptions + `:persistent_term` theme cache), `Mailglass.Telemetry` (4-level span helpers + D-33 metadata whitelist + StreamData property test), `Mailglass.Repo` (runtime `transact/1` facade), `Mailglass.IdempotencyKey` (sanitized keys per T-IDEMP-001)
- [x] Optional-dep gateway pattern (`Mailglass.OptionalDeps.{Oban, OpenTelemetry, Mjml, GenSmtp, Sigra}`): `@compile {:no_warn_undefined, ...}` + `available?/0` + degraded fallback; `mix compile --no-optional-deps --warnings-as-errors` is a merge gate

**Persistence + Tenancy (Phase 2 complete — 2026-04-22):**

- [x] Append-only `mailglass_events` Postgres table — SQLSTATE 45A01 trigger raises on UPDATE/DELETE; `Mailglass.Repo` write path translates to `%Mailglass.EventLedgerImmutableError{}` at four sites (`insert/2`, `update/2`, `delete/2`, `transact/1`)
- [x] Idempotency via partial `UNIQUE` index on `mailglass_events(idempotency_key) WHERE idempotency_key IS NOT NULL` + `on_conflict: :nothing`; StreamData convergence property proves 1000 (event, replay 1..10) sequences converge (D-03 `inserted_at: nil` sentinel for UUIDv7 schemas)
- [x] Three tables (`mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`) with indexed `tenant_id` columns, `citext` for case-insensitive address match, `pg_class`-comment version tracking (Oban-style)
- [x] `Mailglass.Tenancy` behaviour + process-dict helpers (`current/0`, `put_current/1`, `with_tenant/2`, `tenant_id!/0`) + `Mailglass.Tenancy.SingleTenant` default no-op resolver + conditionally-compiled `Mailglass.Oban.TenancyMiddleware` (dual-surface `call/2` + `wrap_perform/2` for OSS/Pro)
- [x] `Mailglass.Events.append/1` + `append_multi/3` canonical write path with telemetry spans (counts/IDs/latencies only, zero PII); `Mailglass.Events.Reconciler` find_orphans/attempt_link
- [x] `Mailglass.Outbound.Projector` single-writer for Delivery projection columns (D-14) with D-15 monotonic rules + D-18 optimistic_lock; `Mailglass.SuppressionStore` behaviour + Ecto impl with per-stream `citext` partial unique index

### Active

<!-- Current scope. Building toward these as the v0.1 → v0.5 → v1.0 trajectory. -->

**v0.1 — Core (validation release):**

- [ ] `Mailglass.Mailable` behaviour with `deliver/2`, `deliver_later/2`, `deliver_many/2` (Oban optional, falls back to `Task.Supervisor` with warning)
- [x] HEEx-native component library (`Mailglass.Components`: container, section, row, column, heading, text, button, img, link, hr, preheader) with MSO VML fallbacks for Outlook — Validated in Phase 1
- [x] Render pipeline: HEEx → Premailex CSS inlining → `data-mg-*` strip → auto-plaintext (Floki walker) — Validated in Phase 1
- [ ] Gettext-first i18n with `dgettext("emails", ...)` convention
- [ ] `Mailglass.Adapter.Fake` — in-memory, deterministic, time-advanceable, the release-blocking test target
- [ ] `Mailglass.TestAssertions` extending Swoosh's: `assert_mail_sent`, `last_mail/0`, `wait_for_mail/1`
- [ ] **Dev-mode preview LiveView** (`mailglass_admin`): mailable sidebar with `preview_props/1` auto-discovery, device toggle, dark toggle, HTML/Text/Raw/Headers tabs
- [x] Append-only `mailglass_events` Postgres table protected by trigger raising SQLSTATE 45A01 on UPDATE/DELETE — Validated in Phase 2
- [x] Idempotency keys (`provider_message_id`, `webhook_event_id`) via `UNIQUE` partial index — replay-safe webhooks — Validated in Phase 2 (1000-run StreamData convergence property)
- [x] First-class multi-tenancy: `tenant_id` on every record, `Mailglass.Tenancy.scope/2` behaviour, scope-aware admin queries (Phoenix 1.8 `scope` aligned) — Validated in Phase 2 (SingleTenant default resolver ships as no-op)
- [x] `Mailglass.Error` struct hierarchy (`SendError`, `TemplateError`, `SignatureError`, `SuppressedError`, `RateLimitError`, `ConfigError`) — pattern-match by struct, never by message string — Validated in Phase 1
- [ ] Telemetry spans on `[:mailglass, :outbound, :send, :*]` and `[:mailglass, :preview, :render, :*]` — counts/IDs/latencies only, never PII
- [ ] Webhook plug + event normalization for **Postmark + SendGrid** (Anymail event taxonomy verbatim: `queued/sent/rejected/failed/bounced/deferred/delivered/autoresponded/opened/clicked/complained/unsubscribed/subscribed/unknown` with `reject_reason` ∈ `:invalid | :bounced | :timed_out | :blocked | :spam | :unsubscribed | :other | nil`)
- [ ] `mix mailglass.install` — generates context, migrations, router mounts, webhook plug, Oban worker stub, default mailable + layout, `runtime.exs` config block. Flag matrix: `--no-admin`. Idempotent reruns write `.mailglass_conflict_*` sidecars instead of clobbering. Golden-diff CI against `test/example/` Phoenix host app
- [ ] Open/click tracking **off by default** (signed click rewriting + tracking pixel injection are explicit per-mailable opt-ins; never auto-applied to auth-carrying messages like password resets)
- [ ] Migration guide from raw Swoosh + `Phoenix.Swoosh`
- [ ] CI/CD on GitHub Actions: format, compile `--warnings-as-errors --no-optional-deps`, ExUnit + StreamData property tests + Mox + Fake-adapter release gate, Credo `--strict` + custom checks (`NoRawSwooshSendInLib`, `RequiredListUnsubscribeHeaders`, `NoPiiInTelemetryMeta`), Dialyzer with cached PLT, `mix docs --warnings-as-errors`, `mix hex.audit`, dependency-review, actionlint
- [ ] Conventional Commits + Release Please + sibling-linked-version automation, Hex publish from protected ref only
- [ ] ExDoc with `main: "getting-started"`, full guides (Getting Started, Authoring Mailables, Components, Preview, Webhooks, Multi-Tenancy, Telemetry, Testing, Migration from Swoosh)

**v0.5 — Deliverability + admin (differentiation release):**

- [ ] List-Unsubscribe + List-Unsubscribe-Post headers (RFC 8058) — auto-injected, signed-token unsubscribe controller generator
- [ ] Message-stream separation (`:transactional` vs `:operational` vs `:bulk`) with auto-injection rules per stream
- [ ] `Mailglass.Suppressions` Ecto schema + pre-send check + auto-add on hard-bounce/complaint/explicit-unsubscribe (configurable soft-bounce escalation: 5 in 7 days → hard suppress)
- [ ] Webhook adapters extended to Mailgun + SES + Resend with per-provider HMAC verification (Postmark Basic Auth + IP, SendGrid ECDSA, Mailgun HMAC-SHA256, SES SNS, Resend signing)
- [ ] **Prod-mountable admin LiveView** (`mailglass_admin`): sent-mail inbox with stream-based delivery log, per-delivery event timeline, suppression management UI, resend, search/filter/pagination
- [ ] `mix mail.doctor` — live DNS checks (SPF lookup count, DKIM selector, DMARC alignment, MX, BIMI hint)
- [ ] Per-tenant adapter resolver (different ESPs per customer)
- [ ] Per-domain rate limiting (token bucket via ETS or Oban)
- [ ] DKIM signing helper for self-hosted SMTP relay; pass-through for ESPs
- [ ] Feedback-ID helper with stable SenderID format

**v0.5+ — `mailglass_inbound` (separate sibling package):**

- [ ] `Mailglass.Inbound.Router` DSL: recipient regex, subject pattern, header matcher, function matcher
- [ ] `Mailglass.Inbound.Mailbox` behaviour: `before_process/1`, `process/1`, `bounce_with/2`
- [ ] Ingress plugs for Postmark (JSON), SendGrid (multipart), Mailgun (form/MIME), SES (SNS), Relay (SMTP via gen_smtp)
- [ ] Storage behaviour with LocalFS + S3 reference adapters for raw MIME preservation
- [ ] Async routing via Oban with optional incineration after retention window
- [ ] `Mailglass.Inbound.Conductor` — dev LiveView for synthesizing/replaying inbound mail
- [ ] Mailbox handler can answer with `:accept | :reject | :ignore | {:bounce, reason}`

**Cross-cutting forever-true requirements:**

- [ ] **Dev ergonomics**: install in <5 minutes, send first preview-styled email in first hour, no Node/JS toolchain ever required
- [ ] **Mobile-first responsive admin UI** following [`ui-brand.md`](file:$HOME/.claude/get-shit-done/references/ui-brand.md) component conventions and the mailglass brand book
- [ ] **Documentation depth**: every public function has examples, intent, options, return value, errors, telemetry effects; every guide has a runnable end-to-end example; doctest coverage on the public API
- [ ] **Telemetry/SRE excellence**: structured logs with `request_id`, `tenant_id`, `mailable`, `delivery_id`; OpenTelemetry integration via optional dep; LiveDashboard metrics
- [ ] **Test pyramid**: doctests + ExUnit unit + StreamData property tests (headers, idempotency keys, signature verification) + Mox for behaviours + Fake adapter release gate + real-provider sandbox CI (advisory, daily cron + `workflow_dispatch`)
- [ ] **Shift-left integration tests**: `Mailglass.{MailerCase, WebhookCase, AdminCase}` per-domain test templates with sandbox + Fake adapter + actor seeded
- [ ] **Backwards-compatibility discipline**: `:type` atom set in errors documented in `api_stability.md`, NimbleOptions deprecation warnings, ExDoc `:since` annotations, post-1.0 deprecation cycle in current major + removal in next

### Out of Scope

<!-- Explicit boundaries with reasoning to prevent re-adding. -->

- **Marketing email** (campaigns, contact lists, segmentation, drip automations, A/B testing, broadcast scheduling) — that's [Keila](https://www.keila.io) / [Listmonk](https://listmonk.app) territory and would multiply the maintenance and compliance surface area beyond what one team can sustain. Mailglass is forever **transactional + operational** mail. Per user directive in initialization prompt.
- **Single-pane multi-channel notifications** (push, SMS, in-app, Slack alongside email) — that's a [Noticed](https://github.com/excid3/noticed) / `mail_notifier`-shaped library with a different abstraction. Mailglass stays focused on email so it can be excellent at email. Per user directive.
- **Built-in subscriber management / preference center** — depends on having marketing concerns; if/when individual adopters need it, they can build it on the suppression + consent primitives mailglass exposes.
- **AMP for Email** — declared dead post-Cloudflare's October 2025 sunset; <5% adoption. Don't waste maintenance budget on it.
- **MJML as a default rendering path** — HEEx + Phoenix.Component with MSO fallbacks IS the default. MJML stays as an opt-in `Mailglass.TemplateEngine.MJML` adapter (via the [`mjml`](https://hex.pm/packages/mjml) Hex package, a Rust NIF binding to the `mrml` crate, no Node) for teams who insist on it. The killer differentiator is *not needing* MJML.
- **Standalone ops console / SaaS dashboard** — `mailglass_admin` mounts in adopters' Phoenix apps (sigra/Oban Web pattern); we don't run hosted infrastructure.
- **Backwards compatibility with Bamboo APIs** — Bamboo is in maintenance mode and Swoosh is the Phoenix 1.7+ default. Migration guide is from raw Swoosh + `Phoenix.Swoosh`, not from Bamboo.
- **Pre-Phoenix-1.8 / pre-LiveView-1.0 support** — bleeding edge floor (Elixir 1.18+, OTP 27+, Phoenix 1.8+, LiveView 1.0+, Ecto 3.13+) trades a slice of the long-tail user base for newest features (LiveView streams/async/colocated hooks, Phoenix scopes, schema_redact) and a small CI matrix. Conservative LTS support is **not** a goal.
- **Custom SMTP server** — `gen_smtp` for inbound relay is the floor; mailglass is not building or maintaining an SMTP daemon.
- **Adapter coverage parity with Swoosh at v0.1** — mailglass v0.1 ships **event normalization for Postmark + SendGrid** (the most-used Anymail providers) and lets users keep using any of Swoosh's 12+ adapters for transport. Other providers' webhook normalization arrives in v0.5 (Mailgun, SES, Resend) or via community contribution.
- **Open core / paid Pro tier** — MIT pure OSS across all sibling packages. No `mailglass_pro`. Decision can be revisited at v1.0+ but is not a v0.x consideration.

## Context

**The gap mailglass fills.** Swoosh is the canonical Phoenix mailer (39k downloads/month, healthy maintenance, extensible). It is excellent at the `compose → adapter → deliver` primitive. But everything around it — responsive templates, preview dashboards, normalized webhook events, suppression enforcement, signed unsubscribe, inbound routing, admin tooling, deliverability tooling — is left to each project to rebuild. The 2024 Gmail/Yahoo bulk-sender rules, React Email's emergence, and Phoenix 1.7's removal of `Phoenix.View` made the timing acute. Per the prompts/ research: this is "a real, top-tier gap larger in surface area than the auth or Stripe gaps in Elixir, and more clearly differentiated from incumbents."

**Position relative to the ecosystem.** Mailglass is **not** a Swoosh replacement; it composes on top. It is **not** Bamboo (maintenance mode). It is **not** Keila (newsletter application, AGPLv3, not embeddable). It IS the missing framework layer between Swoosh's transport and a senior Phoenix team's transactional email needs.

**Engineering DNA inherited from prior libraries.** mailglass converges patterns from four shipped libraries (accrue, lattice_stripe, sigra, scrypath):

- **Pluggable behaviours over magic** — narrow callbacks, minimal surface, optional callbacks where lifecycle naturally supports skipping
- **Errors as a public API contract** — structured `Mailglass.Error.t()` with closed `:type` atom set, `:raw_body` escape hatch, one mapper per provider
- **Telemetry as first-class** — `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]` 4-level naming convention, never raise from handlers, never include PII
- **Append-only event ledger with Postgres trigger immutability** — every mutation flows through `Ecto.Multi` that includes a `mailglass_events` row; trigger raises SQLSTATE 45A01 on UPDATE/DELETE; idempotency keys make replays safe no-ops via `UNIQUE` partial index
- **Sibling packages with linked-version releases** — Release Please with `separate-pull-requests: false` + linked-versions plugin
- **Fake adapter as required release gate** — real provider sandbox tests are advisory only (daily cron + `workflow_dispatch`), never block PRs
- **Custom Credo checks for domain rules** — domain invariants enforced at lint time, not just runtime
- **Continuous phase counter & evidence-led backlog triage** — the `.planning/` discipline this very document is part of

**Prior research artifacts** (preserved in `prompts/`, referenced throughout development):

- `Phoenix needs an email framework not another mailer.md` — the founding thesis
- `The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` — current ecosystem state
- `mailglass-brand-book.md` — visual identity, voice, palette (Ink/Glass/Ice/Mist/Paper/Slate)
- `mailer-domain-language-deep-research.md` — canonical vocabulary (Mailable, Message, Delivery, Event, InboundMessage, Mailbox, Suppression)
- `mailglass-engineering-dna-from-prior-libs.md` — the patterns above, distilled
- `elixir-best-practices-deep-research.md`, `ecto-best-practices-deep-research.md`, `phoenix-best-practices-deep-research.md`, `phoenix-live-view-best-practices-deep-research.md`, `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — convention references
- `elixir-opensource-libs-best-practices-deep-research.md`, `elixir-oss-lib-ci-cd-best-practices-deep-research.md` — packaging and shipping references

These files are the source of truth for vocabulary, conventions, and rationale. New planning artifacts should reference them by filename when invoking a decision they ground.

**Brand voice.** mailglass is "clear, exact, confident (not cocky), warm (not cute), modern (not trendy), technical (not intimidating)." The voice is "a thoughtful maintainer." Errors are specific and composed ("Delivery blocked: recipient is on the suppression list" — never "Oops!"). Documentation prefers the direct word ("preview" over "experience the full rendering lifecycle"). Visual palette: **Ink** #0D1B2A, **Glass** #277B96, **Ice** #A6EAF2, **Mist** #EAF6FB, **Paper** #F8FBFD, **Slate** #5C6B7A. Typography: Inter (UI/body), Inter Tight (display), IBM Plex Mono (code). Mobile-first responsive. No glassmorphism, bevels, lens flares, or "literal broken glass" visuals despite the name.

**Target persona / JTBD.** Senior or technical-lead Phoenix developers shipping production transactional email for SaaS apps. Common JTBDs: "let me ship a welcome email I can preview before deploying," "let me trust my password-reset deliveries," "let me audit why a customer's receipt didn't arrive," "let me operationalize bounce/complaint handling without rolling my own webhook plumbing," "let me support multiple tenants with different sending domains."

## Constraints

- **Tech stack**: Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+ / Postgres (Postgrex). Bleeding-edge floor; conservative LTS support is explicitly not a goal.
- **Required deps**: `:ecto_sql`, `:postgrex`, `:phoenix`, `:swoosh`, `:nimble_options`, `:telemetry`, `:gettext`, `:premailex`, `:floki`. Hard required from v0.1.
- **Optional deps** (with `optional: true` in mix.exs and `Code.ensure_loaded?/1` guards): `:oban`, `:opentelemetry`, `:sigra`, `:mjml` (Rust NIF binding to the `mrml` crate — the actual Hex package name; `:mrml` is not on Hex), `:gen_smtp`. CI must pass `mix compile --no-optional-deps --warnings-as-errors`.
- **Persistence**: Postgres only at v0.1. MySQL/SQLite explicitly not supported (advisory locks, JSONB, partial unique indexes are load-bearing).
- **Phoenix coupling**: Phoenix is a hard dep; mailglass is unapologetically Phoenix-first. Plain-Plug or non-Phoenix BEAM apps are not a target.
- **License**: MIT across all sibling packages, forever. Patent grant via the Apache-2.0 path was considered and rejected for ecosystem alignment with Swoosh/Phoenix/Ecto (all MIT).
- **Distribution**: Hex.pm only. Source on GitHub. ExDoc auto-published to HexDocs. No standalone npm packages, no compiled binaries, no Node toolchain anywhere.
- **Compliance**: RFC 8058 (List-Unsubscribe-Post), 2024 Gmail/Yahoo bulk-sender rules, US CAN-SPAM physical address requirement (auto-injected when stream is `:bulk`), GDPR-shaped consent + suppression audit trail.
- **Privacy**: open/click tracking off by default. Telemetry metadata never includes recipient addresses, message bodies, or response payloads — counts/statuses/IDs/latencies only.
- **Security**: webhook signature failures raise `Mailglass.SignatureError` at call site — no recovery from forged webhooks. Unsubscribe tokens are signed (Phoenix.Token / `Plug.Crypto.MessageVerifier`) with rotation support.
- **Maintenance budget**: one-person maintainer realistic; v0.1 must be coastable for 6 months without releases. Provider/compliance churn is expected to consume 20–30% of maintenance time forever.

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| ID | Decision | Rationale | Outcome |
|----|----------|-----------|---------|
| D-01 | Sibling packages from v0.1 (`mailglass`, `mailglass_admin`, `mailglass_inbound` v0.5+) | Per accrue/sigra DNA — admin is mounted in adopters' apps, not run standalone; linked-version releases via Release Please | — Pending |
| D-02 | MIT license across all packages | Aligns with Swoosh/Phoenix/Ecto; maximizes adoption; no commercial path planned | — Pending |
| D-03 | Marketing email **permanently** out of scope | Different problem (lists/segments/campaigns), different compliance surface, different abstraction — that's Keila/Listmonk territory; keeps mailglass excellent at one thing | — Pending |
| D-04 | Single-pane multi-channel notifications **out** | That's a Noticed-shaped lib (`mail_notifier`); mailglass stays email-only | — Pending |
| D-05 | Inbound (Action Mailbox equivalent) **in scope** as `mailglass_inbound` v0.5 sibling | Inbound webhook plumbing shares HMAC + plug + event-normalization infrastructure with v0.5 deliverability work — natural pairing | — Pending |
| D-06 | Bleeding-edge version floor (Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+) | Newest features (streams, async, scopes, schema_redact, colocated hooks); smallest CI matrix; trades long-tail compatibility for momentum | — Pending |
| D-07 | Ecto + Phoenix **required**; Oban **optional** | mailglass is a Phoenix-first framework — admit it. `deliver_later/2` degrades to `Task.Supervisor` with a warning when Oban absent | — Pending |
| D-08 | Open/click tracking **off by default** | Apple Mail Privacy Protection (~50% consumer mail) makes opens noisy; signed click rewriting is a legal liability if misconfigured; auth-carrying messages (password reset, magic link) must NEVER have rewritten links | — Pending |
| D-09 | Multi-tenancy **first-class from v0.1** | Phoenix 1.8 scopes default makes this the right time; harder to retrofit; per-tenant adapter resolver is a 2nd-most-asked feature in research | — Pending |
| D-10 | v0.1 normalizes **Postmark + SendGrid** webhooks; Mailgun/SES/Resend land in v0.5 | Most-used per Anymail data; smallest validation matrix; Swoosh handles transport for any of its 12+ adapters in the meantime | — Pending |
| D-11 | Preview LiveView is **dev-only at v0.1**, prod admin lands at v0.5 | Aligns research recommendation; v0.1 surface stays scoped; admin UI needs event taxonomy (v0.5 work) to be useful | — Pending |
| D-12 | Full `mix mailglass.install` with golden-diff CI from v0.1 | "Batteries-included" brand promise demands one-command setup; golden-diff against `test/example/` Phoenix host app catches install regressions | — Pending |
| D-13 | Test pyramid: doctests + ExUnit + StreamData property + Mox + **Fake adapter release gate** + real-provider sandbox advisory only | Per accrue DNA — real provider tests on daily cron + `workflow_dispatch`, never block PRs; Fake is the line | — Pending |
| D-14 | Anymail event taxonomy **verbatim** for normalized webhook events | Don't reinvent; Anymail is the multi-language standard; lowers cognitive cost for polyglot teams | — Pending |
| D-15 | `mailglass_events` table is **append-only**, enforced by Postgres trigger raising SQLSTATE 45A01 | Per accrue DNA — single source of truth for admin timeline, replay, audit trails, analytics; immutability is structural, not policy | — Pending |
| D-16 | Conventional Commits + Release Please + sibling-linked-version automation; Hex publish from protected ref only | Per OSS CI/CD best practices; squash-merge workflow keeps casual contributor UX low-friction | — Pending |
| D-17 | Custom Credo checks enforce domain rules (`NoRawSwooshSendInLib`, `RequiredListUnsubscribeHeaders`, `NoPiiInTelemetryMeta`) | Per engineering DNA — invariants caught at lint time, not just runtime | — Pending |
| D-18 | Renderer default is HEEx + `Phoenix.Component` with MSO VML fallbacks; MJML is opt-in `Mailglass.TemplateEngine.MJML` via the `:mjml` Hex package (Rust NIF binding to the `mrml` crate; the bare `:mrml` package does not exist on Hex) | Native composition, no Node, killer differentiator vs React Email + Mailing | — Pending |
| D-19 | Brand voice & visual identity locked to `prompts/mailglass-brand-book.md` (Ink/Glass/Ice/Mist/Paper/Slate palette, Inter + IBM Plex Mono, mobile-first, no glassmorphism) | Brand discipline prevents drift toward generic SaaS or growth-marketing aesthetic | — Pending |
| D-20 | Domain vocabulary locked to `prompts/mailer-domain-language-deep-research.md` (Mailable / Message / Delivery / Event / InboundMessage / Mailbox / Suppression as the irreducible nouns) | Borrowed from battle-tested libs (ActionMailer, ActionMailbox, Anymail, Laravel Mailable); avoid "Email" or "Status" as ambiguous primitives | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions with `D-NN` ID
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
5. Brand voice / domain vocabulary still aligned with `prompts/` source-of-truth files? Reconcile any drift.

---
*Last updated: 2026-04-22 after Phase 2 (Persistence + Tenancy) completion*
