<p align="center">
  <img src="brandbook/examples/readme-header.svg" alt="mailglass - Email, made visible." width="580">
</p>

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
**`mailglass_inbound`** (inbound routing; stable 2.0). It is for senior
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

## Demo App

For a realistic local click-around, run the B2B SaaS Ops demo (needs Docker):

```bash
make demo
```

It builds, starts, waits until healthy, then **prints the URLs** for the
dashboard, preview, and outbound/inbound operator journeys (default
http://localhost:4015) over seeded data. Stop with `make demo-down`. Ports are
configurable so the demo runs alongside other library demos without collisions —
see [`guides/run-the-demo.md`](guides/run-the-demo.md) for the full walkthrough.

The demo lives in `reference/demo_app`; the narrower `reference/host_app` remains
the maintained trust-proof baseline.

## Current package compatibility

For the current package line, add the linked core and admin packages together.
The declaration below is production-capable, which is required when mounting the
production operator surface. Add the independently released inbound package when
your app receives mail:

```elixir
# mix.exs
def deps do
  [
    {:mailglass, "~> 2.6"},
    {:mailglass_admin, "~> 2.6"},
    {:mailglass_inbound, "~> 2.2"}
  ]
end
```

Preview-only adopters that do not mount the production operator may instead add
`only: :dev` to the `mailglass_admin` dependency. A dev-scoped dependency is not
compiled or available in production.

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

The installer generates a config block in `config/runtime.exs`. Confirm your repo and
adapter are wired:

```elixir
# config/runtime.exs
config :mailglass,
  repo: MyApp.Repo,
  adapter:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter: {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_API_KEY")}},
  telemetry: [default_logger: true]
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

## Deliverability Doctor

Run the DNS-only doctor against one explicit domain at a time:

```bash
mix mail.doctor --domain example.com
mix mail.doctor --domain example.com --dkim-selector default --dkim-selector selector2
mix mail.doctor --domain example.com --verbose
mix mail.doctor --domain example.com --format json
```

`mix mail.doctor` reports DNS truth and remediation guidance for SPF,
DKIM, DMARC, MX, and BIMI. It can return honest `cannot_verify`
outcomes when DNS alone is insufficient, and it does not promise inbox
placement certainty or a deliverability grade.

- `--domain` is required, and each run checks exactly one domain.
- `--dkim-selector` is repeatable so you can name the selectors your
  mail stream actually uses.
- `--verbose` includes supporting evidence inline.
- `--format json` emits the shared machine-readable result shape with
  `schema_version: 1`.

## API Stability

The canonical `v2.x` contract for the core package lives in
[`docs/api_stability.md`](docs/api_stability.md).

The compatibility guide retains the historical `1.x` promises and defines the
current v2 deprecation and support-matrix policy in
[`guides/compatibility-and-deprecations.md`](guides/compatibility-and-deprecations.md).

Use that document, not root-module reachability, as the source of truth for:

- which `Mailglass` modules, behaviours, Mix tasks, telemetry families,
  structs, and documented fields are stable
- which exported surfaces are intentionally `internal`
- which hooks exist only for first-party sibling-package integration

`mailglass_admin` has its own narrow contract inventory, and
`mailglass_inbound` has its own stable `2.0` contract inventory in
[`mailglass_inbound/docs/api_stability.md`](mailglass_inbound/docs/api_stability.md);
it remains an independent package release line rather than part of the linked
core/admin `v2.x` group.

For release posture, support floors, retained legacy bridges, and upgrade
expectations, use the compatibility guide rather than inferring policy from the
stability inventory alone.

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
  `Mailglass.Tenancy` behaviour, `SingleTenant` default resolver,
  runtime per-tenant adapter resolution through tenancy callbacks plus
  named `adapter_ref` routes, and an Oban tenancy middleware
  (conditionally compiled).
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
| `mailglass`         | `v2.x` contract documented in `docs/api_stability.md` | Core library: mailables, rendering, delivery pipeline, event ledger, webhook ingest, streams, unsubscribe, suppressions, tenancy. |
| `mailglass_admin`   | Narrow `v2.x` admin contract documented separately | Mountable LiveView dashboard with stable router/auth/operator seams and internal UI implementation details. |
| `mailglass_inbound` | Stable `2.0` contract documented separately | Inbound routing (Action Mailbox equivalent): recipient/subject/header matchers, ingress plugs per provider, storage adapters, Oban routing. |

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
- [`guides/learning-path.md`](guides/learning-path.md) — first-week
  learning arc: ordered sequence from install to production
- [`guides/run-the-demo.md`](guides/run-the-demo.md) — see mailglass
  working locally in one command (`make demo`)
- [`guides/compatibility-and-deprecations.md`](guides/compatibility-and-deprecations.md)
  — current `v2.x` compatibility, deprecation, and support-matrix policy with retained historical `1.x` promises
- [`guides/upgrading-to-v1_0.md`](guides/upgrading-to-v1_0.md) — canonical
  latest-`0.x` to `1.0` upgrade path
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
- [`guides/rate-limiting.md`](guides/rate-limiting.md) — multi-bucket throughput protection

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
