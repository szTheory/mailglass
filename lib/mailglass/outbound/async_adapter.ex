defmodule Mailglass.Outbound.AsyncAdapter do
  @moduledoc false
  # Internal — may move to public surface in Phase 9 per D-08-29.
  #
  # Pluggable behaviour for async dispatch in the Outbound pipeline.
  # The 5th first-class behaviour in mailglass (after Tenancy, Clock,
  # Adapters, OptionalDeps) — "Pluggable behaviours over magic" (CLAUDE.md).
  #
  # Two impls ship in v0.2:
  #
  #   * Mailglass.Outbound.AsyncAdapter.TaskSupervisor (prod default)
  #   * Mailglass.Outbound.AsyncAdapter.Inline (test default)
  #
  # Resolved via Application.get_env(:mailglass, :async_adapter_impl).
  # NOTE: separate env key from :async_adapter (which selects between
  # :task_supervisor and :oban for the prod-side dispatch strategy at
  # outbound.ex — DO NOT collide, per D-08-11).
  #
  # ## Pattern (D-08-11)
  #
  # Configure in test support:
  #
  #     Application.put_env(:mailglass, :async_adapter_impl,
  #       Mailglass.Outbound.AsyncAdapter.Inline)
  #
  # The default (no config) uses TaskSupervisor — prod behaviour.

  @callback dispatch(fun :: (-> any()), opts :: keyword()) :: {:ok, pid()} | :ok

  @doc """
  Dispatches `fun` via the configured async adapter impl.

  The caller is responsible for stamping tenant context inside the closure
  via `Mailglass.Tenancy.with_tenant/2` before calling this function — the
  tenancy re-stamp works for both impls (D-08-15):

  - `TaskSupervisor`: spawns a fresh process; `with_tenant/2` stamps it.
  - `Inline`: runs synchronously in the caller's process; `with_tenant/2`
    re-stamps and restores on return.
  """
  @spec dispatch((-> any()), keyword()) :: {:ok, pid()} | :ok
  def dispatch(fun, opts \\ []) when is_function(fun, 0) do
    impl().dispatch(fun, opts)
  end

  defp impl do
    case Application.get_env(:mailglass, :async_adapter_impl) do
      nil -> Mailglass.Outbound.AsyncAdapter.TaskSupervisor
      mod when is_atom(mod) -> mod
    end
  end
end
