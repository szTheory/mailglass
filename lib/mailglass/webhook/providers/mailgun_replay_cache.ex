defmodule Mailglass.Webhook.Providers.MailgunReplayCache do
  @moduledoc """
  ETS-backed replay cache for Mailgun webhook tokens.
  """

  @table :mailglass_webhook_mailgun_replay_cache

  @spec check_and_put(binary(), DateTime.t()) :: :ok | {:error, :replay}
  def check_and_put(token, %DateTime{} = expires_at) when is_binary(token) do
    now = Mailglass.Clock.utc_now()

    case :ets.lookup(@table, token) do
      [{^token, %DateTime{} = existing_expires_at}] ->
        if DateTime.compare(existing_expires_at, now) == :lt do
          :ets.take(@table, token)

          if :ets.insert_new(@table, {token, expires_at}) do
            :ok
          else
            {:error, :replay}
          end
        else
          {:error, :replay}
        end

      _ ->
        if :ets.insert_new(@table, {token, expires_at}) do
          :ok
        else
          {:error, :replay}
        end
    end
  end

  @doc since: "0.2.1"
  @spec reset() :: :ok
  def reset do
    :ets.delete_all_objects(@table)
    :ok
  end

  @doc since: "0.2.1"
  @spec table() :: atom()
  def table, do: @table
end
