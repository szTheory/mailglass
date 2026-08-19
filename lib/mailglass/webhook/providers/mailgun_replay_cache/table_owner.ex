defmodule Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner do
  @moduledoc """
  Owns the Mailgun replay cache ETS table.
  """
  use GenServer

  @table :mailglass_webhook_mailgun_replay_cache
  @default_max_entries 100_000
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
  @spec check_and_put(binary(), DateTime.t()) :: :ok | {:error, :replay}
  def check_and_put(token, expires_at),
    do: GenServer.call(__MODULE__, {:check_and_put, token, expires_at})

  @doc false
  def reset, do: GenServer.call(__MODULE__, :reset)

  @impl GenServer
  def handle_call({:check_and_put, token, expires_at}, _from, state) do
    ensure_table()
    now = Mailglass.Clock.utc_now()
    purge_expired(now)

    result =
      case :ets.lookup(@table, token) do
        [{^token, existing_expires_at}] when is_struct(existing_expires_at, DateTime) ->
          if DateTime.compare(existing_expires_at, now) == :gt, do: {:error, :replay}, else: :ok

        [] ->
          if :ets.info(@table, :size) < max_entries() and
               :ets.insert_new(@table, {token, expires_at}) do
            :ok
          else
            {:error, :replay}
          end
      end

    {:reply, result, state}
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

  @doc since: "0.2.1"
  @spec table() :: :mailglass_webhook_mailgun_replay_cache
  def table, do: @table

  defp max_entries do
    Application.get_env(:mailglass, :mailgun_replay_cache, [])
    |> Keyword.get(:max_entries, @default_max_entries)
  end

  defp purge_expired(now) do
    @table
    |> :ets.tab2list()
    |> Enum.each(fn {token, expires_at} ->
      if DateTime.compare(expires_at, now) != :gt, do: :ets.delete(@table, token)
    end)
  end

  defp schedule_sweep do
    opts = Application.get_env(:mailglass, :mailgun_replay_cache, [])

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
