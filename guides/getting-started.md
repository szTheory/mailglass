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

`mix mailglass.install` now fails closed when it detects an unmanaged `Plug.Parsers` plug
(one that lacks a `body_reader` option) in your `endpoint.ex`. It exits non-zero via
`Mix.raise` and prints an actionable error — this prevents the silent production webhook
401 that occurred with earlier versions.

**If the installer stopped with a conflict error:**

- Re-run with `--force` to bypass the check and proceed: `mix mailglass.install --force`.
  The installer will insert the managed `Plug.Parsers` block (with
  `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}`) **above** your
  existing parser. Use `--force` only if you understand the parser ordering implications.
- After a successful install, run `mix mailglass.doctor` to confirm the
  `Mailglass.Webhook.CachingBodyReader` wiring is present in your endpoint parser. The
  command exits non-zero if the wiring is absent.

**If you installed mailglass with an older installer:**

Earlier installer versions warned instead of failing closed on this conflict. Check
`lib/my_app_web/endpoint.ex` manually: if your `Plug.Parsers` block lacks a `body_reader`
option, add the `CachingBodyReader` wiring as shown in the [Webhooks guide](webhooks.md),
then run `mix mailglass.doctor` to verify.

## Next steps

The first hour is behind you. Here is a natural week-one path:

1. [What you can do with mailglass](jobs.md) — the JTBD map; read once straight through
   when evaluating.
2. [Authoring mailables](authoring-mailables.md) — native setter API, HEEx layouts,
   reusable components.
3. [Preview](preview.md) — dev preview at `/dev/mail`; device-width and dark-mode toggles.
4. [Webhooks](webhooks.md) — webhook ingest, verification, and suppression wiring.
5. [Testing](testing.md) — Fake adapter, TestAssertions, and the `deliver/2` baseline.
6. [Telemetry and operating](telemetry.md) — `[:mailglass, :outbound, :dispatch, ...]`
   events and alerting.

For a fuller ordered index, see the [learning path](learning-path.md).
