defmodule Mailglass.RateLimiter.TableOwner do
  @moduledoc """
  Owns the `:mailglass_rate_limit` ETS table and the small amount of work that
  must be serialized: missing-key admission, the bounded contention fallback,
  and idle sweeping. Callers use `AtomicBucket`'s compare-and-swap fast path;
  only a caller that exhausts that finite budget enters this mailbox.

  ## ETS opts (OTP 27+)

  - `:set` — single-entry-per-key bucket
  - `:public` — cross-process read/write without owner-forwarding
  - `:named_table` — caller references `:mailglass_rate_limit` directly
  - `read_concurrency: true` — hot read path optimization
  - `write_concurrency: :auto` — OTP 27 flag for lock striping
  - `decentralized_counters: true` — OTP 27 flag, per-scheduler counters

  ## Crash semantics

  If this process crashes, BEAM deletes the ETS table. The supervisor restarts
  TableOwner and `ensure_table/0` recreates the canonical table before every
  owner ETS operation, including a caller that deleted the table immediately
  before admission. Bucket state is intentionally ephemeral across a restart;
  callers either re-admit through the replacement owner or receive the normal
  bounded limiter denial, never an ETS exception.

  ## Reserved-singleton note

  This module uses `name: __MODULE__`. It is library-internal
  machinery (not a user-facing singleton) and documented in
  `docs/api_stability.md` as a reserved singleton. `NoDefaultModuleNameSingleton`
  has an allowlist entry for this
  module.
  """
  use GenServer

  alias Mailglass.RateLimiter.AtomicBucket

  @table :mailglass_rate_limit

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) when is_list(opts) do
    {name, _init_opts} = Keyword.pop(opts, :name)
    start_opts = if is_nil(name), do: [], else: [name: name]
    GenServer.start_link(__MODULE__, :ok, start_opts)
  end

  @impl GenServer
  def init(:ok) do
    ensure_table()
    schedule_sweep()
    {:ok, %{}}
  end

  @doc false
  @spec admit(term(), tuple(), integer()) :: :ok | {:error, :denied}
  def admit(key, initial, now_us) do
    GenServer.call(__MODULE__, {:admit, key, initial, now_us})
  end

  @impl GenServer
  def handle_call({:admit, key, initial, now_us}, _from, state) do
    ensure_table()

    result =
      case :ets.lookup(@table, key) do
        [_] -> :ok
        [] -> admit_missing(key, initial, now_us)
      end

    {:reply, result, state}
  end

  @impl GenServer
  def handle_call({:consume_contended, key, capacity, per_minute, now_us}, _from, state) do
    ensure_table()

    result =
      case :ets.take(@table, key) do
        [bucket] -> consume_and_reinsert(bucket, capacity, per_minute, now_us)
        [] -> admit_and_consume(key, capacity, per_minute, now_us)
      end

    {:reply, result, state}
  end

  @impl GenServer
  def handle_info(:sweep, state) do
    ensure_table()
    purge_idle(System.monotonic_time(:microsecond))
    schedule_sweep()
    {:noreply, state}
  end

  @doc "Returns the ETS table name. Public so tests can inspect state."
  @doc since: "0.1.0"
  def table, do: @table

  defp admit_missing(key, initial, now_us) do
    opts = Application.get_env(:mailglass, :rate_limit_table_owner, [])
    max_keys = Keyword.get(opts, :max_keys, 100_000)

    if :ets.info(@table, :size) >= max_keys do
      purge_idle(now_us)
    end

    if :ets.info(@table, :size) < max_keys and :ets.insert_new(@table, initial) do
      :ok
    else
      # Another caller may have admitted this key while we were reclaiming.
      if :ets.member(@table, key), do: :ok, else: {:error, :denied}
    end
  end

  defp admit_and_consume(key, capacity, per_minute, now_us) do
    initial = {key, capacity * 1_000_000, now_us, 0, now_us}

    case admit_missing(key, initial, now_us) do
      :ok ->
        case :ets.take(@table, key) do
          [bucket] -> consume_and_reinsert(bucket, capacity, per_minute, now_us)
          [] -> {:error, :denied}
        end

      {:error, :denied} ->
        {:error, :denied}
    end
  end

  defp consume_and_reinsert(bucket, capacity, per_minute, now_us) do
    {result, replacement} = AtomicBucket.consume_taken(bucket, capacity, per_minute, now_us)
    true = :ets.insert(@table, replacement)
    if result == :ok, do: :ok, else: {:error, :denied}
  end

  defp purge_idle(now_us) do
    opts = Application.get_env(:mailglass, :rate_limit_table_owner, [])
    expiry_us = Keyword.get(opts, :idle_expiry_ms, 3_600_000) * 1_000

    :ets.select_delete(@table, [
      {{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:<, :"$5", now_us - expiry_us}], [true]}
    ])
  end

  defp schedule_sweep do
    opts = Application.get_env(:mailglass, :rate_limit_table_owner, [])
    Process.send_after(self(), :sweep, Keyword.get(opts, :sweep_interval_ms, 60_000))
  end

  defp ensure_table do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [
        :set,
        :public,
        :named_table,
        read_concurrency: true,
        write_concurrency: :auto,
        decentralized_counters: true
      ])
    else
      @table
    end
  end
end
