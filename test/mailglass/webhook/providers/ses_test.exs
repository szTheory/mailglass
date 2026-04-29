defmodule Mailglass.HTTPCStub do
  @moduledoc false
  # Minimal :httpc stub for SubscriptionConfirmation tests.
  # Returns HTTP 200 for any GET request, avoiding real network calls.
  def request(:get, _url_req, _http_opts, _opts),
    do: {:ok, {{"HTTP/1.1", 200, "OK"}, [], ""}}
end

defmodule Mailglass.Webhook.Providers.SESTest do
  use Mailglass.WebhookCase, async: false

  alias Mailglass.SignatureError
  alias Mailglass.Events.Event
  alias Mailglass.Webhook.Providers.SES
  alias Mailglass.Webhook.Providers.SES.CertCache

  @cert_url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem"
  @config %{cert_cache_ttl_seconds: 86_400}
  @config_with_httpc_stub %{cert_cache_ttl_seconds: 86_400, httpc_client: Mailglass.HTTPCStub}

  # SNS signable fields (byte-sorted alphabetical) for Notification:
  # Message, MessageId, Subject (if present), Timestamp, TopicArn, Type
  # For SubscriptionConfirmation/UnsubscribeConfirmation:
  # Message, MessageId, SubscribeURL, Timestamp, Token, TopicArn, Type

  setup do
    CertCache.reset()
    :ok
  end

  # -------- helpers ------------------------------------------------

  defp catch_raised(fun) do
    try do
      fun.()
      flunk("expected exception to be raised, but function returned normally")
    rescue
      error -> error
    end
  end

  defp build_canonical_string(payload, "Notification") do
    keys = ~w(Message MessageId Subject Timestamp TopicArn Type)

    keys
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  defp build_canonical_string(payload, type)
       when type in ["SubscriptionConfirmation", "UnsubscribeConfirmation"] do
    keys = ~w(Message MessageId SubscribeURL Timestamp Token TopicArn Type)

    keys
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  defp sign_fixture(raw_fixture_json, private_key) do
    payload = Jason.decode!(raw_fixture_json)
    msg_type = payload["Type"]
    canonical = build_canonical_string(payload, msg_type)
    sig = sign_sns_canonical_string(canonical, private_key)
    payload |> Map.put("Signature", sig) |> Jason.encode!()
  end

  # -------- verify!/3 — SNS signature verification -----------------

  describe "verify!/3 SES SNS signature verification" do
    test "returns :ok for a valid Notification payload" do
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)

      raw = sign_fixture(load_ses_fixture("notification_delivery"), private_key)
      assert :ok = SES.verify!(raw, [], @config)
    end

    test "raises :bad_signature for a tampered Notification payload" do
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)

      raw = sign_fixture(load_ses_fixture("notification_delivery"), private_key)

      tampered =
        String.replace(raw, "\"Message\":", "\"Message\":\"TAMPERED\", \"X\":", global: false)

      refute tampered == raw

      err = catch_raised(fn -> SES.verify!(tampered, [], @config) end)
      assert %SignatureError{type: :bad_signature, provider: :ses} = err
    end

    test "raises :bad_signature for an invalid SigningCertURL (SSRF guard)" do
      raw = load_ses_fixture("notification_delivery")
      forged_url = "https://sns.s3-us-west-2.amazonaws.com/evil.pem"
      payload = raw |> Jason.decode!() |> Map.put("SigningCertURL", forged_url) |> Jason.encode!()

      err = catch_raised(fn -> SES.verify!(payload, [], @config) end)
      assert %SignatureError{type: :bad_signature, provider: :ses} = err
    end

    test "raises :malformed_header for non-JSON body" do
      err = catch_raised(fn -> SES.verify!("not json", [], @config) end)
      assert %SignatureError{type: :malformed_header, provider: :ses} = err
    end
  end

  # -------- verify!/3 — control-plane paths ------------------------

  describe "verify!/3 SES SNS control-plane" do
    test "returns {:ok, :control_plane, :subscription_confirmed} for SubscriptionConfirmation" do
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)

      raw = sign_fixture(load_ses_fixture("subscription_confirmation"), private_key)
      # Use @config_with_httpc_stub to inject Mailglass.HTTPCStub instead of real :httpc,
      # preventing network I/O to AWS during tests (D-07 compliant constructed URL).
      assert {:ok, :control_plane, :subscription_confirmed} =
               SES.verify!(raw, [], @config_with_httpc_stub)
    end

    test "returns {:ok, :control_plane, :unsubscribe_confirmed} for UnsubscribeConfirmation" do
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)

      raw = sign_fixture(load_ses_fixture("unsubscribe_confirmation"), private_key)
      assert {:ok, :control_plane, :unsubscribe_confirmed} = SES.verify!(raw, [], @config)
    end
  end

  # -------- normalize/2 — classic SNS feedback notifications -------

  describe "normalize/2 SES classic feedback (notificationType)" do
    test "Bounce Permanent -> :bounced/:bounced fan-out per recipient" do
      raw = load_ses_fixture("notification_bounce_permanent")
      events = SES.normalize(raw, [])

      assert events != []
      [event | _] = events
      assert %Event{type: :bounced, reject_reason: :bounced} = event
      assert event.metadata["provider"] == "ses"
      assert is_binary(event.metadata["provider_event_id"])
      assert String.contains?(event.metadata["provider_event_id"], "bounce@example.com")
    end

    test "Bounce Transient -> :deferred fan-out per recipient" do
      raw = load_ses_fixture("notification_bounce_transient")
      [event | _] = SES.normalize(raw, [])

      assert event.type == :deferred
      assert event.reject_reason == nil
    end

    test "Complaint -> :complained fan-out per recipient" do
      raw = load_ses_fixture("notification_complaint")
      [event | _] = SES.normalize(raw, [])

      assert event.type == :complained
      assert event.metadata["provider"] == "ses"
    end

    test "Delivery -> :delivered fan-out per recipient" do
      raw = load_ses_fixture("notification_delivery")
      [event | _] = SES.normalize(raw, [])

      assert event.type == :delivered
    end
  end

  # -------- normalize/2 — SES event publishing ---------------------

  describe "normalize/2 SES event publishing (eventType)" do
    test "Send -> :sent" do
      raw = load_ses_fixture("event_send")
      [event] = SES.normalize(raw, [])
      assert event.type == :sent
    end

    test "Delivery -> :delivered" do
      raw = load_ses_fixture("event_delivered")
      [event] = SES.normalize(raw, [])
      assert event.type == :delivered
    end

    test "Bounce Permanent -> :bounced" do
      raw = load_ses_fixture("event_bounced_permanent")
      [event | _] = SES.normalize(raw, [])
      assert event.type == :bounced
    end

    test "Bounce Transient -> :deferred" do
      raw = load_ses_fixture("event_bounced_transient")
      [event | _] = SES.normalize(raw, [])
      assert event.type == :deferred
    end

    test "Complaint -> :complained" do
      raw = load_ses_fixture("event_complained")
      [event | _] = SES.normalize(raw, [])
      assert event.type == :complained
    end

    test "Reject -> :rejected" do
      raw = load_ses_fixture("event_rejected")
      [event] = SES.normalize(raw, [])
      assert event.type == :rejected
    end

    test "Open -> :opened" do
      raw = load_ses_fixture("event_opened")
      [event] = SES.normalize(raw, [])
      assert event.type == :opened
    end

    test "Click -> :clicked" do
      raw = load_ses_fixture("event_clicked")
      [event] = SES.normalize(raw, [])
      assert event.type == :clicked
    end

    test "Rendering Failure -> :failed" do
      raw = load_ses_fixture("event_failed")
      [event] = SES.normalize(raw, [])
      assert event.type == :failed
    end

    test "DeliveryDelay -> :deferred" do
      raw = load_ses_fixture("event_delivery_delay")
      [event] = SES.normalize(raw, [])
      assert event.type == :deferred
    end
  end

  describe "normalize/2 metadata requirements" do
    test "all events have string-keyed metadata with required fields" do
      raw = load_ses_fixture("notification_delivery")
      [event] = SES.normalize(raw, [])

      assert is_map(event.metadata)
      assert event.metadata["provider"] == "ses"
      assert is_binary(event.metadata["provider_event_id"])
      assert is_binary(event.metadata["record_type"]) or is_nil(event.metadata["record_type"])
    end

    test "fan-out produces stable provider_event_id per recipient" do
      raw = load_ses_fixture("notification_bounce_permanent")
      [event] = SES.normalize(raw, [])

      # provider_event_id follows "#{sns_message_id}:#{email}" pattern
      assert event.metadata["provider_event_id"] =~ "bounce@example.com"
    end
  end
end
