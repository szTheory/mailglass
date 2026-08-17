defmodule MailglassInbound.Ingress.SendgridProviderTest do
  use ExUnit.Case, async: true

  alias Mailglass.{ConfigError, SignatureError}
  alias MailglassInbound.Ingress.Providers.Sendgrid
  alias MailglassInbound.Ingress.Request

  test "verifies shared-secret basic auth and fails closed on bad credentials" do
    request = sendgrid_request(headers: [{"authorization", basic_auth("sendgrid", "secret")}])

    facts = Sendgrid.verify!(request, %{basic_auth: {"sendgrid", "secret"}})

    assert facts.auth == :basic_auth

    assert_raise SignatureError, fn ->
      request
      |> Map.put(:headers, [{"authorization", basic_auth("wrong", "secret")}])
      |> Sendgrid.verify!(%{basic_auth: {"sendgrid", "secret"}})
    end
  end

  test "requires the raw email MIME part with operator-helpful guidance" do
    assert_raise ConfigError, ~r/raw MIME/i, fn ->
      sendgrid_request(raw_mime: nil)
      |> Sendgrid.normalize()
    end
  end

  test "normalizes into the locked inbound message shape using message-id and provider envelope" do
    %{message: message} = Sendgrid.normalize(sendgrid_request())

    assert message.provider == :sendgrid
    assert message.provider_message_id == nil
    assert message.message_id == "<rfc-message@example.com>"
    assert message.envelope_recipient == "support@example.com"
    assert [%{address: "sender@example.com", name: "Sender"}] = message.from
    assert [%{address: "support@example.com", name: "Support"}] = message.to
    assert [%{address: "carbon@example.com", name: "Carbon"}] = message.cc
    assert [%{address: "blind@example.com", name: "Blind"}] = message.bcc
    assert [%{address: "reply@example.com", name: "Reply"}] = message.reply_to
    assert message.subject == "Support request"
    assert message.text_body == "Plain body\r\n"
    assert message.html_body == "<p>HTML body</p>\r\n"
    assert get_in(message.headers, ["message-id"]) == ["<rfc-message@example.com>"]
  end

  test "keeps provider-only multipart fields, auth verdicts, raw mime, and blobs in evidence" do
    %{message: message, evidence: evidence} = Sendgrid.normalize(sendgrid_request())

    assert [
             %{
               filename: "invoice.txt",
               content_type: "text/plain",
               disposition: :attachment,
               content_id: "cid-1"
             }
           ] =
             message.attachments

    refute Map.has_key?(message, :spam_score)
    refute Map.has_key?(message, :attachment_blobs)
    refute Map.has_key?(message, :raw_mime)

    assert evidence.raw_mime == raw_mime()
    assert evidence.raw_payload["spam_score"] == "0.001"
    assert evidence.raw_payload["charsets"] == "{\"to\":\"UTF-8\"}"
    assert evidence.verification_facts == %{}
    assert evidence.attachment_blobs["1:invoice.txt"] == "invoice-bytes\r\n"
  end

  defp sendgrid_request(overrides \\ []) do
    base = %Request{
      provider: :sendgrid,
      headers: [{"content-type", "multipart/form-data; boundary=boundary42"}],
      params: %{
        "from" => "Sender <sender@example.com>",
        "to" => "Support <support@example.com>",
        "cc" => "Carbon <carbon@example.com>",
        "bcc" => "Blind <blind@example.com>",
        "subject" => "Support request",
        "spam_score" => "0.001",
        "SPF" => "pass",
        "dkim" => "{@example.com : pass}",
        "charsets" => "{\"to\":\"UTF-8\"}",
        "envelope" => Jason.encode!(%{"to" => ["support@example.com"]})
      },
      raw_mime: raw_mime(),
      content_type: "multipart/form-data"
    }

    Enum.reduce(overrides, base, fn {key, value}, acc -> Map.put(acc, key, value) end)
  end

  defp basic_auth(user, pass) do
    "Basic " <> Base.encode64("#{user}:#{pass}")
  end

  defp raw_mime do
    [
      "From: Sender <sender@example.com>\r\n",
      "To: Support <support@example.com>\r\n",
      "Cc: Carbon <carbon@example.com>\r\n",
      "Bcc: Blind <blind@example.com>\r\n",
      "Reply-To: Reply <reply@example.com>\r\n",
      "Subject: Support request\r\n",
      "Message-ID: <rfc-message@example.com>\r\n",
      "Date: Tue, 06 May 2026 12:00:00 +0000\r\n",
      "MIME-Version: 1.0\r\n",
      "Content-Type: multipart/mixed; boundary=boundary42\r\n",
      "\r\n",
      "--boundary42\r\n",
      "Content-Type: multipart/alternative; boundary=alt42\r\n",
      "\r\n",
      "--alt42\r\n",
      "Content-Type: text/plain; charset=UTF-8\r\n",
      "\r\n",
      "Plain body\r\n",
      "--alt42\r\n",
      "Content-Type: text/html; charset=UTF-8\r\n",
      "\r\n",
      "<p>HTML body</p>\r\n",
      "--alt42--\r\n",
      "--boundary42\r\n",
      "Content-Type: text/plain; name=invoice.txt\r\n",
      "Content-Disposition: attachment; filename=invoice.txt\r\n",
      "Content-ID: <cid-1>\r\n",
      "\r\n",
      "invoice-bytes\r\n",
      "--boundary42--\r\n"
    ]
    |> IO.iodata_to_binary()
  end
end
