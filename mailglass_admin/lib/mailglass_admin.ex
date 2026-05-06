defmodule MailglassAdmin do
  @moduledoc since: "0.1.0"
  @moduledoc """
  Mountable LiveView preview and operator surfaces for mailglass.

  The canonical `v1.x` admin contract lives in
  `mailglass_admin/docs/api_stability.md`.

  The stable package promise is narrow:

  - `MailglassAdmin.Router` is the stable mount surface.
  - `MailglassAdmin.Auth` is the stable adopter-owned auth seam.
  - `version/0` is a stable package helper.

  LiveView implementation modules, DOM/CSS shape, preview plumbing, and
  internal mount hooks remain internal even when framework wiring requires them
  to stay reachable.

  ## Quick start

  Add to your adopter app's `lib/my_app_web/router.ex`:

      import MailglassAdmin.Router

      if Application.compile_env(:my_app, :dev_routes) do
        scope "/dev" do
          pipe_through :browser
          mailglass_admin_routes "/mail"
        end
      end

  Restart `mix phx.server`, visit `/dev/mail`. Done.

  See `MailglassAdmin.Router.mailglass_admin_routes/2` and
  `MailglassAdmin.Router.mailglass_operator_routes/2` for options.
  """

  # CONTEXT D-10 / CORE-07 renderer-purity rule: PreviewLive may call
  # `Mailglass.Renderer.render/1` and `Mailglass.Message.*` builders but
  # NOT `Mailglass.Outbound.deliver/2` (preview NEVER sends).
  # `exports: [Router]` reflects the narrow stable package root. Other modules
  # may still be documented as stable semantic seams without becoming root
  # exports, and exported wiring hooks do not become public contract by
  # default.
  use Boundary,
    deps: [Mailglass],
    exports: [Router]

  @version Mix.Project.config()[:version]

  @doc since: "0.1.0"
  @doc """
  Returns the package version string at compile time.
  """
  @spec version() :: String.t()
  def version, do: @version
end
