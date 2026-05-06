defmodule MailglassInbound.Ingress.PersistTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Ingress.Persist

  defmodule SupportMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule TestRouter do
    use MailglassInbound.Router

    route SupportMailbox, recipient: "support@example.com"
  end

  defmodule FakeRepo do
    def transact(fun, _opts \\ []), do: fun.()

    def one(_query, _opts \\ []) do
      Process.get(:mailglass_inbound_duplicate_record)
    end

    def insert(changeset, _opts \\ []) do
      struct =
        Ecto.Changeset.apply_changes(changeset)
        |> ensure_id()

      inserted = Process.get(:mailglass_inbound_inserts, [])
      Process.put(:mailglass_inbound_inserts, inserted ++ [struct])
      {:ok, struct}
    end

    defp ensure_id(%{id: nil} = struct), do: %{struct | id: Ecto.UUID.generate()}
    defp ensure_id(struct), do: struct
  end

  setup do
    Process.delete(:mailglass_inbound_duplicate_record)
    Process.delete(:mailglass_inbound_inserts)
    :ok
  end

  test "persists one canonical row plus one evidence row and returns route proof" do
    {:ok, result} =
      Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)

    inserts = Process.get(:mailglass_inbound_inserts)

    assert result.status == :inserted
    assert result.route == %{status: :matched, mailbox: SupportMailbox}
    assert Enum.count(inserts, &match?(%InboundRecord{}, &1)) == 1
    assert Enum.count(inserts, &match?(%InboundEvidence{}, &1)) == 1
    refute Enum.any?(inserts, &match?(%MailglassInbound.InboundRecords.ReplayRun{}, &1))
  end

  test "collapses duplicates on the provider idempotency anchor without reinserting" do
    Process.put(
      :mailglass_inbound_duplicate_record,
      %InboundRecord{
        id: Ecto.UUID.generate(),
        tenant_id: "tenant-123",
        provider: "postmark",
        provider_message_id: "pm-message-123",
        envelope_recipient: "support@example.com",
        received_at: DateTime.utc_now()
      }
    )

    {:ok, result} =
      Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)

    assert result.status == :duplicate
    assert result.route == %{status: :matched, mailbox: SupportMailbox}
    assert Process.get(:mailglass_inbound_inserts) in [nil, []]
  end

  test "documents the partial unique index for Postmark ingress idempotency" do
    migration =
      File.read!(
        Path.expand("../../../priv/repo/migrations/20260506180000_add_postmark_ingress_idempotency.exs", __DIR__)
      )

    assert migration =~ "create unique_index"
    assert migration =~ "provider_message_id IS NOT NULL"
    assert migration =~ "mailglass_inbound_records_postmark_idempotency_idx"
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
        attachments: [%{filename: "invoice.txt", content_type: "text/plain"}]
      },
      evidence: %{
        raw_payload: %{"MessageID" => "pm-message-123"},
        raw_headers: %{"content-type" => ["application/json"]},
        verification_facts: %{auth: :basic_auth},
        parse_warnings: %{},
        attachment_blobs: %{"0:invoice.txt" => "invoice-bytes"}
      }
    }
  end
end
