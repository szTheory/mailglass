defmodule MailglassInbound.Ingress.MailgunProviderTest do
  use ExUnit.Case, async: false

  alias Mailglass.ConfigError
  alias Mailglass.Webhook.Providers.MailgunReplayCache
  alias MailglassInbound.Ingress.Providers.Mailgun
  alias MailglassInbound.Ingress.Request
  alias MailglassInbound.SignatureError

  @signing_key "mailgun-test-signing-key"

  setup do
    # Reuse the RUNNING core MailgunReplayCache (booted by the :mailglass OTP
    # app via core's supervision tree, D-46-02). We do NOT start a second one —
    # we only reset the shared ETS table between runs so replayed-token tests
    # are deterministic.
    MailgunReplayCache.reset()
    on_exit(&MailgunReplayCache.reset/0)
    :ok
  end

  describe "verify!/2 — flat-field HMAC" do
    test "authentic flat-field signature returns {:ok, facts}" do
      request = mailgun_request()

      assert {:ok, facts} = Mailgun.verify!(request, %{signing_key: @signing_key})
      assert facts == %{auth: :hmac}
    end

    test "tampered signature raises SignatureError :bad_signature, provider :mailgun" do
      request = mailgun_request(signature: String.duplicate("0", 64))

      error =
        assert_raise SignatureError, fn ->
          Mailgun.verify!(request, %{signing_key: @signing_key})
        end

      assert error.type == :bad_signature
      assert error.provider == :mailgun
    end

    test "missing timestamp/token/signature form field raises SignatureError" do
      for field <- ["timestamp", "token", "signature"] do
        request = mailgun_request()
        params = Map.delete(request.params, field)
        request = %{request | params: params}

        error =
          assert_raise SignatureError, fn ->
            Mailgun.verify!(request, %{signing_key: @signing_key})
          end

        assert error.type in [:missing_header, :malformed_header]
        assert error.provider == :mailgun
      end
    end

    test "timestamp older than tolerance raises SignatureError :timestamp_skew" do
      stale_ts = Integer.to_string(System.os_time(:second) - 10_000)
      request = mailgun_request(timestamp: stale_ts)

      error =
        assert_raise SignatureError, fn ->
          Mailgun.verify!(request, %{signing_key: @signing_key})
        end

      assert error.type == :timestamp_skew
      assert error.provider == :mailgun
    end

    test "timestamp too far in the future raises SignatureError :timestamp_skew" do
      future_ts = Integer.to_string(System.os_time(:second) + 10_000)
      request = mailgun_request(timestamp: future_ts)

      error =
        assert_raise SignatureError, fn ->
          Mailgun.verify!(request, %{signing_key: @signing_key})
        end

      assert error.type == :timestamp_skew
      assert error.provider == :mailgun
    end

    test "missing signing_key config raises Mailglass.ConfigError" do
      request = mailgun_request()

      error =
        assert_raise ConfigError, fn ->
          Mailgun.verify!(request, %{})
        end

      assert error.type == :webhook_verification_key_missing
    end
  end

  describe "verify!/2 — replay no-op via the running MailgunReplayCache" do
    test "first call returns {:ok, facts}, second call (same token) returns {:replay}" do
      token = "replay-token-abc"
      request = mailgun_request(token: token)

      assert {:ok, %{auth: :hmac}} = Mailgun.verify!(request, %{signing_key: @signing_key})
      assert {:replay} = Mailgun.verify!(request, %{signing_key: @signing_key})
    end

    test "replay is a no-op return, never a raised SignatureError" do
      token = "replay-token-noraise"
      request = mailgun_request(token: token)

      assert {:ok, _} = Mailgun.verify!(request, %{signing_key: @signing_key})

      # The second (replayed) call must NOT raise — it returns {:replay}.
      assert {:replay} = Mailgun.verify!(request, %{signing_key: @signing_key})
    end
  end

  describe "extract_message_id/1" do
    test "finds Message-Id case-insensitively in a message-headers pairs list" do
      headers =
        Jason.encode!([
          ["From", "sender@example.com"],
          ["Message-Id", "<rfc-msg@example.com>"],
          ["Subject", "Hi"]
        ])

      assert Mailgun.extract_message_id(%{"message-headers" => headers}) ==
               "<rfc-msg@example.com>"
    end

    test "matches a lower-cased message-id header name" do
      headers = Jason.encode!([["message-id", "<lower@example.com>"]])

      assert Mailgun.extract_message_id(%{"message-headers" => headers}) ==
               "<lower@example.com>"
    end

    test "returns nil when no Message-Id is present" do
      headers = Jason.encode!([["From", "x@y.test"], ["Subject", "no id"]])

      assert Mailgun.extract_message_id(%{"message-headers" => headers}) == nil
    end

    test "returns nil when message-headers is absent or malformed" do
      assert Mailgun.extract_message_id(%{}) == nil
      assert Mailgun.extract_message_id(%{"message-headers" => "not-json"}) == nil
    end
  end

  describe "guard: does NOT call core Mailgun.verify!/3" do
    test "verify! reads flat form fields, not a nested JSON signature object" do
      # A request whose params carry ONLY the flat triple (no JSON envelope)
      # must verify — this is exactly the shape core Mailgun.verify!/3 cannot
      # handle (it Jason.decodes the body and expects %{"signature" => %{...}}).
      request = mailgun_request()

      assert {:ok, _facts} = Mailgun.verify!(request, %{signing_key: @signing_key})
    end
  end

  describe "normalize/1 — parsed mode" do
    test "builds %InboundMessage{} from parsed Mailgun fields with provider_message_id" do
      request = parsed_request()

      %{message: message} = Mailgun.normalize(request)

      assert message.provider == :mailgun
      assert message.provider_message_id == "<mg-parsed@example.com>"
      assert message.message_id == "<mg-parsed@example.com>"
      assert [%{address: "sender@example.com", name: "Sender"}] = message.from
      assert [%{address: "support@example.com", name: "Support"}] = message.to
      assert message.subject == "Inbound parsed test"
      assert message.text_body == "Plain body"
      assert message.html_body == "<p>HTML body</p>"
    end

    test "populates envelope_recipient from the Mailgun recipient field" do
      request = parsed_request()

      %{message: message} = Mailgun.normalize(request)

      assert message.envelope_recipient == "support@example.com"
    end

    test "captures attachments into attachment_blobs as index:filename => bytes" do
      request = parsed_request_with_attachment()

      %{message: message, evidence: evidence} = Mailgun.normalize(request)

      assert [%{filename: "invoice.txt", content_type: "text/plain"}] = message.attachments
      assert evidence.attachment_blobs["1:invoice.txt"] == "invoice-bytes"
    end
  end

  describe "normalize/1 — raw-MIME mode" do
    test "routes body-mime through MailglassInbound.MIME.parse/1" do
      request = raw_mime_request(raw_mime_fixture())

      %{message: message} = Mailgun.normalize(request)

      assert message.provider == :mailgun
      assert message.subject == "Raw MIME subject"
      assert message.provider_message_id == "<mg-rawmime@example.com>"
      assert message.text_body =~ "Raw plain body"
    end

    test "malformed body-mime records parse_warnings and never raises" do
      request = raw_mime_request("this is not valid MIME at all")

      %{message: _message, evidence: evidence} = Mailgun.normalize(request)

      assert is_map(evidence.parse_warnings)
      assert evidence.parse_warnings != %{}
    end
  end

  describe "normalize/1 — evidence shape" do
    test "evidence carries raw_payload, raw_headers, raw_mime, attachment_blobs" do
      request = parsed_request()

      %{evidence: evidence} = Mailgun.normalize(request)

      assert Map.has_key?(evidence, :raw_payload)
      assert Map.has_key?(evidence, :raw_headers)
      assert Map.has_key?(evidence, :raw_mime)
      assert Map.has_key?(evidence, :attachment_blobs)
      assert Map.has_key?(evidence, :verification_facts)
      assert Map.has_key?(evidence, :parse_warnings)
      assert evidence.raw_payload["body-plain"] == "Plain body"
    end

    test "does NOT widen the public InboundMessage struct for provider quirks" do
      %{message: message} = Mailgun.normalize(parsed_request())

      refute Map.has_key?(message, :attachment_blobs)
      refute Map.has_key?(message, :raw_mime)
    end
  end

  # ----------------------------------------------------------------------------
  # Code-built fixtures (no .eml files)
  # ----------------------------------------------------------------------------

  defp parsed_request(overrides \\ []) do
    params =
      %{
        "recipient" => "support@example.com",
        "sender" => "sender@example.com",
        "from" => "Sender <sender@example.com>",
        "to" => "Support <support@example.com>",
        "subject" => "Inbound parsed test",
        "body-plain" => "Plain body",
        "body-html" => "<p>HTML body</p>",
        "message-headers" =>
          Jason.encode!([
            ["Message-Id", "<mg-parsed@example.com>"],
            ["From", "Sender <sender@example.com>"],
            ["To", "Support <support@example.com>"],
            ["Subject", "Inbound parsed test"],
            ["Date", "Tue, 06 May 2026 12:00:00 +0000"]
          ])
      }
      |> Map.merge(Map.new(overrides))

    %Request{
      provider: :mailgun,
      headers: [{"content-type", "application/x-www-form-urlencoded"}],
      params: params,
      content_type: "application/x-www-form-urlencoded"
    }
  end

  defp parsed_request_with_attachment do
    request = parsed_request()

    params =
      Map.merge(request.params, %{
        "attachment-count" => "1",
        "attachment-1" => "invoice-bytes",
        "attachment-1-filename" => "invoice.txt",
        "attachment-1-content-type" => "text/plain"
      })

    %{request | params: params, content_type: "multipart/form-data"}
  end

  defp raw_mime_request(body_mime) do
    %Request{
      provider: :mailgun,
      headers: [{"content-type", "application/x-www-form-urlencoded"}],
      params: %{"body-mime" => body_mime},
      content_type: "application/x-www-form-urlencoded"
    }
  end

  defp raw_mime_fixture do
    [
      "From: Sender <sender@example.com>\r\n",
      "To: Support <support@example.com>\r\n",
      "Subject: Raw MIME subject\r\n",
      "Message-Id: <mg-rawmime@example.com>\r\n",
      "Date: Tue, 06 May 2026 12:00:00 +0000\r\n",
      "MIME-Version: 1.0\r\n",
      "Content-Type: text/plain; charset=UTF-8\r\n",
      "\r\n",
      "Raw plain body\r\n"
    ]
    |> IO.iodata_to_binary()
  end

  defp mailgun_request(overrides \\ []) do
    timestamp = Keyword.get(overrides, :timestamp, Integer.to_string(System.os_time(:second)))
    token = Keyword.get(overrides, :token, "test-token-#{System.unique_integer([:positive])}")

    signature =
      Keyword.get(overrides, :signature, sign(timestamp, token))

    params =
      %{
        "timestamp" => timestamp,
        "token" => token,
        "signature" => signature,
        "message-headers" =>
          Jason.encode!([
            ["Message-Id", "<mg-#{token}@example.com>"],
            ["From", "Sender <sender@example.com>"],
            ["To", "Support <support@example.com>"],
            ["Subject", "Inbound test"]
          ]),
        "body-plain" => "Plain body",
        "body-html" => "<p>HTML body</p>"
      }

    %Request{
      provider: :mailgun,
      headers: [{"content-type", "application/x-www-form-urlencoded"}],
      params: params,
      content_type: "application/x-www-form-urlencoded"
    }
  end

  defp sign(timestamp, token) do
    :hmac
    |> :crypto.mac(:sha256, @signing_key, timestamp <> token)
    |> Base.encode16(case: :lower)
  end
end
