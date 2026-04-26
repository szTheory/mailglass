# Feature Research

**Domain:** Phoenix-native transactional email framework (composable on Swoosh)
**Researched:** 2026-04-21
**Confidence:** HIGH (sourced from PROJECT.md locked scope + four prior-libs DNA + 2026 ecosystem map; comparison anchors are battle-tested incumbents)

## Executive Framing

Mailglass is **not** competing on raw send throughput, adapter coverage, or templating-language novelty. Swoosh already covers the `compose → adapter → deliver` primitive, has 12+ adapters, and is the Phoenix 1.7+ default. Mailglass competes on **observability + compliance + DX surface area** that every senior Phoenix team currently rebuilds by hand:

- Preview/admin UI native to LiveView (no Node sidecar)
- Webhook normalization across providers (Anymail taxonomy)
- Append-only event ledger as the audit/replay/timeline source of truth
- One-click unsubscribe + suppression + message-stream policy enforcement
- Multi-tenancy as a first-class concern, not a retrofit
- Inbound routing (sibling package) sharing the same plumbing

The comparison set is not other Elixir libs (there are none in this slot) — it's **Rails ActionMailer + Anymail + ActionMailbox**, **Django Anymail**, **Laravel Mailcoach + Mailable**, **React Email / Mailing**, and the ESP dashboards (Postmark Activity, SendGrid Activity Feed, Resend Logs).

## Feature Landscape

### Table Stakes (v0.1 — Must-Have, Users Won't Adopt Without)

These are baseline expectations for a 2026 transactional framework. Missing any one of them = an adopter says "this is unfinished, I'll keep rolling my own."

| # | Feature | Why Expected | Complexity | Dependencies | Source citation |
|---|---------|--------------|------------|--------------|-----------------|
| TS-01 | `Mailglass.Mailable` behaviour with `deliver/2`, `deliver_later/2`, `deliver_many/2` (Oban optional, falls back to `Task.Supervisor` with warning) | Bamboo had `deliver_later`, Swoosh deliberately does not — the #1 cited Swoosh gap on ElixirForum (65703). Without it, every adopter wires Oban manually within their first hour. | M | Swoosh adapter, optional Oban, Task.Supervisor fallback, Telemetry (TS-11) | PROJECT.md L31; primary thesis §6 L297-301; ecosystem map §11 L183 |
| TS-02 | HEEx-native component library: `<.container>`, `<.section>`, `<.row>`, `<.column>`, `<.heading>`, `<.text>`, `<.button>`, `<.img>`, `<.link>`, `<.hr>`, `<.preheader>` — all with MSO VML fallbacks baked in for Outlook | Phoenix 1.7 removed `Phoenix.View`; teams either roll their own components or pull in MJML+mrml NIF (which keeps breaking on HEEx parser changes per ElixirForum 69206/73978). HEEx components are the natural Phoenix-native answer. | L | None (renderer is the foundation) | PROJECT.md L32; primary thesis §3 L93-97, §6 L334; engineering DNA §4.7 |
| TS-03 | Render pipeline: HEEx → Premailex CSS inlining → minify → auto-plaintext via Floki | Email clients require inlined CSS (Gmail strips `<style>`; Outlook ignores most). Plaintext alternative is required by spam filters and accessibility. Premailex is the canonical inliner; no batteries-included assembly exists today. | M | TS-02 (component library), Premailex, Floki | PROJECT.md L33; primary thesis §1 L24, §6 L218 |
| TS-04 | Gettext-first i18n with `dgettext("emails", ...)` convention + per-mailable locale resolver | Phoenix is Gettext-native; transactional email is the #1 i18n surface (welcome emails, receipts, password resets per locale). No prior Elixir mailer ships an opinionated i18n convention. | S | Gettext (already in stack) | PROJECT.md L34; primary thesis §6 L268 |
| TS-05 | `Mailglass.Adapter.Fake` — in-memory, deterministic, time-advanceable adapter; the release-blocking test target | Per accrue DNA: real-provider sandbox tests are advisory-only. The Fake is what every CI run depends on. Without it, adopters can't write deterministic tests of bounce/complaint flows. | M | TS-11 telemetry, append-only ledger (TS-06) | PROJECT.md L35; engineering DNA §3.5 L292-300 |
| TS-06 | Append-only `mailglass_events` Postgres table protected by trigger raising SQLSTATE 45A01 on UPDATE/DELETE | Foundation for admin timeline, webhook replay, audit trail, analytics. Per accrue's hardest-won lesson: every mutation must flow through `Ecto.Multi` writing the data row + event row in one txn. Replays via idempotency keys become safe no-ops. | M | Postgres trigger, Ecto.Multi, idempotency keys (TS-07) | PROJECT.md L37; engineering DNA §3.6 L302-329 (D-15) |
| TS-07 | Idempotency keys (`provider_message_id`, `webhook_event_id`) via `UNIQUE` partial index — replay-safe webhooks | ESPs replay webhooks on 5xx responses. Without idempotency, the same delivered/bounced event creates duplicate ledger rows. Mailgun/SES retry aggressively. | S | TS-06 (event ledger) | PROJECT.md L38; engineering DNA §3.6 L324 |
| TS-08 | First-class multi-tenancy: `tenant_id` on every record, `Mailglass.Tenancy.scope/2` behaviour, scope-aware admin queries (Phoenix 1.8 `scope` aligned) | Phoenix 1.8 generators emit scope-aware contexts; multi-tenancy retrofit is famously painful (Triplex/Apartmentex are dormant per ecosystem map §2 L41). Per-tenant adapter resolver is the second-most-asked-for feature in research. | L | None (foundational) | PROJECT.md L39 (D-09); engineering DNA §4.3 L437; ecosystem map §2 L41 |
| TS-09 | `Mailglass.Error` struct hierarchy (`SendError`, `TemplateError`, `SignatureError`, `SuppressedError`, `RateLimitError`, `ConfigError`) — pattern-match by struct, never by message string | Per lattice_stripe + accrue DNA: closed `:type` atom set, `:raw_body` escape hatch, one mapper per provider. Adopters need to pattern-match on errors in their own callsites; string matching breaks across patches. | S | None | PROJECT.md L40; engineering DNA §2.4 L78-104 |
| TS-10 | Telemetry spans on `[:mailglass, :outbound, :send, :*]` and `[:mailglass, :preview, :render, :*]` — counts/IDs/latencies only, never PII | Convergent across all 4 prior libs (engineering DNA §2.5). `:telemetry.span/3` wrapped in `Mailglass.Telemetry.span/3`. Adopters expect to wire PromEx, OpenTelemetry, LiveDashboard against published events. | S | Telemetry hex dep | PROJECT.md L41; engineering DNA §2.5 L107-135, §4.6 L519-533 |
| TS-11 | Webhook plug + event normalization for **Postmark + SendGrid** — Anymail event taxonomy verbatim (queued/sent/rejected/failed/bounced/deferred/delivered/autoresponded/opened/clicked/complained/unsubscribed/subscribed/unknown) with `reject_reason ∈ :invalid \| :bounced \| :timed_out \| :blocked \| :spam \| :unsubscribed \| :other \| nil` | The Django Anymail taxonomy is the de-facto standard across 14+ providers in three other ecosystems. Postmark + SendGrid are the most-used Anymail providers — covers most v0.1 adopters. Mailgun/SES/Resend land in v0.5. | L | TS-06 (event ledger), TS-07 (idempotency), CachingBodyReader for raw-body HMAC | PROJECT.md L42 (D-10, D-14); primary thesis §3 L83-89; engineering DNA §4.5 L495-516 |
| TS-12 | Webhook signature verification: Postmark Basic Auth + IP allowlist; SendGrid ECDSA signing | Forged webhooks = arbitrary suppression manipulation, fraudulent unsubscribes, fake "delivered" status. Failures must raise `Mailglass.SignatureError` with no recovery path at call site (per accrue D-08). | M | TS-11, TS-09 (error struct) | PROJECT.md L42; engineering DNA §6 L699 (anti-pattern #5); primary thesis §3 L116-117 |
| TS-13 | Dev-mode preview LiveView (`mailglass_admin`): mailable sidebar with `preview_props/1` auto-discovery, device toggle (320/480/600/768), dark/light toggle, HTML/Text/Raw/Headers tabs | Rails ActionMailer::Preview, React Email's preview server, and Mailing.dev all ship this. Swoosh's `Plug.Swoosh.MailboxPreview` is in-memory and doesn't auto-refresh (ElixirForum 46094, 46034). Without this, adopters bolt on a Node toolchain. | L | TS-02 (components), TS-03 (render pipeline), `mailglass_admin` sibling package, Phoenix LiveView 1.0+ | PROJECT.md L36 (D-11); primary thesis §6 L313-323 — "the killer differentiator" |
| TS-14 | `Mailglass.TestAssertions` extending Swoosh's: `assert_mail_sent`, `last_mail/0`, `wait_for_mail/1` | Swoosh's test assertions are minimal. Laravel's `Mail::fake()` + `Mail::assertSent(fn ...)` is the gold standard test DSL — process-isolated, no manual cleanup. BEAM's process isolation makes this trivial in Elixir. | S | TS-05 (Fake adapter) | PROJECT.md (cross-cutting test pyramid L80); primary thesis §3 L77, §6 L309 |
| TS-15 | Open/click tracking **off by default** (signed click rewriting + tracking pixel injection are explicit per-mailable opt-ins; never auto-applied to auth-carrying messages like password resets) | GDPR/ePrivacy legal hot zone; Apple Mail Privacy Protection (~50% consumer mail) makes opens noisy; auto-rewriting password-reset links is a security catastrophe. This is a first-class differentiator vs commercial ESPs that ship tracking on. | S | None | PROJECT.md L43 (D-08); primary thesis §4 L162-165 |
| TS-16 | `mix mailglass.install` — generates context, migrations, router mounts, webhook plug, Oban worker stub, default mailable + layout, `runtime.exs` config block. Flag matrix: `--no-admin`. Idempotent reruns write `.mailglass_conflict_*` sidecars. Golden-diff CI against `test/example/` Phoenix host app. | "Batteries-included" brand promise demands one-command setup. Per sigra/accrue DNA: golden-diff CI catches install regressions; conflict sidecars prevent clobber on rerun. Time-to-first-preview-email = first hour. | XL | TS-01..TS-15 (installer wires them all) | PROJECT.md L44 (D-12); engineering DNA §3.2 L246-260 |
| TS-17 | Migration guide from raw Swoosh + `Phoenix.Swoosh` (NOT from Bamboo) | Bamboo migrants are already on Swoosh per Phoenix 1.7 default; new adopters are coming from `Phoenix.Swoosh` + manual Premailex wiring. Without this guide, adoption stalls at "what does this replace?". | S | TS-01 docs | PROJECT.md L45 (out-of-scope: Bamboo bw-compat L94); primary thesis §1 L17 |
| TS-18 | Conventional Commits + Release Please + sibling-linked-version automation; Hex publish from protected ref only | Convergent across all 4 prior libs. Without it, sibling packages drift in version, CHANGELOG goes stale, every release is manual (and breaks). Day-1 infrastructure. | M | None | PROJECT.md L48 (D-16); engineering DNA §2.3 L65-76 |
| TS-19 | ExDoc with `main: "getting-started"`, full guides (Getting Started, Authoring Mailables, Components, Preview, Webhooks, Multi-Tenancy, Telemetry, Testing, Migration from Swoosh) | Adopters land on HexDocs first. `main: "getting-started"` lands them on a guide rather than a README — better framing for a multi-feature framework. Doc-contract tests lock snippets to real code. | M | All v0.1 features (each needs a guide) | PROJECT.md L49; engineering DNA §3.10 L368-374 |
| TS-20 | CI/CD: format, compile `--warnings-as-errors --no-optional-deps`, ExUnit + StreamData property tests + Mox + Fake-adapter release gate, Credo `--strict` + custom checks (`NoRawSwooshSendInLib`, `RequiredListUnsubscribeHeaders`, `NoPiiInTelemetryMeta`), Dialyzer with cached PLT, `mix docs --warnings-as-errors`, `mix hex.audit`, dependency-review, actionlint | Convergent infrastructure across all 4 prior libs. Without strict CI, contributions break the lib silently. Custom Credo checks catch domain rule violations at lint time. | L | TS-05 (Fake adapter), TS-08 (Tenancy for Credo check), TS-10 (Telemetry for PII check) | PROJECT.md L46-47 (D-13, D-17); engineering DNA §2.2, §2.8 |

**Why these are non-negotiable for v0.1:** Drop any of them and the lib fails the "do I trust this in production for password resets and receipts?" question. Adopters compare to ActionMailer + Anymail; that bar is the floor.

### Differentiators (Competitive Moats — Unique to mailglass at v0.1 or v0.5)

These are what make adopters say "I'd pick mailglass over rolling my own + Swoosh + a Node sidecar." Each one is something no other Phoenix lib offers, and most can't be replicated without rewriting in another stack.

| # | Feature | Value Proposition | Complexity | Dependencies | Source citation |
|---|---------|-------------------|------------|--------------|-----------------|
| DF-01 | LiveView preview dashboard with live-assigns form, device/dark toggle, client simulator, hot reload — same surface that becomes the prod admin in v0.5 | Rails/Laravel/Django can't match this without a separate Node tooling chain (React Email, Mailing.dev). Phoenix LiveView's real-time push makes the live-assigns editor trivial; in JS-land it's a fragile Next.js bundle (React Email issue #2432). | L | TS-13 (preview core), Phoenix LiveView 1.0+, LiveReload | Primary thesis §6 L313-323, §9 L388-390 — "the single feature worth being stubborn about" |
| DF-02 | HEEx-native components, no Node/JS toolchain ever required | The "no Node" promise is the entire reason a Phoenix team picks this over piping JSX through `react-email render`. Phoenix has the full component model (attr/slot, compile warnings); the only thing missing is the email-safe HTML primitives + MSO fallbacks. | L (covered by TS-02) | TS-02 | PROJECT.md L76 (cross-cutting); D-18 L170; primary thesis §3 L108-110 |
| DF-03 | Multi-tenancy first-class from v0.1 with per-tenant adapter resolver in v0.5 | "Different tenants on different ESPs" is the second-most-asked feature in primary research and a strict moat: nobody else ships a tenant-scoped adapter resolver out of the box. Mailcoach has "unlimited-domains license" as a paid feature; Phoenix gets it free. | L (TS-08 base) + M (resolver in v0.5, see DV-08) | TS-08, Phoenix 1.8 scopes | PROJECT.md L39 (D-09); primary thesis §6 L309 |
| DF-04 | Append-only Postgres event ledger with trigger immutability | Differentiator vs ESP dashboards (which lose history on retention boundary) and vs every other framework (which models status as mutable column). Becomes the engine for replay, audit export, analytics rollups, admin timeline — one schema, four use cases. | M (covered by TS-06) | TS-06, TS-07 | D-15 L168; engineering DNA §3.6 |
| DF-05 | Normalized event taxonomy across all providers with `esp_event` raw escape hatch | Anymail's taxonomy ported verbatim is portable intellectual property. Adopters who switch from Postmark to SendGrid don't rewrite their handlers. ESPs themselves don't standardize this; only Anymail does and it's not in Elixir. | M (covered by TS-11) | TS-11 | D-14 L167; primary thesis §3 L83-89 |
| DF-06 | Tracking off by default (privacy-first stance, opt-in per-mailable) | Differentiator vs commercial ESPs and most frameworks that auto-rewrite. Aligns with brand voice ("calm under pressure," "infrastructure not magic"). GDPR-defensible by default. | S (covered by TS-15) | TS-15 | D-08 L160; primary thesis §4 L162-165 |
| DF-07 | `mix mail.doctor` — live DNS deliverability checks (SPF lookup count, DKIM selector, DMARC alignment, MX, BIMI hint) | No Elixir lib does this. The `mailibex` lib has DKIM primitives but isn't on Hex and isn't integrated. Senior teams hit Gmail/Yahoo bulk-sender rules and have nowhere to turn for "is my domain set up right?" diagnostic. | M | DNS resolution (Erlang `:inet_res`); v0.5 feature | PROJECT.md L58 (v0.5); primary thesis §4 L160 (SHOULD list); engineering DNA §4.7 L542 |
| DF-08 | `mailglass_admin` as a separate sibling package — mountable, not standalone | Mounted in adopters' Phoenix apps via router macro (sigra/Oban Web pattern). Differentiator vs Mailpit (separate Go binary), Mailcoach (PHP standalone), Postmark Activity (hosted SaaS). Lives inside the app where the actor/scope is already known. | L | TS-13, sigra-style router macro, daisyUI 5 + Tailwind v4 | D-01 L153; engineering DNA §3.1 L232-244, §4.4 L458-493 |
| DF-09 | Custom Credo checks enforcing domain rules at lint time | Per all 4 prior libs DNA: `NoRawSwooshSendInLib`, `RequiredListUnsubscribeHeaders`, `NoPiiInTelemetryMeta`, `NoUnscopedTenantQueryInLib`. Adopters get domain invariants enforced in their own codebase via the lib's `requires:` config. | M | TS-20 (CI), Credo | D-17 L169; engineering DNA §2.8 L177-187 |
| DF-10 | Doctest + `preview_props/1` colocation: compile-time signature alignment between fixtures and real callers | Rails' #1 preview footgun is silent drift between preview modules and real callers (mailers update, previews don't). Colocating `preview_props/1` on the same module makes the compiler enforce signature alignment via dialyzer + warnings. | S | TS-13 (preview), Dialyzer | Primary thesis §6 L292-296, §6 L306 — "The Rails footgun fix" |
| DF-11 | `Mailglass.Adapter.Fake` is a stateful, time-advanceable, event-triggerable in-memory adapter (not just a stub) | Per accrue DNA: tests can fast-forward time, trigger bounces/complaints/opens deterministically, simulate inbound webhooks. JSON-compatible state machine. Massively beats Swoosh's `:test` adapter (which is just a process-dict log). | M (covered by TS-05) | TS-05 | engineering DNA §3.5 L292-300 |
| DF-12 | Anymail-shape `tags`, `metadata`, `merge_data`, `merge_global_data`, `merge_headers`, `template_id`, `track_opens`, `track_clicks`, `esp_extra` first-class on Mailable | Django Anymail's most-used surface. Adopters set tag/metadata once; Mailglass routes them to whichever adapter language (SendGrid `personalizations[]`, Postmark `Tag`/`Metadata`, etc.). v0.1 supports the fields; per-adapter mapping fills out in v0.5. | M | TS-01 (Mailable), per-adapter mapping | Primary thesis §3 L83-89 |

**Together, DF-01..DF-08 form the "irreplicable Phoenix advantage."** They lean directly on LiveView 1.0+, OTP process isolation, Phoenix.Component, Postgres triggers, and one-language-from-DB-to-UI. None of them can be cleanly ported to Rails/Laravel/Django without losing the integration story.

### Anti-Features (Deliberately NOT Building — Document Why)

These are things adopters or contributors will request. Documenting why they're out of scope (with the alternative) prevents re-litigation and scope creep.

| # | Anti-Feature | Why People Will Ask | Why Mailglass Won't | Alternative |
|---|--------------|---------------------|---------------------|-------------|
| AF-01 | Marketing email (campaigns, contact lists, segmentation, drip automations, A/B testing, broadcast scheduling) | Every "email lib" eventually gets a "wouldn't this be great for newsletters?" issue; Mailcoach proves the embeddable-marketing slot has demand. | Different problem space, different compliance surface (CAN-SPAM physical address, double opt-in, list hygiene), different abstraction. Multiplies maintenance and compliance burden beyond a one-person maintainer can sustain. PERMANENTLY locked per user directive in initialization prompt. | [Keila](https://www.keila.io) (standalone app, AGPLv3) or [Listmonk](https://listmonk.app) (standalone app). |
| AF-02 | Single-pane multi-channel notifications (SMS, push, in-app, Slack alongside email) | Rails' Noticed gem is popular; "mail_notifier" is the obvious analog. | That's a different abstraction (event-first with per-channel delivery, like Noticed). Mailglass stays focused on email so it can be excellent at email. | A future companion package (`mail_notifier`-shaped) or [Noticed-equivalent](https://github.com/excid3/noticed); Pigeon for push, ExTwilio for SMS. |
| AF-03 | Hosted SaaS dashboard / standalone ops console | "Just give me a hosted dashboard at app.mailglass.io." | Not a SaaS company. `mailglass_admin` mounts in adopters' Phoenix apps (sigra/Oban Web pattern); no hosted infrastructure to run. | Mailpit for local dev SMTP catching; Postmark/Resend hosted dashboards for ESP-side observability. |
| AF-04 | AMP for Email | "Interactive email is the future." | Declared dead post-Cloudflare's October 2025 sunset; <5% sender adoption per ESPC data. Don't waste maintenance budget on a dying spec. | Plain HTML email with progressive enhancement; no special handling. |
| AF-05 | MJML as the default rendering path | "MJML is the standard responsive email DSL; just use mrml." | HEEx + Phoenix.Component with MSO fallbacks IS the default. The killer differentiator is *not needing* MJML. MJML stays as opt-in `Mailglass.TemplateEngine.MJML` adapter via mrml NIF for teams who insist. | Use the default HEEx components (TS-02); opt into MJML via `renderer: :mjml` config flag (post-v0.5). |
| AF-06 | Bamboo backwards compatibility (`Bamboo.Email` shim, `deliver_now`/`deliver_later` API parity) | Bamboo had `deliver_later`; some legacy apps still use it. | Bamboo is in maintenance mode and Swoosh has been the Phoenix 1.7+ default for 4+ years. Migration guide is from Swoosh + Phoenix.Swoosh. Supporting two API shapes doubles the surface area. | Migration guide TS-17. |
| AF-07 | Pre-Phoenix-1.8 / pre-LiveView-1.0 support (Elixir <1.18, OTP <27, Phoenix <1.8, LiveView <1.0, Ecto <3.13) | "Our app is on Phoenix 1.7, can we still use mailglass?" | Bleeding-edge floor trades a slice of long-tail compatibility for newest features (LiveView streams/async/colocated hooks, Phoenix scopes, `@schema_redact`, daisyUI 5) and a small CI matrix. Conservative LTS support is explicitly not a goal. | Stay on Swoosh + Phoenix.Swoosh + manual Premailex; or upgrade to Phoenix 1.8. |
| AF-08 | Open/click tracking on by default | "All ESPs do this." | GDPR/ePrivacy legal hot zone; Apple MPP makes opens noisy; rewriting auth links is a security catastrophe. Privacy-first stance is a brand pillar (TS-15, DF-06). Opt-in per-mailable; never auto-applied to password resets. | Explicit `track_opens: true, track_clicks: true` per-mailable; never on transactional auth flows. |
| AF-09 | Open core / paid Pro tier (`mailglass_pro`) | "Oban Pro proves Elixir infra can be commercially sustainable." | MIT pure OSS across all sibling packages, no commercial path planned at v0.x. Aligns with Swoosh/Phoenix/Ecto licensing. Decision can be revisited at v1.0+ but is not a v0.x consideration. | All features ship in MIT-licensed sibling packages forever. |
| AF-10 | Adapter coverage parity with Swoosh at v0.1 | "Why don't you support Mailgun/SES/Resend at launch?" | Swoosh handles transport for any of its 12+ adapters out of the box. Mailglass v0.1 normalizes **webhook events** for Postmark + SendGrid (the most-used Anymail providers per cross-language data). Mailgun/SES/Resend webhook normalization arrives in v0.5. | Use any Swoosh adapter for transport; v0.1 ships event-normalization for the top 2; rest in v0.5. |
| AF-11 | Custom SMTP server (replacing or extending gen_smtp) | "We want a turnkey inbound SMTP relay." | `gen_smtp` for inbound relay is the floor; mailglass is not building or maintaining an SMTP daemon. That's a 10-person-team product. | Use `gen_smtp` directly for SMTP relay needs; mailglass_inbound v0.5+ provides routing on top. |
| AF-12 | Built-in subscriber management / preference center | "I want recipients to manage which emails they get." | Depends on having marketing concerns (which AF-01 rules out). Requires lists, segments, preference categorization. Adopters can build it on the suppression + consent primitives mailglass exposes. | Use `Mailglass.Suppression` + a custom Phoenix LiveView preference page wired to your own user schema. |
| AF-13 | MySQL / SQLite database support | "Postgres-only is restrictive." | Advisory locks, JSONB, partial unique indexes, BEFORE-UPDATE-OR-DELETE triggers are all load-bearing for the event ledger and idempotency story. MySQL has no RETURNING, no native JSONB equivalent that supports the same query surface. | Adopters needing MySQL stay on raw Swoosh + custom event tracking. |
| AF-14 | Plain-Plug or non-Phoenix BEAM app support | "I'm using Plug-only, can I still use mailglass?" | Phoenix is a hard dep; mailglass is unapologetically Phoenix-first. The router macros, LiveView preview, Component-based templates all assume Phoenix. | Use Swoosh directly. |
| AF-15 | Built-in LLM-powered email composition / "AI subject line optimizer" / spam-score predictor that calls an external API | "Every modern dev tool has AI features." | Brand voice is "infrastructure not magic" (per brand book §10.2). AI-flavored copy and dependencies actively conflict with the brand pillars (clarity, calm, precision). | Adopters can call OpenAI/Anthropic directly from their own contexts; mailglass does not bake in an AI dep. |
| AF-16 | Status field as primary truth ("status: :delivered") on `mailglass_sends` | "Every other ORM models email this way." | Status as primary truth = lossy history, race conditions, hard to audit. The append-only event ledger (TS-06) is the source of truth; summary fields like `last_event_at`, `delivered_at`, `bounced_at` are projections. | Use derived summary fields on the send aggregate, computed from the event ledger. (Per domain language doc §12 L702-733.) |

### v0.5 Features (Deliverability Wave — Differentiation Release)

These ship in the v0.5 milestone. They build on the v0.1 foundation and constitute the "production-ready for senior Phoenix teams shipping to Gmail/Yahoo/Microsoft" upgrade.

| # | Feature | Why v0.5 (not v0.1) | Complexity | Dependencies | Source citation |
|---|---------|---------------------|------------|--------------|-----------------|
| DV-01 | List-Unsubscribe + List-Unsubscribe-Post headers (RFC 8058) — auto-injected, signed-token unsubscribe controller generator | Required by Gmail/Yahoo/Microsoft bulk-sender rules (Feb 2024 → Nov 2025 enforcement, escalated to 550-class permanent rejections). Zero Elixir libs help with this today. v0.5 because it requires the suppression schema (DV-03) to be useful end-to-end. | L | DV-03 (suppression), Phoenix.Token / Plug.Crypto.MessageVerifier, DV-02 (stream separation) | PROJECT.md L53; primary thesis §4 L143-148; engineering DNA §4.7 L540 |
| DV-02 | Message-stream separation (`:transactional`, `:operational`, `:bulk`) with auto-injection rules per stream | Postmark's Message Streams concept generalized. `:bulk` auto-adds `List-Unsubscribe`, `List-Unsubscribe-Post`, `Precedence: bulk`, physical-address footer (CAN-SPAM); `:transactional` auto-adds `Auto-Submitted: auto-generated`. Streams encode policy at compile time, not at every callsite. | M | TS-01 (Mailable), DV-01 (unsubscribe headers) | PROJECT.md L54; primary thesis §3 L116-122; domain language §4 L228-241 |
| DV-03 | `Mailglass.Suppressions` Ecto schema + pre-send check + auto-add on hard-bounce/complaint/explicit-unsubscribe (configurable soft-bounce escalation: 5 in 7 days → hard suppress) | Required by deliverability stack: must refuse to send to suppressed addresses (Gmail spam rate <0.30% threshold). Pre-send check returns `{:error, %SuppressedError{}}`. Soft-bounce escalation is an industry-standard pattern. | L | TS-06 (event ledger), TS-09 (SuppressedError), TS-11 (webhook events trigger auto-add) | PROJECT.md L55; primary thesis §4 L155 (suppression list MUST); engineering DNA §4.7 L543 |
| DV-04 | Webhook adapters extended to Mailgun + SES + Resend with per-provider HMAC verification (Mailgun HMAC-SHA256, SES SNS, Resend signing) | TS-11 covered Postmark + SendGrid (the most-used Anymail providers per data). Mailgun/SES/Resend complete the practical adapter coverage. SES uses SNS notifications (not webhooks proper) — needs a separate ingress shape. | L | TS-11 (webhook plug + normalization), TS-12 (signature verification), per-provider mapper modules | PROJECT.md L56 (D-10 L162); primary thesis §3 L116-122 |
| DV-05 | Prod-mountable admin LiveView (`mailglass_admin`): sent-mail inbox with stream-based delivery log, per-delivery event timeline, suppression management UI, resend, search/filter/pagination | The "killer differentiator" per primary thesis §6 L388-390. v0.5 because it requires the event taxonomy (TS-11) and suppression (DV-03) to be useful — empty timelines aren't compelling. Prod safety requires step-up auth on destructive actions. | XL | TS-13 (preview core), TS-06 (event ledger), DV-03 (suppression), DV-04 (full provider coverage), Flop pagination, sigra/PhxGenAuth integration | PROJECT.md L57 (D-11 L163); primary thesis §6 L313-323; engineering DNA §4.4 L458-493 |
| DV-06 | `mix mail.doctor` — live DNS checks (SPF lookup count, DKIM selector, DMARC alignment, MX, BIMI hint) | DF-07 elaborated. Unique in the Elixir ecosystem; closes the "is my sending domain set up right?" gap. Senior teams hitting Gmail bulk-sender rejections need a diagnostic. | M | Erlang `:inet_res`, NimbleOptions config schema for verification options | PROJECT.md L58; primary thesis §4 L160 (SHOULD list) |
| DV-07 | Per-tenant adapter resolver (different ESPs per customer) | DF-03 v0.5 piece. `config :mailglass, resolver: {MyApp.TenantRouter, :resolve, []}` lets every send resolve to a tenant-scoped adapter config (Postmark Server / SendGrid Subuser / Resend per-domain key). Stripe-Connect-style multi-tenancy without ceremony. | M | TS-08 (Tenancy), `Mailglass.Adapter` behaviour | PROJECT.md L59; primary thesis §6 L309 |
| DV-08 | Per-domain rate limiting (token bucket via ETS or Oban) | Required for SES (per-account send rate), Postmark (per-server burst limits), Mailgun (per-account RPS). Hammer 7.x has the algorithms; integration into the send pipeline keeps adopters out of the rate-limit-error game. | M | Hammer 7.x or ETS counter, telemetry for emit on throttle | PROJECT.md L60; primary thesis §4 L160 (SHOULD list); ecosystem map §7 L127 |
| DV-09 | DKIM signing helper for self-hosted SMTP relay; pass-through for ESPs | Adopters using gen_smtp + their own SMTP relay (rare but real) need DKIM signing. ESPs sign automatically. Vendoring or upstream-forking the GitHub-only `mailibex` lib is the path. | L | mailibex (vendored), DV-06 doctor for verification | PROJECT.md L61; primary thesis §4 L150 (MUST #2); engineering DNA §4.7 L541 |
| DV-10 | Feedback-ID helper with stable SenderID format (`campaign:customer:mailtype:stableSenderID`) | Required by Gmail Postmaster Tools FBL data. Must be in DKIM `h=` tag for signing coverage. Trivial to add but easy to forget — bake into the helper API. | S | TS-01 (Mailable headers), DV-09 (DKIM `h=` integration) | PROJECT.md L62; primary thesis §4 L148 |

### v0.5+ Features — `mailglass_inbound` (Separate Sibling Package)

Inbound shares the webhook plumbing (HMAC + plug + event normalization) with v0.5 deliverability work. Ships as a separate Hex package so adopters who only need outbound don't pull in storage/SMTP/MIME-parsing dependencies.

| # | Feature | Why It Belongs In `mailglass_inbound` | Complexity | Dependencies | Source citation |
|---|---------|---------------------------------------|------------|--------------|-----------------|
| IB-01 | `Mailglass.Inbound.Router` DSL (recipient regex, subject pattern, header matcher, function matcher) | ActionMailbox's routing DSL is the gold standard ("controllers for inbound email"). Ports cleanly to Elixir as macros. | L | None internal; macro module | PROJECT.md L66; primary thesis §3 L67-71; domain language §7 L425-446 |
| IB-02 | `Mailglass.Inbound.Mailbox` behaviour: `before_process/1`, `process/1`, `bounce_with/2`; mailbox handler can answer with `:accept | :reject | :ignore | {:bounce, reason}` | The handler-vs-router separation matches ActionMailbox precisely; per domain language doc §3 L141-152 the Mailbox is a handler concept (not a UI inbox). | M | IB-01 | PROJECT.md L67, L72; domain language §3 L141-152, §7 L478 |
| IB-03 | Ingress plugs for Postmark (JSON), SendGrid (multipart), Mailgun (form/MIME), SES (SNS), Relay (SMTP via gen_smtp) | Inbound webhooks have provider-shaped payloads. Ingress plugs normalize to `Mailglass.Inbound.InboundMessage` immediately at the edge. SES uses SNS topic delivery (not a webhook proper). | L | TS-11 (CachingBodyReader pattern), gen_smtp (optional dep) | PROJECT.md L68; primary thesis §3 L67-71 |
| IB-04 | Storage behaviour with LocalFS + S3 reference adapters for raw MIME preservation | Inbound MIME must be preserved for replay/debugging (per domain language §7 L500). LocalFS for dev/single-node; S3 for clusters. Adopters bring custom adapters (R2, GCS, etc.). | M | IB-03; pluggable behaviour | PROJECT.md L69; primary thesis §6 L242 |
| IB-05 | Async routing via Oban with optional incineration after retention window | Per ActionMailbox: incineration after 30 days is the default. Oban handles scheduling. Replay via the event ledger keeps audit history even after raw MIME is gone. | M | IB-04, Oban (optional dep), TS-06 (event ledger) | PROJECT.md L70; primary thesis §3 L71 |
| IB-06 | `Mailglass.Inbound.Conductor` — dev LiveView for synthesizing/replaying inbound mail | Rails' Action Mailbox Conductor is "absent from every other ecosystem and is a DX superpower" (primary thesis §3 L71). Lets developers drop a sample MIME blob into the dev preview, see routing, see processing, replay. | L | TS-13 (preview infra), IB-01..IB-05 | PROJECT.md L71; primary thesis §3 L71 |

## Feature Dependencies

```
TS-08 Tenancy ─────────────┬─────────────────────────────────────┐
                           ↓                                     ↓
TS-06 Event Ledger ─→ TS-07 Idempotency ─→ TS-11 Webhook Norm ─→ DV-03 Suppression ─→ DV-01 List-Unsub
                           ↑                       ↑                    ↑                    ↑
                           │                       │                    │                    │
                       Ecto.Multi              CachingBodyReader     auto-add on event   signed token
                                                                                              │
                                                                                              ↓
                                                                                          DV-02 Streams ───→ DV-10 Feedback-ID
                                                                                                              │
                                                                                                              ↓
                                                                                                          DV-09 DKIM h= tag

TS-02 HEEx Components ─→ TS-03 Render Pipeline ─→ TS-04 Gettext i18n
        │                       │                         │
        └────────┬──────────────┘                         │
                 ↓                                        ↓
         TS-13 Dev Preview LiveView ─────→ DV-05 Prod Admin LiveView
                 │                                ↑
                 │                                │
            TS-14 TestAssertions ←─ TS-05 Fake Adapter ←─ TS-01 Mailable behaviour
                                            │
                                            ↓
                                       TS-09 Errors + TS-10 Telemetry

TS-15 Tracking-off-by-default ──→ DF-06 (privacy stance differentiator)

DF-09 Custom Credo checks ──depends-on──→ TS-08 Tenancy + TS-10 Telemetry + DV-01 Headers (each check needs a real surface to enforce)

TS-16 Installer ──orchestrates──→ TS-01..TS-15 (touches every v0.1 feature)
TS-19 Docs ──documents──→ everything
TS-20 CI ──verifies──→ TS-05 (Fake gate) + TS-06 (immutability gate) + DF-09 (Credo)

DV-04 Mailgun/SES/Resend webhooks ──extends──→ TS-11 (Postmark/SendGrid foundation)
DV-05 Prod admin ──requires──→ TS-13 (preview surface) + TS-06 (timeline source) + DV-03 (suppression UI) + DV-04 (full provider events)
DV-07 Per-tenant adapter resolver ──requires──→ TS-08 + Adapter behaviour
DV-08 Rate limiting ──orthogonal-to──→ DV-04 (per-provider RPS limits)
DV-06 mail.doctor ──orthogonal-to──→ DV-09 DKIM signing (doctor verifies, signing produces)

IB-01 Inbound Router ─→ IB-02 Mailbox behaviour ─→ IB-05 Async routing
                              ↑
                              │
IB-03 Ingress plugs ──→ IB-04 Storage ────────────┘
                              │
                              ↓
                       IB-06 Conductor (dev LiveView)

mailglass_inbound (v0.5+) ──depends-on──→ TS-06 (shared event ledger) + TS-11 (CachingBodyReader pattern)
```

### Dependency Notes (Critical Ordering)

- **TS-06 (event ledger) is the keystone.** Every observability/audit/replay/timeline feature depends on it. Phase ordering must put the ledger + immutability trigger in the first or second phase.
- **TS-08 (tenancy) cannot be retrofitted.** Per ecosystem map §2 L41 and per Phoenix 1.8 scopes design, tenant_id must be on every record from day one. Adding it later means a destructive migration on every adopter table.
- **TS-11 (webhook normalization) blocks DV-01 + DV-03 + DV-05.** Without the event taxonomy in place, suppression auto-add can't trigger, the unsubscribe flow has no event to record, the admin timeline has nothing to render. Webhook normalization is the v0.1→v0.5 hinge.
- **TS-13 (dev preview) is the visible v0.1 differentiator.** Even if everything else slipped, shipping the preview LiveView alone would justify the lib. Don't slip this.
- **TS-16 (installer) is the v0.1 release gate.** "Batteries-included" brand promise (per PROJECT.md core value L13) demands one-command setup. Without TS-16, nothing else matters at validation time.
- **DV-05 (prod admin) requires DV-03 + DV-04** to be useful. Empty event timelines and missing suppression UI = unconvincing demo. Don't ship DV-05 ahead of those.
- **mailglass_inbound (v0.5+) reuses TS-11's CachingBodyReader + TS-06 ledger.** Sibling package, but tightly coupled to the v0.5 deliverability foundation. Hence the v0.5+ landing rather than parallel v0.1 work.
- **AF-08 (tracking on by default) conflicts with TS-15 + DF-06.** This is a brand-pillar conflict, not a technical one — opt-in tracking is non-negotiable.

## MVP Definition

### Launch With (v0.1) — Validation Release

The minimum to validate "is anyone willing to adopt a Phoenix-native email framework on top of Swoosh?"

- [ ] **TS-01 Mailable behaviour with deliver/deliver_later/deliver_many** — closes the #1 cited Swoosh gap
- [ ] **TS-02 HEEx component library with MSO fallbacks** — the "no Node" promise made concrete
- [ ] **TS-03 Render pipeline (HEEx → Premailex → minify → Floki plaintext)** — the assembled batteries-included rendering
- [ ] **TS-04 Gettext-first i18n** — Phoenix-native i18n convention
- [ ] **TS-05 Fake adapter as release-gate** — deterministic test foundation
- [ ] **TS-06 Append-only event ledger with trigger** — observability foundation
- [ ] **TS-07 Idempotency keys** — replay-safe webhooks
- [ ] **TS-08 First-class multi-tenancy** — can't retrofit later
- [ ] **TS-09 Error struct hierarchy** — pattern-match contract
- [ ] **TS-10 Telemetry spans (PII-free)** — observability
- [ ] **TS-11 Webhook normalization for Postmark + SendGrid (Anymail taxonomy)** — the differentiated event layer
- [ ] **TS-12 Webhook signature verification** — security floor
- [ ] **TS-13 Dev-mode preview LiveView** — the killer demo
- [ ] **TS-14 TestAssertions extending Swoosh's** — test ergonomics
- [ ] **TS-15 Tracking off by default** — privacy stance + brand pillar
- [ ] **TS-16 mix mailglass.install with golden-diff CI** — batteries-included promise
- [ ] **TS-17 Migration guide from Swoosh + Phoenix.Swoosh** — adoption ramp
- [ ] **TS-18 Conventional Commits + Release Please + sibling-linked-version** — ship infrastructure
- [ ] **TS-19 ExDoc with full guides + main: getting-started** — adopter ramp
- [ ] **TS-20 CI/CD with custom Credo checks + Fake gate** — quality floor
- [ ] **DF-01 LiveView preview dashboard with live-assigns + device/dark/hot-reload** — the moat (this IS TS-13 elaborated as differentiator)
- [ ] **DF-09 Custom Credo checks** — domain rules at lint time
- [ ] **DF-10 preview_props/1 colocation for compile-time alignment** — fixes the Rails footgun
- [ ] **DF-11 Stateful Fake adapter (time-advance, event-trigger)** — beats Swoosh `:test` adapter
- [ ] **DF-12 Anymail-shape mailable fields (tags/metadata/template_id/...)** — adapter-agnostic surface

**Validation criteria:** v0.1 is "successful" if (a) install in <5min, send first preview-styled email in first hour; (b) at least one external adopter ships a transactional flow on it within 60 days of release; (c) at least one bug report comes from production use that the Fake adapter would have caught (proving the test gate is meaningful).

### Add After Validation (v0.5) — Deliverability + Differentiation Release

Triggers for adding: v0.1 has 1+ external production adopter; webhook normalization has stabilized through real-provider use.

- [ ] **DV-01 List-Unsubscribe + List-Unsubscribe-Post (RFC 8058)** — Gmail/Yahoo/Microsoft compliance
- [ ] **DV-02 Message-stream separation** — :transactional vs :operational vs :bulk
- [ ] **DV-03 Suppressions + auto-add + soft-bounce escalation** — production deliverability
- [ ] **DV-04 Webhook adapters: Mailgun + SES + Resend** — full provider coverage
- [ ] **DV-05 Prod-mountable admin LiveView (sent inbox + timeline + resend + suppression UI)** — the irreplicable Phoenix advantage at scale
- [ ] **DV-06 mix mail.doctor (DNS checks)** — unique-in-Elixir diagnostic
- [ ] **DV-07 Per-tenant adapter resolver** — Stripe-Connect-style multi-tenancy
- [ ] **DV-08 Per-domain rate limiting (token bucket)** — keeps adopters out of rate-limit hell
- [ ] **DV-09 DKIM signing helper** — for self-hosted SMTP relay use
- [ ] **DV-10 Feedback-ID helper** — Gmail Postmaster requirement

### Future Consideration (v0.5+ sibling package: `mailglass_inbound`)

Triggers: v0.5 ships and v0.5 deliverability is in production at 2+ adopters; one of those adopters is asking for inbound routing.

- [ ] **IB-01 Inbound.Router DSL** — ActionMailbox-equivalent
- [ ] **IB-02 Inbound.Mailbox behaviour** — handler with accept/reject/ignore/bounce
- [ ] **IB-03 Ingress plugs (Postmark/SendGrid/Mailgun/SES + SMTP relay via gen_smtp)** — provider coverage
- [ ] **IB-04 Storage behaviour (LocalFS + S3)** — raw MIME preservation
- [ ] **IB-05 Async routing via Oban + incineration** — production lifecycle
- [ ] **IB-06 Inbound.Conductor dev LiveView** — synthesize/replay (DX superpower per Rails precedent)

### Future Consideration (v1.0 — Stability Commit, Not New Features)

Triggers: 6+ months of v0.5 in production with no API churn; deliberate API-stability lock.

- [ ] **`api_stability.md` lock + deprecation policy** — adopters can rely on the surface
- [ ] **Full guide audit + release-runbook dry-run** — quality at the 1.0 boundary
- [ ] No new feature additions in v1.0 — it's a contract commitment, not a feature release

### Permanently Out of Scope (Will Not Ship)

See **Anti-Features** section above (AF-01 through AF-16). These are decisions, not deferrals.

## Feature Prioritization Matrix

| # | Feature | User Value | Implementation Cost | Priority | Ship-Blocking for v0.1? |
|---|---------|-----------|---------------------|----------|--------------------------|
| TS-01 | Mailable + deliver_later | HIGH | M | P1 | YES |
| TS-02 | HEEx components + MSO | HIGH | L | P1 | YES |
| TS-03 | Render pipeline | HIGH | M | P1 | YES |
| TS-04 | Gettext i18n | MEDIUM | S | P1 | YES |
| TS-05 | Fake adapter | HIGH | M | P1 | YES |
| TS-06 | Event ledger | HIGH | M | P1 | YES |
| TS-07 | Idempotency keys | HIGH | S | P1 | YES |
| TS-08 | Multi-tenancy | HIGH | L | P1 | YES (cannot retrofit) |
| TS-09 | Error structs | HIGH | S | P1 | YES |
| TS-10 | Telemetry spans | HIGH | S | P1 | YES |
| TS-11 | Postmark + SendGrid webhooks | HIGH | L | P1 | YES |
| TS-12 | Signature verification | HIGH | M | P1 | YES (security) |
| TS-13 | Dev preview LiveView | HIGH | L | P1 | YES (the demo) |
| TS-14 | TestAssertions | HIGH | S | P1 | YES |
| TS-15 | Tracking off by default | MEDIUM | S | P1 | YES (brand) |
| TS-16 | mix mailglass.install | HIGH | XL | P1 | YES (batteries-included) |
| TS-17 | Migration guide | MEDIUM | S | P1 | YES (adoption) |
| TS-18 | Release Please + linked versions | MEDIUM | M | P1 | YES (infra) |
| TS-19 | ExDoc + guides | HIGH | M | P1 | YES |
| TS-20 | CI + Credo + Dialyzer | HIGH | L | P1 | YES (quality) |
| DF-01 | Live-assigns/hot-reload preview | HIGH | L | P1 | YES (TS-13 elaborated) |
| DF-09 | Custom Credo checks | MEDIUM | M | P1 | YES |
| DF-10 | preview_props/1 colocation | MEDIUM | S | P1 | YES (DF over Rails footgun) |
| DF-11 | Stateful Fake | HIGH | M | P1 | YES (TS-05 elaborated) |
| DF-12 | Anymail-shape Mailable fields | MEDIUM | M | P1 | YES (adapter-agnostic) |
| DV-01 | List-Unsubscribe RFC 8058 | HIGH | L | P2 | NO (v0.5) |
| DV-02 | Stream separation | HIGH | M | P2 | NO (v0.5) |
| DV-03 | Suppressions + auto-add | HIGH | L | P2 | NO (v0.5) |
| DV-04 | Mailgun/SES/Resend webhooks | HIGH | L | P2 | NO (v0.5) |
| DV-05 | Prod admin LiveView | HIGH | XL | P2 | NO (v0.5) |
| DV-06 | mix mail.doctor | MEDIUM | M | P2 | NO (v0.5) |
| DV-07 | Per-tenant adapter resolver | HIGH | M | P2 | NO (v0.5) |
| DV-08 | Per-domain rate limiting | MEDIUM | M | P2 | NO (v0.5) |
| DV-09 | DKIM signing | LOW (most use ESP) | L | P2 | NO (v0.5) |
| DV-10 | Feedback-ID helper | MEDIUM | S | P2 | NO (v0.5) |
| IB-01..IB-06 | Inbound (sibling pkg) | HIGH (for some) | XL combined | P3 | NO (v0.5+) |

**Priority key:**
- **P1**: Must ship for v0.1 — table stakes + v0.1 differentiators.
- **P2**: v0.5 — deliverability wave; differentiated production-readiness.
- **P3**: v0.5+ sibling package; ships independently per `mailglass_inbound` cadence.

## Competitor Feature Analysis

Comparison across the relevant set. "✓" = first-class; "△" = exists but partial/awkward; "—" = not provided.

| Feature | Rails ActionMailer + Anymail + ActionMailbox | Django + django-anymail + ActionMailbox-shape | Laravel Mail + Mailcoach | React Email / Mailing.dev | Bamboo + Swoosh + Phoenix.Swoosh | **mailglass v0.1** | **mailglass v0.5** |
|---|---|---|---|---|---|---|---|
| One-class-per-mail behaviour | ✓ Mailer class | ✓ EmailMessage subclass | ✓ Mailable class | △ JSX component | △ Swoosh.Email function | ✓ Mailable behaviour | ✓ |
| `deliver_later` first-class | ✓ ActiveJob | ✓ Celery integration | ✓ ShouldQueue | — | — (Bamboo had it) | ✓ Oban or Task fallback | ✓ |
| Component-based templates with email-safe primitives | △ partials, no MSO | △ template tags | ✓ Blade `x-mail::*` | ✓ React Email primitives | — | ✓ HEEx + MSO | ✓ |
| CSS inlining built-in | ✓ premailer-rails | △ inlinestyler | ✓ via Markdown templates | ✓ juice | △ Premailex add-on | ✓ Premailex baked-in | ✓ |
| Auto plaintext alternative | △ via ActionMailer's `text` template | △ manual | △ manual | △ manual | △ manual | ✓ Floki auto-derive | ✓ |
| Preview dashboard | ✓ /rails/mailers (dev only, no auto-refresh) | △ django-mail-templated has minimal | ✓ via route return | ✓ Next.js bundled (✗ no LiveView/hot-reload-equivalent in Phoenix today) | △ /dev/mailbox (no auto-refresh) | ✓ LiveView dev preview | ✓ + prod admin |
| Live-assigns editor in preview | — | — | — | △ partial in Mailing.dev | — | ✓ LiveView form | ✓ |
| Device + dark + client simulator | △ Litmus integration (paid) | — | — | ✓ React Email | — | ✓ baked in | ✓ |
| Webhook normalization across providers | △ via Anymail | ✓ Anymail (gold standard) | △ Mailcoach Postmark/Mailgun adapters | — (provider SDKs only) | — | ✓ Postmark + SendGrid | ✓ + Mailgun + SES + Resend |
| Append-only event ledger | — (status updates in place) | — | △ Mailcoach has events table (mutable) | — | — | ✓ Postgres trigger immutability | ✓ |
| Idempotent webhook replay | △ depends on adopter | △ depends on adopter | △ depends on adopter | — | — | ✓ UNIQUE partial index | ✓ |
| List-Unsubscribe + RFC 8058 | △ manual | △ manual | △ Mailcoach has it (marketing only) | — | — | — | ✓ auto-injected, signed token |
| Suppression list with auto-add | △ ActiveSuppression gem | △ manual | ✓ Mailcoach | — | — | — | ✓ + soft-bounce escalation |
| Message-stream separation | — | — | △ Postmark stream attr | — | — | — | ✓ :transactional/:operational/:bulk |
| First-class multi-tenancy | △ apartment/acts_as_tenant retrofit | △ django-tenants | △ via spatie/laravel-multitenancy | — | — | ✓ TS-08 baked in | ✓ + per-tenant adapter resolver |
| Inbound routing DSL | ✓ ActionMailbox | △ django-mailbox | ✓ Mail::raw | — | — | — | ✓ mailglass_inbound (sibling) |
| Inbound conductor dev UI | ✓ /rails/conductor (DX superpower) | — | — | — | — | — | ✓ mailglass_inbound |
| Mountable admin in adopter app | — (separate dashboards) | — | △ Mailcoach mounts in Laravel | — | — | △ dev only at v0.1 | ✓ prod-mountable LiveView |
| `mix mail.doctor` DNS checks | — | — | — | — | — | — | ✓ unique in ecosystem |
| Custom-Credo-equivalent lint enforcement of domain rules | — | — | — | — | — | ✓ DF-09 | ✓ |
| Tracking off by default | — | — (default on) | — (default on) | △ no tracking pixel | — | ✓ DF-06 | ✓ |
| Compile-time preview/caller alignment | — (silent drift) | — | △ static analysis only | △ TS types | — | ✓ DF-10 colocated preview_props | ✓ |
| One-command install with golden-diff | △ rails generators | △ django manage.py | ✓ artisan vendor:publish | — | — | ✓ TS-16 | ✓ |
| Telemetry events | △ ActiveSupport::Notifications | △ Django signals | △ Laravel events | — | △ Swoosh telemetry minimal | ✓ TS-10 4-level naming | ✓ |

**Reading the matrix:** mailglass v0.1 already matches or exceeds the reference set on the **DX surface** (preview, components, render pipeline, multi-tenancy, event ledger, normalization). v0.5 closes the **production deliverability gap** (List-Unsubscribe, suppression, prod admin, full provider coverage, mail.doctor). The mailglass_inbound sibling completes the **inbound parity** with ActionMailbox.

The unique cells are the moats:
- LiveView preview with live-assigns + hot reload (DF-01)
- Append-only event ledger with trigger immutability (TS-06 + DF-04)
- mix mail.doctor (DV-06)
- Custom Credo checks (DF-09)
- Compile-time preview alignment (DF-10)

These are not "features the others could add easily" — each one depends on Phoenix LiveView 1.0+, OTP process model, Postgres triggers, or the Elixir AST. They are structural, not cosmetic.

## Sources

### Primary (locked scope and feature lists)

- `/Users/jon/projects/mailglass/.planning/PROJECT.md` — locked decisions (D-01 through D-20), v0.1/v0.5/v0.5+ requirement lists, anti-features with reasoning
- `/Users/jon/projects/mailglass/prompts/Phoenix needs an email framework not another mailer.md` — exhaustive feature analysis with v0.1/v0.5/v1.0 split, comparison set rationale
- `/Users/jon/projects/mailglass/prompts/mailer-domain-language-deep-research.md` — canonical vocabulary (Mailable/Message/Delivery/Event/InboundMessage/Mailbox/Suppression), aggregate boundaries, distinction rules
- `/Users/jon/projects/mailglass/prompts/mailglass-engineering-dna-from-prior-libs.md` — concrete v0.1/v0.5 feature list distilled from accrue/lattice_stripe/sigra/scrypath, "10 must-port wins" ranking
- `/Users/jon/projects/mailglass/prompts/mailglass-brand-book.md` — brand pillars (clarity, composure, precision, warmth, visibility-over-magic), preferred vocabulary, anti-vocabulary informing AF-15 (no AI features)

### Comparison and ecosystem context

- `/Users/jon/projects/mailglass/prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` — current Phoenix landscape (1.8 + LiveView 1.1 baseline), Bandit/Req/Oban defaults, multi-tenancy answer, email section §11
- Django Anymail event taxonomy reference: <https://anymail.dev/en/stable/sending/tracking/>
- ActionMailer Basics: <https://guides.rubyonrails.org/action_mailer_basics.html>
- ActionMailbox Basics: <https://guides.rubyonrails.org/action_mailbox_basics.html>
- React Email: <https://react.email/docs/utilities/render>
- Laravel Mailable + Mailcoach: <https://laravel.com/docs/11.x/mail>, <https://mailcoach.app>
- RFC 8058 (one-click unsubscribe): <https://datatracker.ietf.org/doc/html/rfc8058>
- Google sender guidelines (bulk-sender rules): <https://support.google.com/mail/answer/81126>
- Apple MPP analysis: <https://postmarkapp.com/blog/how-apples-mail-privacy-changes-affect-email-open-tracking>

### Confidence assessment per source class

| Source | Confidence | Why |
|--------|-----------|-----|
| PROJECT.md locked decisions | HIGH | User-authored, locked, repeatedly cited as ground truth |
| prompts/ deep-research files | HIGH | Comprehensive, cited with primary sources, recently authored |
| Engineering DNA from 4 prior libs | HIGH | 4-of-4 convergence on most patterns; documented commit-history precedent |
| Anymail taxonomy as canonical | HIGH | Battle-tested across 14+ providers, three other ecosystems |
| Comparison matrix cells | MEDIUM-HIGH | Based on documented features; some "△ partial" cells reflect known awkwardness rather than direct testing |
| 2026 ecosystem map | HIGH | Authored Apr 2026, current state, named version numbers, primary-source links |

---

*Feature research for: Phoenix-native transactional email framework (`mailglass`)*
*Researched: 2026-04-21*
