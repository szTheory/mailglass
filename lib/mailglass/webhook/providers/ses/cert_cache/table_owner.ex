defmodule Mailglass.Webhook.Providers.SES.CertCache.TableOwner do
  @moduledoc """
  Owns the SES SNS certificate cache ETS table.

  Creates and holds the `:mailglass_webhook_ses_cert_cache` ETS table.
  The table uses `:public` visibility so `Mailglass.Webhook.Providers.SES.CertCache`
  can read and write directly without GenServer message-passing overhead.
  """
  use GenServer

  @table :mailglass_webhook_ses_cert_cache

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

  @doc since: "0.3.0"
  @spec table() :: :mailglass_webhook_ses_cert_cache
  def table, do: @table
end
