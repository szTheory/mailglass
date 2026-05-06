defmodule MailglassInbound.Repo do
  @moduledoc """
  Thin facade over the host-configured repo for `mailglass_inbound`.

  The sibling package does not own a repo. Host applications configure one via
  `config :mailglass_inbound, :repo, MyApp.Repo`.
  """

  @spec transact((-> {:ok, any()} | {:error, any()}), keyword()) ::
          {:ok, any()} | {:error, any()}
  def transact(fun, opts \\ []) when is_function(fun, 0) and is_list(opts) do
    repo().transact(fun, opts)
  end

  @spec insert(Ecto.Changeset.t() | struct(), keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def insert(struct_or_changeset, opts \\ []) do
    repo().insert(struct_or_changeset, opts)
  end

  @spec all(Ecto.Queryable.t(), keyword()) :: [struct()]
  def all(queryable, opts \\ []), do: repo().all(queryable, opts)

  @spec get(Ecto.Queryable.t(), term(), keyword()) :: struct() | nil
  def get(queryable, id, opts \\ []), do: repo().get(queryable, id, opts)

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
end
