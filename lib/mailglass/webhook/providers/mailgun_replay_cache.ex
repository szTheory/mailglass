defmodule Mailglass.Webhook.Providers.MailgunReplayCache do
  @moduledoc """
  ETS-backed replay cache for Mailgun webhook tokens.
  """

  @table :mailglass_webhook_mailgun_replay_cache

  alias Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner

  @spec check_and_put(binary(), DateTime.t()) :: :ok | {:error, :replay}
  def check_and_put(token, %DateTime{} = expires_at) when is_binary(token) do
    TableOwner.check_and_put(token, expires_at)
  end

  @doc since: "0.2.1"
  @spec reset() :: :ok
  def reset do
    TableOwner.reset()
    :ok
  end

  @doc since: "0.2.1"
  @spec table() :: :mailglass_webhook_mailgun_replay_cache
  def table, do: @table
end
