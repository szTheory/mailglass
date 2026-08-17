defmodule Mailglass.Webhook.Providers.SES.CertCache.TableOwner do
  @moduledoc """
  Owns bounded certificate admission and expiry.  Cache misses are deliberately
  serialized here: a single process is the conservative global in-flight cap,
  so a cold burst cannot stampede an SNS endpoint.
  """
  use GenServer

  @table :mailglass_webhook_ses_cert_cache
  @default_max_entries 1_024
  @default_negative_ttl_seconds 60
  @default_sweep_interval_ms 60_000

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
  def fetch_or_store(url, fetch, opts) do
    GenServer.call(__MODULE__, {:fetch_or_store, url, fetch, opts}, :infinity)
  end

  @doc false
  def put(url, public_key, expires_at),
    do: GenServer.call(__MODULE__, {:put, url, public_key, expires_at})

  @doc false
  def reset, do: GenServer.call(__MODULE__, :reset)

  @impl GenServer
  def handle_call({:fetch_or_store, url, fetch, opts}, _from, state) do
    ensure_table()
    now = Mailglass.Clock.utc_now()
    purge_expired(now)

    result =
      case cached(url, now) do
        {:ok, _public_key} = hit -> hit
        {:error, reason} -> {:error, reason}
        :miss -> fetch_missing(url, fetch, opts, now)
      end

    {:reply, result, state}
  end

  def handle_call({:put, url, public_key, expires_at}, _from, state) do
    ensure_table()
    now = Mailglass.Clock.utc_now()
    purge_expired(now)

    if admit?(url, max_entries([])) do
      true = :ets.insert(@table, {url, public_key, expires_at})
    end

    {:reply, :ok, state}
  end

  def handle_call(:reset, _from, state) do
    ensure_table()
    :ets.delete_all_objects(@table)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:sweep, state) do
    ensure_table()
    purge_expired(Mailglass.Clock.utc_now())
    schedule_sweep()
    {:noreply, state}
  end

  @doc since: "0.3.0"
  @spec table() :: :mailglass_webhook_ses_cert_cache
  def table, do: @table

  defp fetch_missing(url, fetch, opts, now) do
    if admit?(url, max_entries(opts)) do
      case fetch.() do
        {:ok, public_key} ->
          expires_at = DateTime.add(now, Keyword.get(opts, :positive_ttl_seconds, 86_400), :second)
          true = :ets.insert(@table, {url, public_key, expires_at})
          {:ok, public_key}

        {:error, reason} ->
          expires_at =
            DateTime.add(
              now,
              Keyword.get(opts, :negative_ttl_seconds, @default_negative_ttl_seconds),
              :second
            )

          true = :ets.insert(@table, {url, {:negative, reason}, expires_at})
          {:error, reason}
      end
    else
      {:error, :capacity}
    end
  end

  defp cached(url, now) do
    case :ets.lookup(@table, url) do
      [{^url, {:negative, reason}, expires_at}] ->
        if DateTime.compare(expires_at, now) == :gt, do: {:error, reason}, else: :miss

      [{^url, public_key, expires_at}] ->
        if DateTime.compare(expires_at, now) == :gt, do: {:ok, public_key}, else: :miss

      [] ->
        :miss
    end
  end

  defp admit?(url, max_entries) do
    :ets.member(@table, url) or :ets.info(@table, :size) < max_entries
  end

  defp max_entries(opts) do
    Keyword.get(
      opts,
      :max_entries,
      Application.get_env(:mailglass, :ses_cert_cache, [])
      |> Keyword.get(:max_entries, @default_max_entries)
    )
  end

  defp purge_expired(now) do
    @table
    |> :ets.tab2list()
    |> Enum.each(fn {url, _value, expires_at} ->
      if DateTime.compare(expires_at, now) != :gt, do: :ets.delete(@table, url)
    end)
  end

  defp schedule_sweep do
    opts = Application.get_env(:mailglass, :ses_cert_cache, [])

    Process.send_after(
      self(),
      :sweep,
      Keyword.get(opts, :sweep_interval_ms, @default_sweep_interval_ms)
    )
  end

  defp ensure_table do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [
        :set,
        :public,
        :named_table,
        read_concurrency: true,
        write_concurrency: :auto
      ])
    else
      @table
    end
  end
end
