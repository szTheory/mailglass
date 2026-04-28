# Getting Started

This guide wires mailglass into a Phoenix app and sends one message through the v0.2 public pipeline.

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
mix compile
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
mix compile
```
