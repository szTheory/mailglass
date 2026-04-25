# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-25

Mailglass is the framework layer Swoosh deliberately leaves out of its
transport-only core: HEEx-native components, an append-only event ledger,
first-class multi-tenancy, and normalized webhook events across providers.
This is a validation release — the API surface is documented in
`docs/api_stability.md`, the test suite is green on Elixir 1.18+ / OTP 27+ /
Phoenix 1.8+, and we are inviting feedback from teams who want to see the
mail their app sends before it ships.

### Added

- HEEx-native component library (`<.container>`, `<.row>`, `<.column>`,
  `<.button>`, `<.img>`, `<.heading>`, `<.text>`, `<.divider>`, `<.spacer>`)
  with MSO Outlook VML fallbacks generated at render time. No Node toolchain
  required at any point in the pipeline.
- A pure-function render pipeline: `Mailglass.Renderer.render/1` runs HEEx →
  Premailex CSS inlining → Floki-derived plaintext, returning a fully formed
  `%Swoosh.Email{}` ready for any Swoosh adapter.
- An append-only `mailglass_events` ledger backed by a Postgres trigger that
  raises SQLSTATE `45A01` on UPDATE and DELETE attempts. Audit history is a
  database-level invariant, not a convention.
- Multi-tenancy via the `Mailglass.Tenancy` behaviour with `tenant_id` on
  every record from day one. The single-tenant default works out of the box;
  multi-tenant adopters swap in their own scope without retrofitting schemas.
- Webhook ingest for Postmark and SendGrid that normalizes provider payloads
  into the Anymail event taxonomy, deduplicates on
  `(provider, provider_event_id)`, and reconciles orphan events to deliveries
  via a 15-minute Oban cron when their delivery row arrives late.
- A send pipeline that flows `Mailable` → preflight (suppression list,
  rate-limit, stream policy) → render → atomic
  `Multi(Delivery + Event + Worker enqueue)` → adapter dispatch, with the
  adapter call held outside the transaction to keep the Postgres pool free.
- `Mailglass.Adapters.Fake` — a stateful, time-advanceable test adapter with
  the `assert_mail_sent/1` family of matchers for ExUnit, plus
  `Mailglass.Test.set_mailglass_global/1` for cross-process delivery capture.
- A dev-preview LiveView (`mailglass_admin`) with auto-discovered mailables,
  HTML / Text / Raw / Headers tabs, device-width and dark/light toggles, and
  the brand palette (Ink, Glass, Ice, Mist, Paper, Slate) wired through
  Tailwind v4 — also without Node, via static asset bundling.
- Twelve custom Credo checks that enforce domain rules at lint time —
  telemetry PII whitelist, tracking-off-by-default on auth-stream mailables,
  no-raw-Swoosh-deliver in lib code, prefixed PubSub topics, and append-only
  event writes among them.
- `mix mailglass.install` for Phoenix 1.8 hosts — an idempotent installer
  that writes config, migration, and module seams, leaving
  `.mailglass_conflict_*` sidecars when an existing file would be touched.
  A golden-diff CI snapshot test catches installer regressions.
- ExDoc with nine guides covering authoring, components, preview, webhooks,
  multi-tenancy, telemetry, testing, the Fake adapter, and migration from
  raw Swoosh + `Phoenix.Swoosh`.

### Security

- HMAC-verified webhook ingest. Postmark uses HTTP Basic Auth compared via
  `Plug.Crypto.secure_compare/2`; SendGrid uses ECDSA P-256 verification via
  OTP 27 `:public_key`. Forged signatures raise `Mailglass.SignatureError`
  with no recovery path and the plug returns `401`.
- A suppression-list check runs before every send. Recipients on the list
  cannot be re-sent to without an explicit unblock through the suppression
  store — bounce and complaint signals feed the list automatically.
- Open and click tracking are off by default. Per-mailable opt-in is
  required, and the `NoTrackingOnAuthStream` Credo check raises at compile
  time on auth-context heuristics (`magic_link`, `password_reset`,
  `verify_email`, `confirm_account`).
- Telemetry metadata is whitelisted to counts, statuses, IDs, and latencies.
  The PII keys (`:to`, `:from`, `:body`, `:html_body`, `:subject`,
  `:headers`, `:recipient`, `:email`) are forbidden by the
  `NoPiiInTelemetryMeta` Credo check, so adopters cannot accidentally leak
  recipient data through their handlers.
- Click-rewriting tokens are signed via `Phoenix.Token` with rotation
  support. Target URLs live inside the signed payload, never as a query
  parameter — the open-redirect CVE class is structurally unreachable.
