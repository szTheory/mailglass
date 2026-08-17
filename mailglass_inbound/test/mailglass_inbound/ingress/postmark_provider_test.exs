defmodule MailglassInbound.Ingress.PostmarkProviderTest do
  use ExUnit.Case, async: true

  alias Mailglass.SignatureError
  alias MailglassInbound.Ingress.Providers.Postmark

  test "verifies basic auth and optional allowlist" do
    facts =
      Postmark.verify!(
        postmark_payload(),
        [{"authorization", basic_auth("postmark", "secret")}],
        %{
          basic_auth: {"postmark", "secret"},
          ip_allowlist: ["127.0.0.0/24"],
          remote_ip: {127, 0, 0, 1}
        }
      )

    assert facts.auth == :basic_auth
    assert facts.ip_allowlist == :matched
  end

  test "fails closed on bad credentials" do
    assert_raise SignatureError, fn ->
      Postmark.verify!(
        postmark_payload(),
        [{"authorization", basic_auth("wrong", "secret")}],
        %{basic_auth: {"postmark", "secret"}, ip_allowlist: []}
      )
    end
  end

  test "normalizes into the locked inbound message shape and keeps blobs in evidence" do
    %{message: message, evidence: evidence} =
      Postmark.normalize(postmark_payload(), [{"content-type", "application/json"}])

    assert message.provider == :postmark
    assert message.provider_message_id == "pm-message-123"
    assert message.message_id == "<rfc-message@example.com>"
    assert message.envelope_recipient == "support@example.com"
    assert [%{address: "sender@example.com", name: "Sender"}] = message.from
    assert [%{address: "support@example.com", name: "Support"}] = message.to
    assert [%{address: "reply@example.com", name: "Reply"}] = message.reply_to
    assert message.subject == "Support request"
    assert message.text_body == "Plain body"
    assert message.html_body == "<p>HTML body</p>"
    assert get_in(message.headers, ["message-id"]) == ["<rfc-message@example.com>"]
    assert [%{filename: "invoice.txt", content_type: "text/plain"}] = message.attachments

    refute Map.has_key?(message, :attachment_blobs)
    assert evidence.raw_payload["MessageID"] == "pm-message-123"
    assert is_binary(evidence.attachment_blobs["0:invoice.txt"])
    assert evidence.raw_mime == nil
  end

  defp basic_auth(user, pass) do
    "Basic " <> Base.encode64("#{user}:#{pass}")
  end

  defp postmark_payload do
    Jason.encode!(%{
      "FromFull" => [%{"Email" => "sender@example.com", "Name" => "Sender"}],
      "ToFull" => [%{"Email" => "support@example.com", "Name" => "Support"}],
      "CcFull" => [],
      "BccFull" => [],
      "ReplyToFull" => [%{"Email" => "reply@example.com", "Name" => "Reply"}],
      "Subject" => "Support request",
      "MessageID" => "pm-message-123",
      "OriginalRecipient" => "support@example.com",
      "TextBody" => "Plain body",
      "HtmlBody" => "<p>HTML body</p>",
      "Headers" => [
        %{"Name" => "Message-Id", "Value" => "<rfc-message@example.com>"},
        %{"Name" => "Date", "Value" => "2026-05-06T12:00:00Z"}
      ],
      "Attachments" => [
        %{
          "Name" => "invoice.txt",
          "ContentType" => "text/plain",
          "ContentDisposition" => "attachment",
          "ContentID" => "cid-1",
          "Content" => Base.encode64("invoice-bytes")
        }
      ]
    })
  end
end
