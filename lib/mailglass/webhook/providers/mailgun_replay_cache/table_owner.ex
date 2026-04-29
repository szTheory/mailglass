defmodule Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner do
  @moduledoc """
  Owns the Mailgun replay cache ETS table.
  """
  use GenServer

  @table :mailglass_webhook_mailgun_replay_cache

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) when is_list(opts) do
    {name, _init_opts} = Keyword.pop(opts, :name)
    start_opts = if is_nil(name), do: [], else: [name: name]
    GenServer.start_link(__MODULE__, :ok, start_opts)
  end

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

  @doc since: "0.2.1"
  @spec table() :: atom()
  def table, do: @table
end
