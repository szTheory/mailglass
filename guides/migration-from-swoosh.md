# Migration from raw Swoosh

Swoosh handles transport; mailglass adds the framework layer you'd otherwise rebuild —
preview, webhooks, audit ledger, suppressions, and multi-tenancy. It composes on top of
Swoosh rather than replacing it: your existing adapter credentials stay in place, and you
gain an observable, replayable, auditable delivery pipeline without switching transports.

This guide is now a subordinate raw-Swoosh migration reference.

The canonical latest-`0.x` to `1.0` path lives in
[`upgrading-to-v1_0.md`](upgrading-to-v1_0.md). Use that guide for the full
compatibility-lane inventory, support matrix, and strict-CI posture. Use this
page when you specifically need the incremental "keep raw `%Swoosh.Email{}` for
parity while adopting mailglass" slice.

This guide helps you move from a raw Swoosh setup to mailglass while preserving your adapter credentials and your ability to deliver plain `%Swoosh.Email{}` values through the mailglass pipeline.

## Prerequisites

- An existing Phoenix app using Swoosh directly
- Your Swoosh adapter config
- Ecto and PostgreSQL configured for the host app

## 1) Install mailglass and keep Swoosh as transport

Add mailglass to your dependencies:

```elixir
def deps do
  [
    {:mailglass, "~> 1.6"},
    {:mailglass_admin, "~> 1.6", only: [:dev]}
  ]
end
```

Then fetch deps, run the installer, and migrate:

```bash
mix deps.get
mix mailglass.install
mix ecto.migrate
```

## 2) Move adapter configuration under `:mailglass`

Keep your existing Swoosh adapter, but configure it through `Mailglass.Adapters.Swoosh`:

```elixir
# config/runtime.exs
config :mailglass,
  repo: MyApp.Repo,
  adapter:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter: {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_API_KEY")}}
```

## 3) Replace raw mailer modules with mailables

Instead of `use Swoosh.Mailer`, define mailable modules:

```elixir
defmodule MyApp.UserMailer do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    new()
    |> to(user.email)
    |> from({"MyApp", "support@example.com"})
    |> subject("Welcome")
    |> html_body("<h1>Welcome</h1>")
    |> text_body("Welcome")
    |> Mailglass.Message.put_function(:welcome)
  end
end
```

## 4) Deliver through mailglass

Pipe mailable results into `Mailglass.deliver/1`:

```elixir
MyApp.UserMailer.welcome(%{email: "migrated@example.com"})
|> Mailglass.deliver()
```

Mailglass still accepts a plain `%Swoosh.Email{}` when you need parity during an incremental migration.

That raw-email path is a retained compatibility bridge, not the preferred
`1.x` authoring lane. For the canonical support horizon and replacement story,
defer to [`upgrading-to-v1_0.md`](upgrading-to-v1_0.md) and
[`compatibility-and-deprecations.md`](compatibility-and-deprecations.md).

## End-to-End Example

```elixir
email =
  Swoosh.Email.new()
  |> Swoosh.Email.to("migrated@example.com")
  |> Swoosh.Email.from("system@example.com")
  |> Swoosh.Email.subject("Migration test")

assert {:ok, _delivery} = Mailglass.deliver(email)
```
