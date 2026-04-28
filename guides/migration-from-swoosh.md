# Migration from raw Swoosh

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
    {:mailglass, "~> 0.2"},
    {:mailglass_admin, "~> 0.2", only: [:dev]}
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

## End-to-End Example

```elixir
email =
  Swoosh.Email.new()
  |> Swoosh.Email.to("migrated@example.com")
  |> Swoosh.Email.from("system@example.com")
  |> Swoosh.Email.subject("Migration test")

assert {:ok, _delivery} = Mailglass.deliver(email)
```
