# Migration from raw Swoosh

This guide helps you migrate from a raw Swoosh setup to mailglass while preserving your existing templates and adapter credentials.

## Prerequisites

- An existing Phoenix app using Swoosh directly
- Your Swoosh adapter config (API keys, etc.)

## 1) Install mailglass

Add `:mailglass` to your `mix.exs` and run `mix mailglass.install`.

## 2) Update your Mailer module

Instead of `use Swoosh.Mailer`, use `Mailglass.Mailable`:

```elixir
# Old
defmodule MyApp.Mailer do
  use Swoosh.Mailer, otp_app: :my_app
end

# New
defmodule MyApp.UserMailer do
  use Mailglass.Mailable, stream: :transactional
end
```

## 3) Wrap delivery calls

Replace `MyApp.Mailer.deliver()` with `Mailglass.deliver()`:

```elixir
# Old
MyApp.Mailer.deliver(email)

# New
email |> Mailglass.deliver()
```

## 4) Move configuration

Move your adapter config under the `:mailglass` key in `runtime.exs`.

## End-to-End Example

```elixir
# Verify that a Swoosh.Email can still be delivered through the mailglass pipeline
Swoosh.Email.new()
|> Swoosh.Email.to("migrated@example.com")
|> Swoosh.Email.from("system@example.com")
|> Swoosh.Email.subject("Migration test")
|> Mailglass.deliver()
```
