defmodule MailglassInbound.MailboxExecutionTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.Execution
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords

  defmodule AcceptMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule IgnoreMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :ignore
  end

  defmodule RejectMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: {:reject, :spam}
  end

  defmodule BounceMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: {:bounce, "loop"}
  end

  defmodule RaiseMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: raise("boom")
  end

  defmodule ExitMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: exit(:mailbox_down)
  end

  defmodule ThrowMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: throw(:bad_mail)
  end

  defmodule InvalidMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :retry
  end

  defmodule RecordingInboundRecords do
    def insert_execution_run(attrs, _opts \\ []) do
      Process.put(:mailglass_inbound_execution_attrs, attrs)
      {:ok, attrs}
    end
  end

  defmodule RecordingRepo do
    def one(_query, _opts) do
      case Process.get(:mailglass_inbound_execution_load_rows, []) do
        [row | remaining] ->
          Process.put(:mailglass_inbound_execution_load_rows, remaining)
          row

        [] ->
          nil
      end
    end
  end

  setup do
    Process.delete(:mailglass_inbound_execution_attrs)
    Process.delete(:mailglass_inbound_execution_load_rows)
    :ok
  end

  describe "fresh execution lineage" do
    test "captures matched mailbox identity for fresh execution runs" do
      changeset =
        InboundRecords.change_execution_run(%{
          tenant_id: "tenant-123",
          inbound_record_id: Ecto.UUID.generate(),
          inbound_evidence_id: Ecto.UUID.generate(),
          source: :fresh,
          mailbox: "MyApp.Mailboxes.SupportMailbox",
          mailbox_outcome: :accept
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :source) == :fresh
      assert Ecto.Changeset.get_field(changeset, :mailbox) == "MyApp.Mailboxes.SupportMailbox"
      assert Ecto.Changeset.get_field(changeset, :outcome) == :accept
    end

    test "records matched mailbox outcomes as append-only execution runs" do
      persisted = persisted_payload(%{status: :matched, mailbox: AcceptMailbox})

      assert {:ok, %{outcome: :accept}} =
               Execution.execute(persisted, inbound_records: RecordingInboundRecords)

      assert %{
               tenant_id: "tenant-123",
               source: :fresh,
               mailbox: "Elixir.MailglassInbound.MailboxExecutionTest.AcceptMailbox",
               mailbox_outcome: :accept,
               inbound_record_id: "record-123",
               inbound_evidence_id: "evidence-123"
             } = Process.get(:mailglass_inbound_execution_attrs)
    end

    test "records :no_match without invoking a mailbox" do
      persisted = persisted_payload(%{status: :no_match})

      assert {:ok, %{outcome: :no_match}} =
               Execution.execute(persisted, inbound_records: RecordingInboundRecords)

      assert %{
               source: :fresh,
               mailbox: nil,
               mailbox_outcome: :no_match
             } = Process.get(:mailglass_inbound_execution_attrs)
    end

    test "normalizes semantic mailbox outcomes without widening the mailbox contract" do
      assert {:ok, %{outcome: :ignore}} =
               Execution.execute(
                 persisted_payload(%{status: :matched, mailbox: IgnoreMailbox}),
                 inbound_records: RecordingInboundRecords
               )

      assert {:ok, %{outcome: :reject, outcome_reason: "spam"}} =
               Execution.execute(
                 persisted_payload(%{status: :matched, mailbox: RejectMailbox}),
                 inbound_records: RecordingInboundRecords
               )

      assert {:ok, %{outcome: :bounce, outcome_reason: "loop"}} =
               Execution.execute(
                 persisted_payload(%{status: :matched, mailbox: BounceMailbox}),
                 inbound_records: RecordingInboundRecords
               )
    end

    test "classifies raises, exits, throws, and invalid return shapes as failed execution runs" do
      assert_failed_execution(RaiseMailbox, :error)
      assert_failed_execution(ExitMailbox, :exit)
      assert_failed_execution(ThrowMailbox, :throw)
      assert_failed_execution(InvalidMailbox, :invalid_return)
    end

    test "loads every supported persisted provider through a finite map" do
      for provider <- ["postmark", "sendgrid", "mailgun", "ses"] do
        Process.put(:mailglass_inbound_execution_load_rows, [record(provider), evidence()])

        assert {:ok, %{message: %{provider: provider_atom}}} =
                 Execution.load(job_args(), repo: RecordingRepo)

        assert provider_atom == String.to_existing_atom(provider)
      end
    end

    test "rejects invalid persisted providers without allocating atoms" do
      Process.put(:mailglass_inbound_execution_load_rows, [record("unknown-provider-warmup")])
      assert {:error, :invalid_job_args} = Execution.load(job_args(), repo: RecordingRepo)
      atom_count = :erlang.system_info(:atom_count)

      for suffix <- 1..300 do
        Process.put(:mailglass_inbound_execution_load_rows, [record("unknown-provider-#{suffix}")])
        assert {:error, :invalid_job_args} = Execution.load(job_args(), repo: RecordingRepo)
      end

      assert :erlang.system_info(:atom_count) == atom_count
    end
  end

  defp assert_failed_execution(mailbox, expected_kind) do
    assert {:ok, %{outcome: :failed, failure: %{kind: ^expected_kind}}} =
             Execution.execute(
               persisted_payload(%{status: :matched, mailbox: mailbox}),
               inbound_records: RecordingInboundRecords
             )

    assert %{mailbox: mailbox_name, execution_failure: %{kind: ^expected_kind}} =
             Process.get(:mailglass_inbound_execution_attrs)

    assert mailbox_name == Atom.to_string(mailbox)
  end

  defp persisted_payload(route) do
    %{
      status: :inserted,
      route: route,
      message: %InboundMessage{
        tenant_id: "tenant-123",
        provider: :postmark,
        envelope_recipient: "support@example.com"
      },
      inbound_record: %{id: "record-123", tenant_id: "tenant-123"},
      inbound_evidence: %{id: "evidence-123"}
    }
  end

  defp job_args do
    %{
      "inbound_record_id" => "record-123",
      "inbound_evidence_id" => "evidence-123",
      "route_status" => "no_match",
      "mailglass_tenant_id" => "tenant-123"
    }
  end

  defp record(provider) do
    %MailglassInbound.InboundRecords.InboundRecord{
      id: "record-123",
      tenant_id: "tenant-123",
      provider: provider,
      received_at: DateTime.utc_now()
    }
  end

  defp evidence do
    %MailglassInbound.InboundRecords.InboundEvidence{
      id: "evidence-123",
      tenant_id: "tenant-123",
      inbound_record_id: "record-123",
      provider: "postmark",
      verification_facts: %{"mailglass_execution_route" => %{"status" => "no_match"}}
    }
  end
end
