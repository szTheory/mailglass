# Requirements: mailglass

**Defined:** 2026-04-21
**Core Value:** Email you can see, audit, and trust before it ships.

> Requirements derive from `PROJECT.md` (locked decisions D-01..D-20) and `.planning/research/SUMMARY.md` (7-layer build order). Each REQ-ID is atomic, user-observable, and testable. Cross-references to `research/FEATURES.md` IDs (TS-/DF-/DV-/IB-/AF-) are noted in parentheses.
>
> **Three-tier scope**:
> - **v0.1** = validation release. The "we have a working core" milestone. All requirements below in this section ship together as `mailglass` 0.1.0 + `mailglass_admin` 0.1.0.
> - **v0.5** = deliverability + admin + inbound. Roadmapped after v0.1 ships and adopter feedback comes in; tracked here, not in current execution roadmap.
> - **Out of scope** = explicit exclusions with permanent reasoning.

---

## v1 Requirements (= v0.1 release)

### Foundations

- [x] **CORE-01
**: Library exposes a single `Mailglass.Error` exception hierarchy (`SendError`, `TemplateError`, `SignatureError`, `SuppressedError`, `RateLimitError`, `ConfigError`) with a closed `:type` atom set documented in `api_stability.md`. Pattern-matching by struct works; pattern-matching by error message string is never required. (TS-09)
- [x] **CORE-02
**: Library exposes `Mailglass.Config` validated via NimbleOptions at boot. Reading runtime config outside this module is forbidden by Credo check `NoCompileEnvOutsideConfig`. (LIB-02 prevention)
- [x] **CORE-03
**: Library emits telemetry events on the `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]` 4-level convention. Metadata is restricted to a whitelisted key set: `:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`. PII keys (`:to`, `:from`, `:body`, `:html_body`, `:subject`, `:headers`, `:recipient`, `:email`) are forbidden. Telemetry handlers that raise do not break the send pipeline. (TS-10, OBS-01 prevention)
- [x] **CORE-04
**: Library exposes `Mailglass.Repo.transact/1` wrapper for `Ecto.Multi` flows. `Ecto.Multi` insertion of an `Event` row is required for every state-changing operation.
- [x] **CORE-05
**: Library exposes `Mailglass.IdempotencyKey` helper producing keys of form `"#{provider}:#{provider_event_id}"`. Used by webhook ingest + `deliver_many` partial-failure recovery.
- [x] **CORE-06
**: All optional deps (`oban`, `opentelemetry`, `mjml`, `gen_smtp`, `sigra`) are gated through `Mailglass.OptionalDeps.{Oban, OpenTelemetry, MJML, ...}` modules with `@compile {:no_warn_undefined, ...}` declared once + `available?/0` predicate + degraded fallback. CI lane `mix compile --no-optional-deps --warnings-as-errors` passes. (DIST-04 prevention)
- [x] **CORE-07
**: Library adopts the `boundary` library from Phase 1. `Mailglass.Renderer` cannot depend on `Mailglass.Outbound`, `Mailglass.Repo`, or any process. `Mailglass.Events` cannot depend on `Mailglass.Outbound`.

### Authoring

- [x] **AUTHOR-01
**: Adopter defines a Mailable as `defmodule MyApp.UserMailer do; use Mailglass.Mailable; def welcome(user), do: ...; end`. The `use` macro injects ≤20 lines (verified by `NoOversizedUseInjection` Credo check). Mailable returns a `%Mailglass.Message{}` struct wrapping `%Swoosh.Email{}`. (TS-01)
- [x] **AUTHOR-02
**: Library ships `Mailglass.Components` HEEx component library with: `<.container>`, `<.section>`, `<.row>`, `<.column>`, `<.heading>`, `<.text>`, `<.button>`, `<.img>`, `<.link>`, `<.hr>`, `<.preheader>`. Every component renders with MSO Outlook VML fallback wrapper. No Node toolchain required at any point. (TS-02, DF-02)
- [x] **AUTHOR-03
**: Render pipeline is `HEEx → Premailex CSS inlining → minify → Floki auto-plaintext`. Pure-function `Mailglass.Renderer.render(message)` produces `{html_body, text_body}` in <50ms for a typical template. (TS-03)
- [x] **AUTHOR-04
**: Templates support `Gettext` `dgettext("emails", ...)` for i18n. `mix mailglass.gettext.extract` mix task generates `priv/gettext/emails.pot`. (TS-04)
- [x] **AUTHOR-05
**: `Mailglass.TemplateEngine` is a pluggable behaviour. HEEx is the default impl. `Mailglass.TemplateEngine.MJML` (via the `:mjml` Hex package — Rust NIF) is documented as opt-in. (D-18, never default)

### Persistence

- [x] **PERSIST-01
**: `mailglass_deliveries` Postgres table exists with columns: `id` (uuidv7), `tenant_id`, `mailable`, `recipient`, `stream` (`:transactional | :operational | :bulk`), `provider`, `provider_message_id`, `last_event_type`, `last_event_at`, `terminal?`, `dispatched_at`, `delivered_at`, `bounced_at`, `complained_at`, `suppressed_at`, `metadata` (jsonb), `inserted_at`. UNIQUE index on `(provider, provider_message_id) WHERE provider_message_id IS NOT NULL`. (MAIL-09 prevention)
- [x] **PERSIST-02
**: `mailglass_events` Postgres table exists with columns: `id`, `tenant_id`, `delivery_id`, `type`, `occurred_at`, `idempotency_key`, `raw_payload` (jsonb), `normalized_payload` (jsonb), `inserted_at`. Trigger `mailglass_raise_immutability` raises SQLSTATE 45A01 on UPDATE or DELETE. Test `assert_raise EventLedgerImmutableError` passes against the live schema. (TS-06, D-15)
- [x] **PERSIST-03
**: `mailglass_events` has UNIQUE partial index on `idempotency_key WHERE idempotency_key IS NOT NULL`. Webhook ingest uses `Ecto.Multi` with `on_conflict: :nothing` — replay of the same event is a no-op. StreamData property test asserts apply-N converges to apply-once. (TS-07, MAIL-03 prevention)
- [x] **PERSIST-04
**: `mailglass_suppressions` Postgres table exists with columns: `id`, `tenant_id`, `address` (citext, normalized lowercase), `scope` (`:address | :domain | :tenant_address`, no default), `reason` (`:hard_bounce | :complaint | :unsubscribe | :manual | :policy | :invalid_recipient`), `source`, `expires_at`, `created_at`. UNIQUE on `(tenant_id, address, scope, COALESCE(stream, ''))`. (TS-06 partial; full v0.5 in DELIV-03)
- [x] **PERSIST-05
**: `Mailglass.Events.append/2` is the only public API to write to `mailglass_events`. Calling outside an `Ecto.Multi` raises an `ArgumentError`.
- [x] **PERSIST-06
**: Migrations ship via `mix mailglass.gen.migration` (or generator embedded in `mix mailglass.install`). Adopters' `mix ecto.migrate` includes mailglass migrations.

### Multi-Tenancy

- [x] **TENANT-01
**: Every mailglass-owned schema (`mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`) has a `tenant_id` column (nullable for single-tenant mode, indexed). (TS-08, D-09)
- [x] **TENANT-02
**: `Mailglass.Tenancy` is a pluggable behaviour with `scope/2` callback. The default `Mailglass.Tenancy.SingleTenant` impl is a no-op. Adopters can implement custom resolvers. Phoenix 1.8 `%Scope{}` interop is documented but not auto-detected (avoids hidden coupling).
- [x] **TENANT-03**: Custom Credo check `NoUnscopedTenantQueryInLib` flags every `Repo` query on a tenanted schema that doesn't pass through `Mailglass.Tenancy.scope/2`. Bypass requires explicit `scope: :unscoped` opt with telemetry audit emit. Multi-tenant property test spawns 2 tenants, writes 100 records each, asserts zero cross-tenant leak. (PHX-05 prevention)

### Transport

- [x] **TRANS-01
**: `Mailglass.Adapter` behaviour defines `deliver(message, opts) :: {:ok, %{message_id: String.t(), provider_response: term}} | {:error, %Mailglass.Error{}}`. Return shape is locked in `api_stability.md`. (TS-05, LIB-03 prevention)
- [x] **TRANS-02
**: `Mailglass.Adapters.Fake` is a stateful, in-memory, time-advanceable adapter. Records sent messages, supports `trigger_event/2` to simulate `:bounced`/`:complained`/`:opened`/`:clicked`/`:unsubscribed` for an existing `message_id`, supports `advance_time/1`. State is JSON-compatible. **The Fake adapter is the merge-blocking release gate** — every PR must pass `mix test` against Fake. (TS-05, D-13, DF-11)
- [x] **TRANS-03
**: `Mailglass.Adapters.Swoosh` wraps any `Swoosh.Adapter` (Postmark, SendGrid, Mailgun, SES, Resend, SMTP) and normalizes errors into `%Mailglass.Error{}`. Adopters keep their existing Swoosh adapter config; mailglass adds the normalized error mapping + telemetry instrumentation.
- [x] **TRANS-04
**: `Mailglass.Outbound.send/2` (synchronous), `Mailglass.Outbound.deliver/2` (alias for send/2 — Swoosh familiarity), `Mailglass.Outbound.deliver_later/2` (Oban if available, else `Task.Supervisor` with `Logger.warning`), `Mailglass.Outbound.deliver_many/2` (batch with partial-failure recovery via idempotency keys). All four return `{:ok, %Delivery{}}` or `{:error, %Mailglass.Error{}}`. Bang variants `deliver!/2` etc. raise. (TS-01)

### Send Pipeline (composition)

- [x] **SEND-01
**: Pre-send pipeline runs in order: `Tenancy.scope` → `Suppression.check_before_send` → `RateLimiter.check` → `Stream.policy_check` → render → `Multi(Delivery insert + Event(:queued) insert + Oban job enqueue)`. Each stage emits telemetry. Failures short-circuit with structured `Mailglass.Error`.
- [x] **SEND-02
**: `Mailglass.RateLimiter` is an ETS-backed token bucket per `(tenant_id, recipient_domain)`. Default per-domain limit is 100/min (configurable). Exceeded calls return `{:error, %RateLimitError{retry_after_ms: int}}`. ETS table is owned by a small supervisor child, NOT a serialization GenServer.
- [x] **SEND-03
**: `Mailglass.Outbound.Worker` is the Oban worker that dispatches queued deliveries. Without Oban, `Task.Supervisor.async_nolink` is the fallback path with one `Logger.warning` emitted at boot.
- [x] **SEND-04
**: `Mailglass.Suppression.check_before_send/1` queries the suppression store before send. Returns `{:error, %SuppressedError{}}` if recipient is suppressed. `Mailglass.SuppressionStore` is a behaviour; default is the Ecto-backed impl.
- [x] **SEND-05
**: `Mailglass.PubSub.Topics` is a typed builder for topic strings (`mailglass:events:{tenant_id}`, `mailglass:events:{tenant_id}:{delivery_id}`). Custom Credo check `PrefixedPubSubTopics` enforces the `mailglass:` namespace.

### Tracking & Privacy

- [x] **TRACK-01
**: Open and click tracking are **off by default**. No tracking pixel injection or link rewriting unless `tracking: [opens: true, clicks: true]` is explicitly opted in per-mailable. (TS-15, D-08)
- [x] **TRACK-02**: Custom Credo check `NoTrackingOnAuthStream` raises at compile time when tracking is set on a mailable matching auth-context heuristics (function name contains `magic_link`, `password_reset`, `verify_email`, `confirm_account`). (MAIL-01 prevention)
- [x] **TRACK-03
**: When tracking IS opted in, click rewriting uses `Phoenix.Token`-signed tokens with rotation support. Tracking host must be a separate subdomain. SSRF / open-redirect verified by integration test.

### Webhook Ingest

- [x] **HOOK-01
**: `Mailglass.Webhook.CachingBodyReader` preserves the raw request bytes for HMAC verification while still allowing JSON parsing downstream. Plugged into the adopter's endpoint before any body parsing.
- [x] **HOOK-02
**: `Mailglass.Webhook.Plug` is a single mountable plug that routes per-provider via path scope (`/webhooks/postmark`, `/webhooks/sendgrid`). Returns 200 OK on signature failure replays (idempotent). Returns 401 + raises `Mailglass.SignatureError` on actual signature mismatch (no recovery path). (HOOK-04, D-08 prevention)
- [x] **HOOK-03
**: `Mailglass.Webhook.Providers.Postmark` verifies via Basic Auth + IP allowlist. Normalizes Postmark events to the Anymail taxonomy (TS-11).
- [x] **HOOK-04
**: `Mailglass.Webhook.Providers.SendGrid` verifies via ECDSA signature using the `:crypto` OTP module. Normalizes SendGrid events to the Anymail taxonomy.
- [x] **HOOK-05
**: Webhook events normalized to Anymail event taxonomy verbatim: `:queued, :sent, :rejected, :failed, :bounced, :deferred, :delivered, :autoresponded, :opened, :clicked, :complained, :unsubscribed, :subscribed, :unknown` with `reject_reason ∈ :invalid | :bounced | :timed_out | :blocked | :spam | :unsubscribed | :other | nil`. Per-provider mapper exhaustive case (no silent `_ -> :unknown` fallback without `Logger.warning`). (TS-11, D-14, MAIL-08 prevention)
- [x] **HOOK-06
**: Webhook ingest is one `Ecto.Multi`: insert Event row (with `idempotency_key`) `on_conflict: :nothing` + update Delivery projection columns (`last_event_type`, `last_event_at`, `terminal?`, type-specific timestamps). Broadcast via `PubSub` to admin LiveView topic. Orphan webhooks (no matching `delivery_id`) insert with `delivery_id: nil` + `needs_reconciliation: true`. (TS-11, MAIL-03 prevention)
- [x] **HOOK-07
**: StreamData property test: generate 1000 sequences of `(webhook_event, replay_count_1..10)`. Assert applying any sequence converges to the same final state as applying each event once. (TEST-03)

### Compliance (v0.1 floor)

- [x] **COMP-01
**: `Mailglass.Compliance.add_rfc_required_headers/1` injects `Date`, `Message-ID`, `MIME-Version` if absent. (Full RFC 8058 List-Unsubscribe lands in v0.5 / DELIV-01.)
- [x] **COMP-02
**: Auto-injected headers: `Mailglass-Mailable: <module>.<function>/<arity>`, `Feedback-ID: <stable_sender_id>:<mailable>:<tenant_id>` (when configured). Auth-Results parsing deferred to v2.

### Preview LiveView (mailglass_admin v0.1)

- [ ] **PREV-01**: `mailglass_admin` is a separate Hex package. Its `mix.exs` declares `{:mailglass, "== <pinned_version>"}` — sibling versions never drift. (D-01, DIST-01 prevention)
- [ ] **PREV-02**: `MailglassAdmin.Router` exposes a macro `mailglass_admin_routes(path, opts)` for adopter routers. Mount path is the adopter's first arg with no default. (PHX-02 prevention)
- [ ] **PREV-03**: `MailglassAdmin.PreviewLive` (dev-only mount) renders: a sidebar listing all `Mailglass.Mailable` modules + their preview functions auto-discovered via `preview_props/0` callback; HTML/Text/Raw/Headers tabs in main pane; device width toggle (mobile/tablet/desktop); dark/light mode toggle; live-assigns form for each `preview_props/0` field. (TS-13, DF-01, DF-10)
- [ ] **PREV-04**: Live-reload via Phoenix LiveReload integration: editing the mailable source file refreshes the preview without page reload.
- [ ] **PREV-05**: `MailglassAdmin.Components` ships responsive, mobile-first UI components matching the brand book palette (Ink/Glass/Ice/Mist/Paper/Slate, Inter + IBM Plex Mono). daisyUI 5 + Tailwind v4 (Phoenix 1.8 default; no Node required for adopters' build). (BRAND-01)
- [ ] **PREV-06**: `mailglass_admin/priv/static/` is a committed compiled bundle. CI runs `git diff --exit-code` after `mix mailglass_admin.assets.build`. Hex tarball size <2MB. (PHX-03, DIST-02 prevention)

### Test Tooling

- [x] **TEST-01
**: `Mailglass.TestAssertions` extends Swoosh's: `assert_mail_sent/1`, `assert_no_mail_sent/0`, `last_mail/0`, `wait_for_mail/1`, `assert_mail_delivered/2`, `assert_mail_bounced/2`. (TS-14)
- [x] **TEST-02
**: Per-domain Case templates: `Mailglass.MailerCase`, `Mailglass.WebhookCase`, `Mailglass.AdminCase`. Each sets up Ecto sandbox + Fake adapter + actor seeded.
- [x] **TEST-03**: StreamData property tests on: idempotency key collision (PERSIST-03), webhook signature verification (HOOK-03/HOOK-04), header construction (COMP-01
), multi-tenant scope leak (TENANT-03). All four are merge-blocking in CI.
- [x] **TEST-04**: Real-provider sandbox tests (Postmark, SendGrid sandbox modes) tagged `@tag :provider_live`. Excluded from PR CI. Daily cron + `workflow_dispatch` only. Failures notify, never block. (TEST-02
 prevention)
- [x] **TEST-05
**: `Mailglass.Clock` injection point for time-dependent code. Tests use `Mailglass.Clock.Frozen`; production uses `Mailglass.Clock.System`. (TEST-06 prevention)

### Custom Credo (Lint-Time Domain Rules)

- [x] **LINT-01**: `Mailglass.Credo.NoRawSwooshSendInLib` — every send goes via `Mailglass.Outbound.*`, never `Swoosh.Mailer.deliver/1` directly. (DF-09)
- [x] **LINT-02**: `Mailglass.Credo.NoPiiInTelemetryMeta` — flags any literal `:to`/`:from`/`:body`/`:html_body`/`:subject`/`:headers`/`:recipient`/`:email` keys in telemetry metadata maps. (CORE-03
 enforcement, OBS-01 prevention)
- [x] **LINT-03**: `Mailglass.Credo.NoUnscopedTenantQueryInLib` — every Repo query on `mailglass_deliveries`/`mailglass_events`/`mailglass_suppressions` passes through `Mailglass.Tenancy.scope/2`. (TENANT-03 enforcement)
- [x] **LINT-04**: `Mailglass.Credo.NoBareOptionalDepReference` — direct calls to `Oban.*`, `OpenTelemetry.*`, `Mjml.*` outside the `Mailglass.OptionalDeps.*` gateway modules are flagged. (CORE-06
 enforcement)
- [x] **LINT-05**: `Mailglass.Credo.NoOversizedUseInjection` — `use Mailglass.Mailable` injects ≤20 lines (counted via AST analysis). (LIB-01 prevention)
- [x] **LINT-06**: `Mailglass.Credo.PrefixedPubSubTopics` — every `Phoenix.PubSub.broadcast` topic in mailglass code is prefixed `mailglass:`. (SEND-05
 enforcement, PHX-06 prevention)
- [x] **LINT-07**: `Mailglass.Credo.NoDefaultModuleNameSingleton` — flags any `GenServer.start_link(..., name: __MODULE__)` in mailglass library code. (LIB-05 prevention)
- [x] **LINT-08**: `Mailglass.Credo.NoCompileEnvOutsideConfig` — only `Mailglass.Config` may call `Application.compile_env*`. (LIB-07 prevention)
- [x] **LINT-09**: `Mailglass.Credo.NoOtherAppEnvReads` — mailglass code never reads other apps' Application env. (LIB-02 prevention)
- [x] **LINT-10**: `Mailglass.Credo.TelemetryEventConvention` — every `:telemetry.execute/3` event matches the 4-level naming convention. (CORE-03
 enforcement)
- [x] **LINT-11**: `Mailglass.Credo.NoFullResponseInLogs` — `Logger.*` calls inspecting raw provider response payloads are flagged. (OBS-04 prevention)
- [x] **LINT-12**: `Mailglass.Credo.NoDirectDateTimeNow` — direct `DateTime.utc_now/0` is flagged outside `Mailglass.Clock`. (TEST-05
 enforcement)

### Installer

- [ ] **INST-01**: `mix mailglass.install` generates: a `MyApp.Mail` context module, mailglass migrations, router mounts (preview LiveView in dev, webhook plug), Oban worker stub (if `:oban` is detected), default mailable + layout, `runtime.exs` config block. Flag matrix: `--no-admin`. (TS-16, D-12)
- [ ] **INST-02**: Installer is idempotent. Reruns on a host with prior mailglass install detect existing files and write `.mailglass_conflict_*` sidecars rather than clobbering. Second-rerun integration test asserts zero file modifications. (DIST-03 prevention)
- [ ] **INST-03**: Golden-diff CI snapshot test: a fresh Phoenix 1.8 host app under `test/example/` runs `mix mailglass.install`, the diff is captured, and a snapshot file is committed. PRs that change installer behavior surface a snapshot diff that requires explicit review.
- [ ] **INST-04**: `mix verify.phase<NN>` aliases per phase per the engineering DNA convention. One focused mix task per concern, never a kitchen-sink verifier.

### CI/CD

- [ ] **CI-01**: GitHub Actions workflows: `ci.yml` (PR + main push: format, compile w/ warnings-as-errors, compile `--no-optional-deps --warnings-as-errors`, ExUnit, Credo `--strict`, Dialyzer w/ cached PLT, `mix docs --warnings-as-errors`, `mix hex.audit`), `dependency-review.yml`, `actionlint.yml`, `release-please.yml`, `publish-hex.yml` (publish only from protected ref + GitHub Environment with required reviewers). (TS-20)
- [ ] **CI-02**: Required test matrix: 1 cell (Elixir 1.18 / OTP 27, current stable). Wider matrix runs nightly cron + `workflow_dispatch`, advisory only.
- [ ] **CI-03**: Conventional Commits enforced via PR title check. Squash-merge workflow keeps casual contributor UX low-friction.
- [ ] **CI-04**: Release Please configured with manifest + linked-versions plugin. `mailglass` and `mailglass_admin` ship coordinated releases; `mailglass_admin/mix.exs` declares `{:mailglass, "== <new-version>"}`. (D-16, DIST-01 prevention)
- [ ] **CI-05**: Hex tarball contents whitelisted to `lib/`, `priv/templates/`, `mix.exs`, `LICENSE`, `README.md`, `CHANGELOG.md`. Tarball size <500KB for `mailglass`, <2MB for `mailglass_admin`. (PHX-03 prevention)
- [ ] **CI-06**: All third-party GitHub Actions pinned to commit SHA. Dependabot watches both `mix.lock` and `.github/workflows/`.
- [ ] **CI-07**: `HEX_API_KEY` is a GitHub Environment secret with required reviewer approval. PR jobs never see it. (DIST-05, CI-03 prevention)

### Documentation

- [ ] **DOCS-01**: ExDoc configured with `main: "getting-started"`, `source_url`, `homepage_url`, source-version refs, full extras + module groups. ExDoc 0.40+ ships `llms.txt` automatically.
- [ ] **DOCS-02**: Guides set: `getting-started.md`, `authoring-mailables.md`, `components.md`, `preview.md`, `webhooks.md`, `multi-tenancy.md`, `telemetry.md`, `testing.md`, `migration-from-swoosh.md`. Every guide ends with a runnable end-to-end example.
- [ ] **DOCS-03**: Migration guide from raw Swoosh + `Phoenix.Swoosh` is testable: an adopter following it in a single afternoon reaches mailglass parity with no production behavior change. (TS-17)
- [ ] **DOCS-04**: Doc-contract tests: every README "Quick Start" snippet compiles; guide setup steps reference real mix tasks; config examples validate against NimbleOptions; admin nav entries match real LiveView routes. CI gate. (TEST-04 prevention)
- [ ] **DOCS-05**: `MAINTAINING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` ship in the repo root. SECURITY.md documents responsible disclosure for webhook signature bypass + tenant isolation issues.

### Brand & Voice

- [ ] **BRAND-01**: All `mailglass_admin` UI conforms to `prompts/mailglass-brand-book.md`: Ink/Glass/Ice/Mist/Paper/Slate palette, Inter + Inter Tight + IBM Plex Mono typography, mobile-first responsive, no glassmorphism / lens flares / literal broken glass. WCAG AA contrast verified.
- [ ] **BRAND-02**: All error messages and log messages match the brand voice ("clear, exact, confident not cocky, warm not cute, modern not trendy, technical not intimidating"). Errors are specific ("Delivery blocked: recipient is on the suppression list" — never "Oops!").
- [ ] **BRAND-03**: Documentation prefers the direct word ("preview" over "experience the full rendering lifecycle"). Doc copy reviewed against brand book before publishing.

---

## v2 Requirements (= v0.5 deliverability + v0.5+ inbound; tracked, not in current roadmap)

### v0.5 — Deliverability Wave (within `mailglass` + `mailglass_admin`)

#### Compliance

- **DELIV-01**: List-Unsubscribe + List-Unsubscribe-Post headers per RFC 8058. Auto-injected on `:bulk` stream; opt-in on `:operational`. Signed-token unsubscribe controller via `mix mailglass.gen.unsubscribe`. Both headers atomic + included in DKIM `h=` list. (DV-01, MAIL-02 prevention)
- **DELIV-02**: Message-stream separation enforced: `:transactional` (auth, receipts, password reset — never tracked, never marketing), `:operational` (account notifications), `:bulk` (newsletters — auto List-Unsubscribe, auto physical address per CAN-SPAM). Stream policy violations raise. (DV-02)
- **DELIV-03**: Suppression auto-add on `:bounced`/`:complained`/`:unsubscribed` events. Soft-bounce escalation rule (5 in 7 days → hard suppress, configurable). Suppression checked pre-send via SuppressionStore. Resync mix task to repopulate suppressions from event ledger. (DV-03)

#### Webhook Coverage

- **DELIV-04**: Webhook normalization extended to `Mailglass.Webhook.Providers.{Mailgun, SES, Resend}`. Mailgun: HMAC-SHA256. SES: SNS subscription confirmation + signature. Resend: provider-specific signing. (DV-04)

#### Admin (mailglass_admin v0.5)

- **DELIV-05**: Prod-mountable admin LiveView: sent-mail browser (stream-based, paginated, filterable by tenant/recipient/status/date), per-delivery event timeline with raw + normalized payloads, suppression management UI (list, add, remove with reason audit), one-click resend with idempotency key bump, replay webhook from raw payload. Step-up auth on destructive actions via sigra/PhxGenAuth integration. (DV-05)

#### Operations

- **DELIV-06**: `mix mail.doctor` — live DNS deliverability checks: SPF lookup count <10, DKIM selector exists + key valid, DMARC `p=` policy, MX records, BIMI hint. Output: actionable per-domain report with severity. (DV-06)
- **DELIV-07**: Per-tenant adapter resolver — different ESPs per customer. `Mailglass.AdapterRegistry` caches resolved adapters per `(tenant_id, scope)`. (DV-07)
- **DELIV-08**: Per-domain rate limiting promoted from ETS-only to `:pg`-coordinated when cluster-coordinated limits required (defer evaluation to v0.5 with empirical benchmark). (DV-08)
- **DELIV-09**: DKIM signing helper for self-hosted SMTP relay use case. Pass-through for ESPs (they sign with their key). (DV-09)
- **DELIV-10**: Stable Feedback-ID format: `{sender_id}:{mailable}:{tenant_id}:{stream}`. (DV-10)

### v0.5+ — Inbound (`mailglass_inbound` separate sibling package)

- **INBOUND-01**: `Mailglass.Inbound.Router` DSL with recipient regex, subject pattern, header matcher, function matcher. (IB-01)
- **INBOUND-02**: `Mailglass.Inbound.Mailbox` behaviour: `before_process/1`, `process/1`, `bounce_with/2`. Handlers respond `:accept | :reject | :ignore | {:bounce, reason}`. (IB-02)
- **INBOUND-03**: Ingress plugs for Postmark (JSON), SendGrid (multipart), Mailgun (form/MIME), SES (SNS). Each verifies signature + parses to `%InboundMessage{}`. (IB-03)
- **INBOUND-04**: SMTP relay ingress via `gen_smtp` for self-hosted scenarios. (IB-03 partial)
- **INBOUND-05**: `Mailglass.Inbound.Storage` behaviour. Default `LocalFS` impl + reference S3 impl preserve raw MIME for replay. Configurable retention + incineration. (IB-04)
- **INBOUND-06**: Async routing via Oban. Each inbound message becomes one Oban job that runs the matching mailbox handler. (IB-05)
- **INBOUND-07**: `Mailglass.Inbound.Conductor` dev LiveView — synthesize inbound messages from fixtures, replay stored messages through router for debugging. (IB-06)

---

## Out of Scope

Explicitly excluded with permanent reasoning. Anti-features documented to prevent re-litigation.

| Feature | Reason |
|---------|--------|
| **Marketing email** (campaigns, contact lists, segmentation, drip automations, A/B testing, broadcast scheduling) | Different problem, different compliance surface, different abstraction. That's [Keila](https://www.keila.io) / [Listmonk](https://listmonk.app) territory. (D-03, AF-01) |
| **Single-pane multi-channel notifications** (push, SMS, in-app, Slack alongside email) | Different abstraction; that's a [Noticed](https://github.com/excid3/noticed)-shaped library (`mail_notifier`). Mailglass stays email-only. (D-04, AF-02) |
| **Built-in subscriber management / preference center** | Depends on marketing concerns; adopters can build it on suppression + consent primitives. |
| **AMP for Email** | Cloudflare sunsetted Oct 20, 2025; <5% adoption pre-sunset. Don't waste maintenance budget. (AF-04) |
| **MJML as default rendering path** | HEEx + Phoenix.Component with MSO fallbacks IS the default. MJML stays opt-in via `:mjml` Hex package. (D-18, AF-05) |
| **Standalone ops console / SaaS dashboard** | `mailglass_admin` mounts in adopters' Phoenix apps. We don't run hosted infrastructure. (AF-06) |
| **Backwards compatibility with Bamboo APIs** | Bamboo in maintenance mode; Swoosh is Phoenix 1.7+ default. Migration guide is from raw Swoosh + `Phoenix.Swoosh`. (AF-07) |
| **Pre-Phoenix-1.8 / pre-LiveView-1.0 / pre-Elixir-1.18 support** | Bleeding-edge floor trades long-tail for newest features (streams, async, scopes, schema_redact, colocated hooks) and a small CI matrix. (D-06, AF-08) |
| **Custom SMTP server** | `gen_smtp` for inbound relay is the floor; mailglass is not building or maintaining an SMTP daemon. |
| **Adapter coverage parity with Swoosh at v0.1** | v0.1 normalizes events for Postmark + SendGrid only (most-used per Anymail). Swoosh's 12+ adapters remain available for transport. v0.5 adds Mailgun + SES + Resend. (D-10) |
| **Open core / paid Pro tier** | MIT pure OSS across all sibling packages forever. No `mailglass_pro`. (D-02) |
| **MySQL/SQLite support** | Postgres only. Advisory locks, JSONB, partial unique indexes, triggers are load-bearing. (AF-15) |
| **Open/click tracking on by default** | Privacy-first stance; legal liability on auth-carrying messages; signed click rewriting opt-in only. (D-08, AF-12) |
| **LLM-powered "AI subject line optimizer" / "AI send-time predictor"** | Brand book conflict ("not AI magic"); not in domain language. Adopters can layer it on top. (AF-16) |
| **Hosted SaaS Pro tier** | Same as standalone ops console — we mount, never host. |

---

## Traceability

Populated by `gsd-roadmapper` during roadmap creation. Each requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 1 — Foundation | Complete (01-02) |
| CORE-02 | Phase 1 — Foundation | Complete (01-03) |
| CORE-03 | Phase 1 — Foundation | Complete (01-03) |
| CORE-04 | Phase 1 — Foundation | Complete (01-03) |
| CORE-05 | Phase 1 — Foundation | Complete (01-03) |
| CORE-06 | Phase 1 — Foundation | Complete (01-04) |
| CORE-07 | Phase 1 — Foundation | Complete (01-01) |
| AUTHOR-01 | Phase 3 — Transport + Send Pipeline | Pending |
| AUTHOR-02 | Phase 1 — Foundation | Complete (01-05) |
| AUTHOR-03 | Phase 1 — Foundation | Complete (01-06) |
| AUTHOR-04 | Phase 1 — Foundation | Complete (01-06) |
| AUTHOR-05 | Phase 1 — Foundation | Complete (01-04) |
| PERSIST-01 | Phase 2 — Persistence + Tenancy | Complete (02-02, 02-03, 02-06) |
| PERSIST-02 | Phase 2 — Persistence + Tenancy | Complete (02-02) |
| PERSIST-03 | Phase 2 — Persistence + Tenancy | Complete (02-02, 02-05) |
| PERSIST-04 | Phase 2 — Persistence + Tenancy | Complete (02-02, 02-03, 02-06) |
| PERSIST-05 | Phase 2 — Persistence + Tenancy | Complete (02-01) |
| PERSIST-06 | Phase 2 — Persistence + Tenancy | Complete (02-02) |
| TENANT-01 | Phase 2 — Persistence + Tenancy | Complete (02-02, 02-03) |
| TENANT-02 | Phase 2 — Persistence + Tenancy | Complete (02-04, 02-06) |
| TENANT-03 | Phase 6 — Custom Credo + Boundary | Complete |
| TRANS-01 | Phase 3 — Transport + Send Pipeline | Pending |
| TRANS-02 | Phase 3 — Transport + Send Pipeline | Pending |
| TRANS-03 | Phase 3 — Transport + Send Pipeline | Pending |
| TRANS-04 | Phase 3 — Transport + Send Pipeline | Pending |
| SEND-01 | Phase 3 — Transport + Send Pipeline | Pending |
| SEND-02 | Phase 3 — Transport + Send Pipeline | Pending |
| SEND-03 | Phase 3 — Transport + Send Pipeline | Pending |
| SEND-04 | Phase 3 — Transport + Send Pipeline | Pending |
| SEND-05 | Phase 3 — Transport + Send Pipeline | Pending |
| TRACK-01 | Phase 3 — Transport + Send Pipeline | Pending |
| TRACK-02 | Phase 6 — Custom Credo + Boundary | Complete |
| TRACK-03 | Phase 3 — Transport + Send Pipeline | Pending |
| HOOK-01 | Phase 4 — Webhook Ingest | Pending |
| HOOK-02 | Phase 4 — Webhook Ingest | Complete (04-04, 04-08) |
| HOOK-03 | Phase 4 — Webhook Ingest | Pending |
| HOOK-04 | Phase 4 — Webhook Ingest | Pending |
| HOOK-05 | Phase 4 — Webhook Ingest | Pending |
| HOOK-06 | Phase 4 — Webhook Ingest | Complete (04-06, 04-07, 04-08) |
| HOOK-07 | Phase 4 — Webhook Ingest | Complete (04-09) |
| COMP-01 | Phase 1 — Foundation | Complete (01-06) |
| COMP-02 | Phase 1 — Foundation | Complete (01-06) |
| PREV-01 | Phase 5 — Dev Preview LiveView | Pending |
| PREV-02 | Phase 5 — Dev Preview LiveView | Pending |
| PREV-03 | Phase 5 — Dev Preview LiveView | Pending |
| PREV-04 | Phase 5 — Dev Preview LiveView | Pending |
| PREV-05 | Phase 5 — Dev Preview LiveView | Pending |
| PREV-06 | Phase 5 — Dev Preview LiveView | Pending |
| TEST-01 | Phase 3 — Transport + Send Pipeline | Pending |
| TEST-02 | Phase 3 — Transport + Send Pipeline | Pending |
| TEST-03 | Phase 4 — Webhook Ingest | Complete (04-09) |
| TEST-04 | Phase 7 — Installer + CI/CD + Docs | Pending |
| TEST-05 | Phase 3 — Transport + Send Pipeline | Pending |
| LINT-01 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-02 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-03 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-04 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-05 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-06 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-07 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-08 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-09 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-10 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-11 | Phase 6 — Custom Credo + Boundary | Complete |
| LINT-12 | Phase 6 — Custom Credo + Boundary | Complete |
| INST-01 | Phase 7 — Installer + CI/CD + Docs | Pending |
| INST-02 | Phase 7 — Installer + CI/CD + Docs | Pending |
| INST-03 | Phase 7 — Installer + CI/CD + Docs | Pending |
| INST-04 | Phase 7 — Installer + CI/CD + Docs | Pending |
| CI-01 | Phase 7 — Installer + CI/CD + Docs | Pending |
| CI-02 | Phase 7 — Installer + CI/CD + Docs | Pending |
| CI-03 | Phase 7 — Installer + CI/CD + Docs | Pending |
| CI-04 | Phase 7 — Installer + CI/CD + Docs | Pending |
| CI-05 | Phase 7 — Installer + CI/CD + Docs | Pending |
| CI-06 | Phase 7 — Installer + CI/CD + Docs | Pending |
| CI-07 | Phase 7 — Installer + CI/CD + Docs | Pending |
| DOCS-01 | Phase 7 — Installer + CI/CD + Docs | Pending |
| DOCS-02 | Phase 7 — Installer + CI/CD + Docs | Pending |
| DOCS-03 | Phase 7 — Installer + CI/CD + Docs | Pending |
| DOCS-04 | Phase 7 — Installer + CI/CD + Docs | Pending |
| DOCS-05 | Phase 7 — Installer + CI/CD + Docs | Pending |
| BRAND-01 | Phase 5 — Dev Preview LiveView | Pending |
| BRAND-02 | Phase 7 — Installer + CI/CD + Docs | Pending |
| BRAND-03 | Phase 7 — Installer + CI/CD + Docs | Pending |

**Coverage:**
- v1 requirements: 84 total (CORE: 7, AUTHOR: 5, PERSIST: 6, TENANT: 3, TRANS: 4, SEND: 5, TRACK: 3, HOOK: 7, COMP: 2, PREV: 6, TEST: 5, LINT: 12, INST: 4, CI: 7, DOCS: 5, BRAND: 3). Earlier "76 total" count in the initial draft was off; the breakdown sums to 84 distinct REQ-IDs and all 84 are mapped.
- Mapped to phases: 84 / 84
- Unmapped: 0
- Per-phase counts: Phase 1 = 13, Phase 2 = 8, Phase 3 = 15, Phase 4 = 8, Phase 5 = 7, Phase 6 = 14, Phase 7 = 19. Sum = 84.

---
*Requirements defined: 2026-04-21*
*Last updated: 2026-04-21 — Traceability populated by gsd-roadmapper.*
