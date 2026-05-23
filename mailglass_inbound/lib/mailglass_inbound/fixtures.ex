defmodule MailglassInbound.Fixtures do
  @moduledoc """
  Code-built inbound payload fixtures for adopter tests (ITEST-07).

  `MailglassInbound.Fixtures` builds a canonical `%MailglassInbound.InboundMessage{}`
  and raw provider payloads — Postmark JSON, SendGrid form-encoded MIME, Mailgun
  multipart params, and a valid X.509-signed SES SNS notification — **entirely
  from code**. Each provider payload is shaped so it round-trips through the real
  provider `verify!`/`normalize` seam to a valid `%InboundMessage{}`, which makes
  the fixtures faithful to production parsing rather than to a hand-written stub.

  This module belongs to the **Testing** surface and ships in `lib/` so adopters
  can build inbound messages from their own test suites with a single call. It
  references only core/runtime modules (`Jason`, `:public_key`, the inbound
  providers, and the SES `CertCache` / `S3Fetcher.Fake` seams) so it compiles
  under `mix compile --no-optional-deps --warnings-as-errors` — never `Oban`,
  `ExAws`, or `Plug.Test`.

  ## Locked posture

  - **Code-built only.** No `.eml` file and no `.pem` key/cert is ever written to
    disk or committed (D-47-10, D-47-11; security V6/V7).
  - **No real-PII sample data.** Defaults use `.test` / `example.com` addresses.
  - **Defaulted `tenant_id`.** Every builder defaults a `tenant_id` so a test
    cannot accidentally assert across tenants (security V4, T-47-04).
  - **Ephemeral SES keypair.** `build_ses_sns_payload/1` mints a fresh in-memory
    RSA-2048 keypair per call; it primes the real `CertCache` so the signed SNS
    notification verifies through the real `SES.verify!` with no network fetch.

  ## Examples

      # A canonical message, ready for `MailglassInbound.Test.Ingress`:
      message = MailglassInbound.Fixtures.build_inbound_message(subject: "Hello")

      # A raw Postmark body that the real Postmark provider normalizes:
      raw = MailglassInbound.Fixtures.build_postmark_payload(subject: "Hello")
      %{message: %MailglassInbound.InboundMessage{}} =
        MailglassInbound.Ingress.Providers.Postmark.normalize(raw, [])
  """

  alias MailglassInbound.InboundMessage

  @default_tenant_id "fixture-tenant"
  @default_from "sender@example.com"
  @default_to "support@example.com"
  @default_subject "Inbound fixture"
  @default_text_body "Hello from a code-built fixture.\r\n"

  # --------------------------------------------------------------------------
  # Canonical %InboundMessage{}
  # --------------------------------------------------------------------------

  @doc """
  Builds a canonical `%MailglassInbound.InboundMessage{}` entirely from code.

  Mirrors the canonical builder shape used across the inbound suite (address
  shape `%{address: ...}`, defaulted list fields). A `tenant_id` is always
  defaulted.

  ## Options

  - `:tenant_id` (default `"fixture-tenant"`)
  - `:provider` (default `:postmark`)
  - `:provider_message_id` (default a generated id)
  - `:message_id` (default mirrors `:provider_message_id`)
  - `:from` / `:to` — bare address strings (default fixture addresses)
  - `:subject`, `:text_body`, `:html_body`, `:envelope_recipient`
  """
  @spec build_inbound_message(keyword()) :: InboundMessage.t()
  def build_inbound_message(opts \\ []) do
    provider_message_id = Keyword.get(opts, :provider_message_id, generate_id("msg"))
    from = Keyword.get(opts, :from, @default_from)
    to = Keyword.get(opts, :to, @default_to)

    %InboundMessage{
      tenant_id: Keyword.get(opts, :tenant_id, @default_tenant_id),
      provider: Keyword.get(opts, :provider, :postmark),
      provider_message_id: provider_message_id,
      message_id: Keyword.get(opts, :message_id, provider_message_id),
      envelope_recipient: Keyword.get(opts, :envelope_recipient, to),
      from: [%{address: from}],
      to: [%{address: to}],
      subject: Keyword.get(opts, :subject, @default_subject),
      headers: %{},
      received_at: DateTime.utc_now(),
      text_body: Keyword.get(opts, :text_body, @default_text_body),
      html_body: Keyword.get(opts, :html_body)
    }
  end

  # --------------------------------------------------------------------------
  # Postmark — JSON body
  # --------------------------------------------------------------------------

  @doc """
  Builds a raw Postmark inbound JSON body (a binary, ready for
  `Postmark.normalize/2`).

  ## Options

  - `:tenant_id` (carried for API symmetry; Postmark normalize ignores it)
  - `:provider_message_id` / `:subject` / `:from` / `:recipient` / `:text_body`
  """
  @spec build_postmark_payload(keyword()) :: binary()
  def build_postmark_payload(opts \\ []) do
    message_id = Keyword.get(opts, :provider_message_id, generate_id("postmark"))
    from = Keyword.get(opts, :from, @default_from)
    recipient = Keyword.get(opts, :recipient, @default_to)
    subject = Keyword.get(opts, :subject, @default_subject)

    Jason.encode!(%{
      "MessageID" => message_id,
      "OriginalRecipient" => recipient,
      "Subject" => subject,
      "FromFull" => [%{"Email" => from, "Name" => "Fixture Sender"}],
      "ToFull" => [%{"Email" => recipient, "Name" => "Fixture Recipient"}],
      "Headers" => [
        %{"Name" => "Message-ID", "Value" => "<#{message_id}@example.com>"},
        %{"Name" => "Subject", "Value" => subject}
      ],
      "TextBody" => Keyword.get(opts, :text_body, @default_text_body),
      "HtmlBody" => Keyword.get(opts, :html_body),
      "Attachments" => []
    })
  end

  # --------------------------------------------------------------------------
  # SendGrid — form-encoded raw MIME
  # --------------------------------------------------------------------------

  @doc """
  Builds a SendGrid inbound payload.

  Returns a map with:

  - `:raw_mime` — the raw MIME the SendGrid provider parses (also the dedupe key
    `md5(raw_mime)` when `provider_message_id` is nil; expose it via
    `evidence: %{raw_mime: ...}` so replays are detected — Pitfall 5).
  - `:headers` — the request header list.
  - `:params` — the form params (carries `"envelope"` so the provider resolves
    `envelope_recipient`).

  ## Options

  - `:tenant_id`, `:subject`, `:from`, `:recipient`, `:text_body`
  """
  @spec build_sendgrid_payload(keyword()) :: %{
          raw_mime: binary(),
          headers: [{String.t(), String.t()}],
          params: map()
        }
  def build_sendgrid_payload(opts \\ []) do
    from = Keyword.get(opts, :from, @default_from)
    recipient = Keyword.get(opts, :recipient, @default_to)
    subject = Keyword.get(opts, :subject, @default_subject)
    text_body = Keyword.get(opts, :text_body, @default_text_body)
    message_id = Keyword.get(opts, :provider_message_id, generate_id("sendgrid"))

    raw_mime =
      [
        "Message-ID: <#{message_id}@example.com>",
        "From: #{from}",
        "To: #{recipient}",
        "Subject: #{subject}",
        "Content-Type: text/plain",
        "",
        text_body
      ]
      |> Enum.join("\r\n")

    %{
      raw_mime: raw_mime,
      headers: [{"content-type", "multipart/form-data"}],
      params: %{"envelope" => Jason.encode!(%{"to" => [recipient], "from" => from})}
    }
  end

  # --------------------------------------------------------------------------
  # Mailgun — parsed multipart params
  # --------------------------------------------------------------------------

  @doc """
  Builds a Mailgun inbound payload (parsed mode).

  Returns a map with `:params` (the flat form fields the Mailgun provider
  normalizes) and `:headers` (the request header list). `message-headers`
  carries the RFC `Message-Id` Mailgun has no flat field for (D-46-10).

  ## Options

  - `:tenant_id`, `:subject`, `:from`, `:recipient`, `:text_body`
  """
  @spec build_mailgun_payload(keyword()) :: %{
          params: map(),
          headers: [{String.t(), String.t()}]
        }
  def build_mailgun_payload(opts \\ []) do
    from = Keyword.get(opts, :from, @default_from)
    recipient = Keyword.get(opts, :recipient, @default_to)
    subject = Keyword.get(opts, :subject, @default_subject)
    text_body = Keyword.get(opts, :text_body, @default_text_body)
    message_id = Keyword.get(opts, :provider_message_id, generate_id("mailgun"))

    message_headers =
      Jason.encode!([
        ["Message-Id", "<#{message_id}@example.com>"],
        ["Subject", subject],
        ["From", from],
        ["To", recipient]
      ])

    %{
      headers: [{"content-type", "multipart/form-data"}],
      params: %{
        "recipient" => recipient,
        "sender" => from,
        "from" => from,
        "to" => recipient,
        "subject" => subject,
        "body-plain" => text_body,
        "message-headers" => message_headers,
        "attachment-count" => "0"
      }
    }
  end

  # --------------------------------------------------------------------------
  # Internal helpers
  # --------------------------------------------------------------------------

  # Per-call unique id so concurrent fixtures never collide on dedupe keys.
  defp generate_id(prefix) do
    "#{prefix}-" <> (:crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false))
  end
end
