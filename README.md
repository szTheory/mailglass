# Mailglass

> *Mail you can see through.*

[![CI](https://github.com/szTheory/mailglass/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/mailglass/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/mailglass.svg)](https://hex.pm/packages/mailglass)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/mailglass)
[![License](https://img.shields.io/hexpm/l/mailglass.svg)](https://github.com/szTheory/mailglass/blob/main/LICENSE)

> **Pre-release.** v0.1 is in active development (Phase 4 of 7). The
> installation and quickstart below describe the target API for v0.1 and
> will ship as tested against published Hex tarballs when Phase 7
> (Installer + CI/CD + Docs) completes. Track progress in
> [`.planning/ROADMAP.md`](.planning/ROADMAP.md).

Mailglass is a batteries-included transactional email framework for
Phoenix. It composes on top of [Swoosh](https://hex.pm/packages/swoosh)
and ships the framework layer Swoosh deliberately leaves out: HEEx-native
components with Outlook MSO/VML fallbacks, a LiveView preview/admin
dashboard, normalized webhook events, an append-only event ledger with
Postgres trigger immutability, multi-tenant routing, suppression lists,
and — at v0.5 — RFC 8058 List-Unsubscribe with signed tokens and
`mix mail.doctor` deliverability checks.

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
    {:mailglass, "~> 0.1"},
    {:mailglass_admin, "~> 0.1", only: [:dev]}
  ]
end
```

Fetch deps, run the installer, and migrate:

```bash
mix deps.get
mix mailglass.install   # Phase 7 — not yet shipped
mix ecto.migrate
```

The installer generates: a `MyApp.Mailing` context, the three-table
migration (`mailglass_deliveries`, `mailglass_events`,
`mailglass_suppressions` plus the immutability trigger), router mounts
for the dev preview and webhook plug, a default mailable and layout,
an Oban worker stub (when Oban is installed), and a `config/runtime.exs`
configuration block.

## Quickstart

Define a mailable:

```elixir
defmodule MyApp.UserMailer do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    Mailglass.Message.new()
    |> Mailglass.Message.to(user.email)
    |> Mailglass.Message.subject("Welcome to MyApp")
    |> Mailglass.Message.render(MyApp.Mailing.Templates, :welcome, user: user)
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
  `complained`, `unsubscribed`, …) with `reject_reason` enum. v0.1
  verifies Postmark (Basic Auth + IP allowlist) and SendGrid (ECDSA).
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
| `mailglass`         | v0.1 in development      | Core library: mailables, rendering, delivery pipeline, event ledger, webhook ingest, tenancy. |
| `mailglass_admin`   | v0.1 (dev-preview only)  | Mountable LiveView preview in dev. Prod-mountable sent-mail inbox + event timeline + suppression UI arrive in v0.5. |
| `mailglass_inbound` | v0.5+                    | Inbound routing (Action Mailbox equivalent): recipient/subject/header matchers, ingress plugs per provider, storage adapters, Oban routing. |

## Roadmap

- **v0.1 — Core (validation release)** — foundation, persistence,
  transport, webhook ingest, dev preview LiveView, installer, CI/CD,
  guides. Migration guide from raw Swoosh + `Phoenix.Swoosh`.
- **v0.5 — Deliverability + admin** — RFC 8058 List-Unsubscribe with
  signed tokens, message-stream separation, suppressions auto-add on
  bounce/complaint, Mailgun/SES/Resend webhook verification,
  prod-mountable admin, `mix mail.doctor` deliverability checks,
  per-tenant adapter resolver, per-domain rate limiting.
- **v1.0** — API stability lock, production references, long-lived
  deprecation policy.

Full trajectory in [`.planning/ROADMAP.md`](.planning/ROADMAP.md) and
[`.planning/PROJECT.md`](.planning/PROJECT.md).

## Documentation

- [`guides/webhooks.md`](guides/webhooks.md) — webhook ingest,
  verification, event normalization, and reconciliation (currently
  the only shipped guide).

Phase 7 ships the full guide suite on HexDocs: Getting Started,
Authoring Mailables, Components, Preview, Multi-Tenancy, Telemetry,
Testing, and Migration from Swoosh.

## Contributing

Mailglass is developed in public. Contributor conventions, decision
log, and phase-by-phase roadmap live in [`CLAUDE.md`](CLAUDE.md) and
[`.planning/`](.planning/); a dedicated `CONTRIBUTING.md` lands in
Phase 7.

Reproduce the default CI gate locally:

```bash
mix verify.phase_02
mix verify.cold_start
mix compile --no-optional-deps --warnings-as-errors
```

## License

MIT. The `LICENSE` file ships with Phase 7; the license is already
declared in [`mix.exs`](mix.exs) and applies across all sibling
packages.
