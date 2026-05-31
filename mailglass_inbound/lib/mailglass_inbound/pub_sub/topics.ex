defmodule MailglassInbound.PubSub.Topics do
  @moduledoc since: "0.2.0"
  @moduledoc """
  Typed topic builder for `mailglass_inbound` PubSub broadcasts (TELE-07, the design contract).

  Mirrors `Mailglass.PubSub.Topics` in the core library: every topic is prefixed
  `mailglass:` so this milestone phase `LINT-06 PrefixedPubSubTopics` enforces the namespace at
  lint time. Broadcasts always go through this builder (never a literal topic
  string at the call site) — that is what keeps `PrefixedPubSubTopics`, which only
  flags literal string arguments, satisfied while still routing every inbound
  fan-out through one auditable surface.

  ## Topics emitted

  - `inbound_record_inserted/1` — `"mailglass:inbound:\#{tenant_id}"` — the
    per-tenant stream that fires once after an `InboundRecord` is committed
    (status `:inserted`). The this milestone phase admin LiveView subscribes here on
    `Mailglass.PubSub` so it can render new inbound mail in real time without an
    inbound→admin compile dependency. The topic carries `tenant_id` so a
    subscriber only ever sees its own tenant's records.

  Payloads broadcast on this topic are PII-free by contract (record id +
  provider + record_type only) — see `MailglassInbound.Ingress.Plug`.
  """

  @doc """
  Returns the per-tenant inbound record-inserted stream topic.

  The this milestone phase admin LiveView subscribes to this topic on `Mailglass.PubSub`.
  The `tenant_id` is embedded so subscribers are scoped to a single tenant.
  """
  @doc since: "0.2.0"
  @spec inbound_record_inserted(String.t()) :: String.t()
  def inbound_record_inserted(tenant_id) when is_binary(tenant_id),
    do: "mailglass:inbound:" <> tenant_id
end
