defmodule MailglassInbound.ReplayTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.ReplayRun

  @migration_path Path.expand("../../priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs", __DIR__)

  describe "replay lineage" do
    test "links replay runs to stored record and evidence rather than fresh receive truth" do
      fields = ReplayRun.__schema__(:fields)
      record_assoc = ReplayRun.__schema__(:association, :inbound_record)
      evidence_assoc = ReplayRun.__schema__(:association, :inbound_evidence)
      migration_source = File.read!(@migration_path)

      assert :tenant_id in fields
      assert :inbound_record_id in fields
      assert :inbound_evidence_id in fields
      assert :replay_id in fields
      assert :mailbox in fields
      assert :outcome in fields
      assert :failure in fields

      refute :subject in fields
      refute :headers in fields
      refute :text_body in fields
      refute :raw_payload in fields

      assert %{owner_key: :inbound_record_id} = record_assoc
      assert %{owner_key: :inbound_evidence_id} = evidence_assoc
      assert migration_source =~ "references(:mailglass_inbound_records"
      assert migration_source =~ "references(:mailglass_inbound_evidence"
    end

    test "normalizes mailbox outcomes and execution failures into append-only replay truth" do
      base_attrs = %{
        tenant_id: "tenant-123",
        inbound_record_id: Ecto.UUID.generate(),
        inbound_evidence_id: Ecto.UUID.generate(),
        replay_id: "replay-123",
        mailbox: "MyApp.Mailboxes.SupportMailbox"
      }

      accept = InboundRecords.change_replay_run(Map.put(base_attrs, :mailbox_outcome, :accept))
      reject =
        InboundRecords.change_replay_run(
          Map.put(base_attrs, :mailbox_outcome, {:reject, "spam"})
        )

      failed =
        InboundRecords.change_replay_run(
          Map.put(base_attrs, :execution_failure, %{kind: :error, reason: "boom"})
        )

      invalid =
        InboundRecords.change_replay_run(
          Map.put(base_attrs, :mailbox_outcome, {:reject, ""})
        )

      assert accept.valid?
      assert Ecto.Changeset.get_field(accept, :outcome) == :accept
      assert Ecto.Changeset.get_field(accept, :failure) == %{}

      assert reject.valid?
      assert Ecto.Changeset.get_field(reject, :outcome) == :reject
      assert Ecto.Changeset.get_field(reject, :outcome_reason) == "spam"

      assert failed.valid?
      assert Ecto.Changeset.get_field(failed, :outcome) == :failed
      assert Ecto.Changeset.get_field(failed, :failure) == %{kind: :error, reason: "boom"}

      refute invalid.valid?
      assert {"must be :accept, :ignore, {:reject, reason}, {:bounce, reason}, or :failed with failure metadata", _} =
               invalid.errors[:outcome]
    end

    test "keeps replay persistence append-only at the context boundary" do
      refute function_exported?(InboundRecords, :update_replay_run, 1)
      refute function_exported?(InboundRecords, :update_replay_run, 2)
      refute function_exported?(InboundRecords, :update_inbound_evidence, 1)
      refute function_exported?(InboundRecords, :update_inbound_evidence, 2)
    end
  end
end
