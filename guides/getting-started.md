# Getting Started

This guide wires mailglass into a Phoenix app and sends one message through the standard pipeline.

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
mix verify.phase_07
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
    |> Mailglass.Message.update_swoosh(fn email ->
      email
      |> Swoosh.Email.to(user.email)
      |> Swoosh.Email.from({"MyApp", "support@example.com"})
      |> Swoosh.Email.subject("Welcome")
    end)
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
mix verify.phase_07
```
