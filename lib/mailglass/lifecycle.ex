defmodule Mailglass.Lifecycle do
  @moduledoc """
  Compatibility lifecycle seam for adopter-side event composition.

  The callback shape remains `handle_event(Ecto.Multi.t(), map()) ::
  Ecto.Multi.t()`. For one-click unsubscribe, Mailglass calls
  `handle_event(Ecto.Multi.new(), attrs)` only after the primary event and suppression convergence commits, then runs the returned Multi as a separate,
  best-effort transaction. A lifecycle failure is logged and cannot roll back or
  change the already-successful unsubscribe response.
  """

  @callback handle_event(Ecto.Multi.t(), map()) :: Ecto.Multi.t()

  @doc """
  Default no-op implementation for lifecycle hooks.

  Returns the supplied Multi unchanged so adopters can opt out without branching
  in the caller.
  """
  @spec handle_event(Ecto.Multi.t(), map()) :: Ecto.Multi.t()
  def handle_event(multi, attrs) when is_map(attrs) do
    Mailglass.Lifecycle.Noop.handle_event(multi, attrs)
  end
end

defmodule Mailglass.Lifecycle.Noop do
  @moduledoc """
  Default no-op lifecycle implementation.

  Returns the in-flight multi unchanged.
  """

  @behaviour Mailglass.Lifecycle

  @impl true
  def handle_event(%Ecto.Multi{} = multi, _attrs), do: multi
end
