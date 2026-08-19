defmodule Mailglass.PubSub do
  @moduledoc """
  Name atom for the mailglass-owned Phoenix.PubSub child.

  The `Mailglass.Application` supervision tree starts
  `{Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2}`.
  Projector broadcasts, admin LiveView subscriptions, and TestAssertions'
  PubSub-backed matchers all target this name.

  ## Topics

  See `Mailglass.PubSub.Topics` — a typed builder producing
  `mailglass:`-prefixed binaries.  `PrefixedPubSubTopics`
  enforces the prefix at lint time.
  """

  @doc false
  @spec safe_broadcast(String.t(), term()) :: :ok
  def safe_broadcast(topic, payload) when is_binary(topic) do
    case Phoenix.PubSub.broadcast(__MODULE__, topic, payload) do
      :ok ->
        :ok

      {:error, reason} ->
        log_failure("returned an error", reason)
        :ok
    end
  rescue
    e in [ArgumentError, RuntimeError] ->
      log_failure("failed", Exception.message(e))
      :ok
  catch
    :exit, reason ->
      log_failure("exited", reason)
      :ok
  end

  defp log_failure(outcome, reason) do
    require Logger
    Logger.debug("[mailglass] PubSub broadcast #{outcome} (non-fatal): #{inspect(reason)}")
  end
end
