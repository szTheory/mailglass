defmodule MailglassInbound.Mailbox do
  @moduledoc since: "0.1.0"
  @moduledoc """
  Behaviour for adopter-defined inbound mailboxes.

  this milestone phase locks the public mailbox contract to one callback:
  `process/1`. The callback receives the stable
  `%MailglassInbound.InboundMessage{}` value object and must return one of the
  approved outcomes:

  - `:accept`
  - `:ignore`
  - `{:reject, reason}`
  - `{:bounce, reason}`

  Raises, throws, and exits are execution failures handled by internal runners.
  They are not semantic mailbox outcomes.
  """

  alias MailglassInbound.InboundMessage

  @type outcome_reason :: term()
  @type outcome :: :accept | :ignore | {:reject, outcome_reason()} | {:bounce, outcome_reason()}

  @doc since: "0.1.0"
  @callback process(InboundMessage.t()) :: outcome()

  @spec valid_outcome?(term()) :: boolean()
  def valid_outcome?(:accept), do: true
  def valid_outcome?(:ignore), do: true
  def valid_outcome?({:reject, _reason}), do: true
  def valid_outcome?({:bounce, _reason}), do: true
  def valid_outcome?(_outcome), do: false
end
