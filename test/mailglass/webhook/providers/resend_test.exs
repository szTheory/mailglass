defmodule Mailglass.Webhook.Providers.ResendTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Webhook.Providers.Resend

  @secret_bytes :crypto.strong_rand_bytes(32)
  @secret "whsec_" <> Base.encode64(@secret_bytes)
  @config %{secret: @secret, timestamp_tolerance_seconds: 300}

  describe "verify!/3 Svix happy path" do
    test "returns :ok for valid signature and timestamp" do
      body = resend_payload("email.delivered")
      svix_id = "msg_123"
      svix_timestamp = Integer.to_string(System.system_time(:second))

      signature =
        Mailglass.WebhookFixtures.sign_resend_payload(
          svix_id,
          svix_timestamp,
          body,
          @secret_bytes
        )

      headers = [
        {"svix-id", svix_id},
        {"svix-timestamp", svix_timestamp},
        {"svix-signature", "v1," <> signature}
      ]

      assert :ok = Resend.verify!(body, headers, @config)
    end

    test "accepts rotated signatures when one v1 value matches" do
      body = resend_payload("email.sent")
      svix_id = "msg_456"
      svix_timestamp = Integer.to_string(System.system_time(:second))

      signature =
        Mailglass.WebhookFixtures.sign_resend_payload(
          svix_id,
          svix_timestamp,
          body,
          @secret_bytes
        )

      headers = [
        {"svix-id", svix_id},
        {"svix-timestamp", svix_timestamp},
        {"svix-signature", "v1,invalid v1," <> signature}
      ]

      assert :ok = Resend.verify!(body, headers, @config)
    end
  end

  describe "verify!/3 Svix failure modes" do
    test "raises :missing_header when a required header is absent" do
      body = resend_payload("email.delivered")
      svix_timestamp = Integer.to_string(System.system_time(:second))

      err =
        catch_raised(fn ->
          Resend.verify!(body, [{"svix-timestamp", svix_timestamp}], @config)
        end)

      assert %SignatureError{type: :missing_header, provider: :resend} = err
    end

    test "raises :timestamp_skew when the timestamp is stale" do
      body = resend_payload("email.delivered")
      svix_id = "msg_123"
      svix_timestamp = Integer.to_string(System.system_time(:second) - 601)

      signature =
        Mailglass.WebhookFixtures.sign_resend_payload(
          svix_id,
          svix_timestamp,
          body,
          @secret_bytes
        )

      headers = [
        {"svix-id", svix_id},
        {"svix-timestamp", svix_timestamp},
        {"svix-signature", "v1," <> signature}
      ]

      err = catch_raised(fn -> Resend.verify!(body, headers, @config) end)
      assert err.type == :timestamp_skew
      assert err.provider == :resend
    end

    test "raises :bad_signature when the signature does not match the body" do
      body = resend_payload("email.delivered")
      svix_id = "msg_123"
      svix_timestamp = Integer.to_string(System.system_time(:second))

      signature =
        Mailglass.WebhookFixtures.sign_resend_payload(
          svix_id,
          svix_timestamp,
          body,
          @secret_bytes
        )

      tampered = String.replace(body, "delivered", "delivered_late")

      headers = [
        {"svix-id", svix_id},
        {"svix-timestamp", svix_timestamp},
        {"svix-signature", "v1," <> signature}
      ]

      err = catch_raised(fn -> Resend.verify!(tampered, headers, @config) end)
      assert err.type == :bad_signature
      assert err.provider == :resend
    end

    test "raises :malformed_header when the timestamp is not an integer" do
      body = resend_payload("email.delivered")

      headers = [
        {"svix-id", "msg_123"},
        {"svix-timestamp", "not-a-number"},
        {"svix-signature", "v1,abc"}
      ]

      err = catch_raised(fn -> Resend.verify!(body, headers, @config) end)
      assert err.type == :malformed_header
      assert err.provider == :resend
    end

    test "raises ConfigError when the secret is missing" do
      body = resend_payload("email.delivered")

      headers = [
        {"svix-id", "msg_123"},
        {"svix-timestamp", Integer.to_string(System.system_time(:second))},
        {"svix-signature", "v1,abc"}
      ]

      err = catch_raised(fn -> Resend.verify!(body, headers, %{}) end)
      assert %ConfigError{type: :webhook_verification_key_missing} = err
    end
  end

  describe "normalize/2 Resend event mapping" do
    test "email.sent -> :sent" do
      [event] = Resend.normalize(resend_payload("email.sent"), [])
      assert event.type == :sent
      assert event.reject_reason == nil
      assert event.metadata["record_type"] == "email.sent"
    end

    test "email.delivered -> :delivered" do
      [event] = Resend.normalize(resend_payload("email.delivered"), [])
      assert event.type == :delivered
      assert event.reject_reason == nil
    end

    test "email.delivery_delayed -> :deferred" do
      [event] = Resend.normalize(resend_payload("email.delivery_delayed"), [])
      assert event.type == :deferred
      assert event.reject_reason == nil
    end

    test "email.bounced -> :bounced with reject_reason :bounced" do
      [event] = Resend.normalize(resend_payload("email.bounced"), [])
      assert event.type == :bounced
      assert event.reject_reason == :bounced
    end

    test "email.complained -> :complained" do
      [event] = Resend.normalize(resend_payload("email.complained"), [])
      assert event.type == :complained
      assert event.reject_reason == nil
      assert event.metadata["provider"] == "resend"
      assert event.metadata["provider_event_id"] == "evt_123"
      assert event.metadata["message_id"] == "email_123"
    end

    test "unknown types log and map to :unknown" do
      {events, log} =
        with_log(fn ->
          Resend.normalize(resend_payload("email.mystery"), [])
        end)

      [event] = events

      assert event.type == :unknown
      assert log =~ "Unmapped Resend event type"
      assert log =~ "email.mystery"
    end

    test "malformed JSON returns [] and logs" do
      {events, log} = with_log(fn -> Resend.normalize("not json", []) end)
      assert events == []
      assert log =~ "Resend normalize: malformed JSON body"
    end
  end

  defp resend_payload(type) do
    Jason.encode!(%{
      "id" => "evt_123",
      "type" => type,
      "created_at" => "2026-04-28T12:00:00Z",
      "data" => %{
        "email_id" => "email_123",
        "to" => ["person@example.com"]
      }
    })
  end

  defp catch_raised(fun) do
    try do
      fun.()
      flunk("expected exception to be raised, but function returned normally")
    rescue
      error -> error
    end
  end
end
