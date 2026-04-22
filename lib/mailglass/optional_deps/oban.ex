defmodule Mailglass.OptionalDeps.Oban do
  @moduledoc """
  Gateway for the optional Oban dependency (`{:oban, "~> 2.21"}`).

  When Oban is present, `available?/0` returns `true` and callers may safely
  reference `Oban`, `Oban.Worker`, and `Oban.Job`. When absent,
  `Mailglass.Outbound.deliver_later/2` falls back to `Task.Supervisor` with a
  `Logger.warning` emitted at boot (see `Mailglass.Application`).

  Oban integration lands in Phase 3 (Outbound). This gateway is delivered in
  Phase 1 so Config/Telemetry can reference it without forward-reference pain.

  ## Lint Enforcement (Phase 6)

  The Credo check `NoBareOptionalDepReference` flags direct `Oban.*` calls
  outside this module. All Oban interaction routes through the Outbound
  facade, which consults `available?/0` before dispatching.
  """

  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

  @doc """
  Returns `true` when `:oban` is loaded in the current runtime.

  Backed by `Code.ensure_loaded?/1`, so purge-aware and safe to call from
  compile-time callbacks (e.g. `Application.start/2`).
  """
  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)
end
