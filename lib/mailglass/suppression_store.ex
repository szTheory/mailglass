defmodule Mailglass.SuppressionStore do
  @moduledoc """
  Behaviour for suppression-list storage backends.

   ships two callbacks — `check/2` (pre-send lookup) and
  `record/2` (add/update entry).  may extend with more
  callbacks when the Outbound preflight lands. Default impl is
  `Mailglass.SuppressionStore.Ecto` (Postgres-backed).

  Adopters swap via:

      config :mailglass, suppression_store: MyApp.SuppressionStore

  ## Semantics

  `check/2` returns `{:suppressed, %Entry{}}` when the recipient is
  on the list under any matching scope (address, domain, or
  address_stream with the stream parameter). Returns `:not_suppressed`
  otherwise. Never raises except on infrastructure failure.

  `record/2` inserts an Entry; on UNIQUE collision
  `(tenant_id, address, scope, COALESCE(stream, ''))` it UPDATES
  `reason`/`source`/`expires_at`/`metadata` (admin re-adds become
  idempotent at the application layer).
  """

  alias Mailglass.Suppression.Entry

  @typedoc """
  Lookup key accepted by `c:check/2`.

  `tenant_id` and `address` are required. `stream` is required when
  the caller intends to match an `:address_stream`-scoped entry.
  """
  @type lookup_key :: %{
          required(:tenant_id) => String.t(),
          required(:address) => String.t(),
          optional(:stream) => atom() | nil
        }

  @typedoc "Attr map accepted by `c:record/2`; passes through to `Mailglass.Suppression.Entry.changeset/1`."
  @type record_attrs :: map()

  @callback check(lookup_key(), keyword()) ::
              {:suppressed, Entry.t()} | :not_suppressed | {:error, term()}

  @doc """
  Optionally checks multiple lookup keys in their original order.

  Stores that implement this callback must return exactly one result for each
  input key. `check_many/3` below probes this capability so existing stores
  that only implement `check/2` remain compatible.
  """
  @callback check_many([lookup_key()], keyword()) ::
              [{:suppressed, Entry.t()} | :not_suppressed | {:error, term()}]

  @callback record(record_attrs(), keyword()) ::
              {:ok, Entry.t()} | {:error, Ecto.Changeset.t() | term()}

  @optional_callbacks check_many: 2

  @default_batch_size 100
  @max_batch_size 100

  @doc """
  Checks a list through an optional native bulk callback or a bounded legacy
  `check/2` fallback. Results always correspond to the input positions.
  """
  @spec check_many(module(), [lookup_key()], keyword()) ::
          [{:suppressed, Entry.t()} | :not_suppressed | {:error, term()}]
  def check_many(store, keys, opts \\ []) when is_atom(store) and is_list(keys) and is_list(opts) do
    keys
    |> Enum.chunk_every(batch_size(opts))
    |> Enum.flat_map(&check_chunk(store, &1, opts))
  end

  defp check_chunk(store, keys, opts) do
    result =
      if function_exported?(store, :check_many, 2) do
        store.check_many(keys, opts)
      else
        Enum.map(keys, &store.check(&1, opts))
      end

    if is_list(result) and length(result) == length(keys) do
      result
    else
      List.duplicate({:error, :invalid_bulk_result}, length(keys))
    end
  end

  defp batch_size(opts) do
    case Keyword.get(
           opts,
           :batch_size,
           Application.get_env(:mailglass, :suppression_store_batch_size, @default_batch_size)
         ) do
      size when is_integer(size) and size > 0 -> min(size, @max_batch_size)
      _ -> @default_batch_size
    end
  end
end
