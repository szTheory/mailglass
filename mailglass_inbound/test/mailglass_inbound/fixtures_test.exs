defmodule MailglassInbound.FixturesTest do
  # async: false — the SES self-tests prime the process-global CertCache ETS and
  # the SendGrid/Mailgun/Postmark round-trips touch no shared state, but keeping
  # the whole file serial keeps the cert-cache priming deterministic alongside
  # the unique-cert-URL guard (Pitfall 2 belt-and-suspenders).
  use ExUnit.Case, async: false

  alias MailglassInbound.Fixtures
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Ingress.Providers.{Mailgun, Postmark, Sendgrid, SES}
  alias MailglassInbound.Ingress.Request
  alias MailglassInbound.S3Fetcher
  alias Mailglass.Webhook.Providers.SES.CertCache

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
        Fixtures.build_sendgrid_payload(
          subject: "SendGrid inbound",
          recipient: "support@example.test"
        )

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
        Fixtures.build_mailgun_payload(
          subject: "Mailgun inbound",
          recipient: "support@example.test"
        )

      assert is_map(params)

      request = %Request{provider: :mailgun, headers: headers, params: params}

      %{message: message} = Mailgun.normalize(request)

      assert %InboundMessage{provider: :mailgun} = message
      assert message.subject == "Mailgun inbound"
      assert message.envelope_recipient == "support@example.test"
    end
  end

  describe "build_ses_sns_payload/1" do
    setup do
      # The builder primes the process-global CertCache ETS and the process-dict
      # S3Fetcher.Fake; reset both so each test starts clean (ses_provider_test.exs:26-28).
      CertCache.reset()
      S3Fetcher.Fake.reset()
      :ok
    end

    test "the built X.509-signed SNS payload passes the real SES.verify! via the primed CertCache" do
      %{raw_body: raw_body, headers: headers, config: config} =
        Fixtures.build_ses_sns_payload(subject: "SES inbound")

      assert is_binary(raw_body)
      request = %Request{provider: :ses, raw_body: raw_body, headers: headers}

      # Real verifier — does NOT raise because the fixture primed the real CertCache.
      assert {:ok, verified_request} = SES.verify!(request, config)
      assert verified_request.verification_facts.auth == :sns_x509

      resolved_request = SES.resolve_content!(verified_request, config)
      %{message: message, evidence: evidence} = SES.normalize(resolved_request)
      assert %InboundMessage{provider: :ses} = message
      assert message.subject == "SES inbound"
      # The Action:S3 body path served the raw MIME via the primed S3Fetcher.Fake.
      assert is_binary(evidence.raw_mime)
      assert evidence.raw_mime != ""
    end

    test "mints a per-call unique cert URL so concurrent primes do not collide" do
      %{raw_body: raw_one} = Fixtures.build_ses_sns_payload()
      %{raw_body: raw_two} = Fixtures.build_ses_sns_payload()

      cert_url_one = Jason.decode!(raw_one)["SigningCertURL"]
      cert_url_two = Jason.decode!(raw_two)["SigningCertURL"]

      assert cert_url_one != cert_url_two
      # Both must still satisfy the SNS cert-host TrustPolicy (sns.<region>.amazonaws.com/*.pem).
      assert String.starts_with?(cert_url_one, "https://sns.")
      assert String.ends_with?(cert_url_one, ".pem")
    end

    test "a forged signature against the same envelope fails the real verifier" do
      # Build a legitimate payload, then re-sign nothing — swap the Signature for
      # garbage. The real verifier must reject it (proves verify! is genuinely
      # exercising the signature, not a stub).
      %{raw_body: raw_body, headers: headers, config: config} = Fixtures.build_ses_sns_payload()

      forged =
        raw_body
        |> Jason.decode!()
        |> Map.put("Signature", Base.encode64("not-a-real-signature"))
        |> Jason.encode!()

      request = %Request{provider: :ses, raw_body: forged, headers: headers}

      assert_raise MailglassInbound.SignatureError, fn -> SES.verify!(request, config) end
    end
  end
end
