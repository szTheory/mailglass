defmodule MailglassInbound.Ingress.SesProviderTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.{S3FetchError, S3Fetcher, SignatureError}
  alias MailglassInbound.Ingress.Providers.SES
  alias MailglassInbound.Ingress.{Request, VerifiedRequest}
  alias Mailglass.Webhook.Providers.SES.CertCache

  # SES inbound provider tests. Envelopes are CODE-BUILT (no .eml): each test
  # mints a fresh RSA keypair, signs the canonical SNS string, primes the (core,
  # process-global) CertCache, and drives the inbound SES provider. The S3 body
  # is served by the fake-first S3Fetcher.Fake via the config-resolution seam.

  @cert_url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem"
  @subscribe_url "https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&TopicArn=arn%3Aaws%3Asns%3Aus-east-1%3A123%3At&Token=tok"
  @bucket "inbound-bucket"

  @raw_mime "From: sender@example.com\r\n" <>
              "To: support@example.com\r\n" <>
              "Subject: Inbound via SES\r\n" <>
              "Message-ID: <ses-inbound@example.com>\r\n" <>
              "Date: Tue, 01 Apr 2026 12:00:00 +0000\r\n" <>
              "Content-Type: text/plain\r\n\r\n" <>
              "Hello from S3\r\n"

  setup do
    CertCache.reset()
    S3Fetcher.Fake.reset()
    {public_key, private_key} = generate_sns_keypair()
    future = DateTime.add(DateTime.utc_now(), 86_400, :second)
    CertCache.put(@cert_url, public_key, future)
    %{private_key: private_key}
  end

  # ---- behaviors -------------------------------------------------------

  test "authenticated SES values retain exact signed bytes and resolve MIME once", %{
    private_key: pk
  } do
    S3Fetcher.Fake.put(@bucket, "ses-msg-1", @raw_mime)
    raw = signed_s3_notification(pk, "ses-msg-1")
    request = ses_request(raw)

    assert {:ok, %VerifiedRequest{} = verified} = SES.verify!(request, ses_config())
    assert verified.raw_body == raw
    assert verified.verification_facts == %{auth: :sns_x509}
    assert S3Fetcher.Fake.call_count(@bucket, "ses-msg-1") == 0

    verified = SES.resolve_content!(verified, ses_config())
    %{message: message, evidence: evidence} = SES.normalize(verified)
    assert message.provider_message_id == "ses-msg-1"
    assert evidence.raw_mime == @raw_mime
    assert message.subject == "Inbound via SES"
    assert S3Fetcher.Fake.call_count(@bucket, "ses-msg-1") == 1
  end

  test "forged SNS signature raises MailglassInbound.SignatureError :bad_signature" do
    {_pub, other_private} = generate_sns_keypair()
    raw = signed_s3_notification(other_private, "ses-msg-1")
    request = ses_request(raw)

    err = assert_raise SignatureError, fn -> SES.verify!(request, ses_config()) end
    assert err.type == :bad_signature
    assert err.provider == :ses
  end

  test "SigningCertURL failing TrustPolicy raises :bad_signature (SSRF guard)", %{private_key: pk} do
    raw =
      pk
      |> signed_s3_notification("ses-msg-1")
      |> Jason.decode!()
      |> Map.put("SigningCertURL", "https://sns.s3-us-west-2.amazonaws.com/evil.pem")
      |> Jason.encode!()

    err = assert_raise SignatureError, fn -> SES.verify!(ses_request(raw), ses_config()) end
    assert err.type == :bad_signature
  end

  test "SubscriptionConfirmation with a valid SubscribeURL returns {:control_plane, 200}", %{
    private_key: pk
  } do
    raw = signed_subscription_confirmation(pk, @subscribe_url)

    assert {:control_plane, 200} = SES.verify!(ses_request(raw), ses_config())
  end

  test "SubscriptionConfirmation with a hijacked SubscribeURL raises :subscribe_url_untrusted", %{
    private_key: pk
  } do
    hijacked = "https://evil.example.com/?Action=ConfirmSubscription&Token=tok"
    raw = signed_subscription_confirmation(pk, hijacked)

    err = assert_raise SignatureError, fn -> SES.verify!(ses_request(raw), ses_config()) end
    assert err.type == :subscribe_url_untrusted
    assert err.provider == :ses
  end

  test "UnsubscribeConfirmation returns {:control_plane, 200}", %{private_key: pk} do
    raw = signed_unsubscribe_confirmation(pk, @subscribe_url)

    assert {:control_plane, 200} = SES.verify!(ses_request(raw), ses_config())
  end

  test "SNS-inline content path decodes and MIME-parses (no S3 action)", %{private_key: pk} do
    raw = signed_inline_notification(pk, "ses-inline-1", @raw_mime)
    request = ses_request(raw)

    verified = verified_request!(request)

    %{message: message, evidence: evidence} = SES.normalize(verified)
    assert message.provider_message_id == "ses-inline-1"
    assert evidence.raw_mime == @raw_mime
  end

  test "SNS-inline base64 content path decodes and MIME-parses", %{private_key: pk} do
    encoded = Base.encode64(@raw_mime)
    raw = signed_inline_notification(pk, "ses-inline-b64", encoded)
    request = ses_request(raw)

    %{evidence: evidence} = request |> verified_request!() |> SES.normalize()
    assert evidence.raw_mime == @raw_mime
  end

  # WR-05: the base64 branch is an ambiguous heuristic, so taking it must be
  # auditable via a parse_warning.
  test "SNS-inline base64 decode records a parse_warning so the ambiguity is auditable", %{
    private_key: pk
  } do
    encoded = Base.encode64(@raw_mime)
    raw = signed_inline_notification(pk, "ses-inline-b64-warn", encoded)
    request = ses_request(raw)

    %{evidence: evidence} = request |> verified_request!() |> SES.normalize()

    assert evidence.parse_warnings[:inline_content_base64_decoded] == true
  end

  # WR-05: terse content that happens to be valid base64 but whose decoded form
  # is NOT a MIME header block must be kept as raw content (not mis-decoded), and
  # no base64 warning is recorded.
  test "SNS-inline content that is valid base64 but not MIME stays raw (tightened heuristic)", %{
    private_key: pk
  } do
    # "From: x@example.com..." base64-decodes to bytes that do NOT start with an
    # RFC-5322 header line, so the tightened looks_like_mime?/1 rejects the
    # decode and the content is treated as raw MIME.
    not_mime_but_base64 = Base.encode64("not a header block, just prose with a : colon inside")
    raw = signed_inline_notification(pk, "ses-inline-raw", not_mime_but_base64)
    request = ses_request(raw)

    %{evidence: evidence} = request |> verified_request!() |> SES.normalize()

    # Kept as raw content (the base64 form), NOT silently decoded.
    assert evidence.raw_mime == not_mime_but_base64
    refute Map.has_key?(evidence.parse_warnings, :inline_content_base64_decoded)
  end

  test "S3 fetch failing the first N calls retries then surfaces, no record on exhaustion", %{
    private_key: pk
  } do
    # Always not-ready -> bounded retry exhausts -> S3FetchError, provider surfaces it.
    S3Fetcher.Fake.put_error_then_ok(@bucket, "ses-retry", 99, "never")
    raw = signed_s3_notification(pk, "ses-retry")
    request = ses_request(raw)

    err = assert_raise S3FetchError, fn -> request |> verified_request!() end
    assert err.type == :s3_object_not_ready
  end

  test "normalize builds evidence with raw_payload=SNS envelope and raw_mime=fetched body", %{
    private_key: pk
  } do
    S3Fetcher.Fake.put(@bucket, "ses-ev", @raw_mime)
    raw = signed_s3_notification(pk, "ses-ev")
    request = ses_request(raw)

    %{message: message, evidence: evidence} = request |> verified_request!() |> SES.normalize()

    assert message.provider == :ses
    assert message.message_id == "<ses-inbound@example.com>"
    assert evidence.raw_payload["Type"] == "Notification"
    assert evidence.raw_mime == @raw_mime
    assert evidence.verification_facts == %{}
    refute Map.has_key?(message, :raw_mime)
  end

  # WR-02: SES dedupes primarily on mail.messageId. When the inner JSON omits it
  # (inline-content / degraded payloads), normalize/1 must flag the missing
  # primary anchor so the weaker MD5(raw_mime) fallback path is auditable.
  test "normalize records :missing_provider_message_id when mail.messageId is absent", %{
    private_key: pk
  } do
    raw = signed_inline_notification_without_message_id(pk, @raw_mime)
    request = ses_request(raw)

    %{message: message, evidence: evidence} = request |> verified_request!() |> SES.normalize()

    assert message.provider_message_id == nil
    assert evidence.parse_warnings[:missing_provider_message_id] == true
  end

  test "verification ignores stale ambient values and normalization does not refetch", %{
    private_key: pk
  } do
    # A caller may have stale values in its process, but production flow never
    # reads them because the verified value owns all authenticated material.
    Process.put({SES, :verified}, {%{"Type" => "Notification"}, "STALE BODY FROM PRIOR REQUEST"})

    S3Fetcher.Fake.put(@bucket, "ses-fresh", @raw_mime)
    raw = signed_s3_notification(pk, "ses-fresh")
    request = ses_request(raw)

    %{evidence: evidence} = request |> verified_request!() |> SES.normalize()

    assert evidence.raw_mime == @raw_mime
    refute evidence.raw_mime == "STALE BODY FROM PRIOR REQUEST"
    assert S3Fetcher.Fake.call_count(@bucket, "ses-fresh") == 1
  end

  # ---- helpers ---------------------------------------------------------

  defp ses_config, do: %{s3_fetcher: S3Fetcher.Fake, cert_cache_ttl_seconds: 86_400}

  defp verified_request!(request) do
    {:ok, verified} = SES.verify!(request, ses_config())
    SES.resolve_content!(verified, ses_config())
  end

  defp ses_request(raw) do
    %Request{provider: :ses, raw_body: raw, headers: [{"content-type", "text/plain"}]}
  end

  # SES inbound "Received" notification with an S3 receipt action.
  defp signed_s3_notification(private_key, message_id) do
    inner =
      Jason.encode!(%{
        "notificationType" => "Received",
        "mail" => %{"messageId" => message_id, "source" => "sender@example.com"},
        "receipt" => %{
          "action" => %{"type" => "S3", "bucketName" => @bucket, "objectKey" => message_id}
        }
      })

    sign_notification(private_key, "sns-#{message_id}", inner)
  end

  # SES inbound "Received" notification carrying inline MIME `content`.
  defp signed_inline_notification(private_key, message_id, content) do
    inner =
      Jason.encode!(%{
        "notificationType" => "Received",
        "mail" => %{"messageId" => message_id, "source" => "sender@example.com"},
        "receipt" => %{"action" => %{"type" => "SNS"}},
        "content" => content
      })

    sign_notification(private_key, "sns-#{message_id}", inner)
  end

  # SES inbound "Received" inline notification whose inner JSON omits
  # mail.messageId (WR-02 path).
  defp signed_inline_notification_without_message_id(private_key, content) do
    inner =
      Jason.encode!(%{
        "notificationType" => "Received",
        "mail" => %{"source" => "sender@example.com"},
        "receipt" => %{"action" => %{"type" => "SNS"}},
        "content" => content
      })

    sign_notification(private_key, "sns-no-msg-id", inner)
  end

  defp sign_notification(private_key, sns_message_id, inner_message) do
    payload = %{
      "Type" => "Notification",
      "MessageId" => sns_message_id,
      "TopicArn" => "arn:aws:sns:us-east-1:123:t",
      "Message" => inner_message,
      "Timestamp" => "2026-04-01T12:00:00.000Z",
      "SignatureVersion" => "1",
      "SigningCertURL" => @cert_url
    }

    canonical = canonical_string(payload, "Notification")
    sig = sign_canonical(canonical, private_key)
    payload |> Map.put("Signature", sig) |> Jason.encode!()
  end

  defp signed_subscription_confirmation(private_key, subscribe_url) do
    signed_control(private_key, "SubscriptionConfirmation", subscribe_url)
  end

  defp signed_unsubscribe_confirmation(private_key, subscribe_url) do
    signed_control(private_key, "UnsubscribeConfirmation", subscribe_url)
  end

  defp signed_control(private_key, type, subscribe_url) do
    payload = %{
      "Type" => type,
      "MessageId" => "sns-ctrl-1",
      "Token" => "tok",
      "TopicArn" => "arn:aws:sns:us-east-1:123:t",
      "Message" => "control plane",
      "SubscribeURL" => subscribe_url,
      "Timestamp" => "2026-04-01T12:00:00.000Z",
      "SignatureVersion" => "1",
      "SigningCertURL" => @cert_url
    }

    canonical = canonical_string(payload, type)
    sig = sign_canonical(canonical, private_key)
    payload |> Map.put("Signature", sig) |> Jason.encode!()
  end

  # Byte-sorted SNS canonical string (matches core build_canonical_string/2).
  defp canonical_string(payload, "Notification") do
    ~w(Message MessageId Subject Timestamp TopicArn Type)
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  defp canonical_string(payload, type)
       when type in ["SubscriptionConfirmation", "UnsubscribeConfirmation"] do
    ~w(Message MessageId SubscribeURL Timestamp Token TopicArn Type)
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  defp sign_canonical(canonical, private_key) do
    :public_key.sign(canonical, :sha, private_key) |> Base.encode64()
  end

  defp generate_sns_keypair do
    private_key = :public_key.generate_key({:rsa, 2048, 65537})
    n = elem(private_key, 2)
    e = elem(private_key, 3)
    {{:RSAPublicKey, n, e}, private_key}
  end
end
