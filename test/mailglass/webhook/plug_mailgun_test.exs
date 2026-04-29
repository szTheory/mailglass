defmodule Mailglass.Webhook.PlugMailgunTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.TestRepo
  alias Mailglass.Webhook.Plug, as: WebhookPlug
  alias Mailglass.Webhook.Providers.MailgunReplayCache
  alias Mailglass.Webhook.WebhookEvent

  setup do
    MailgunReplayCache.reset()
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
    :ok
  end

  test "WebhookCase can build a signed Mailgun conn from raw bytes" do
    raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")

    conn = Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body)
    payload = Jason.decode!(conn.private[:raw_body])

    assert conn.request_path == "/webhooks/mailgun"
    assert conn.private[:raw_body] != raw_body
    assert get_req_header(conn, "content-type") == ["application/json"]
    assert %{"signature" => %{"signature" => _, "timestamp" => _, "token" => _}} = payload
  end

  describe "call/2 Mailgun replay response" do
    test "returns 200 on a valid signed Mailgun request" do
      raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")

      conn =
        Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body, token: "mailgun-valid-200")

      result = WebhookPlug.call(conn, WebhookPlug.init(provider: :mailgun))

      assert result.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end

    test "returns 200 on a replayed Mailgun request" do
      raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")

      conn =
        Mailglass.WebhookCase.mailglass_webhook_conn(
          :mailgun,
          raw_body,
          token: "mailgun-replay-200"
        )

      first = WebhookPlug.call(conn, WebhookPlug.init(provider: :mailgun))
      second = WebhookPlug.call(conn, WebhookPlug.init(provider: :mailgun))

      assert first.status == 200
      assert second.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end

  describe "call/2 Mailgun bad signature response" do
    test "returns 401 when the Mailgun signature is invalid" do
      raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")

      conn =
        Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body,
          token: "mailgun-bad-signature"
        )

      tampered_body =
        String.replace(conn.private[:raw_body], "\"signature\":\"", "\"signature\":\"0",
          global: false
        )

      tampered_conn =
        conn
        |> Plug.Conn.put_private(:raw_body, tampered_body)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(tampered_conn, WebhookPlug.init(provider: :mailgun))
        end)

      assert result.status == 401
      assert log =~ "provider=mailgun"
      refute log =~ raw_body
    end
  end

  describe "call/2 Mailgun missing config response" do
    test "returns 500 when Mailgun signing config is missing" do
      raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")

      conn =
        Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body,
          token: "mailgun-missing-config"
        )

      prior = Application.get_env(:mailglass, :mailgun)

      Application.put_env(:mailglass, :mailgun,
        enabled: true,
        signing_key: nil,
        timestamp_tolerance_seconds: 28_800,
        future_skew_seconds: 300,
        replay_cache_ttl_seconds: 28_800
      )

      on_exit(fn ->
        if is_nil(prior) do
          Application.delete_env(:mailglass, :mailgun)
        else
          Application.put_env(:mailglass, :mailgun, prior)
        end
      end)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :mailgun))
        end)

      assert result.status == 500
      assert log =~ "provider=mailgun"
      assert log =~ "reason=webhook_verification_key_missing"
    end
  end

  describe "call/2 Mailgun explicit route execution" do
    test "init/1 accepts :mailgun as an explicit provider" do
      assert Keyword.get(WebhookPlug.init(provider: :mailgun), :provider) == :mailgun
    end
  end
end
