defmodule MailglassInbound.InboundMessage do
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
  """

  @type provider :: :postmark | :sendgrid | String.t()

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
          attachments: [attachment()]
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
    attachments: []
  ]
end
