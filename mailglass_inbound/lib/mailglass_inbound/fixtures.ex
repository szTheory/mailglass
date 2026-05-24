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
  alias MailglassInbound.S3Fetcher
  alias Mailglass.Webhook.Providers.SES.CertCache

  @default_tenant_id "fixture-tenant"
  @default_from "sender@example.com"
  @default_to "support@example.com"
  @default_subject "Inbound fixture"
  @default_text_body "Hello from a code-built fixture.\r\n"

  # SES SNS fixture defaults.
  @ses_bucket "fixture-inbound-bucket"
  @ses_cert_host "https://sns.us-east-1.amazonaws.com"
  @ses_topic_arn "arn:aws:sns:us-east-1:123456789012:fixture-topic"
  @ses_cert_ttl_seconds 86_400

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
  # SES — X.509-signed SNS notification (real CertCache priming)
  # --------------------------------------------------------------------------

  @doc """
  Builds a valid X.509-signed SES SNS `Notification` payload entirely from code.

  Mints a fresh in-memory RSA-2048 keypair, builds an SNS `Notification`
  envelope carrying an `Action:S3` receipt, computes the byte-sorted canonical
  string, signs it with `:public_key.sign(canonical, :sha, private_key)`, and
  `Jason.encode!`s the result. The builder then primes:

  - the **real** `Mailglass.Webhook.Providers.SES.CertCache` so the real
    `SES.verify!` is a cache hit (no `:httpc` fetch), and
  - the `MailglassInbound.S3Fetcher.Fake` so the `Action:S3` body path resolves
    to the fixture's raw MIME.

  The keypair is ephemeral, in-memory, and per call — nothing is written to
  disk (D-47-10, security V6). The `SigningCertURL` carries a per-call unique
  suffix so concurrent fixtures priming the shared `:public` cert cache never
  collide (Pitfall 2); the host still satisfies the SNS cert-host TrustPolicy.

  > #### Cross-test hygiene: reset the cert cache {: .warning}
  >
  > This builder primes the **process-global** ETS cert cache
  > (`Mailglass.Webhook.Providers.SES.CertCache`, shared across concurrent async
  > tests). Each call inserts one entry under a unique cert URL with a 24h TTL
  > that is never evicted within a run. If you build SES fixtures from a plain
  > `ExUnit.Case` (without `MailglassInbound.MailboxCase`), reset the cache
  > between tests so entries do not accumulate or bleed across cases:
  >
  >     setup do: Mailglass.Webhook.Providers.SES.CertCache.reset()
  >
  > `MailglassInbound.MailboxCase` already does this in its `setup`, so suites
  > that `use` it need no extra step.

  Returns a map with:

  - `:raw_body` — the JSON SNS envelope (feed to `SES.verify!/2` then `SES.normalize/1`).
  - `:headers` — the request header list.
  - `:config` — `%{s3_fetcher: S3Fetcher.Fake, cert_cache_ttl_seconds: 86_400}`
    (the SES config seam).

  ## Options

  - `:tenant_id` (carried for API symmetry), `:subject`, `:from`, `:recipient`,
    `:text_body`, `:provider_message_id`
  """
  @spec build_ses_sns_payload(keyword()) :: %{
          raw_body: binary(),
          headers: [{String.t(), String.t()}],
          config: map()
        }
  def build_ses_sns_payload(opts \\ []) do
    from = Keyword.get(opts, :from, @default_from)
    recipient = Keyword.get(opts, :recipient, @default_to)
    subject = Keyword.get(opts, :subject, @default_subject)
    text_body = Keyword.get(opts, :text_body, @default_text_body)
    ses_message_id = Keyword.get(opts, :provider_message_id, generate_id("ses"))

    raw_mime =
      [
        "Message-ID: <#{ses_message_id}@example.com>",
        "From: #{from}",
        "To: #{recipient}",
        "Subject: #{subject}",
        "Content-Type: text/plain",
        "",
        text_body
      ]
      |> Enum.join("\r\n")

    {public_key, private_key} = generate_sns_keypair()
    cert_url = unique_cert_url()

    # Prime the REAL ETS cert cache so SES.verify! is a cache hit (D-47-10).
    future = DateTime.add(DateTime.utc_now(), @ses_cert_ttl_seconds, :second)
    CertCache.put(cert_url, public_key, future)

    # Prime the fake fetcher for the Action:S3 body path.
    S3Fetcher.Fake.put(@ses_bucket, ses_message_id, raw_mime)

    inner =
      Jason.encode!(%{
        "notificationType" => "Received",
        "mail" => %{"messageId" => ses_message_id, "source" => from},
        "receipt" => %{
          "action" => %{
            "type" => "S3",
            "bucketName" => @ses_bucket,
            "objectKey" => ses_message_id
          }
        }
      })

    raw_body = sign_notification(private_key, cert_url, "sns-#{ses_message_id}", subject, inner)

    %{
      raw_body: raw_body,
      headers: [{"content-type", "text/plain"}],
      config: %{s3_fetcher: S3Fetcher.Fake, cert_cache_ttl_seconds: @ses_cert_ttl_seconds}
    }
  end

  # --------------------------------------------------------------------------
  # SES SNS signing helpers (extracted verbatim from ses_provider_test.exs)
  # --------------------------------------------------------------------------

  # Source: ses_provider_test.exs:287-301 — SNS Notification envelope + sign.
  defp sign_notification(private_key, cert_url, sns_message_id, subject, inner_message) do
    payload = %{
      "Type" => "Notification",
      "MessageId" => sns_message_id,
      "Subject" => subject,
      "TopicArn" => @ses_topic_arn,
      "Message" => inner_message,
      "Timestamp" => DateTime.to_iso8601(DateTime.utc_now()),
      "SignatureVersion" => "1",
      "SigningCertURL" => cert_url
    }

    canonical = canonical_string(payload)
    sig = sign_canonical(canonical, private_key)
    payload |> Map.put("Signature", sig) |> Jason.encode!()
  end

  # Source: ses_provider_test.exs:330-334 — byte-sorted canonical string for a
  # Notification (matches core build_canonical_string/2).
  defp canonical_string(payload) do
    ~w(Message MessageId Subject Timestamp TopicArn Type)
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  # Source: ses_provider_test.exs:343-345.
  defp sign_canonical(canonical, private_key) do
    :public_key.sign(canonical, :sha, private_key) |> Base.encode64()
  end

  # Source: ses_provider_test.exs:347-352 — OTP 27 RSAPrivateKey: index 2 =
  # modulus, index 3 = public exponent; emit an {:RSAPublicKey, n, e} record.
  defp generate_sns_keypair do
    private_key = :public_key.generate_key({:rsa, 2048, 65537})
    n = elem(private_key, 2)
    e = elem(private_key, 3)
    {{:RSAPublicKey, n, e}, private_key}
  end

  # Per-call unique cert URL. The host stays inside the SNS cert-host TrustPolicy
  # (`sns.<region>.amazonaws.com`) and the path ends in `.pem`; only the filename
  # suffix varies so concurrent primes of the shared `:public` cache never
  # collide (Pitfall 2, T-47-03).
  defp unique_cert_url do
    suffix = :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
    "#{@ses_cert_host}/SimpleNotificationService-#{suffix}.pem"
  end

  # --------------------------------------------------------------------------
  # Internal helpers
  # --------------------------------------------------------------------------

  # Per-call unique id so concurrent fixtures never collide on dedupe keys.
  defp generate_id(prefix) do
    "#{prefix}-" <> (:crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false))
  end
end
