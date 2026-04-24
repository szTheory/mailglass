# mailglass_admin

Mountable LiveView dashboard for mailglass. The dev-preview surface at v0.1:
see every mailable in your app, pick a scenario, edit the assigns inline, and
inspect HTML / Text / Raw / Headers tabs — all without leaving the browser.

## Installation

Add `mailglass_admin` to your adopter app's `mix.exs`:

    def deps do
      [
        {:mailglass, "~> 0.1"},
        {:mailglass_admin, "~> 0.1", only: :dev}
      ]
    end

Then `mix deps.get`.

## Mount the preview

Add four lines to `lib/my_app_web/router.ex`:

    import MailglassAdmin.Router

    if Application.compile_env(:my_app, :dev_routes) do
      scope "/dev" do
        pipe_through :browser
        mailglass_admin_routes "/mail"
      end
    end

Restart `mix phx.server`, visit `/dev/mail`. Done.

The `if Application.compile_env(:my_app, :dev_routes) do ... end` wrapper is
the Phoenix 1.8 convention (same gate that protects `live_dashboard` and
`Plug.Swoosh.MailboxPreview`). `mailglass_admin` does not check `Mix.env()`
itself — dev-only is the adopter's responsibility.

## LiveReload setup (optional)

When your adopter app runs under `:phoenix_live_reload`, mailglass_admin can
refresh the preview automatically on file save. Add a `live_reload.notify`
entry to your endpoint:

    config :my_app, MyAppWeb.Endpoint,
      live_reload: [
        notify: [
          "mailglass:admin:reload": [~r"lib/.*mailer.*\.ex$"]
        ]
      ]

The topic is prefixed `mailglass:admin:reload` (not bare `mailglass_admin_reload`)
to match the LINT-06 `mailglass:`-prefixed PubSub topic convention. When
LiveReload is not configured the preview still works — the adopter just
refreshes the browser manually.

## `preview_props/0` contract

Each `Mailglass.Mailable` module can declare preview scenarios by defining
`preview_props/0`:

    defmodule MyApp.UserMailer do
      use Mailglass.Mailable, stream: :transactional

      def preview_props do
        [
          welcome_default: %{user: %User{name: "Ada"}, team: %Team{name: "Analytical Engines"}},
          welcome_enterprise: %{user: %User{name: "Ada"}, team: %Team{name: "Analytical Engines"}, plan: :enterprise}
        ]
      end

      def welcome(assigns), do: ...
    end

Each tuple is a discrete scenario; the sidebar nests scenarios under the
mailable module name (`MyApp.UserMailer -> welcome_default`). Scenarios
appear in insertion order. Mailables without `preview_props/0` still show
up in the sidebar as `No previews defined` — they remain discoverable even
before you write any scenarios.

## What this ships

- Auto-discovered mailable sidebar (collapsible scenario groups)
- Four tabs per scenario: HTML, Text, Raw (RFC 5322 envelope), Headers
- Type-inferred assigns form — edit any top-level assign inline and
  re-render
- Device toggle (375 / 768 / 1024) + chrome dark toggle
- Graceful failure badges for mailables whose `preview_props/0` raises

## What this does NOT ship

- Any prod-mountable admin surface (sent-mail inbox, event timeline,
  suppression UI). That lands at v0.5.
- Authentication or step-up protection. Dev-only mount relies on the
  adopter's `:dev_routes` wrapper — do not mount this in production.
- Search, filter, or pagination over mailables. v0.5.
- Inbound-mail (`mailglass_inbound`) Conductor LiveView — separate sibling
  package, v0.5+.

## License

MIT. See [LICENSE](./LICENSE). Released alongside `mailglass` via
coordinated linked-version Release Please tags.
