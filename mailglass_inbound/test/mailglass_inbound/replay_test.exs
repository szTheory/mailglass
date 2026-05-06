defmodule MailglassInbound.ReplayTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.ExecutionRun

  @migration_path Path.expand("../../priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs", __DIR__)
  @execution_migration_path Path.expand("../../priv/repo/migrations/20260506210000_generalize_replay_runs_to_execution_lineage.exs", __DIR__)

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
      no_match = InboundRecords.change_execution_run(%{
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
        InboundRecords.change_execution_run(
          Map.put(base_attrs, :mailbox_outcome, :maybe)
        )

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
      assert {"must be :no_match, :accept, :ignore, {:reject, reason}, {:bounce, reason}, or :failed with failure metadata", _} =
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
end
