defmodule Mailglass.Webhook.PlugMailgunTest do
  use Mailglass.WebhookCase, async: false

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
    @tag :skip
    test "returns 200 on a valid signed Mailgun request" do
      flunk("implemented in Task 3 after runtime wiring lands")
    end

    @tag :skip
    test "returns 200 on a replayed Mailgun request" do
      flunk("implemented in Task 3 after runtime wiring lands")
    end
  end

  describe "call/2 Mailgun bad signature response" do
    @tag :skip
    test "returns 401 when the Mailgun signature is invalid" do
      flunk("implemented in Task 3 after runtime wiring lands")
    end
  end

  describe "call/2 Mailgun missing config response" do
    @tag :skip
    test "returns 500 when Mailgun signing config is missing" do
      flunk("implemented in Task 3 after runtime wiring lands")
    end
  end

  describe "call/2 Mailgun explicit route execution" do
  end
end
