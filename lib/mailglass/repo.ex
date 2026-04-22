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

  ## SQLSTATE 45A01 translation (D-06)

  Every write that touches `mailglass_events` can raise the immutability
  trigger (`BEFORE UPDATE OR DELETE` raises SQLSTATE 45A01). The facade
  rescues `%Postgrex.Error{}` at every call site and reraises as
  `Mailglass.EventLedgerImmutableError` so callers pattern-match a
  mailglass-owned error, never the raw Postgrex struct. The translation
  is centralized in `translate_postgrex_error/2` — adding new write
  functions means wiring the same rescue clause.
  """

  @doc """
  Delegates to `c:Ecto.Repo.transact/2` on the host-configured Repo.

  Preferred over `c:Ecto.Repo.transaction/2` because Ecto 3.13+ `transact/2`
  accepts a zero-arity function that returns `{:ok, result}` or
  `{:error, reason}` and rolls the transaction back on `:error` without
  requiring `Ecto.Repo.rollback/1`.

  Raises `Mailglass.ConfigError` of type `:missing` when `:repo` is not
  configured. Raises `Mailglass.EventLedgerImmutableError` when the
  mailglass_events immutability trigger fires (SQLSTATE 45A01).

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
  rescue
    err in Postgrex.Error ->
      translate_postgrex_error(err, __STACKTRACE__)
  end

  @doc "Delegates to the host Repo's `insert/2`, translating event-ledger immutability errors."
  @doc since: "0.1.0"
  @spec insert(Ecto.Changeset.t() | struct(), keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def insert(struct_or_changeset, opts \\ []) do
    repo().insert(struct_or_changeset, opts)
  rescue
    err in Postgrex.Error ->
      translate_postgrex_error(err, __STACKTRACE__)
  end

  @doc "Delegates to the host Repo's `update/2`, translating event-ledger immutability errors."
  @doc since: "0.1.0"
  @spec update(Ecto.Changeset.t(), keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def update(changeset, opts \\ []) do
    repo().update(changeset, opts)
  rescue
    err in Postgrex.Error ->
      translate_postgrex_error(err, __STACKTRACE__)
  end

  @doc "Delegates to the host Repo's `delete/2`, translating event-ledger immutability errors."
  @doc since: "0.1.0"
  @spec delete(struct() | Ecto.Changeset.t(), keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def delete(struct_or_changeset, opts \\ []) do
    repo().delete(struct_or_changeset, opts)
  rescue
    err in Postgrex.Error ->
      translate_postgrex_error(err, __STACKTRACE__)
  end

  @doc "Delegates to the host Repo's `one/2`."
  @doc since: "0.1.0"
  @spec one(Ecto.Queryable.t(), keyword()) :: struct() | nil
  def one(queryable, opts \\ []), do: repo().one(queryable, opts)

  @doc "Delegates to the host Repo's `all/2`."
  @doc since: "0.1.0"
  @spec all(Ecto.Queryable.t(), keyword()) :: [struct()]
  def all(queryable, opts \\ []), do: repo().all(queryable, opts)

  @doc "Delegates to the host Repo's `get/3`."
  @doc since: "0.1.0"
  @spec get(Ecto.Queryable.t(), term(), keyword()) :: struct() | nil
  def get(queryable, id, opts \\ []), do: repo().get(queryable, id, opts)

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

  # Translates Postgrex errors that represent mailglass-specific SQL-level
  # invariants. Currently handles SQLSTATE 45A01 (event ledger immutability
  # per D-06) + passthrough for unrelated errors.
  @spec translate_postgrex_error(Postgrex.Error.t(), Exception.stacktrace()) :: no_return()
  defp translate_postgrex_error(%Postgrex.Error{postgres: %{pg_code: "45A01"}} = err, stacktrace) do
    type = infer_immutability_type(err)

    reraise Mailglass.EventLedgerImmutableError.new(type,
              cause: err,
              context: %{pg_code: "45A01"}
            ),
            stacktrace
  end

  defp translate_postgrex_error(err, stacktrace), do: reraise(err, stacktrace)

  # The trigger fires for BOTH UPDATE and DELETE; we can distinguish by
  # inspecting the Postgrex error's message, but since the message text is
  # not a stable API (Pitfall 3 in RESEARCH) we default to `:update_attempt`
  # and let the context carry the pg_code. Callers that care about the
  # distinction can read ctx.pg_code or walk `:cause` to the raw Postgrex
  # error.
  @spec infer_immutability_type(Postgrex.Error.t()) :: :update_attempt | :delete_attempt
  defp infer_immutability_type(%Postgrex.Error{} = _err), do: :update_attempt
end
