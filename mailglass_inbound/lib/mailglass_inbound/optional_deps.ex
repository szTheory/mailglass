defmodule MailglassInbound.OptionalDeps do
  @moduledoc """
  Namespace for package-local optional dependency gateway modules.

  `mailglass_inbound` keeps optional runtime integrations behind its own
  gateway surface instead of reusing `Mailglass.OptionalDeps.*` across package
  boundaries. This preserves a coherent sibling-package contract and keeps
  `mix compile --no-optional-deps --warnings-as-errors` green.
  """
end

defmodule MailglassInbound.OptionalDeps.Oban do
  @moduledoc """
  Gateway for the optional Oban dependency (`{:oban, "~> 2.21"}`).

  Phase 39 does not ship an async execution runner. This module exists so later
  execution plans can branch on Oban availability without turning Oban into a
  mandatory install-time or runtime dependency for the package.

  The public promise in this phase is intentionally small:

  - `available?/0` reports whether `:oban` is loaded in the current runtime.
  - callers may use `runner/0` to name the future execution mode without
    referencing `Oban` directly outside this gateway.

  No `%Oban.Job{}` contract, queue names, worker modules, or execution hooks
  are part of the Phase 39 package surface.
  """

  @compile {:no_warn_undefined, [Oban, Oban.Job, Oban.Worker]}

  @doc """
  Returns `true` when `:oban` is loaded in the current runtime.
  """
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)

  @doc """
  Reports which execution seam is available for future internal runners.
  """
  @spec runner() :: :oban | :inline
  def runner do
    if available?(), do: :oban, else: :inline
  end
end
