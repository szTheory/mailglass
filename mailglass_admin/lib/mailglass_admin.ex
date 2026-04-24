defmodule MailglassAdmin do
  @moduledoc """
  Mountable LiveView dashboard for mailglass. Dev preview at v0.1; prod admin at v0.5.

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

  See `MailglassAdmin.Router.mailglass_admin_routes/2` for options.
  """

  # CONTEXT D-10 / CORE-07 renderer-purity rule: PreviewLive may call
  # `Mailglass.Renderer.render/1` and `Mailglass.Message.*` builders but
  # NOT `Mailglass.Outbound.deliver/2` (preview NEVER sends).
  # `exports: [Router]` reflects that the router macro is the only public
  # surface at v0.1; every other submodule is internal.
  use Boundary,
    deps: [Mailglass],
    exports: [Router]

  @version Mix.Project.config()[:version]

  @doc """
  Returns the package version string at compile time.
  """
  @spec version() :: String.t()
  def version, do: @version
end
