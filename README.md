# Mailglass

> *Mail you can see through.*

[![CI](https://github.com/szTheory/mailglass/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/mailglass/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/mailglass.svg)](https://hex.pm/packages/mailglass)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/mailglass)
[![License](https://img.shields.io/hexpm/l/mailglass.svg)](https://github.com/szTheory/mailglass/blob/main/LICENSE)

Mailglass is a batteries-included transactional email framework for
Phoenix. It composes on top of [Swoosh](https://hex.pm/packages/swoosh)
and ships the framework layer Swoosh deliberately leaves out: HEEx-native
components with Outlook MSO/VML fallbacks, a LiveView preview/admin
dashboard, normalized webhook events, an append-only event ledger with
Postgres trigger immutability, multi-tenant routing, message streams,
RFC 8058 List-Unsubscribe with signed tokens, suppression lists, and
webhook-driven auto-suppression.

It is shipped as three sibling packages: **`mailglass`** (core),
**`mailglass_admin`** (mountable LiveView dashboard), and
**`mailglass_inbound`** (inbound routing; v0.5+). It is for senior
Phoenix teams building production transactional email — welcome flows,
password resets, magic links, receipts, notifications — who today
rebuild the same 40% of framework plumbing on every project.

## Requirements

- **Elixir** `~> 1.18` and **OTP** `27+`
- **Phoenix** `~> 1.8`
- **Phoenix LiveView** `~> 1.1`
- **Ecto / Ecto SQL** `~> 3.13`
- **PostgreSQL** 14+ (trigger support required; `citext` used for
  case-insensitive address match)
- **Swoosh** `~> 1.25` (compose any Swoosh adapter for transport)

## Installation

Add `mailglass` to your dependencies:

```elixir
# mix.exs
def deps do
  [
    {:mailglass, "~> 0.3"},
    {:mailglass_admin, "~> 0.3", only: [:dev]}
  ]
end
```

Fetch deps, run the installer, and migrate:

```bash
mix deps.get
mix mailglass.install
mix ecto.migrate
```

The installer generates: a `MyApp.Mailing` context, the three-table
migration (`mailglass_deliveries`, `mailglass_events`,
`mailglass_suppressions` plus the immutability trigger), router mounts
for the dev preview and webhook plug, a default mailable and layout,
an Oban worker stub (when Oban is installed), and a `config/runtime.exs`
configuration block.

## Quickstart

Run the full onboarding path first:

```bash
mix deps.get
mix mailglass.install
mix ecto.migrate
mix compile
```

Define a mailable:

```elixir
defmodule MyApp.UserMailer do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    new()
    |> to(user.email)
    |> from({"MyApp", "support@example.com"})
    |> subject("Welcome to MyApp")
    |> html_body("<h1>Welcome to MyApp</h1>")
    |> text_body("Welcome to MyApp")
    |> Mailglass.Message.put_function(:welcome)
  end
end
```

Send it — synchronously, asynchronously (via Oban when available), or
in a batch:

```elixir
MyApp.UserMailer.welcome(user) |> Mailglass.deliver()
MyApp.UserMailer.welcome(user) |> Mailglass.deliver_later()
Mailglass.deliver_many(Enum.map(users, &MyApp.UserMailer.welcome/1))
```

Preview mailables in dev at `http://localhost:4000/dev/mail` — sidebar
of discovered mailables, device width and dark-mode toggles,
HTML/Text/Raw/Headers tabs, live-editable assigns.

## Feature highlights

- **HEEx-native components** (`container`, `section`, `row`, `column`,
  `heading`, `text`, `button`, `img`, `link`, `hr`, `preheader`) with
  MSO VML fallbacks for Outlook. No Node toolchain.
- **Pure render pipeline** — HEEx → Premailex CSS inlining →
  `data-mg-*` strip → auto-plaintext via Floki walker. ~4ms on a
  ten-component template.
- **Append-only event ledger** — `mailglass_events` table protected by
  a Postgres trigger that raises `SQLSTATE 45A01` on UPDATE/DELETE.
- **Native mailable setters** — `Mailglass.Message.to/2`, `from/2`,
  `subject/2`, `html_body/2`, `text_body/2`, `header/3`, `attach/2`,
  and `put_tag/2` keep the common path free of direct `Swoosh.Email.*`
  calls while `update_swoosh/2` remains the escape hatch.
- **Stream-aware deliverability** — `:transactional`, `:operational`,
  and `:bulk` are enforced message streams. RFC 8058 one-click
  unsubscribe headers are injected automatically for `:bulk` and can be
  opted into on `:operational`.
- **Idempotency** — partial `UNIQUE` index on
  `idempotency_key WHERE idempotency_key IS NOT NULL`; replay-safe
  webhooks and delivery retries.
- **Multi-tenant from day one** — `tenant_id` on every record,
  `Mailglass.Tenancy` behaviour, `SingleTenant` default resolver, and
  an Oban tenancy middleware (conditionally compiled).
- **Fake adapter as the release gate** — deterministic, in-memory,
  time-advanceable; merge-blocking in CI so the full pipeline is
  testable without real provider credentials.
- **Swoosh as transport** — compose on any Swoosh adapter (Postmark,
  SendGrid, Mailgun, SES, Resend, local SMTP, etc.).
- **Normalized webhook events** — Anymail event taxonomy verbatim
  (`queued`, `sent`, `bounced`, `delivered`, `opened`, `clicked`,
  `complained`, `unsubscribed`, …) with `reject_reason` enum.
  Postmark, SendGrid, Mailgun, SES, and Resend are all shipped
  first-party providers, and matched `:bounced`, `:complained`, and
  `:unsubscribed` events project suppressions automatically.
- **Test assertions** — `assert_mail_sent/1`, `last_mail/0`,
  `wait_for_mail/1`, plus `MailerCase`, `WebhookCase`, `AdminCase`
  templates.
- **Telemetry spans** on every entry point with a PII whitelist
  (counts, IDs, and latencies — never addresses or bodies).
- **Optional deps** gated via `Mailglass.OptionalDeps.*`:
  [`oban`](https://hex.pm/packages/oban),
  [`opentelemetry`](https://hex.pm/packages/opentelemetry),
  [`mjml`](https://hex.pm/packages/mjml),
  [`gen_smtp`](https://hex.pm/packages/gen_smtp),
  [`sigra`](https://hex.pm/packages/sigra).

## Packages

| Package             | Status                   | What it is |
|---------------------|--------------------------|------------|
| `mailglass`         | v0.3 public surface      | Core library: mailables, rendering, delivery pipeline, event ledger, webhook ingest, streams, unsubscribe, suppressions, tenancy. |
| `mailglass_admin`   | v0.3 (dev-preview only)  | Mountable LiveView preview in dev. Prod-mountable sent-mail inbox + event timeline + suppression UI arrive in v0.5. |
| `mailglass_inbound` | v0.5+                    | Inbound routing (Action Mailbox equivalent): recipient/subject/header matchers, ingress plugs per provider, storage adapters, Oban routing. |

## Roadmap

- **v0.2 — Production-credible core** — native `Mailglass.Message`
  setter API, `mix mailglass.upgrade.v0_2`, message-stream policy,
  RFC 8058 unsubscribe, webhook-driven suppression projection, linked
  release hardening, and release-blocking Tier 1 docs.
- **v0.5 — Deliverability + admin** — prod-mountable admin,
  `mix mail.doctor` deliverability checks,
  per-tenant adapter resolver, per-domain rate limiting.
- **v1.0** — API stability lock, production references, long-lived
  deprecation policy.

Full trajectory in [`.planning/ROADMAP.md`](.planning/ROADMAP.md) and
[`.planning/PROJECT.md`](.planning/PROJECT.md).

## Documentation

- [`guides/getting-started.md`](guides/getting-started.md) — install,
  route mounting, and first delivery
- [`guides/upgrading-from-v0_1.md`](guides/upgrading-from-v0_1.md) —
  codemod-backed upgrade path for existing adopters
- [`guides/migration-from-swoosh.md`](guides/migration-from-swoosh.md)
  — move from raw Swoosh to the mailglass pipeline
- [`guides/authoring-mailables.md`](guides/authoring-mailables.md) —
  native setter API and `update_swoosh/2` escape hatch
- [`guides/unsubscribe.md`](guides/unsubscribe.md) — RFC 8058 route,
  token, and rollout contract
- [`guides/dkim-setup.md`](guides/dkim-setup.md) — DKIM `h=` checks for
  one-click unsubscribe
- [`guides/webhooks.md`](guides/webhooks.md) — webhook ingest,
  verification, suppression, and retention

## Contributing

Mailglass is developed in public. Contributor conventions, decision
log, and phase-by-phase roadmap live in [`CLAUDE.md`](CLAUDE.md) and
[`.planning/PROJECT.md`](.planning/PROJECT.md); a dedicated `CONTRIBUTING.md` lands in
Phase 7.

Reproduce the default CI gate locally:

```bash
mix verify.foundation
mix verify.cold_start
mix compile --no-optional-deps --warnings-as-errors
```

## License

MIT. The license is declared in [`mix.exs`](mix.exs) and applies across
all sibling packages.
