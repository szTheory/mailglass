# Preview

The preview uses `Mailglass.Renderer` to build HTML and plaintext from a selected Mailable scenario. This is the content-rendering stage also used by outbound preflight; preflight checks, adapter encoding, tracking/compliance transformations, and delivery happen later. This Preview code path does not call `Mailglass.Outbound.deliver/2` and has no send control, so the browser output is not a promise of what a recipient or provider will receive.

The Raw tab is an illustrative MIME-shaped preview, not serialized wire bytes. The Headers tab shows scenario or preview values; Message-ID and Date are generated for the preview when the scenario does not provide them. The HTML iframe shows browser rendering only. Scripts stay disabled, but the iframe is not an HTML sanitizer or network/privacy boundary: rendered remote resource URLs may cause browser requests. Use synthetic, non-sensitive preview assigns.

The screenshot capture workflow is for **preview-pipeline confidence only**. It
does **not** claim cross-client parity across Outlook/Gmail/Apple Mail.

## Prerequisites

- `mailglass_admin` dependency available in `:dev`
- Router mounted at a path selected by your host application
- Route exposure guarded by your host application's `:dev_routes` setting

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

The route macro does not add environment enforcement or authorization. The
host application owns route exposure and must keep this preview mount behind
its development-only guard. The path passed to `mailglass_admin_routes/2`
controls the mount path used by Preview's scenario links.

By default, Preview discovers loaded Mailglass.Mailable modules automatically.
You can pass an explicit list when auto-discovery is not suitable:

```elixir
mailglass_admin_routes "/mail", mailables: [MyApp.UserMailer]
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
    [
      welcome_default: %{
        name: "Alice",
        email: "alice@example.com"
      }
    ]
  end

  def welcome_default(assigns) do
    new()
    |> Mailglass.Message.to(assigns.email)
    |> Mailglass.Message.subject("Welcome, #{assigns.name}")
    |> Mailglass.Message.html_body("<p>Welcome, #{assigns.name}.</p>")
    |> Mailglass.Message.put_function(:welcome_default)
  end
end
```

`preview_props/0` returns an ordered keyword list of scenario names and their
default assigns maps. Each scenario name must match a Mailable function that
builds a `Mailglass.Message`.

## End-to-End Example

```bash
mix phx.server
```

## Deterministic capture workflow

Use one maintainer command to capture a deterministic screenshot matrix from the
same `/dev/mail` preview route:

```bash
cd mailglass_admin
mix mailglass_admin.preview.capture \
  --base-url http://localhost:4000/dev/mail \
  --output-dir tmp/mailglass_admin_preview_capture
```

Default matrix dimensions:

- Widths: `375`, `768`, `1024`
- Themes: `light`, `dark`
- Scenarios: discovered from each mailable's `preview_props/0`

### Dry-run before capture

Dry-run prints the matrix and still writes deterministic contract artifacts:

```bash
cd mailglass_admin
mix mailglass_admin.preview.capture \
  --dry-run \
  --base-url http://localhost:4000/dev/mail \
  --output-dir tmp/mailglass_admin_preview_capture
```

### Artifact contract

The command writes:

- `tmp/mailglass_admin_preview_capture/<mailable>--<scenario>--w<width>--<theme>.png`
- `tmp/mailglass_admin_preview_capture/manifest.json`
- `tmp/mailglass_admin_preview_capture/checkpoint.json`

`manifest.json` and `checkpoint.json` use schema version `preview_capture.v1`
and include bounded language:
`preview-pipeline confidence only; not cross-client parity`.
