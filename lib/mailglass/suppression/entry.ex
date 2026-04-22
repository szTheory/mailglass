defmodule Mailglass.Suppression.Entry do
  @moduledoc """
  Ecto schema for a row in `mailglass_suppressions`.

  ## Atom Sets (D-07, D-10, D-11)

  - `:scope` — `:address | :domain | :address_stream`. NO default;
    changeset `validate_required` enforces (MAIL-07 prevention).
  - `:stream` — `:transactional | :operational | :bulk` (nullable;
    populated only when `scope = :address_stream`).
  - `:reason` — `:hard_bounce | :complaint | :unsubscribe | :manual |
    :policy | :invalid_recipient`.

  ## Coupling invariants (D-07)

  - `scope = :address_stream` REQUIRES `stream`.
  - `scope IN (:address, :domain)` REJECTS `stream`.

  Enforced both at the changeset layer (`validate_scope_stream_coupling/1`)
  and at the DB layer (`mailglass_suppressions_stream_scope_check`
  CHECK constraint — Plan 02). Belt-and-suspenders: either layer alone
  would suffice, but lint-time errors (changeset) are cheaper than
  runtime errors (Postgres).

  ## Address normalization

  The column is `CITEXT`, so the DB compares case-insensitively.
  Additionally, `downcase_address/1` lowercases at cast time — defense
  in depth, and makes "did I downcase?" questions moot for reads that
  bypass citext (e.g. analytics exports).
  """
  use Mailglass.Schema
  import Ecto.Changeset

  @scopes [:address, :domain, :address_stream]
  @streams [:transactional, :operational, :bulk]
  @reasons [:hard_bounce, :complaint, :unsubscribe, :manual, :policy, :invalid_recipient]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          address: String.t() | nil,
          scope: :address | :domain | :address_stream | nil,
          stream: :transactional | :operational | :bulk | nil,
          reason: atom() | nil,
          source: String.t() | nil,
          expires_at: DateTime.t() | nil,
          metadata: map(),
          inserted_at: DateTime.t() | nil
        }

  schema "mailglass_suppressions" do
    field(:tenant_id, :string)
    # DB is citext; Ecto sees string
    field(:address, :string)
    # NO default — D-11
    field :scope, Ecto.Enum, values: @scopes
    # nullable — D-07
    field(:stream, Ecto.Enum, values: @streams)
    field(:reason, Ecto.Enum, values: @reasons)
    field(:source, :string)
    field(:expires_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})
    field(:inserted_at, :utc_datetime_usec, read_after_writes: true)
  end

  @required ~w[tenant_id address scope reason source]a
  @cast @required ++ ~w[stream expires_at metadata]a

  @doc """
  Builds a changeset for a new `%Entry{}` from an attr map.

  Enforces three invariants at the Elixir layer:

  1. `:scope` is required with no default (MAIL-07 prevention — D-11).
  2. Scope/stream coupling (D-07) via `validate_scope_stream_coupling/1`.
  3. Address normalization via `downcase_address/1` — belt-and-suspenders
     with the underlying `CITEXT` column.
  """
  @doc since: "0.1.0"
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> validate_scope_stream_coupling()
    |> downcase_address()
  end

  defp validate_scope_stream_coupling(changeset) do
    scope = get_field(changeset, :scope)
    stream = get_field(changeset, :stream)

    case {scope, stream} do
      {:address_stream, nil} ->
        add_error(changeset, :stream, "required when scope is :address_stream")

      {scope, stream} when scope in [:address, :domain] and not is_nil(stream) ->
        add_error(changeset, :stream, "must be nil when scope is #{inspect(scope)}")

      _ ->
        changeset
    end
  end

  defp downcase_address(changeset) do
    case get_change(changeset, :address) do
      nil -> changeset
      addr -> put_change(changeset, :address, String.downcase(addr))
    end
  end

  @doc "Closed scope atom set."
  @doc since: "0.1.0"
  @spec __scopes__() :: [atom()]
  def __scopes__, do: @scopes

  @doc "Closed stream atom set."
  @doc since: "0.1.0"
  @spec __streams__() :: [atom()]
  def __streams__, do: @streams

  @doc "Closed reason atom set."
  @doc since: "0.1.0"
  @spec __reasons__() :: [atom()]
  def __reasons__, do: @reasons
end
