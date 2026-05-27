# Preview

The preview surface runs in dev and uses your production render pipeline, so HTML/Text/Raw/Headers stay consistent with real delivery.

The screenshot capture workflow is for **preview-pipeline confidence only**. It
does **not** claim cross-client parity across Outlook/Gmail/Apple Mail.

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
