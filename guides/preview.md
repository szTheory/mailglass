# Preview

The preview surface runs in dev and uses your production render pipeline, so HTML/Text/Raw/Headers stay consistent with real delivery.

## Prerequisites

- `mailglass_admin` dependency available in `:dev`
- Router mounted behind your dev-only routes

## Mount preview routes

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import MailglassAdmin.Router

  if Application.compile_env(:my_app, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      mailglass_admin_routes "/mail"
    end
  end
end
```

## Start and open preview

```bash
mix phx.server
# open http://localhost:4000/dev/mail
```

## Add preview props on a mailable

```elixir
defmodule MyApp.UserMailer do
  use Mailglass.Mailable, stream: :transactional

  @impl Mailglass.Mailable
  def preview_props do
    [name: "Alice", email: "alice@example.com"]
  end
end
```

## End-to-End Example

```bash
mix phx.server
```
