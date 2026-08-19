defmodule MailglassInbound.ReplayTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Ingress.Persist
  alias MailglassInbound.Ingress.{Request, VerifiedRequest}
  alias MailglassInbound.Internal.Replay
  alias MailglassInbound.TestRepo
  alias Ecto.Adapters.SQL.Sandbox

  # Phase 135 collapsed the 7 loose historical migrations into a single final-state
  # V01 snapshot (D-08). The canonical schema DDL — records/evidence/replay_runs
  # tables, the execution-lineage columns, and the fingerprint indexes — now lives
  # there, so all three former per-file references point at the snapshot.
  @schema_snapshot_path Path.expand(
                          "../../lib/mailglass_inbound/migrations/postgres/v01.ex",
                          __DIR__
                        )
  @migration_path @schema_snapshot_path
  @execution_migration_path @schema_snapshot_path
  @phase_41_migration_path @schema_snapshot_path

  defmodule SupportMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(message) do
      Process.put(:mailglass_inbound_replay_last_message, message)
      :accept
    end
  end

  defmodule ReplayRouter do
    use MailglassInbound.Router

    route(SupportMailbox, recipient: "support@example.com")
  end

  defmodule LoadedProcessSentinel do
    def process(_message) do
      send(Application.fetch_env!(:mailglass_inbound, :replay_test_pid), :sentinel_invoked)
      :accept
    end
  end

  defmodule ReplayRepo do
    def one(_query, _opts \\ []) do
      case Process.get(:mailglass_inbound_replay_repo_sequence, []) do
        [next | rest] ->
          Process.put(:mailglass_inbound_replay_repo_sequence, rest)
          next

        [] ->
          nil
      end
    end
  end

  defmodule ReplayExecution do
    def execute(result, opts \\ []) do
      Process.put(:mailglass_inbound_replay_execution_payload, result)
      Process.put(:mailglass_inbound_replay_execution_opts, opts)
      {:ok, %{outcome: :accept}}
    end
  end

  defmodule TerminalRecoveryProvider do
    def resolve_content!(%VerifiedRequest{} = verified, _config) do
      Process.put(:mailglass_inbound_terminal_refetched, verified)

      %{
        verified
        | raw_mime:
            "Message-ID: <recovered@example.com>\r\nTo: support@example.com\r\n\r\nrecovered"
      }
    end

    def normalize(%VerifiedRequest{raw_mime: raw_mime}) do
      %{
        message: %InboundMessage{
          provider: :ses,
          provider_message_id: "ses-recovered-1",
          message_id: "<recovered@example.com>",
          envelope_recipient: "support@example.com",
          from: [%{address: "sender@example.com"}],
          to: [%{address: "support@example.com"}],
          subject: "Recovered",
          headers: %{"message-id" => ["<recovered@example.com>"]},
          received_at: DateTime.utc_now(),
          text_body: "recovered"
        },
        evidence: %{
          raw_mime: raw_mime,
          verification_facts: %{"content" => "refetched"},
          parse_warnings: %{},
          attachment_blobs: %{}
        }
      }
    end
  end

  defmodule PersistRepo do
    def transact(fun, _opts \\ []), do: fun.()

    def one(_query, _opts \\ []) do
      case Process.get(:mailglass_inbound_persist_repo_sequence, []) do
        [next | rest] ->
          Process.put(:mailglass_inbound_persist_repo_sequence, rest)
          next

        [] ->
          nil
      end
    end

    def insert(changeset, _opts \\ []) do
      struct =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> ensure_id()

      inserted = Process.get(:mailglass_inbound_persist_inserts, [])
      Process.put(:mailglass_inbound_persist_inserts, inserted ++ [struct])
      {:ok, struct}
    end

    defp ensure_id(%{id: nil} = struct), do: %{struct | id: Ecto.UUID.generate()}
    defp ensure_id(struct), do: struct
  end

  setup do
    Process.delete(:mailglass_inbound_replay_repo_sequence)
    Process.delete(:mailglass_inbound_replay_execution_payload)
    Process.delete(:mailglass_inbound_replay_execution_opts)
    Process.delete(:mailglass_inbound_replay_last_message)
    Process.delete(:mailglass_inbound_persist_repo_sequence)
    Process.delete(:mailglass_inbound_persist_inserts)
    Process.delete(:mailglass_inbound_terminal_refetched)
    Application.put_env(:mailglass_inbound, :replay_test_pid, self())

    on_exit(fn -> Application.delete_env(:mailglass_inbound, :replay_test_pid) end)
    :ok
  end

  describe "execution lineage" do
    test "links fresh and replay execution runs to stored record and evidence truth" do
      fields = ExecutionRun.__schema__(:fields)
      record_assoc = ExecutionRun.__schema__(:association, :inbound_record)
      evidence_assoc = ExecutionRun.__schema__(:association, :inbound_evidence)
      migration_source = File.read!(@migration_path)
      execution_migration_source = File.read!(@execution_migration_path)

      assert :tenant_id in fields
      assert :inbound_record_id in fields
      assert :inbound_evidence_id in fields
      assert :source in fields
      assert :mailbox in fields
      assert :outcome in fields
      assert :failure in fields
      assert :metadata in fields

      refute :subject in fields
      refute :headers in fields
      refute :text_body in fields
      refute :raw_payload in fields

      assert %{owner_key: :inbound_record_id} = record_assoc
      assert %{owner_key: :inbound_evidence_id} = evidence_assoc
      assert migration_source =~ "references(:mailglass_inbound_records"
      assert migration_source =~ "references(:mailglass_inbound_evidence"
      assert execution_migration_source =~ "source"
      assert execution_migration_source =~ "mailbox"
    end

    test "normalizes fresh and replay outcomes plus execution failures into append-only execution truth" do
      base_attrs = %{
        tenant_id: "tenant-123",
        inbound_record_id: Ecto.UUID.generate(),
        inbound_evidence_id: Ecto.UUID.generate(),
        source: :replay,
        mailbox: "MyApp.Mailboxes.SupportMailbox",
        metadata: %{replay_id: "replay-123"}
      }

      accept = InboundRecords.change_execution_run(Map.put(base_attrs, :mailbox_outcome, :accept))
      ignore = InboundRecords.change_execution_run(Map.put(base_attrs, :mailbox_outcome, :ignore))

      no_match =
        InboundRecords.change_execution_run(%{
          tenant_id: "tenant-123",
          inbound_record_id: Ecto.UUID.generate(),
          inbound_evidence_id: Ecto.UUID.generate(),
          source: :fresh,
          mailbox: nil,
          mailbox_outcome: :no_match
        })

      reject =
        InboundRecords.change_execution_run(
          Map.put(base_attrs, :mailbox_outcome, {:reject, "spam"})
        )

      bounce =
        InboundRecords.change_execution_run(
          Map.put(base_attrs, :mailbox_outcome, {:bounce, :loop_detected})
        )

      failed =
        InboundRecords.change_execution_run(
          Map.put(base_attrs, :execution_failure, %{kind: :error, reason: "boom"})
        )

      invalid =
        InboundRecords.change_execution_run(Map.put(base_attrs, :mailbox_outcome, :maybe))

      assert accept.valid?
      assert Ecto.Changeset.get_field(accept, :outcome) == :accept
      assert Ecto.Changeset.get_field(accept, :failure) == %{}

      assert ignore.valid?
      assert Ecto.Changeset.get_field(ignore, :outcome) == :ignore

      assert no_match.valid?
      assert Ecto.Changeset.get_field(no_match, :outcome) == :no_match
      assert Ecto.Changeset.get_field(no_match, :mailbox) == nil

      assert reject.valid?
      assert Ecto.Changeset.get_field(reject, :outcome) == :reject
      assert Ecto.Changeset.get_field(reject, :outcome_reason) == "spam"

      assert bounce.valid?
      assert Ecto.Changeset.get_field(bounce, :outcome) == :bounce
      assert Ecto.Changeset.get_field(bounce, :outcome_reason) == "loop_detected"

      assert failed.valid?
      assert Ecto.Changeset.get_field(failed, :outcome) == :failed
      assert Ecto.Changeset.get_field(failed, :failure) == %{kind: :error, reason: "boom"}

      refute invalid.valid?

      assert {"must be :no_match, :accept, :ignore, {:reject, reason}, {:bounce, reason}, or :failed with failure metadata",
              _} =
               invalid.errors[:outcome]
    end

    test "keeps execution persistence append-only and canonical receive truth immutable" do
      record_fields = MailglassInbound.InboundRecords.InboundRecord.__schema__(:fields)

      refute function_exported?(InboundRecords, :update_execution_run, 1)
      refute function_exported?(InboundRecords, :update_execution_run, 2)
      refute function_exported?(InboundRecords, :update_inbound_evidence, 1)
      refute function_exported?(InboundRecords, :update_inbound_evidence, 2)
      refute :latest_execution_id in record_fields
      refute :latest_execution_outcome in record_fields
      refute :matched_mailbox in record_fields
    end
  end

  describe "sendgrid duplicate persistence" do
    test "collapses duplicates on tenant/provider/raw mime fingerprint without overloading provider_message_id" do
      duplicate_record = %InboundRecord{
        id: Ecto.UUID.generate(),
        tenant_id: "tenant-123",
        provider: "sendgrid",
        provider_message_id: nil,
        received_at: DateTime.utc_now()
      }

      Process.put(:mailglass_inbound_persist_repo_sequence, [duplicate_record])

      {:ok, result} =
        Persist.persist(valid_sendgrid_handoff(),
          repo: PersistRepo,
          routes: []
        )

      inserts = Process.get(:mailglass_inbound_persist_inserts, [])
      migration_source = File.read!(@phase_41_migration_path)

      assert result.status == :duplicate
      assert result.inbound_record.id == duplicate_record.id
      assert inserts == []
      assert migration_source =~ "raw_mime_fingerprint"
      assert migration_source =~ "mailglass_inbound_records_sendgrid_fingerprint_idx"

      # The sendgrid dedup index keys on the raw-mime fingerprint, NOT on
      # provider_message_id. In the collapsed V01 snapshot provider_message_id
      # appears elsewhere (the postmark idempotency index), so scope the check to
      # the sendgrid index definition block.
      sendgrid_index =
        Regex.run(~r/unique_index\([^()]*sendgrid[^()]*\)/s, migration_source) |> List.first()

      assert sendgrid_index =~ "raw_mime_fingerprint"
      refute sendgrid_index =~ "provider_message_id"
    end
  end

  describe "internal replay" do
    test "reuses stored canonical and evidence truth, defaults to the latest fresh matched mailbox, and appends replay lineage" do
      record = valid_inbound_record()
      evidence = valid_inbound_evidence(record.id)

      latest_fresh_match = %ExecutionRun{
        inbound_record_id: record.id,
        inbound_evidence_id: evidence.id,
        source: :fresh,
        mailbox: Atom.to_string(SupportMailbox),
        outcome: :accept
      }

      Process.put(:mailglass_inbound_replay_repo_sequence, [record, evidence, latest_fresh_match])

      assert {:ok, %{outcome: :accept}} =
               Replay.replay(record.id,
                 tenant_id: record.tenant_id,
                 repo: ReplayRepo,
                 router: ReplayRouter,
                 execution: ReplayExecution
               )

      execution_payload = Process.get(:mailglass_inbound_replay_execution_payload)
      execution_opts = Process.get(:mailglass_inbound_replay_execution_opts)

      assert execution_payload.status == :inserted
      assert execution_payload.inbound_record.id == record.id
      assert execution_payload.inbound_evidence.id == evidence.id
      assert execution_payload.route == %{status: :matched, mailbox: SupportMailbox}
      assert execution_payload.message.message_id == record.message_id
      assert execution_payload.message.provider == :sendgrid
      assert Keyword.get(execution_opts, :source) == :replay
    end

    test "fails explicitly when only no-match fresh history exists" do
      record = valid_inbound_record()

      evidence = %{
        valid_inbound_evidence(record.id)
        | verification_facts: %{"mailglass_execution_route" => %{"status" => "no_match"}}
      }

      no_match_run = %ExecutionRun{
        inbound_record_id: record.id,
        inbound_evidence_id: evidence.id,
        source: :fresh,
        mailbox: nil,
        outcome: :no_match
      }

      Process.put(:mailglass_inbound_replay_repo_sequence, [record, evidence, nil, no_match_run])

      assert {:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}} =
               Replay.replay(record.id,
                 tenant_id: record.tenant_id,
                 repo: ReplayRepo,
                 execution: ReplayExecution
               )

      assert Process.get(:mailglass_inbound_replay_execution_payload) == nil
    end

    test "rejects a loaded non-mailbox persisted identity without invocation" do
      record = valid_inbound_record()

      evidence = %{
        valid_inbound_evidence(record.id)
        | verification_facts: %{
            "mailglass_execution_route" => %{
              "status" => "matched",
              "mailbox" => Atom.to_string(LoadedProcessSentinel),
              "router" => Atom.to_string(ReplayRouter)
            }
          }
      }

      sentinel_run = %ExecutionRun{
        inbound_record_id: record.id,
        inbound_evidence_id: evidence.id,
        source: :fresh,
        mailbox: Atom.to_string(LoadedProcessSentinel),
        outcome: :accept
      }

      Process.put(:mailglass_inbound_replay_repo_sequence, [record, evidence, sentinel_run])

      assert {:error, {:replay_mailbox_missing, %{reason: :invalid_mailbox}}} =
               Replay.replay(record.id,
                 tenant_id: record.tenant_id,
                 repo: ReplayRepo,
                 router: ReplayRouter,
                 execution: ReplayExecution
               )

      refute_received :sentinel_invoked
      assert Process.get(:mailglass_inbound_replay_execution_payload) == nil
    end

    test "fails explicitly when the record predates execution lineage capture" do
      record = valid_inbound_record()
      evidence = %{valid_inbound_evidence(record.id) | verification_facts: %{auth: :basic_auth}}

      Process.put(:mailglass_inbound_replay_repo_sequence, [record, evidence, nil, nil])

      assert {:error, {:replay_mailbox_missing, %{reason: :execution_history_missing}}} =
               Replay.replay(record.id,
                 tenant_id: record.tenant_id,
                 repo: ReplayRepo,
                 execution: ReplayExecution
               )
    end

    test "raises without a :tenant_id (T-49-17 cross-tenant replay guard)" do
      record = valid_inbound_record()

      assert_raise ArgumentError, ~r/requires a non-empty :tenant_id/, fn ->
        Replay.replay(record.id, repo: ReplayRepo, execution: ReplayExecution)
      end

      assert_raise ArgumentError, ~r/requires a non-empty :tenant_id/, fn ->
        Replay.replay(record.id, tenant_id: "", repo: ReplayRepo, execution: ReplayExecution)
      end
    end

    test "real terminal evidence refetches, normalizes, updates, routes, and executes end to end" do
      owner = Sandbox.start_owner!(TestRepo, shared: true)
      TestRepo.query!("TRUNCATE TABLE mailglass_inbound_records CASCADE", [])
      on_exit(fn -> Sandbox.stop_owner(owner) end)

      exact_signed_request = <<123, 34, 84, 121, 112, 101, 34, 58, 34, 78, 34, 125, 10>>

      request = %Request{
        provider: :ses,
        raw_body: exact_signed_request,
        headers: [{"content-type", "application/json"}]
      }

      verified = %VerifiedRequest{
        request: request,
        raw_body: exact_signed_request,
        envelope: %{"Type" => "Notification", "Message" => "{}"},
        verification_facts: %{"auth" => "sns_x509"},
        warnings: %{}
      }

      assert {:ok, terminal} =
               Persist.persist_terminal_failure(
                 "tenant-terminal-replay",
                 :ses,
                 request,
                 verified,
                 :s3_fetch_failed,
                 repo: TestRepo,
                 routes: []
               )

      record_id = terminal.inbound_record.id

      assert {:ok, %{outcome: :accept}} =
               Replay.replay(record_id,
                 tenant_id: "tenant-terminal-replay",
                 repo: TestRepo,
                 router: ReplayRouter,
                 provider_module: TerminalRecoveryProvider,
                 provider_config: %{},
                 execution: ReplayExecution
               )

      assert %VerifiedRequest{request: %Request{raw_body: ^exact_signed_request}} =
               Process.get(:mailglass_inbound_terminal_refetched)

      record = TestRepo.get!(InboundRecord, record_id)
      evidence = TestRepo.get_by!(InboundEvidence, inbound_record_id: record_id)
      execution_payload = Process.get(:mailglass_inbound_replay_execution_payload)

      assert record.provider_message_id == "ses-recovered-1"
      assert record.subject == "Recovered"
      assert evidence.raw_signed_request == exact_signed_request
      assert is_binary(evidence.raw_mime_sha256)
      assert evidence.terminal_failure_class == nil
      assert evidence.terminal_context["recovered"] == true
      assert execution_payload.route == %{status: :matched, mailbox: SupportMailbox}
      assert execution_payload.message.subject == "Recovered"
    end
  end

  defp valid_sendgrid_handoff do
    %{
      tenant_id: "tenant-123",
      provider: :sendgrid,
      message: %InboundMessage{
        tenant_id: "tenant-123",
        provider: :sendgrid,
        provider_message_id: nil,
        message_id: "<rfc-message@example.com>",
        envelope_recipient: "support@example.com",
        from: [%{address: "sender@example.com"}],
        to: [%{address: "support@example.com"}],
        subject: "Support request",
        headers: %{"message-id" => ["<rfc-message@example.com>"]},
        received_at: DateTime.utc_now(),
        text_body: "Plain body"
      },
      evidence: %{
        raw_payload: %{"from" => "sender@example.com"},
        raw_headers: %{"content-type" => ["multipart/form-data"]},
        raw_mime: "Message-ID: <rfc-message@example.com>\r\n\r\nhello",
        verification_facts: %{auth: :basic_auth}
      }
    }
  end

  defp valid_inbound_record do
    %InboundRecord{
      id: Ecto.UUID.generate(),
      tenant_id: "tenant-123",
      provider: "sendgrid",
      provider_message_id: nil,
      message_id: "<rfc-message@example.com>",
      envelope_recipient: "support@example.com",
      from: [%{address: "sender@example.com"}],
      to: [%{address: "support@example.com"}],
      cc: [],
      bcc: [],
      reply_to: [%{address: "reply@example.com"}],
      subject: "Support request",
      headers: %{"message-id" => ["<rfc-message@example.com>"]},
      received_at: DateTime.utc_now(),
      text_body: "Plain body",
      html_body: "<p>HTML body</p>",
      attachments: []
    }
  end

  defp valid_inbound_evidence(record_id) do
    %InboundEvidence{
      id: Ecto.UUID.generate(),
      tenant_id: "tenant-123",
      inbound_record_id: record_id,
      provider: "sendgrid",
      raw_payload: %{"from" => "sender@example.com"},
      raw_headers: %{"content-type" => ["multipart/form-data"]},
      raw_mime: "Message-ID: <rfc-message@example.com>\r\n\r\nhello",
      verification_facts: %{
        "mailglass_execution_route" => %{
          "status" => "matched",
          "mailbox" => Atom.to_string(SupportMailbox),
          "router" => Atom.to_string(ReplayRouter)
        },
        auth: :basic_auth
      },
      parse_warnings: %{},
      attachment_blobs: %{}
    }
  end
end
