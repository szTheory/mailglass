defmodule MailglassInbound.FixturesTest do
  # async: false — the SES self-tests prime the process-global CertCache ETS and
  # the SendGrid/Mailgun/Postmark round-trips touch no shared state, but keeping
  # the whole file serial keeps the cert-cache priming deterministic alongside
  # the unique-cert-URL guard (Pitfall 2 belt-and-suspenders).
  use ExUnit.Case, async: false

  alias MailglassInbound.Fixtures
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Ingress.Providers.{Mailgun, Postmark, Sendgrid}
  alias MailglassInbound.Ingress.Request

  describe "build_inbound_message/1" do
    test "returns a valid %InboundMessage{} with a defaulted tenant_id and address-shaped lists" do
      message = Fixtures.build_inbound_message()

      assert %InboundMessage{} = message
      # Default tenant_id is non-nil so a test cannot accidentally assert across
      # tenants (security V4, T-47-04).
      assert is_binary(message.tenant_id)
      assert message.tenant_id != ""
      assert message.provider != nil
      assert is_binary(message.provider_message_id)
      # Address shape is %{address: ...} (convergence test :170-177).
      assert [%{address: from_address}] = message.from
      assert is_binary(from_address)
      assert [%{address: to_address}] = message.to
      assert is_binary(to_address)
    end

    test "honors overridable opts" do
      message =
        Fixtures.build_inbound_message(
          tenant_id: "acme",
          provider: :sendgrid,
          subject: "Custom subject",
          text_body: "Custom body",
          html_body: "<p>Custom</p>",
          envelope_recipient: "ops@example.test"
        )

      assert message.tenant_id == "acme"
      assert message.provider == :sendgrid
      assert message.subject == "Custom subject"
      assert message.text_body == "Custom body"
      assert message.html_body == "<p>Custom</p>"
      assert message.envelope_recipient == "ops@example.test"
    end
  end

  describe "build_postmark_payload/1" do
    test "round-trips through the real Postmark.normalize/2 to a valid %InboundMessage{}" do
      raw_body = Fixtures.build_postmark_payload(subject: "Postmark inbound")

      assert is_binary(raw_body)

      %{message: message, evidence: evidence} = Postmark.normalize(raw_body, [])

      assert %InboundMessage{provider: :postmark} = message
      assert message.subject == "Postmark inbound"
      assert is_binary(message.provider_message_id)
      assert [%{address: _}] = message.from
      assert [%{address: _}] = message.to
      assert is_map(evidence)
    end
  end

  describe "build_sendgrid_payload/1" do
    test "round-trips through the real SendGrid verify!/normalize to a valid %InboundMessage{}" do
      %{raw_mime: raw_mime, headers: headers, params: params} =
        Fixtures.build_sendgrid_payload(subject: "SendGrid inbound", recipient: "support@example.test")

      assert is_binary(raw_mime)
      assert raw_mime != ""

      request = %Request{provider: :sendgrid, raw_mime: raw_mime, headers: headers, params: params}

      %{message: message, evidence: evidence} = Sendgrid.normalize(request)

      assert %InboundMessage{provider: :sendgrid} = message
      assert message.subject == "SendGrid inbound"
      # The raw MIME is exposed for the dedupe key (md5(raw_mime)) — Pitfall 5.
      assert evidence.raw_mime == raw_mime
      assert [%{address: _}] = message.to
    end
  end

  describe "build_mailgun_payload/1" do
    test "round-trips through the real Mailgun.normalize to a valid %InboundMessage{}" do
      %{params: params, headers: headers} =
        Fixtures.build_mailgun_payload(subject: "Mailgun inbound", recipient: "support@example.test")

      assert is_map(params)

      request = %Request{provider: :mailgun, headers: headers, params: params}

      %{message: message} = Mailgun.normalize(request)

      assert %InboundMessage{provider: :mailgun} = message
      assert message.subject == "Mailgun inbound"
      assert message.envelope_recipient == "support@example.test"
    end
  end
end
