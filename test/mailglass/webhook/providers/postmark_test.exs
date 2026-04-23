defmodule Mailglass.Webhook.Providers.PostmarkTest do
  # async: false because `Mailglass.WebhookCase` setup mutates
  # `Application.put_env(:mailglass, :postmark, ...)` per CONTEXT D-26.
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Webhook.Providers.Postmark

  @user "test_user"
  @pass "test_pass"
  @config %{basic_auth: {@user, @pass}, ip_allowlist: []}

  # ---- verify!/3 happy path ------------------------------------------

  describe "verify!/3 Basic Auth happy path" do
    test "returns :ok with valid Basic Auth header" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(@user, @pass)
      assert :ok = Postmark.verify!("{}", [{h, v}], @config)
    end
  end

  # ---- verify!/3 failure modes ---------------------------------------

  describe "verify!/3 Basic Auth failure modes" do
    test "raises :missing_header when Authorization absent" do
      err = catch_raised(fn -> Postmark.verify!("{}", [], @config) end)
      assert %SignatureError{type: :missing_header, provider: :postmark} = err
    end

    test "raises :malformed_header on bad Base64" do
      headers = [{"authorization", "Basic %%%not-base64%%%"}]
      err = catch_raised(fn -> Postmark.verify!("{}", headers, @config) end)
      assert err.type == :malformed_header
      assert err.provider == :postmark
    end

    test "raises :malformed_header when no Basic prefix" do
      headers = [{"authorization", "Bearer foo"}]
      err = catch_raised(fn -> Postmark.verify!("{}", headers, @config) end)
      assert err.type == :malformed_header
    end

    test "raises :malformed_header when colon-split fails" do
      no_colon = Base.encode64("nocolonhere")
      headers = [{"authorization", "Basic " <> no_colon}]
      err = catch_raised(fn -> Postmark.verify!("{}", headers, @config) end)
      assert err.type == :malformed_header
    end

    test "raises :bad_credentials on user mismatch" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header("wrong_user", @pass)
      err = catch_raised(fn -> Postmark.verify!("{}", [{h, v}], @config) end)
      assert err.type == :bad_credentials
      assert err.provider == :postmark
    end

    test "raises :bad_credentials on pass mismatch" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(@user, "wrong_pass")
      err = catch_raised(fn -> Postmark.verify!("{}", [{h, v}], @config) end)
      assert err.type == :bad_credentials
    end

    test "raises ConfigError :webhook_verification_key_missing when basic_auth not configured" do
      err = catch_raised(fn -> Postmark.verify!("{}", [], %{}) end)
      assert %ConfigError{type: :webhook_verification_key_missing} = err
    end
  end

  # ---- verify!/3 IP allowlist ----------------------------------------

  describe "verify!/3 IP allowlist" do
    test "off by default — allows any remote_ip" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(@user, @pass)
      config = Map.put(@config, :remote_ip, {1, 2, 3, 4})
      assert :ok = Postmark.verify!("{}", [{h, v}], config)
    end

    test "raises :ip_disallowed when remote_ip not in CIDR list" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(@user, @pass)

      config =
        Map.merge(@config, %{
          ip_allowlist: ["50.31.156.0/24"],
          remote_ip: {1, 2, 3, 4}
        })

      err = catch_raised(fn -> Postmark.verify!("{}", [{h, v}], config) end)
      assert err.type == :ip_disallowed
      assert err.provider == :postmark
    end

    test "returns :ok when remote_ip in CIDR" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(@user, @pass)

      config =
        Map.merge(@config, %{
          ip_allowlist: ["1.2.3.0/24"],
          remote_ip: {1, 2, 3, 42}
        })

      assert :ok = Postmark.verify!("{}", [{h, v}], config)
    end

    test "raises :malformed_header when ip_allowlist set but remote_ip not forwarded" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(@user, @pass)

      config =
        Map.merge(@config, %{
          ip_allowlist: ["1.2.3.0/24"]
          # no :remote_ip
        })

      err = catch_raised(fn -> Postmark.verify!("{}", [{h, v}], config) end)
      assert err.type == :malformed_header
      assert err.context[:detail] =~ "remote_ip not forwarded"
    end

    test "single-address CIDR (no mask) matches exactly" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(@user, @pass)

      config = Map.merge(@config, %{ip_allowlist: ["1.2.3.4"], remote_ip: {1, 2, 3, 4}})
      assert :ok = Postmark.verify!("{}", [{h, v}], config)

      config_miss = Map.merge(@config, %{ip_allowlist: ["1.2.3.4"], remote_ip: {1, 2, 3, 5}})
      err = catch_raised(fn -> Postmark.verify!("{}", [{h, v}], config_miss) end)
      assert err.type == :ip_disallowed
    end
  end

  # ---- normalize/2 RecordType mapping (Anymail verbatim per D-05) -----

  describe "normalize/2 RecordType mapping (Anymail verbatim per D-05)" do
    test "Delivery -> :delivered" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")
      [event] = Postmark.normalize(body, [])

      assert event.type == :delivered
      assert event.reject_reason == nil
      assert event.metadata["provider"] == "postmark"
      assert event.metadata["record_type"] == "Delivery"
      assert is_binary(event.metadata["provider_event_id"])
    end

    test "Bounce TypeCode 1 (HardBounce) -> :bounced + reject_reason :bounced" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("bounced")
      [event] = Postmark.normalize(body, [])

      assert event.type == :bounced
      assert event.reject_reason == :bounced
      assert event.metadata["record_type"] == "Bounce"
    end

    test "Open -> :opened" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("opened")
      [event] = Postmark.normalize(body, [])
      assert event.type == :opened
      assert event.reject_reason == nil
    end

    test "Click -> :clicked" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("clicked")
      [event] = Postmark.normalize(body, [])
      assert event.type == :clicked
    end

    test "SpamComplaint -> :complained" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("spam_complaint")
      [event] = Postmark.normalize(body, [])
      assert event.type == :complained
    end

    test "Bounce TypeCode 2 (Transient) -> :deferred" do
      body = ~s({"RecordType":"Bounce","TypeCode":2,"MessageID":"abc","ID":2})
      [event] = Postmark.normalize(body, [])
      assert event.type == :deferred
      assert event.reject_reason == nil
    end

    test "Bounce TypeCode 16 (DnsError) -> :bounced + :invalid" do
      body = ~s({"RecordType":"Bounce","TypeCode":16,"MessageID":"abc","ID":3})
      [event] = Postmark.normalize(body, [])
      assert event.type == :bounced
      assert event.reject_reason == :invalid
    end

    test "Bounce TypeCode 24 (SpamNotification) -> :rejected + :spam" do
      body = ~s({"RecordType":"Bounce","TypeCode":24,"MessageID":"abc","ID":4})
      [event] = Postmark.normalize(body, [])
      assert event.type == :rejected
      assert event.reject_reason == :spam
    end

    test "Bounce TypeCode 32 (SoftBounce) -> :deferred" do
      body = ~s({"RecordType":"Bounce","TypeCode":32,"MessageID":"abc","ID":5})
      [event] = Postmark.normalize(body, [])
      assert event.type == :deferred
    end

    test "Bounce TypeCode 64 (Blocked) -> :rejected + :blocked" do
      body = ~s({"RecordType":"Bounce","TypeCode":64,"MessageID":"abc","ID":6})
      [event] = Postmark.normalize(body, [])
      assert event.type == :rejected
      assert event.reject_reason == :blocked
    end

    test "SubscriptionChange SuppressSending=true -> :unsubscribed" do
      body =
        ~s({"RecordType":"SubscriptionChange","SuppressSending":true,"MessageID":"abc","ChangedAt":"2026-04-23T00:00:00Z"})

      [event] = Postmark.normalize(body, [])
      assert event.type == :unsubscribed
    end

    test "SubscriptionChange SuppressSending=false -> :subscribed" do
      body =
        ~s({"RecordType":"SubscriptionChange","SuppressSending":false,"MessageID":"abc","ChangedAt":"2026-04-23T00:00:00Z"})

      [event] = Postmark.normalize(body, [])
      assert event.type == :subscribed
    end

    test "Unmapped RecordType -> :unknown + Logger.warning" do
      body = ~s({"RecordType":"FrobulatedWidget","MessageID":"abc"})

      {events, log} = with_log(fn -> Postmark.normalize(body, []) end)
      [event] = events

      assert event.type == :unknown
      assert log =~ "Unmapped Postmark RecordType"
      assert log =~ "FrobulatedWidget"
    end

    test "Unmapped Bounce TypeCode -> :bounced + :other + Logger.warning" do
      body = ~s({"RecordType":"Bounce","TypeCode":99,"MessageID":"abc","ID":1})

      {events, log} = with_log(fn -> Postmark.normalize(body, []) end)
      [event] = events

      assert event.type == :bounced
      assert event.reject_reason == :other
      assert log =~ "Unmapped Postmark Bounce TypeCode"
      assert log =~ "99"
    end

    test "malformed JSON -> empty list + Logger.warning" do
      {events, log} = with_log(fn -> Postmark.normalize("not json at all", []) end)
      assert events == []
      assert log =~ "malformed JSON"
    end

    test "extract_event_id uses Bounce ID + BouncedAt" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("bounced")
      [event] = Postmark.normalize(body, [])

      id = event.metadata["provider_event_id"]
      assert String.starts_with?(id, "Bounce:")
      assert id =~ "4323372036854775807"
      assert id =~ "2026-04-23T12:00:01Z"
    end

    test "extract_event_id uses MessageID + DeliveredAt for Delivery" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")
      [event] = Postmark.normalize(body, [])

      id = event.metadata["provider_event_id"]
      assert String.starts_with?(id, "Delivery:")
      assert id =~ "00000000-0000-0000-0000-000000000001"
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
