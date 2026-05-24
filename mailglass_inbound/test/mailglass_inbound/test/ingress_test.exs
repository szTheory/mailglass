defmodule MailglassInbound.Test.IngressTest do
  # async: false — these tests share a sandboxed `MailglassInbound.TestRepo`
  # connection (shared-mode owner) and write real inbound records, so they run
  # serially against the single test DB (mirrors the convergence proof's
  # discipline). The SES path also primes the process-global CertCache ETS via
  # Fixtures, so keeping the file serial keeps that deterministic.
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.Fixtures
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Router.Route
  alias MailglassInbound.Test.Ingress
  alias MailglassInbound.TestRepo

  # A mailbox that matches anything (nil recipient/subject) and accepts.
  defmodule AcceptMailbox do
    @behaviour MailglassInbound.Mailbox
    @impl true
    def process(_message), do: :accept
  end

  setup do
    owner = Sandbox.start_owner!(TestRepo, shared: true)
    truncate_all()

    on_exit(fn ->
      # The connection may already be down when the owner is stopped after a
      # failed assertion; guard so cleanup never masks the real failure.
      try do
        Sandbox.stop_owner(owner)
      rescue
        _ -> :ok
      end
    end)

    :ok
  end

  describe "receive_inbound/2" do
    test "drives the real persist+execute path and captures {:inbound, msg, outcome, route}" do
      message = Fixtures.build_inbound_message()

      assert {:ok, %{message: ^message, outcome: outcome, route: route, persisted: persisted}} =
               Ingress.receive_inbound(message, repo: TestRepo, routes: accept_routes())

      # The capture seam fired in this process.
      assert_received {:inbound, ^message, ^outcome, ^route}

      # Default outcome with no matching route is :no_match; with a matching
      # accept route it is :accept. We routed to AcceptMailbox above.
      assert %{outcome: :accept} = outcome
      assert %{status: :matched, mailbox: AcceptMailbox} = route
      assert persisted.status == :inserted
    end

    test "with no routes the captured route is :no_match" do
      message = Fixtures.build_inbound_message()

      assert {:ok, %{route: %{status: :no_match}, outcome: %{outcome: :no_match}}} =
               Ingress.receive_inbound(message, repo: TestRepo)

      assert_received {:inbound, ^message, %{outcome: :no_match}, %{status: :no_match}}
    end

    test "replaying the same message converges to 1 record + 1 fresh run (id dedupe)" do
      message = Fixtures.build_inbound_message(provider_message_id: "converge-1")

      for _ <- 1..3 do
        assert {:ok, _} = Ingress.receive_inbound(message, repo: TestRepo, routes: accept_routes())
      end

      assert record_count() == 1
      assert fresh_run_count() == 1
    end

    # WR-06: the documented raw_mime-dedupe contract for receive_inbound/2.
    # SendGrid keys dedupe on md5(evidence.raw_mime) (persist.ex load_duplicate),
    # NOT on provider_message_id, so the caller must pass evidence: %{raw_mime: ...}.
    # The id-dedupe convergence test above does not exercise that path.
    test "SendGrid raw_mime replay via receive_inbound/2 converges (evidence: raw_mime dedupe)" do
      message = Fixtures.build_inbound_message(provider: :sendgrid)
      raw_mime = "Message-ID: <wr06-converge@example.com>\r\nSubject: hi\r\n\r\nbody"

      for _ <- 1..3 do
        assert {:ok, _} =
                 Ingress.receive_inbound(message,
                   repo: TestRepo,
                   routes: accept_routes(),
                   evidence: %{raw_mime: raw_mime}
                 )
      end

      assert record_count() == 1
      assert fresh_run_count() == 1
    end

    test "two distinct raw_mime payloads produce two records (fingerprint discriminates)" do
      # Real SendGrid carries no provider_message_id, so dedupe is raw_mime-only;
      # model that (nil id) so the only discriminator under test is the
      # md5(raw_mime) fingerprint, not the provider-id unique index.
      base = Fixtures.build_inbound_message(provider: :sendgrid, provider_message_id: nil)

      assert {:ok, _} =
               Ingress.receive_inbound(base,
                 repo: TestRepo,
                 routes: accept_routes(),
                 evidence: %{raw_mime: "Message-ID: <wr06-a@example.com>\r\n\r\nfirst"}
               )

      assert {:ok, _} =
               Ingress.receive_inbound(base,
                 repo: TestRepo,
                 routes: accept_routes(),
                 evidence: %{raw_mime: "Message-ID: <wr06-b@example.com>\r\n\r\nsecond"}
               )

      assert record_count() == 2
      assert fresh_run_count() == 2
    end
  end

  describe "receive_provider_payload/3" do
    test "runs the real Postmark verify!/normalize seam then captures the tuple" do
      raw = Fixtures.build_postmark_payload(subject: "Provider seam")

      assert {:ok, %{outcome: outcome, route: route}} =
               Ingress.receive_provider_payload(:postmark, raw, postmark_opts())

      assert_received {:inbound, _msg, ^outcome, ^route}
      assert %{outcome: :accept} = outcome
    end

    test "Postmark provider-id dedupe converges on replay" do
      raw = Fixtures.build_postmark_payload(provider_message_id: "pm-converge")

      for _ <- 1..3 do
        assert {:ok, _} = Ingress.receive_provider_payload(:postmark, raw, postmark_opts())
      end

      assert record_count() == 1
      assert fresh_run_count() == 1
    end

    test "SES raw_mime dedupe converges on replay (Pitfall 5)" do
      payload = Fixtures.build_ses_sns_payload(provider_message_id: "ses-converge")

      for _ <- 1..2 do
        assert {:ok, _} =
                 Ingress.receive_provider_payload(:ses, payload,
                   repo: TestRepo,
                   tenant_id: "provider-tenant",
                   routes: accept_routes()
                 )
      end

      assert record_count() == 1
      assert fresh_run_count() == 1
    end

    # WR-08 (the gap that let CR-01 ship): the SendGrid round-trip was only ever
    # tested through direct `Sendgrid.normalize/1`, never through the driver's
    # real `verify!`-first seam. This drives the full verify!-then-normalize seam
    # with the shipped fixture and asserts it composes out of the box — it failed
    # before the CR-01 fix (the driver dropped opts[:headers] and the fixture
    # carried no `authorization` header) and passes after it.
    test "runs the real SendGrid verify!/normalize seam out of the box (CR-01/WR-08)" do
      payload = Fixtures.build_sendgrid_payload(subject: "SendGrid seam")

      assert {:ok, %{outcome: outcome, route: route}} =
               Ingress.receive_provider_payload(:sendgrid, payload,
                 repo: TestRepo,
                 tenant_id: "provider-tenant",
                 routes: accept_routes()
               )

      assert_received {:inbound, _msg, ^outcome, ^route}
      assert %{outcome: :accept} = outcome
    end

    # WR-08: SendGrid dedupes on md5(raw_mime), so two drives of the SAME fixture
    # converge to one record + one fresh run through the real verify!-first seam.
    test "SendGrid raw_mime dedupe converges on replay through the verify! seam" do
      payload = Fixtures.build_sendgrid_payload(provider_message_id: "sg-converge")

      for _ <- 1..2 do
        assert {:ok, _} =
                 Ingress.receive_provider_payload(:sendgrid, payload,
                   repo: TestRepo,
                   tenant_id: "provider-tenant",
                   routes: accept_routes()
                 )
      end

      assert record_count() == 1
      assert fresh_run_count() == 1
    end

    # WR-08 (the gap that let CR-01 ship): Mailgun was only ever tested through
    # direct `Mailgun.normalize/1`, never through the driver's real `verify!`-first
    # seam. The shipped fixture now HMAC-signs the timestamp/token/signature
    # triple against the documented default signing key, so the real `verify!`
    # passes out of the box — it raised `:missing_header` before the CR-01 fix.
    test "runs the real Mailgun verify!/normalize seam out of the box (CR-01/WR-08)" do
      payload = Fixtures.build_mailgun_payload(subject: "Mailgun seam")

      assert {:ok, %{outcome: outcome, route: route}} =
               Ingress.receive_provider_payload(:mailgun, payload,
                 repo: TestRepo,
                 tenant_id: "provider-tenant",
                 routes: accept_routes()
               )

      assert_received {:inbound, _msg, ^outcome, ^route}
      assert %{outcome: :accept} = outcome
    end
  end

  defp accept_routes, do: [%Route{mailbox: AcceptMailbox}]

  # Postmark verify! is real (T-47-11, never weakened): it requires a
  # basic_auth config AND a matching `authorization` header on the request.
  # Supply valid credentials + the matching Basic header so the real verifier
  # passes.
  defp postmark_opts do
    user = "pm-user"
    pass = "pm-pass"
    encoded = Base.encode64("#{user}:#{pass}")

    [
      repo: TestRepo,
      tenant_id: "provider-tenant",
      routes: accept_routes(),
      config: %{basic_auth: {user, pass}},
      headers: [{"authorization", "Basic #{encoded}"}]
    ]
  end

  defp record_count, do: TestRepo.aggregate(InboundRecord, :count)

  defp fresh_run_count do
    TestRepo.aggregate(from(r in ExecutionRun, where: r.source == :fresh), :count)
  end

  defp truncate_all do
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_records CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_replay_runs CASCADE", [])
  end
end
