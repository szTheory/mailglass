defmodule MailglassInbound.MailboxExecutionTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.InboundRecords

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
  end
end
