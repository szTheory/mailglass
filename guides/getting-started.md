# Getting Started

This guide wires mailglass into a Phoenix app and sends one message through the
stable `v1.x` lane.

## Prerequisites

- Elixir `~> 1.18` with OTP 27+
- Phoenix `~> 1.8`
- Ecto and PostgreSQL configured
- Swoosh adapter credentials in your runtime environment

## 1) Install and verify

```bash
mix deps.get
mix mailglass.install
mix ecto.migrate
mix compile --warnings-as-errors
```

## 2) Configure mailglass

```elixir
# config/runtime.exs
config :mailglass,
  repo: MyApp.Repo,
  adapter:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter: {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_API_KEY")}},
  telemetry: [default_logger: true]
```

## 3) Mount preview and webhook routes

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import MailglassAdmin.Router
  import Mailglass.Webhook.Router

  if Application.compile_env(:my_app, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      mailglass_admin_routes "/mail"
    end
  end

  scope "/" do
    pipe_through :api
    mailglass_webhook_routes "/webhooks"
  end
end
```

## 4) Send your first message

```elixir
defmodule MyApp.UserMailer do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    new()
    |> to(user.email)
    |> from({"MyApp", "support@example.com"})
    |> subject("Welcome")
    |> html_body("<h1>Welcome to MyApp</h1>")
    |> text_body("Welcome to MyApp")
    |> Mailglass.Message.put_function(:welcome)
  end
end

{:ok, _delivery} =
  %{email: "alice@example.com"}
  |> MyApp.UserMailer.welcome()
  |> Mailglass.deliver()
```

## End-to-End Example

```bash
mix deps.get
mix mailglass.install
mix ecto.migrate
mix compile --warnings-as-errors
```

## Troubleshooting the Installer

### `mix mailglass.install` fails to find `endpoint.ex`

- Ensure you are running the task from the root of your Phoenix application.
- If your application has a non-standard directory structure, you may need to manually wire the components described in the [Webhooks Guide](webhooks.md).

### Webhooks return 401 after installation

- The installer adds `Mailglass.Webhook.CachingBodyReader` to your `Plug.Parsers` configuration.
- Check `lib/my_app_web/endpoint.ex` and ensure that your existing `Plug.Parsers` block was either updated or that the Mailglass-specific parser appears **above** your application's default JSON parser.
- If multiple `Plug.Parsers` are present, the first one that matches the request path will consume the body.

---

*Last updated: 2026-05-03 (Phase 31 ships at v0.1).*
