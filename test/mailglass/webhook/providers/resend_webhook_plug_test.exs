defmodule Mailglass.Webhook.PlugResendTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.TestRepo
  alias Mailglass.Webhook.Plug, as: WebhookPlug
  alias Mailglass.Webhook.WebhookEvent

  setup do
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
    :ok
  end

  test "WebhookCase can build a signed Resend conn from raw bytes" do
    raw_body = Mailglass.WebhookCase.stub_resend_fixture("delivered")
    conn = Mailglass.WebhookCase.mailglass_webhook_conn(:resend, raw_body)

    assert conn.request_path == "/webhooks/resend"
    assert get_req_header(conn, "content-type") == ["application/json"]
    assert [_] = get_req_header(conn, "svix-id")
    assert [_] = get_req_header(conn, "svix-timestamp")
    assert ["v1," <> _] = get_req_header(conn, "svix-signature")
  end

  describe "call/2 Resend valid signature" do
    test "returns 200 on a valid signed Resend request" do
      raw_body = Mailglass.WebhookCase.stub_resend_fixture("delivered")
      conn = Mailglass.WebhookCase.mailglass_webhook_conn(:resend, raw_body)

      result = WebhookPlug.call(conn, WebhookPlug.init(provider: :resend))

      assert result.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end

  describe "call/2 Resend bad signature response" do
    test "returns 401 when the Resend body is tampered" do
      raw_body = Mailglass.WebhookCase.stub_resend_fixture("delivered")
      conn = Mailglass.WebhookCase.mailglass_webhook_conn(:resend, raw_body)
      tampered_conn = Plug.Conn.put_private(conn, :raw_body, raw_body <> "tampered")

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(tampered_conn, WebhookPlug.init(provider: :resend))
        end)

      assert result.status == 401
      assert log =~ "provider=resend"
      refute log =~ raw_body
    end

    test "returns 401 when the Resend svix-timestamp is stale" do
      raw_body = Mailglass.WebhookCase.stub_resend_fixture("delivered")
      stale_ts = Integer.to_string(System.system_time(:second) - 400)
      svix_id = "msg_stale_#{System.unique_integer([:positive])}"

      secret_bytes =
        case Application.fetch_env(:mailglass, :resend) do
          {:ok, cfg} ->
            "whsec_" <> encoded = Keyword.fetch!(cfg, :secret)
            Base.decode64!(encoded)

          :error ->
            :crypto.strong_rand_bytes(32)
        end

      sig = Mailglass.WebhookFixtures.sign_resend_payload(svix_id, stale_ts, raw_body, secret_bytes)

      conn =
        :post
        |> Plug.Test.conn("/webhooks/resend", raw_body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_private(:raw_body, raw_body)
        |> Plug.Conn.put_req_header("svix-id", svix_id)
        |> Plug.Conn.put_req_header("svix-timestamp", stale_ts)
        |> Plug.Conn.put_req_header("svix-signature", "v1," <> sig)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :resend))
        end)

      assert result.status == 401
      assert log =~ "provider=resend"
      refute log =~ raw_body
    end

    test "returns 401 when svix-id header is missing" do
      raw_body = Mailglass.WebhookCase.stub_resend_fixture("delivered")
      svix_timestamp = Integer.to_string(System.system_time(:second))

      conn =
        :post
        |> Plug.Test.conn("/webhooks/resend", raw_body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_private(:raw_body, raw_body)
        |> Plug.Conn.put_req_header("svix-timestamp", svix_timestamp)
        |> Plug.Conn.put_req_header("svix-signature", "v1,invalidsig")

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :resend))
        end)

      assert result.status == 401
      assert log =~ "provider=resend"
      refute log =~ raw_body
    end
  end

  describe "call/2 Resend explicit route execution" do
    test "init/1 accepts :resend as an explicit provider" do
      assert Keyword.get(WebhookPlug.init(provider: :resend), :provider) == :resend
    end
  end
end
