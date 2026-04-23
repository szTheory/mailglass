defmodule Mailglass.SuppressionStore.ETS.TableOwner do
  @moduledoc """
  Init-and-idle GenServer owning the `:mailglass_suppression_store` ETS
  table. Same pattern as `Mailglass.RateLimiter.TableOwner` (D-22).

  ## ETS opts

  - `:set` — single-entry-per-key
  - `:public` — cross-process read/write
  - `:named_table`
  - `read_concurrency: true`
  - `write_concurrency: :auto`
  - `decentralized_counters: false` — suppression lookups are reads,
    not counter updates; `decentralized_counters` trades read speed
    for write parallelism (not what we want here).

  ## Key shape

  ETS keys are `{tenant_id, address, scope, stream_or_nil}` tuples
  (matches the Ecto UNIQUE constraint `(tenant_id, address, scope,
  COALESCE(stream, ''))`).

  ## LIB-05 note

  This module uses `name: __MODULE__`. It is library-internal machinery
  (not a user-facing singleton) and documented in `docs/api_stability.md`
  as a reserved singleton. Phase 6 `LINT-07 NoDefaultModuleNameSingleton`
  has an allowlist entry for this module.
  """
  use GenServer

  @table :mailglass_suppression_store

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl GenServer
  def init(:ok) do
    :ets.new(@table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: :auto
    ])

    {:ok, %{}}
  end

  @doc "Returns the ETS table name. Public so tests can inspect state."
  @doc since: "0.1.0"
  @spec table() :: atom()
  def table, do: @table
end
