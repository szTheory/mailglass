defmodule MailglassInbound.Repo do
  @moduledoc """
  Thin facade over the host-configured repo for `mailglass_inbound`.

  The sibling package does not own a repo. Host applications configure one via
  `config :mailglass_inbound, :repo, MyApp.Repo`.

  ## Schema prefix injection (v2.0)

  Every delegated read/write injects `prefix: MailglassInbound.Config.schema()` via
  `Keyword.put_new`, routing all operations to the configured Postgres schema
  (`"mailglass"` by default, `"public"` for pre-2.0 opt-out). An explicit
  caller-supplied `:prefix` wins over the injected default (INB-01).

  `transact/2` and `multi/2` do NOT inject prefix. The inner `insert/2`, `one/2`,
  `all/2`, and `get/3` calls inside a transaction carry their own prefix via the
  facade. Inbound has no Multi builders today (`multi_opts/1` is deferred); a future
  raw caller that passes an inbound table to a non-facade path must qualify inline.
  """

  @spec transact((-> {:ok, any()} | {:error, any()}), keyword()) ::
          {:ok, any()} | {:error, any()}
  def transact(fun, opts \\ []) when is_function(fun, 0) and is_list(opts) do
    repo().transact(fun, opts)
  end

  @spec insert(Ecto.Changeset.t() | struct(), keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def insert(struct_or_changeset, opts \\ []) do
    repo().insert(struct_or_changeset, put_prefix(opts))
  end

  @spec one(Ecto.Queryable.t(), keyword()) :: struct() | nil
  def one(queryable, opts \\ []), do: repo().one(queryable, put_prefix(opts))

  @spec multi(Ecto.Multi.t(), keyword()) ::
          {:ok, map()} | {:error, atom(), any(), map()}
  def multi(multi, opts \\ []) when is_list(opts) do
    repo().transaction(multi, opts)
  end

  @spec all(Ecto.Queryable.t(), keyword()) :: [struct()]
  def all(queryable, opts \\ []), do: repo().all(queryable, put_prefix(opts))

  @spec get(Ecto.Queryable.t(), term(), keyword()) :: struct() | nil
  def get(queryable, id, opts \\ []), do: repo().get(queryable, id, put_prefix(opts))

  @spec repo() :: module()
  defp repo do
    case Application.get_env(:mailglass_inbound, :repo) do
      nil ->
        raise RuntimeError,
              "mailglass_inbound requires config :mailglass_inbound, :repo to resolve its host repo"

      mod when is_atom(mod) ->
        mod
    end
  end

  # Injects `prefix: MailglassInbound.Config.schema()` via `Keyword.put_new`, so an
  # explicit caller-supplied `:prefix` wins. Every delegated read/write
  # (insert/one/all/get) passes opts through this function — it is the INB-01
  # schema-isolation choke point for the inbound facade.
  # `transact/2` and `multi/2` do NOT use `put_prefix/1`.
  @spec put_prefix(keyword()) :: keyword()
  defp put_prefix(opts), do: Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())
end
