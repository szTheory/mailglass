defmodule Mailglass.Application do
  @moduledoc false
  use Application
  require Logger

  @impl Application
  def start(_type, _args) do
    # Phase 1 ordering: Mailglass.Config lands in Plan 03. Guard prevents an
    # early boot crash when the OTP application starts under `mix test` with
    # only Plan 01 merged. Once Plan 03 lands the guard remains satisfied, so
    # production boot behaviour is unchanged.
    if Code.ensure_loaded?(Mailglass.Config) and
         function_exported?(Mailglass.Config, :validate_at_boot!, 0) do
      Mailglass.Config.validate_at_boot!()
    end

    maybe_warn_missing_oban()

    # Phase 1 supervisor children intentionally empty. Phoenix.PubSub, Registry,
    # and Task.Supervisor are added by the plans that actually use them.
    children = []

    Supervisor.start_link(children, strategy: :one_for_one, name: Mailglass.Supervisor)
  end

  defp maybe_warn_missing_oban do
    unless Code.ensure_loaded?(Oban) do
      Logger.warning("""
      [Mailglass] Oban is not loaded. deliver_later/2 will use Task.Supervisor
      as a fallback, which does not survive node restarts. Add {:oban, "~> 2.21"}
      to your mix.exs for production use.
      """)
    end
  end
end
