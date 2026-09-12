# mailglass_inbound Installation Guide

This guide is the deeper setup detail for the canonical inbound adoption lane
in [`../README.md`](../README.md). Follow this sequence only as an expansion of
that README path — dependency pinning, `mix deps.get`, `mix ecto.migrate`,
`Plug.Parsers` `body_reader`, router + mailbox wiring, provider mount points,
and async mode choice remain identical here.

By the end you will have inbound email flowing from a provider webhook into a
mailbox function you control, with a repeatable test that verifies the path
without a live HTTP request.

> Before starting: this guide assumes your Phoenix application already has
> `mailglass` wired (Repo, Config, Tenancy). If not, install
> [mailglass](https://hexdocs.pm/mailglass) first.

## 1. Add the dependency

Add `mailglass_inbound` to your `mix.exs` dependencies:

```elixir
defp deps do
  [
    {:mailglass,         "~> 2.6"},
    {:mailglass_inbound, "~> 2.3"},
    {:oban,              "~> 2.21"}  # optional — see section 6
  ]
end
```

If you do not want durable background execution yet, omit `{:oban, "~> 2.21"}`.
The package degrades to a bounded `Task.Supervisor` fallback when Oban is absent
(see section 6).

Fetch dependencies:

```bash
mix deps.get
```

## 2. Run the migrations

`mailglass_inbound` manages its own tables: normalized inbound records, raw
evidence, and append-only execution lineage. Generate its Repo-explicit wrapper,
review it, and then run the host migrations:

```bash
mix mailglass.inbound.gen.migration --repo MyApp.Repo
mix ecto.migrate
```

The wrapper calls `MailglassInbound.Migration.up/1` and
`MailglassInbound.Migration.down/1`. The facade resolves the explicit Repo and
the inbound prefix; it does not reuse core's migration anchor. Initial wrappers
are immutable. When a later package schema version needs a populated upgrade,
generate a separate `--upgrade` wrapper instead of editing the initial file.

## 3. Configure the repository

Tell the package which Ecto repo to use. Add this to `config/config.exs` (or
to `config/runtime.exs` if you resolve the repo name at runtime):

```elixir
config :mailglass_inbound, :repo, MyApp.Repo
```

For tests, point it at the test repo in `config/test.exs`:

```elixir
# config/test.exs
# If you have a dedicated sandbox repo, replace MyApp.Repo with your test repo module:
config :mailglass_inbound, :repo, MyApp.Repo
```

This entry is optional if your application uses only one Ecto repo. If you use a
separate test repo for isolation (e.g. `MyApp.TestRepo`), replace `MyApp.Repo` with
that module name here — that is the only line you need to change.

## 4. Wire the body reader in your endpoint

Webhook signature verification requires the exact request bytes as received.
Add `body_reader` to your `Plug.Parsers` call in `lib/my_app_web/endpoint.ex`:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Jason,
  body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}
```

> **Required.** Without `body_reader`, the Postmark ingress path fails closed
> with `:webhook_caching_body_reader_missing`. Wire it once and all providers
> benefit.

## 5. Define your inbound router

Create a module that declares which mailbox handles which recipients. The
compiled route data drives the real ingress path and your test suite:

```elixir
defmodule MyApp.MailglassInboundRouter do
  use MailglassInbound.Router

  route MyApp.Mailboxes.SupportMailbox, recipient: "support@example.com"
  route MyApp.Mailboxes.BillingMailbox, recipient: "billing@example.com"
end
```

Supported route matchers are `:recipient`, `:subject`, and `:headers`. Routes
are evaluated in order and the first match wins.

## 6. Define a mailbox

A mailbox is a module that implements the `MailglassInbound.Mailbox` behaviour
with a single `process/1` callback. The callback receives a
`%MailglassInbound.InboundMessage{}` and returns an outcome atom:

```elixir
defmodule MyApp.Mailboxes.SupportMailbox do
  @behaviour MailglassInbound.Mailbox

  @impl true
  def process(message) do
    # Inspect message.subject, message.from, message.text_body, etc.
    _ = message
    :accept
  end
end
```

The four supported outcomes are:

| Return value       | Meaning                             |
| ------------------ | ----------------------------------- |
| `:accept`          | Message processed; record accepted  |
| `:ignore`          | Message received but not processed  |
| `{:reject, reason}` | Processing refused; reason logged  |
| `{:bounce, reason}` | Bounce signal generated; reason logged |

**Generator shortcut.** Use the generator to scaffold a new mailbox quickly:

```bash
mix mailglass.gen.mailbox MyApp.Mailboxes.SupportMailbox
```

## 7. Mount the ingress plug in your router

Mount one ingress route per provider. The `:tenant_id` URL segment resolves
which tenant owns the incoming message:

```elixir
# lib/my_app_web/router.ex

forward "/inbound/:tenant_id/postmark",
  MailglassInbound.Ingress.Plug,
  provider: :postmark,
  router: MyApp.MailglassInboundRouter

forward "/inbound/:tenant_id/sendgrid",
  MailglassInbound.Ingress.Plug,
  provider: :sendgrid,
  router: MyApp.MailglassInboundRouter
```

The four stable provider lanes are `:postmark`, `:sendgrid`, `:mailgun`, and `:ses`.
The provider modules themselves remain internal; adopters configure the
provider option on `MailglassInbound.Ingress.Plug` and follow the package guides.

> Historical v2.0 note: “The stable provider lanes in this slice are `:postmark` and `:sendgrid`.” At that time, Mailgun and SES guides were integration references and “not part of the current stable provider contract.”
> That statement is retained only as provenance; the four-lane sentence above is current.

## 8. Configure your provider

### Postmark

```elixir
# config/runtime.exs
config :mailglass_inbound, :postmark,
  basic_auth: {"your-postmark-user", System.fetch_env!("POSTMARK_INBOUND_PASS")},
  ip_allowlist: []  # optional — restrict to Postmark's IP ranges
```

Point Postmark's inbound webhook at:

```
https://your-domain.com/inbound/<tenant_id>/postmark
```

### SendGrid

```elixir
config :mailglass_inbound, :sendgrid,
  basic_auth: {"your-sendgrid-user", System.fetch_env!("SENDGRID_INBOUND_PASS")}
```

## 9. Choose the async execution mode

**Oban (recommended).** When Oban is present, newly matched records are
enqueued through a supervised worker after persistence commits. Retries and
crash recovery are durable:

```elixir
# config/config.exs — no additional config needed; Oban presence is detected
# automatically. Configure Oban itself as normal in your application.
```

**Task.Supervisor fallback.** When Oban is absent, `mailglass_inbound` spawns a
bounded `Task.Supervisor` child. This path provides no durable enqueue and no
automatic retry. Recovery after node loss depends on replay or operator action
over the stored receive truth. You may force fallback mode explicitly:

```elixir
config :mailglass_inbound, :async_adapter, :task_supervisor
```

## 10. Write a sandboxed test

Add this to `config/test.exs`:

```elixir
config :mailglass_inbound, :repo, MyApp.Repo
```

Then write a `MailboxCase` test. Each test drives the real persist + route +
execute path synchronously and asserts on the result:

```elixir
defmodule MyApp.Mailboxes.SupportMailboxTest do
  use MailglassInbound.MailboxCase, async: false

  test "accepts a support message" do
    message = Fixtures.build_inbound_message(
      subject: "I need help",
      to: "support@example.com"
    )

    {:ok, %{outcome: %{outcome: :accept}, route: %{mailbox: MyApp.Mailboxes.SupportMailbox}}} =
      Test.Ingress.receive_inbound(message, router: MyApp.MailglassInboundRouter)

    # ONE assertion per drive: assert_inbound_* reads the captured tuple with
    # assert_received, which CONSUMES it from the process mailbox. Drive a second
    # message for a second assertion.
    assert_inbound_received(subject: "I need help")
  end

  test "ignores a message with no matching route" do
    message = Fixtures.build_inbound_message(to: "unknown@example.com")

    {:ok, %{outcome: %{outcome: :no_match}}} =
      Test.Ingress.receive_inbound(message, router: MyApp.MailglassInboundRouter)

    assert_inbound_no_match()
  end
end
```

> `async: false` is required. `MailboxCase` checks out an Ecto sandbox in
> shared mode, and ETS-backed state is global within the test process. Running
> concurrent MailboxCase tests produces non-deterministic results.

## Tenancy

`mailglass_inbound` stores a `tenant_id` on every inbound record. The ingress
plug resolves the tenant from the `:tenant_id` URL segment. Your application
must implement the `Mailglass.Tenancy` behaviour — or use the shipped
`Mailglass.Tenancy.SingleTenant` default for apps that don't partition by
tenant.

## What's next

- Return to the canonical path in [`../README.md`](../README.md) whenever setup
  and troubleshooting wording differ; the README remains the single authority.
- **See [inbound-testing.md](inbound-testing.md) for full test coverage
  patterns**: all four assertion matcher styles, outcome and routing assertions,
  Fixtures for every provider, and the idempotency property pattern.
- **Compatibility/deprecation posture for inbound stable versus internal/deferred
  surfaces:** [../../guides/compatibility-and-deprecations.md](../../guides/compatibility-and-deprecations.md)
- **Provider-specific setup guides:**
  - [inbound-mailgun.md](inbound-mailgun.md) — Mailgun HTTP route URL, signing
    key config, and HMAC verification
  - [inbound-ses.md](inbound-ses.md) — SES SNS topic, IAM policy, S3 bucket,
    and `:ex_aws_s3` setup
- **Operations:** [inbound-operator.md](inbound-operator.md) for
  `mix mailglass.inbound.doctor`, replay, prune, and retention config.
