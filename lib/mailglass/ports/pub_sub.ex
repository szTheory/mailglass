defmodule Mailglass.Ports.PubSub do
  @moduledoc false

  @doc false
  @spec safe_broadcast(String.t(), term()) :: :ok
  defdelegate safe_broadcast(topic, payload), to: Mailglass.PubSub
end
