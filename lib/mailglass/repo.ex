defmodule Mailglass.Repo do
  @moduledoc """
  Thin facade over the host-configured `Ecto.Repo`.

  Mailglass does not own a Repo — the host application does. Every context
  module that needs Postgres routes through this facade, which resolves the
  real Repo via `Application.get_env(:mailglass, :repo)` at call time.

  Runtime resolution is deliberate: tests inject a test repo through
  `config/test.exs`, host apps inject their Repo through
  `config :mailglass, repo: MyApp.Repo`, and neither path requires
  recompiling mailglass.

  This module re-exports only what mailglass itself uses. Callers that need
  lower-level operations call the host Repo directly.

  ## Phase 1 scope

  Only `transact/1` is wired in Phase 1 (used by the render preview path in
  later phases and by the event append path in Phase 2). The SQLSTATE 45A01
  immutability translation for the events-ledger trigger lands in Phase 2
  alongside the trigger itself.
  """

  @doc """
  Delegates to `c:Ecto.Repo.transact/2` on the host-configured Repo.

  Preferred over `c:Ecto.Repo.transaction/2` because Ecto 3.13+ `transact/2`
  accepts a zero-arity function that returns `{:ok, result}` or
  `{:error, reason}` and rolls the transaction back on `:error` without
  requiring `Ecto.Repo.rollback/1`.

  Raises `Mailglass.ConfigError` of type `:missing` when `:repo` is not
  configured.

  ## Examples

      Mailglass.Repo.transact(fn ->
        {:ok, inserted} = Mailglass.Events.append(multi)
        {:ok, inserted}
      end)
  """
  @doc since: "0.1.0"
  @spec transact((-> {:ok, any()} | {:error, any()}), keyword()) ::
          {:ok, any()} | {:error, any()}
  def transact(fun, opts \\ []) when is_function(fun, 0) and is_list(opts) do
    repo().transact(fun, opts)
  end

  # Resolves the configured repo module. Raises `Mailglass.ConfigError` with
  # type `:missing` and a `%{key: :repo}` context when unset. Phase 2+
  # callers (Events.append, Suppression.record, Delivery.upsert) rely on
  # this error to fail fast when an adopter forgets the config wiring.
  @spec repo() :: module()
  defp repo do
    case Application.get_env(:mailglass, :repo) do
      nil -> raise Mailglass.ConfigError.new(:missing, context: %{key: :repo})
      mod when is_atom(mod) -> mod
    end
  end

  # Phase 2 will activate this when the `mailglass_raise_immutability`
  # trigger on `mailglass_events` starts firing. Lifted verbatim from the
  # accrue Repo pattern; kept here as a forward-reference stub so the
  # translation point is documented at the facade layer where it belongs.
  #
  # defp translate_immutability_error(err) do
  #   case err do
  #     %Postgrex.Error{postgres: %{pg_code: "45A01"}} ->
  #       reraise Mailglass.EventLedgerImmutableError,
  #               [pg_code: "45A01"],
  #               __STACKTRACE__
  #
  #     _ ->
  #       reraise err, __STACKTRACE__
  #   end
  # end
end
