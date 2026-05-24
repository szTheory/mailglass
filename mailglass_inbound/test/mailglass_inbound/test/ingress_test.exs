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
  end

  describe "receive_provider_payload/3" do
    test "runs the real Postmark verify!/normalize seam then captures the tuple" do
      raw = Fixtures.build_postmark_payload(subject: "Provider seam")

      assert {:ok, %{outcome: outcome, route: route}} =
               Ingress.receive_provider_payload(:postmark, raw,
                 repo: TestRepo,
                 tenant_id: "provider-tenant",
                 routes: accept_routes()
               )

      assert_received {:inbound, _msg, ^outcome, ^route}
      assert %{outcome: :accept} = outcome
    end

    test "Postmark provider-id dedupe converges on replay" do
      raw = Fixtures.build_postmark_payload(provider_message_id: "pm-converge")

      for _ <- 1..3 do
        assert {:ok, _} =
                 Ingress.receive_provider_payload(:postmark, raw,
                   repo: TestRepo,
                   tenant_id: "provider-tenant",
                   routes: accept_routes()
                 )
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
  end

  defp accept_routes, do: [%Route{mailbox: AcceptMailbox}]

  defp record_count, do: TestRepo.aggregate(InboundRecord, :count)

  defp fresh_run_count do
    TestRepo.aggregate(from(r in ExecutionRun, where: r.source == :fresh), :count)
  end

  defp truncate_all do
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_records CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_replay_runs CASCADE", [])
  end
end
