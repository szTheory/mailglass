defmodule MailglassInbound.TelemetryTest do
  @moduledoc """
  Coverage for the four inbound spans (TELE-01..04), telemetry handler
  raise-safety (TELE-05), and the post-commit PubSub broadcast (TELE-07).

  All assertions verify that inbound telemetry metadata is PII-free (D-45-03):
  the only keys allowed are provider, tenant_id, status, latency, byte_size,
  mailbox, candidate_count, outcome, source, operation, record_type.
  """
  use ExUnit.Case, async: false

  alias MailglassInbound.Execution
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Ingress.Persist
  alias MailglassInbound.Ingress.Plug, as: IngressPlug
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.PubSub.Topics
  alias MailglassInbound.Router.Matcher
  alias MailglassInbound.Router.Route

  # Keys that must NEVER appear in any inbound telemetry metadata map (D-45-03).
  @forbidden_meta_keys [
    :to,
    :from,
    :cc,
    :bcc,
    :subject,
    :body,
    :html_body,
    :headers,
    :recipient,
    :sender,
    :email
  ]

  defmodule SupportMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule TenantResolver do
    @behaviour Mailglass.Tenancy

    def scope(query, _context), do: query
    def resolve_outbound_adapter_ref(_context), do: :default

    def resolve_webhook_tenant(%{path_params: %{"tenant_id" => tenant_id}})
        when is_binary(tenant_id) and tenant_id != "",
        do: {:ok, tenant_id}

    def resolve_webhook_tenant(_context), do: {:error, :missing_path_param}
  end

  defmodule TestRouter do
    use MailglassInbound.Router

    route(SupportMailbox, recipient: "support@example.com")
  end

  defmodule RecordingInboundRecords do
    def insert_execution_run(attrs, _opts \\ []), do: {:ok, attrs}
  end

  defmodule FakeRepo do
    def transact(fun, _opts \\ []), do: fun.()
    def one(_query, _opts \\ []), do: Process.get(:mailglass_inbound_duplicate_record)

    def insert(changeset, _opts \\ []) do
      struct =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> ensure_id()

      {:ok, struct}
    end

    defp ensure_id(%{id: nil} = struct), do: %{struct | id: Ecto.UUID.generate()}
    defp ensure_id(struct), do: struct
  end

  defmodule FakePersistence do
    def persist(handoff, _opts) do
      status = Process.get(:mailglass_inbound_persist_status, :inserted)

      {:ok,
       %{
         status: status,
         message: handoff.message,
         inbound_record: %{id: "record-123", tenant_id: handoff.tenant_id},
         inbound_evidence: %{id: "evidence-123"},
         route: %{status: :matched, mailbox: SupportMailbox}
       }}
    end
  end

  defmodule FakeExecution do
    def dispatch(_result, _opts \\ []), do: {:ok, %{status: :queued, mode: :oban}}
  end

  setup do
    # Mailglass.PubSub is started by the core Mailglass.Application; if it is not
    # already running in this test env, start it under the test supervisor so the
    # broadcast assertions have a server to fan out through.
    unless Process.whereis(Mailglass.PubSub) do
      start_supervised!({Phoenix.PubSub, name: Mailglass.PubSub})
    end

    prior_tenancy = Application.get_env(:mailglass, :tenancy)
    prior_postmark = Application.get_env(:mailglass_inbound, :postmark)

    Application.put_env(:mailglass, :tenancy, TenantResolver)

    Application.put_env(:mailglass_inbound, :postmark,
      basic_auth: {"postmark", "secret"},
      ip_allowlist: []
    )

    Process.delete(:mailglass_inbound_persist_status)
    Process.delete(:mailglass_inbound_duplicate_record)

    on_exit(fn ->
      restore_env(:mailglass, :tenancy, prior_tenancy)
      restore_env(:mailglass_inbound, :postmark, prior_postmark)
    end)

    :ok
  end

  describe "TELE-02 route span" do
    test "a matched route emits start+stop with {mailbox, candidate_count}, no PII" do
      attach([
        [:mailglass_inbound, :route, :match, :start],
        [:mailglass_inbound, :route, :match, :stop]
      ])

      routes = [%Route{mailbox: SupportMailbox, recipient: "support@example.com"}]
      assert {:ok, %Route{mailbox: SupportMailbox}} = Matcher.match(routes, message())

      assert_receive {[:mailglass_inbound, :route, :match, :start], _measure, start_meta}
      assert_receive {[:mailglass_inbound, :route, :match, :stop], stop_measure, stop_meta}

      assert start_meta.candidate_count == 1
      assert stop_meta.mailbox == SupportMailbox
      assert stop_meta.candidate_count == 1
      assert Map.has_key?(stop_measure, :duration)
      assert_pii_free(stop_meta)
    end

    test "a no-match emits stop meta {status: :no_match, candidate_count}" do
      attach([[:mailglass_inbound, :route, :match, :stop]])

      routes = [%Route{mailbox: SupportMailbox, recipient: "nobody@example.com"}]
      assert :no_match = Matcher.match(routes, message())

      assert_receive {[:mailglass_inbound, :route, :match, :stop], _measure, stop_meta}
      assert stop_meta.status == :no_match
      assert stop_meta.candidate_count == 1
      assert_pii_free(stop_meta)
    end
  end

  describe "TELE-04 persist span" do
    test "a fresh payload emits operation: :insert; record_type inbound_record" do
      attach([[:mailglass_inbound, :persist, :record, :stop]])
      Process.delete(:mailglass_inbound_duplicate_record)

      {:ok, result} = Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)
      assert result.status == :inserted

      assert_receive {[:mailglass_inbound, :persist, :record, :stop], _measure, stop_meta}
      assert stop_meta.operation == :insert
      assert stop_meta.record_type == "inbound_record"
      assert stop_meta.provider == "postmark"
      assert stop_meta.tenant_id == "tenant-123"
      assert_pii_free(stop_meta)
    end

    test "a duplicate emits operation: :dedup_skip" do
      attach([[:mailglass_inbound, :persist, :record, :stop]])

      Process.put(:mailglass_inbound_duplicate_record, %InboundRecord{
        id: Ecto.UUID.generate(),
        tenant_id: "tenant-123",
        provider: "postmark",
        provider_message_id: "pm-message-123",
        envelope_recipient: "support@example.com",
        received_at: DateTime.utc_now()
      })

      {:ok, result} = Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)
      assert result.status == :duplicate

      assert_receive {[:mailglass_inbound, :persist, :record, :stop], _measure, stop_meta}
      assert stop_meta.operation == :dedup_skip
      assert_pii_free(stop_meta)
    end
  end

  describe "TELE-03 execution span" do
    test "an :inserted record emits stop meta {mailbox, outcome, source}, no PII" do
      attach([
        [:mailglass_inbound, :execution, :run, :start],
        [:mailglass_inbound, :execution, :run, :stop]
      ])

      assert {:ok, %{outcome: :accept}} =
               Execution.execute(persisted_payload(), inbound_records: RecordingInboundRecords)

      assert_receive {[:mailglass_inbound, :execution, :run, :start], _m1, _start_meta}
      assert_receive {[:mailglass_inbound, :execution, :run, :stop], _m2, stop_meta}

      assert stop_meta.mailbox == Atom.to_string(SupportMailbox)
      assert stop_meta.outcome == :accept
      assert stop_meta.source == :fresh
      assert_pii_free(stop_meta)
    end

    test "the :duplicate short-circuit emits NO execution span and inserts no run" do
      attach([
        [:mailglass_inbound, :execution, :run, :start],
        [:mailglass_inbound, :execution, :run, :stop]
      ])

      assert {:ok, %{status: :skipped}} =
               Execution.execute(%{status: :duplicate}, inbound_records: RecordingInboundRecords)

      refute_receive {[:mailglass_inbound, :execution, :run, :start], _m, _meta}
      refute_receive {[:mailglass_inbound, :execution, :run, :stop], _m, _meta}
    end
  end

  describe "TELE-01 ingress span" do
    test "a posted ingress request emits the span pair once with {provider, tenant_id, status, byte_size}" do
      attach([
        [:mailglass_inbound, :ingress, :request, :start],
        [:mailglass_inbound, :ingress, :request, :stop]
      ])

      conn = drive_ingress()
      assert conn.status == 200

      assert_receive {[:mailglass_inbound, :ingress, :request, :start], _m1, start_meta}
      assert_receive {[:mailglass_inbound, :ingress, :request, :stop], stop_measure, stop_meta}
      # exactly once
      refute_receive {[:mailglass_inbound, :ingress, :request, :stop], _m, _meta}

      assert start_meta.provider == :postmark
      assert stop_meta.provider == :postmark
      assert stop_meta.tenant_id == "tenant-123"
      assert stop_meta.status == :inserted
      assert is_integer(stop_meta.byte_size) and stop_meta.byte_size > 0
      assert Map.has_key?(stop_measure, :duration)
      assert_pii_free(stop_meta)
    end
  end

  describe "TELE-05 handler raise-safety" do
    test "a raising telemetry handler does not break the inbound pipeline" do
      handler_id = "raising-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:mailglass_inbound, :ingress, :request, :stop],
        fn _event, _measure, _meta, _config -> raise "handler boom" end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      conn = drive_ingress()

      # The pipeline still returns its normal success result despite the raising
      # handler (:telemetry.span/3 isolates the handler and auto-detaches it).
      assert conn.status == 200
      assert Jason.decode!(conn.resp_body)["status"] == "inserted"
    end
  end

  describe "TELE-07 post-commit broadcast" do
    test "an :inserted ingress broadcasts {:inbound_record_inserted, id, %{provider, record_type}}" do
      Phoenix.PubSub.subscribe(Mailglass.PubSub, Topics.inbound_record_inserted("tenant-123"))

      conn = drive_ingress()
      assert conn.status == 200

      assert_receive {:inbound_record_inserted, "record-123",
                      %{provider: :postmark, record_type: "inbound_record"} = meta}

      # PII-free payload metadata
      assert_pii_free(meta)
    end

    test "a :duplicate ingress broadcasts nothing" do
      Process.put(:mailglass_inbound_persist_status, :duplicate)
      Phoenix.PubSub.subscribe(Mailglass.PubSub, Topics.inbound_record_inserted("tenant-123"))

      conn = drive_ingress()
      assert conn.status == 200

      refute_receive {:inbound_record_inserted, _id, _meta}
    end
  end

  # --- helpers ---

  defp drive_ingress do
    body = postmark_payload()

    Plug.Test.conn(:post, "/inbound/tenant-123/postmark", body)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("authorization", "Basic " <> Base.encode64("postmark:secret"))
    |> Plug.Conn.put_private(:raw_body, body)
    |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})
    |> IngressPlug.call(
      IngressPlug.init(
        provider: :postmark,
        router: TestRouter,
        persistence: FakePersistence,
        execution: FakeExecution
      )
    )
  end

  defp attach(events) do
    handler_id = "telemetry-test-#{System.unique_integer([:positive])}"
    test_pid = self()

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _config ->
        send(test_pid, {event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  defp assert_pii_free(meta) when is_map(meta) do
    present = Enum.filter(@forbidden_meta_keys, &Map.has_key?(meta, &1))
    assert present == [], "telemetry metadata leaked PII keys: #{inspect(present)}"
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)

  defp message do
    %InboundMessage{
      tenant_id: "tenant-123",
      provider: :postmark,
      envelope_recipient: "support@example.com"
    }
  end

  defp persisted_payload do
    %{
      status: :inserted,
      route: %{status: :matched, mailbox: SupportMailbox},
      message: message(),
      inbound_record: %{id: "record-123", tenant_id: "tenant-123"},
      inbound_evidence: %{id: "evidence-123"}
    }
  end

  defp valid_handoff do
    %{
      tenant_id: "tenant-123",
      provider: :postmark,
      message: %InboundMessage{
        tenant_id: "tenant-123",
        provider: :postmark,
        provider_message_id: "pm-message-123",
        message_id: "<rfc-message@example.com>",
        envelope_recipient: "support@example.com",
        from: [%{address: "sender@example.com"}],
        to: [%{address: "support@example.com"}],
        subject: "Support request",
        headers: %{"message-id" => ["<rfc-message@example.com>"]},
        received_at: DateTime.utc_now(),
        text_body: "Plain body",
        attachments: []
      },
      evidence: %{
        raw_payload: %{"MessageID" => "pm-message-123"},
        raw_headers: %{"content-type" => ["application/json"]},
        verification_facts: %{auth: :basic_auth},
        parse_warnings: %{},
        attachment_blobs: %{}
      }
    }
  end

  defp postmark_payload do
    Jason.encode!(%{
      "FromFull" => [%{"Email" => "sender@example.com", "Name" => "Sender"}],
      "ToFull" => [%{"Email" => "support@example.com", "Name" => "Support"}],
      "Subject" => "Support request",
      "MessageID" => "pm-message-123",
      "OriginalRecipient" => "support@example.com",
      "TextBody" => "Plain body",
      "HtmlBody" => "<p>HTML body</p>",
      "Headers" => [%{"Name" => "Message-Id", "Value" => "<rfc-message@example.com>"}],
      "Attachments" => []
    })
  end
end
