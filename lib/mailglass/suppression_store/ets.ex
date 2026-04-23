defmodule Mailglass.SuppressionStore.ETS do
  @moduledoc """
  ETS-backed implementation of `Mailglass.SuppressionStore` (D-28).

  Test-speed + narrow production use case (single-node, read-heavy,
  sub-100-entry lists). Default impl remains
  `Mailglass.SuppressionStore.Ecto` — adopters override via:

      config :mailglass, :suppression_store, Mailglass.SuppressionStore.ETS

  ## Key shape

  ETS keys: `{tenant_id, address, scope, stream_or_nil}` (mirrors
  Ecto UNIQUE constraint `(tenant_id, address, scope, COALESCE(stream, ''))`).

  ## Lookup algorithm

  `check/2` tries three scopes in order (matching Ecto's OR-union):

  1. `{tenant_id, address, :address, nil}`
  2. `{tenant_id, domain(address), :domain, nil}`
  3. `{tenant_id, address, :address_stream, stream}` (only when stream is set)

  First hit wins. Expiry filter at read time (expired entries not returned).

  ## UPSERT behaviour

  `record/2` with the same `{tenant_id, address, scope, stream}` key
  overwrites the existing entry (equivalent to Ecto's `on_conflict: {:replace, [...]}`).

  ## Test override pattern (RESEARCH §5.3)

  Tests scope by unique `tenant_id` to avoid cross-test interference — no
  per-pid ownership needed (ETS table is global). Tests that need a clean
  slate between runs call `Mailglass.SuppressionStore.ETS.reset/0`.
  """

  @behaviour Mailglass.SuppressionStore

  alias Mailglass.Suppression.Entry

  @table :mailglass_suppression_store

  @impl Mailglass.SuppressionStore
  def check(key, opts \\ [])

  def check(%{tenant_id: tid, address: addr} = key, _opts)
      when is_binary(tid) and is_binary(addr) do
    stream = Map.get(key, :stream)
    addr_down = String.downcase(addr)
    now = Mailglass.Clock.utc_now()

    Enum.find_value(build_lookups(tid, addr_down, stream), :not_suppressed, fn lookup_key ->
      case :ets.lookup(@table, lookup_key) do
        [{^lookup_key, %Entry{} = entry}] ->
          if not_expired?(entry, now), do: {:suppressed, entry}, else: nil

        _ ->
          nil
      end
    end)
  end

  def check(_key, _opts), do: {:error, :invalid_key}

  @impl Mailglass.SuppressionStore
  def record(attrs, opts \\ [])

  def record(attrs, _opts) when is_map(attrs) do
    with {:ok, entry} <- build_entry(attrs) do
      key = ets_key(entry)
      :ets.insert(@table, {key, entry})
      {:ok, entry}
    end
  end

  def record(_attrs, _opts), do: {:error, :invalid_attrs}

  @doc """
  Clears the ETS suppression table. Test-only helper.

  Use this in `setup` blocks to ensure a clean slate between tests.
  """
  @doc since: "0.1.0"
  @spec reset() :: :ok
  def reset do
    :ets.delete_all_objects(@table)
    :ok
  end

  # --- Private helpers ---

  defp build_lookups(tid, addr_down, stream) do
    base = [
      {tid, addr_down, :address, nil},
      {tid, domain(addr_down), :domain, nil}
    ]

    if stream do
      base ++ [{tid, addr_down, :address_stream, stream}]
    else
      base
    end
  end

  defp domain(address) do
    case String.split(address, "@", parts: 2) do
      [_local, d] -> String.downcase(d)
      _ -> address
    end
  end

  defp ets_key(%Entry{tenant_id: tid, address: addr, scope: scope, stream: stream}) do
    {tid, String.downcase(addr), scope, stream}
  end

  defp not_expired?(%Entry{expires_at: nil}, _now), do: true
  defp not_expired?(%Entry{expires_at: ea}, now), do: DateTime.compare(ea, now) != :lt

  defp build_entry(attrs) do
    required = [:tenant_id, :address, :scope]

    missing = Enum.filter(required, fn k -> not Map.has_key?(attrs, k) end)

    if missing != [] do
      {:error, {:missing, missing}}
    else
      entry = %Entry{
        id: Map.get(attrs, :id) || Ecto.UUID.generate(),
        tenant_id: attrs.tenant_id,
        address: String.downcase(attrs.address),
        scope: attrs.scope,
        stream: Map.get(attrs, :stream),
        reason: Map.get(attrs, :reason),
        source: Map.get(attrs, :source),
        expires_at: Map.get(attrs, :expires_at),
        metadata: Map.get(attrs, :metadata, %{}),
        inserted_at: Map.get(attrs, :inserted_at, Mailglass.Clock.utc_now())
      }

      {:ok, entry}
    end
  end
end
