defmodule MailglassInbound.InboundMessage do
  @moduledoc since: "0.1.0"
  @moduledoc """
  Canonical normalized inbound message passed to routing and mailbox code.

  `MailglassInbound.InboundMessage` is the stable adopter-facing contract for
  the first inbound package slice. It models the normalized fields Mailglass
  can promise across first-party ingress providers while keeping raw payloads,
  signature evidence, replay metadata, and mailbox execution state out of the
  public struct.

  ## Stable Fields

  - `:tenant_id` - explicit tenant scope for routing and execution.
  - `:provider` - first-party ingress provider name.
  - `:provider_message_id` - provider-specific message reference when present.
  - `:message_id` - RFC `Message-ID` header value when present.
  - `:envelope_recipient` - SMTP/envelope recipient used for routing.
  - `:from`, `:to`, `:cc`, `:bcc`, `:reply_to` - normalized address data.
  - `:subject` - normalized message subject.
  - `:headers` - normalized header map for routing and mailbox reads.
  - `:sent_at`, `:received_at` - normalized timestamps.
  - `:text_body`, `:html_body` - normalized body fields.
  - `:attachments` - normalized attachment manifest without attachment bytes.
  - `:signals` - framework-derived, read-only signals about the message; a typed
    `MailglassInbound.InboundMessage.Signals` struct (framework writes, adopter
    reads). See `MailglassInbound.InboundMessage.Signals`.

  ## Reading framework signals

  The `:signals` field exposes framework-derived facts, today the
  `suppression_flagged` boolean. Read it via safe dot-access or pattern-match it
  in a mailbox `process/1` head:

      def process(%MailglassInbound.InboundMessage{
            signals: %MailglassInbound.InboundMessage.Signals{suppression_flagged: true}
          }), do: {:reject, :sender_suppressed}

      def process(%MailglassInbound.InboundMessage{} = message) do
        if MailglassInbound.InboundMessage.suppression_flagged?(message),
          do: ...,
          else: :accept
      end

  > **Deviation:** the spec's literal wording exposes the flag at
  > `%InboundMessage{}.metadata.suppression_flagged`. Mailglass instead ships
  > `%InboundMessage{}.signals.suppression_flagged` as a deliberate, documented
  > improvement (the erratum precedent): `:metadata` is reserved
  > framework-wide for adopter-owned data, so framework-derived facts live on the
  > distinct, framework-owned `:signals` typed struct.
  """

  alias MailglassInbound.InboundMessage.Signals

  @type provider :: :postmark | :sendgrid | :mailgun | :ses | String.t()

  @type address :: %{
          required(:address) => String.t(),
          optional(:name) => String.t() | nil
        }

  @type attachment :: %{
          optional(:filename) => String.t() | nil,
          optional(:content_type) => String.t() | nil,
          optional(:disposition) => :attachment | :inline | String.t() | nil,
          optional(:content_id) => String.t() | nil
        }

  @type t :: %__MODULE__{
          tenant_id: String.t() | nil,
          provider: provider() | nil,
          provider_message_id: String.t() | nil,
          message_id: String.t() | nil,
          envelope_recipient: String.t() | nil,
          from: [address()],
          to: [address()],
          cc: [address()],
          bcc: [address()],
          reply_to: [address()],
          subject: String.t() | nil,
          headers: %{optional(String.t()) => [String.t()]},
          sent_at: DateTime.t() | nil,
          received_at: DateTime.t() | nil,
          text_body: String.t() | nil,
          html_body: String.t() | nil,
          attachments: [attachment()],
          signals: Signals.t()
        }

  defstruct [
    :tenant_id,
    :provider,
    :provider_message_id,
    :message_id,
    :envelope_recipient,
    :subject,
    :sent_at,
    :received_at,
    :text_body,
    :html_body,
    from: [],
    to: [],
    cc: [],
    bcc: [],
    reply_to: [],
    headers: %{},
    attachments: [],
    signals: %Signals{}
  ]

  @doc """
  Returns the message's `suppression_flagged` signal.

  `true` when the message's first `from` address was on the tenant's suppression
  list at receipt time. This is the one convenience predicate over the `:signals`
  struct; read other signals via dot-access or pattern-matching. Safe on any
  `%InboundMessage{}` — the `:signals` default guarantees no `KeyError`.
  """
  @doc since: "0.2.0"
  @spec suppression_flagged?(t()) :: boolean()
  def suppression_flagged?(%__MODULE__{signals: %Signals{suppression_flagged: flagged}}),
    do: flagged
end
