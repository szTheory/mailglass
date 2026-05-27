defmodule Mailglass.Lifecycle do
  @moduledoc """
  Transaction lifecycle seam for adopter-side event composition.

   introduces the contract only. The unsubscribe controller's
  `Ecto.Multi` integration lands in 11-03 per , where this callback
  will be invoked inside the durable unsubscribe transaction.
  """

  @callback handle_event(Ecto.Multi.t(), map()) :: Ecto.Multi.t()

  @doc """
  Default no-op implementation for lifecycle hooks.

  Returns the in-flight multi unchanged so adopters can opt out without
  branching in the caller.
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
