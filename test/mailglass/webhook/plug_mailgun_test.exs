defmodule Mailglass.Webhook.PlugMailgunTest do
  use Mailglass.WebhookCase, async: false

  test "WebhookCase can build a signed Mailgun conn from raw bytes" do
    raw_body = stub_mailgun_fixture("accepted")

    conn = mailglass_webhook_conn(:mailgun, raw_body)

    assert conn.request_path == "/webhooks/mailgun"
    assert conn.private[:raw_body] == conn.assigns[:mailgun_signed_body]
  end

  describe "call/2 Mailgun replay response" do
  end

  describe "call/2 Mailgun bad signature response" do
  end

  describe "call/2 Mailgun missing config response" do
  end

  describe "call/2 Mailgun explicit route execution" do
  end
end
