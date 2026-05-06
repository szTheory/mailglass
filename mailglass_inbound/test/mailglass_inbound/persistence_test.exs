defmodule MailglassInbound.PersistenceTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Repo

  @migration_path Path.expand("../../priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs", __DIR__)

  describe "canonical and evidence boundaries" do
    test "keeps normalized adopter-facing truth separate from raw evidence" do
      canonical_fields = InboundRecord.__schema__(:fields)
      evidence_fields = InboundEvidence.__schema__(:fields)

      assert :tenant_id in canonical_fields
      assert :provider in canonical_fields
      assert :provider_message_id in canonical_fields
      assert :message_id in canonical_fields
      assert :envelope_recipient in canonical_fields
      assert :subject in canonical_fields
      assert :headers in canonical_fields
      assert :attachments in canonical_fields

      refute :raw_payload in canonical_fields
      refute :raw_headers in canonical_fields
      refute :raw_mime in canonical_fields
      refute :verification_facts in canonical_fields
      refute :parse_warnings in canonical_fields
      refute :attachment_blobs in canonical_fields

      assert :tenant_id in evidence_fields
      assert :inbound_record_id in evidence_fields
      assert :raw_payload in evidence_fields
      assert :raw_headers in evidence_fields
      assert :raw_mime in evidence_fields
      assert :verification_facts in evidence_fields
      assert :parse_warnings in evidence_fields
      assert :attachment_blobs in evidence_fields

      refute function_exported?(InboundMessage, :__schema__, 1)
    end

    test "requires tenant scope on persisted rows and keeps evidence foreign keys package-local" do
      record_changeset = InboundRecord.changeset(%{})
      evidence_changeset = InboundEvidence.changeset(%{})
      evidence_assoc = InboundEvidence.__schema__(:association, :inbound_record)
      migration_source = File.read!(@migration_path)

      assert {"can't be blank", _opts} = record_changeset.errors[:tenant_id]
      assert {"can't be blank", _opts} = evidence_changeset.errors[:tenant_id]
      assert {"can't be blank", _opts} = evidence_changeset.errors[:inbound_record_id]

      assert %{related: InboundRecord, owner_key: :inbound_record_id} = evidence_assoc

      referenced_tables =
        Regex.scan(~r/references\((:[a-zA-Z0-9_]+)/, migration_source, capture: :all_but_first)
        |> Enum.map(&List.first/1)

      assert ":mailglass_inbound_records" in referenced_tables
      assert Enum.all?(referenced_tables, &String.starts_with?(&1, ":mailglass_inbound_"))
    end
  end

  describe "package-local helpers" do
    defmodule FakeRepo do
      @moduledoc false

      def insert(changeset, _opts), do: {:ok, {:inserted, changeset.data.__struct__}}
      def transact(fun, _opts), do: fun.()
    end

    setup do
      original = Application.get_env(:mailglass_inbound, :repo)
      Application.delete_env(:mailglass_inbound, :repo)

      on_exit(fn ->
        if is_nil(original) do
          Application.delete_env(:mailglass_inbound, :repo)
        else
          Application.put_env(:mailglass_inbound, :repo, original)
        end
      end)

      :ok
    end

    test "raises when the package repo is not configured" do
      assert_raise RuntimeError, ~r/mailglass_inbound.*:repo/, fn ->
        Repo.transact(fn -> {:ok, :done} end)
      end
    end

    test "delegates inserts and transactions to the configured host repo" do
      Application.put_env(:mailglass_inbound, :repo, FakeRepo)

      assert {:ok, {:inserted, InboundRecord}} =
               Repo.insert(InboundRecord.changeset(%{
                 tenant_id: "tenant-123",
                 provider: "postmark",
                 received_at: DateTime.utc_now()
               }))

      assert {:ok, :done} = Repo.transact(fn -> {:ok, :done} end)
    end
  end
end
