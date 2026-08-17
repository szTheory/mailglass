defmodule Mailglass.HTTPCStub do
  @moduledoc false
  # Minimal :httpc stub for SubscriptionConfirmation tests.
  # Returns HTTP 200 for any GET request, avoiding real network calls.
  def request(:get, _url_req, _http_opts, _opts),
    do: {:ok, {{"HTTP/1.1", 200, "OK"}, [], ""}}
end

defmodule Mailglass.StreamingHTTPCStub do
  @moduledoc false

  def request(:get, _url_req, _http_opts, opts) do
    true = Keyword.get(opts, :sync) == false
    {:self, :once} = Keyword.fetch!(opts, :stream)
    caller = self()
    request_id = make_ref()
    test_pid = Application.fetch_env!(:mailglass, :ses_stream_test_pid)

    handler =
      spawn(fn ->
        receive do
          :next ->
            send(test_pid, {:cert_chunk_requested, 1})
            send(caller, {:http, {request_id, :stream, :binary.copy("x", 17)}})

            receive do
              :next ->
                send(test_pid, {:cert_chunk_requested, 2})
                send(caller, {:http, {request_id, :stream, "never-needed"}})
            after
              100 -> :ok
            end
        end
      end)

    send(caller, {:http, {request_id, :stream_start, [], handler}})
    {:ok, request_id}
  end

  def stream_next(handler), do: send(handler, :next)
  def cancel_request(_request_id), do: :ok
end

defmodule Mailglass.SuccessfulStreamingHTTPCStub do
  @moduledoc false

  def request(:get, _url_req, _http_opts, opts) do
    true = Keyword.get(opts, :sync) == false
    {:self, :once} = Keyword.fetch!(opts, :stream)
    caller = self()
    request_id = make_ref()
    chunks = Application.fetch_env!(:mailglass, :ses_success_stream_chunks)

    handler = spawn(fn -> stream(caller, request_id, chunks) end)
    send(caller, {:http, {request_id, :stream_start, [], handler}})
    {:ok, request_id}
  end

  def stream_next(handler), do: send(handler, :next)
  def cancel_request(_request_id), do: :ok

  defp stream(caller, request_id, [chunk | rest]) do
    receive do
      :next ->
        send(caller, {:http, {request_id, :stream, chunk}})
        stream(caller, request_id, rest)
    end
  end

  defp stream(caller, request_id, []) do
    receive do
      :next -> send(caller, {:http, {request_id, :stream_end, []}})
    end
  end
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
    prior_stream_test_pid = Application.get_env(:mailglass, :ses_stream_test_pid)
    prior_success_chunks = Application.get_env(:mailglass, :ses_success_stream_chunks)

    on_exit(fn ->
      if is_nil(prior_stream_test_pid) do
        Application.delete_env(:mailglass, :ses_stream_test_pid)
      else
        Application.put_env(:mailglass, :ses_stream_test_pid, prior_stream_test_pid)
      end

      if is_nil(prior_success_chunks) do
        Application.delete_env(:mailglass, :ses_success_stream_chunks)
      else
        Application.put_env(:mailglass, :ses_success_stream_chunks, prior_success_chunks)
      end
    end)

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
    test "verifies a cold-cache certificate delivered as a bounded successful stream" do
      test_data =
        :public_key.pkix_test_data(%{
          root: [key: {:rsa, 2048, 65_537}],
          peer: [key: {:rsa, 2048, 65_537}]
        })

      cert_der = Keyword.fetch!(test_data, :cert)
      {:RSAPrivateKey, private_key_der} = Keyword.fetch!(test_data, :key)
      private_key = :public_key.der_decode(:RSAPrivateKey, private_key_der)

      pem = :public_key.pem_encode([{:Certificate, cert_der, :not_encrypted}])
      split_at = div(byte_size(pem), 2)
      <<first::binary-size(split_at), second::binary>> = pem
      Application.put_env(:mailglass, :ses_success_stream_chunks, [first, second])

      raw = sign_fixture(load_ses_fixture("notification_delivery"), private_key)

      config = %{
        cert_cache_ttl_seconds: 86_400,
        cert_max_response_bytes: byte_size(pem) + 1,
        httpc_client: Mailglass.SuccessfulStreamingHTTPCStub
      }

      assert :ok = SES.verify!(raw, [], config)
    end

    test "aborts a streamed certificate response at the configured byte cap" do
      Application.put_env(:mailglass, :ses_stream_test_pid, self())

      raw =
        Jason.encode!(%{
          "Type" => "Notification",
          "Message" => "{}",
          "MessageId" => "stream-limit",
          "Timestamp" => "2026-08-17T00:00:00Z",
          "TopicArn" => "arn:aws:sns:us-east-1:123456789012:test",
          "SigningCertURL" => @cert_url,
          "SignatureVersion" => "2",
          "Signature" => Base.encode64("invalid")
        })

      config = %{
        cert_cache_ttl_seconds: 86_400,
        cert_max_response_bytes: 16,
        httpc_client: Mailglass.StreamingHTTPCStub
      }

      assert_raise SignatureError, fn -> SES.verify!(raw, [], config) end
      assert_receive {:cert_chunk_requested, 1}
      refute_receive {:cert_chunk_requested, 2}, 50
    end

    test "returns :ok for a valid Notification payload" do
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)

      raw = sign_fixture(load_ses_fixture("notification_delivery"), private_key)
      assert :ok = SES.verify!(raw, [], @config)
    end

    test "reuses a caller-supplied decoded SNS envelope for verification and normalization" do
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)

      decoded =
        load_ses_fixture("notification_delivery") |> sign_fixture(private_key) |> Jason.decode()

      assert :ok = SES.verify_decoded!(decoded, [], @config)
      assert [_event] = SES.normalize_decoded(decoded, [])
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

  # -------- verify_envelope!/2 — inbound-reuse crypto seam ---------

  describe "verify_envelope!/2 (inbound-reuse seam, D-46-01)" do
    test "returns {:ok, payload} with the decoded SNS payload for a valid Notification" do
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)

      raw = sign_fixture(load_ses_fixture("notification_delivery"), private_key)

      assert {:ok, payload} = SES.verify_envelope!(raw, @config)
      assert is_map(payload)
      assert payload["Type"] == "Notification"
      assert Map.has_key?(payload, "Message")
    end

    test "raises :bad_signature for a tampered payload (no dispatch on the seam)" do
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)

      raw = sign_fixture(load_ses_fixture("notification_delivery"), private_key)

      tampered =
        String.replace(raw, "\"Message\":", "\"Message\":\"TAMPERED\", \"X\":", global: false)

      err = catch_raised(fn -> SES.verify_envelope!(tampered, @config) end)
      assert %SignatureError{type: :bad_signature, provider: :ses} = err
    end

    test "raises :malformed_header for non-JSON body" do
      err = catch_raised(fn -> SES.verify_envelope!("not json", @config) end)
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
