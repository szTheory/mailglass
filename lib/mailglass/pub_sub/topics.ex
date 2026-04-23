defmodule Mailglass.PubSub.Topics do
  @moduledoc """
  Typed topic builder for `Mailglass.PubSub` (SEND-05, D-27). Every topic
  is prefixed `mailglass:` — Phase 6 `LINT-06 PrefixedPubSubTopics`
  enforces the prefix at lint time.

  ## Topics emitted

  - `events/1` — `"mailglass:events:\#{tenant_id}"` — tenant-wide event stream
  - `events/2` — `"mailglass:events:\#{tenant_id}:\#{delivery_id}"` — per-delivery
  - `deliveries/1` — `"mailglass:deliveries:\#{tenant_id}"` — delivery-list stream

  Projector broadcasts on BOTH `events/1` and `events/2` after every
  successful projection update (D-04).
  """

  @doc "Returns the tenant-wide event stream topic."
  @doc since: "0.1.0"
  @spec events(String.t()) :: String.t()
  def events(tenant_id) when is_binary(tenant_id),
    do: "mailglass:events:" <> tenant_id

  @doc "Returns the per-delivery event stream topic."
  @doc since: "0.1.0"
  @spec events(String.t(), binary()) :: String.t()
  def events(tenant_id, delivery_id)
      when is_binary(tenant_id) and is_binary(delivery_id),
    do: "mailglass:events:" <> tenant_id <> ":" <> delivery_id

  @doc "Returns the delivery-list stream topic for the given tenant."
  @doc since: "0.1.0"
  @spec deliveries(String.t()) :: String.t()
  def deliveries(tenant_id) when is_binary(tenant_id),
    do: "mailglass:deliveries:" <> tenant_id
end
