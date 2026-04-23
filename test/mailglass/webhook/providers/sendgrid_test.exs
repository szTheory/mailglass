defmodule Mailglass.Webhook.Providers.SendGridTest do
  # async: false because `Mailglass.WebhookCase` setup mutates
  # `Application.put_env(:mailglass, :sendgrid, ...)` per CONTEXT D-26.
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Webhook.Providers.SendGrid

  setup %{sendgrid_keypair: {pub_b64, priv_key}} do
    # WebhookCase setup already installed the keypair into Application env.
    # Build a config map matching what the Plug (Plan 04) will forward to
    # verify!/3 — the Provider contract is conn-free per D-02.
    config = %{
      public_key: pub_b64,
      timestamp_tolerance_seconds: 300
    }

    {:ok, config: config, public_key: pub_b64, private_key: priv_key}
  end

  # ---- verify!/3 happy path ------------------------------------------

  describe "verify!/3 ECDSA happy path" do
    test "returns :ok for valid signature + valid timestamp",
         %{config: config, private_key: priv} do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("single_event")
      ts = Integer.to_string(System.system_time(:second))
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)

      headers = [
        {"x-twilio-email-event-webhook-signature", sig},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      assert :ok = SendGrid.verify!(body, headers, config)
    end

    test "returns :ok for batch payload (5 events)",
         %{config: config, private_key: priv} do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("batch_5_events")
      ts = Integer.to_string(System.system_time(:second))
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)

      headers = [
        {"x-twilio-email-event-webhook-signature", sig},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      assert :ok = SendGrid.verify!(body, headers, config)
    end
  end

  # ---- verify!/3 failure modes ---------------------------------------

  describe "verify!/3 ECDSA failure modes" do
    test "raises :missing_header when signature header absent", %{config: config} do
      body = "[]"
      ts = Integer.to_string(System.system_time(:second))
      headers = [{"x-twilio-email-event-webhook-timestamp", ts}]

      err = catch_raised(fn -> SendGrid.verify!(body, headers, config) end)
      assert %SignatureError{type: :missing_header, provider: :sendgrid} = err
    end

    test "raises :missing_header when timestamp header absent",
         %{config: config, private_key: priv} do
      body = "[]"
      ts = Integer.to_string(System.system_time(:second))
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)
      headers = [{"x-twilio-email-event-webhook-signature", sig}]

      err = catch_raised(fn -> SendGrid.verify!(body, headers, config) end)
      assert err.type == :missing_header
      assert err.provider == :sendgrid
    end

    test "raises :bad_signature on bit-flipped body",
         %{config: config, private_key: priv} do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("single_event")
      ts = Integer.to_string(System.system_time(:second))
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)

      # Flip a single word in the body BEFORE verification — signature
      # was computed on `body`, not `tampered`, so verify/4 returns false.
      tampered = String.replace(body, "delivered", "DeliveRed")
      refute tampered == body, "fixture must contain 'delivered' for this test"

      headers = [
        {"x-twilio-email-event-webhook-signature", sig},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      err = catch_raised(fn -> SendGrid.verify!(tampered, headers, config) end)
      assert err.type == :bad_signature
      assert err.provider == :sendgrid
    end

    test "raises on bit-flipped signature (:bad_signature or :malformed_key)",
         %{config: config, private_key: priv} do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("single_event")
      ts = Integer.to_string(System.system_time(:second))
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)

      # Tamper one byte of the signature mid-string. Depending on
      # where the flip lands the decoded DER may still parse (→
      # `:bad_signature`) or become unparseable (→ `:malformed_key`).
      # Either is correct fail-closed behavior.
      mid = div(String.length(sig), 2)

      tampered_sig =
        sig
        |> String.graphemes()
        |> List.update_at(mid, fn c -> if c == "A", do: "B", else: "A" end)
        |> Enum.join()

      refute tampered_sig == sig, "signature must actually be tampered"

      headers = [
        {"x-twilio-email-event-webhook-signature", tampered_sig},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      err = catch_raised(fn -> SendGrid.verify!(body, headers, config) end)
      assert err.type in [:bad_signature, :malformed_key]
      assert err.provider == :sendgrid
    end

    test "raises :malformed_header on non-integer timestamp", %{config: config} do
      body = "[]"

      headers = [
        {"x-twilio-email-event-webhook-signature", "fake"},
        {"x-twilio-email-event-webhook-timestamp", "not-a-number"}
      ]

      err = catch_raised(fn -> SendGrid.verify!(body, headers, config) end)
      assert err.type == :malformed_header
      assert err.provider == :sendgrid
    end

    test "raises ConfigError :webhook_verification_key_missing when public_key not set" do
      body = "[]"
      ts = Integer.to_string(System.system_time(:second))

      headers = [
        {"x-twilio-email-event-webhook-signature", "x"},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      err = catch_raised(fn -> SendGrid.verify!(body, headers, %{}) end)
      assert %ConfigError{type: :webhook_verification_key_missing} = err
    end

    test "raises on malformed base64 public_key (:malformed_key or :bad_signature)" do
      body = "[]"
      ts = Integer.to_string(System.system_time(:second))

      headers = [
        {"x-twilio-email-event-webhook-signature", "MEUC"},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      config = %{public_key: "%%%not-base64%%%"}
      err = catch_raised(fn -> SendGrid.verify!(body, headers, config) end)
      assert err.type in [:malformed_key, :bad_signature]
      assert err.provider == :sendgrid
    end
  end

  # ---- verify!/3 timestamp tolerance window ---------------------------

  describe "verify!/3 timestamp tolerance window" do
    test "passes within +/- default tolerance (250s ago)",
         %{config: config, private_key: priv} do
      body = "[]"
      ts_int = System.system_time(:second) - 250
      ts = Integer.to_string(ts_int)
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)

      headers = [
        {"x-twilio-email-event-webhook-signature", sig},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      assert :ok = SendGrid.verify!(body, headers, config)
    end

    test "rejects beyond default tolerance (600s ago) with :timestamp_skew",
         %{config: config, private_key: priv} do
      body = "[]"
      ts_int = System.system_time(:second) - 600
      ts = Integer.to_string(ts_int)
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)

      headers = [
        {"x-twilio-email-event-webhook-signature", sig},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      err = catch_raised(fn -> SendGrid.verify!(body, headers, config) end)
      assert err.type == :timestamp_skew
      assert err.provider == :sendgrid
    end

    test "respects custom tolerance config (60s threshold, 120s-old rejects)",
         %{private_key: priv, public_key: pub} do
      config = %{public_key: pub, timestamp_tolerance_seconds: 60}
      body = "[]"
      ts_int = System.system_time(:second) - 120
      ts = Integer.to_string(ts_int)
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)

      headers = [
        {"x-twilio-email-event-webhook-signature", sig},
        {"x-twilio-email-event-webhook-timestamp", ts}
      ]

      err = catch_raised(fn -> SendGrid.verify!(body, headers, config) end)
      assert err.type == :timestamp_skew
    end
  end

  # ---- normalize/2 event mapping (Anymail verbatim per D-05) ----------

  describe "normalize/2 SendGrid event mapping" do
    test "single delivered event" do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("single_event")
      [event] = SendGrid.normalize(body, [])

      assert event.type == :delivered
      assert event.reject_reason == nil
      assert event.metadata["provider"] == "sendgrid"
      assert event.metadata["event"] == "delivered"
      assert is_binary(event.metadata["sg_message_id"])
      assert is_binary(event.metadata["provider_event_id"])
    end

    test "batch of 5 events maps each to correct Anymail atom" do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("batch_5_events")
      events = SendGrid.normalize(body, [])

      assert length(events) == 5
      types = Enum.map(events, & &1.type)

      # Per fixture order: processed, delivered, bounce, open, click
      assert types == [:queued, :delivered, :bounced, :opened, :clicked]
    end

    test "each event in batch gets a unique provider_event_id" do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("batch_5_events")
      events = SendGrid.normalize(body, [])
      ids = Enum.map(events, & &1.metadata["provider_event_id"])
      assert length(Enum.uniq(ids)) == length(ids)
    end

    test "spamreport -> :complained" do
      body =
        ~s([{"event":"spamreport","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_X","sg_message_id":"msg_X"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :complained
      assert event.reject_reason == nil
    end

    test "unsubscribe -> :unsubscribed" do
      body =
        ~s([{"event":"unsubscribe","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_Y","sg_message_id":"msg_Y"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :unsubscribed
    end

    test "group_unsubscribe -> :unsubscribed" do
      body =
        ~s([{"event":"group_unsubscribe","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_GU","sg_message_id":"msg_GU"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :unsubscribed
    end

    test "group_resubscribe -> :subscribed" do
      body =
        ~s([{"event":"group_resubscribe","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_GR","sg_message_id":"msg_GR"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :subscribed
    end

    test "dropped with reason 'Bounced Address' -> :rejected + :bounced" do
      body =
        ~s([{"event":"dropped","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_Z","sg_message_id":"msg_Z","reason":"Bounced Address"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :rejected
      assert event.reject_reason == :bounced
    end

    test "dropped with unrecognized reason -> :rejected + :other" do
      body =
        ~s([{"event":"dropped","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_Z","sg_message_id":"msg_Z","reason":"Some New Reason"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :rejected
      assert event.reject_reason == :other
    end

    test "bounce with type 'blocked' -> :bounced + :blocked" do
      body =
        ~s([{"event":"bounce","type":"blocked","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_B","sg_message_id":"msg_B"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :bounced
      assert event.reject_reason == :blocked
    end

    test "bounce with type 'expired' -> :bounced + :timed_out" do
      body =
        ~s([{"event":"bounce","type":"expired","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_E","sg_message_id":"msg_E"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :bounced
      assert event.reject_reason == :timed_out
    end

    test "bounce with unmapped type -> :bounced + :other + Logger.warning" do
      body =
        ~s([{"event":"bounce","type":"frobulated","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_F","sg_message_id":"msg_F"}])

      {events, log} = with_log(fn -> SendGrid.normalize(body, []) end)
      [event] = events

      assert event.type == :bounced
      assert event.reject_reason == :other
      assert log =~ "Unmapped SendGrid bounce type"
      assert log =~ "frobulated"
    end

    test "processed -> :queued" do
      body =
        ~s([{"event":"processed","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_P","sg_message_id":"msg_P"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :queued
    end

    test "deferred -> :deferred" do
      body =
        ~s([{"event":"deferred","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_D","sg_message_id":"msg_D"}])

      [event] = SendGrid.normalize(body, [])
      assert event.type == :deferred
    end

    test "unmapped event string -> :unknown + Logger.warning" do
      body =
        ~s([{"event":"sparkly_unicorn_event","email":"a@example.com","timestamp":1745409600,"sg_event_id":"evt_U","sg_message_id":"msg_U"}])

      {events, log} = with_log(fn -> SendGrid.normalize(body, []) end)
      [event] = events

      assert event.type == :unknown
      assert log =~ "Unmapped SendGrid event"
      assert log =~ "sparkly_unicorn_event"
    end

    test "malformed JSON body -> empty list + Logger.warning" do
      {events, log} = with_log(fn -> SendGrid.normalize("not json at all", []) end)
      assert events == []
      assert log =~ "malformed JSON"
    end

    test "non-array JSON root -> empty list + Logger.warning" do
      {events, log} = with_log(fn -> SendGrid.normalize(~s({"not":"an array"}), []) end)
      assert events == []
      assert log =~ "expected JSON array"
    end

    test "provider_event_id falls back to smtp-id:idx when sg_event_id missing" do
      body =
        ~s([{"event":"delivered","email":"a@example.com","timestamp":1745409600,"smtp-id":"<smtp-abc>","sg_message_id":"msg_M"}])

      [event] = SendGrid.normalize(body, [])
      assert event.metadata["provider_event_id"] == "<smtp-abc>:0"
    end

    test "provider_event_id falls back to sg_message_id:idx when sg_event_id + smtp-id missing" do
      body =
        ~s([{"event":"delivered","email":"a@example.com","timestamp":1745409600,"sg_message_id":"msg_only"}])

      [event] = SendGrid.normalize(body, [])
      assert event.metadata["provider_event_id"] == "msg_only:0"
    end

    test "metadata stashes 'provider' string (not atom) per revision W9" do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("single_event")
      [event] = SendGrid.normalize(body, [])

      # JSONB roundtrip safety: keys and the provider value are strings,
      # never atoms. Plan 06's Ingest reads metadata["provider"] directly.
      assert event.metadata["provider"] == "sendgrid"
      refute Map.has_key?(event.metadata, :provider)
    end
  end

  # ---- helper --------------------------------------------------------

  defp catch_raised(fun) do
    try do
      fun.()
      flunk("expected exception")
    rescue
      e -> e
    end
  end
end
