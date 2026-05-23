defmodule MailglassInbound.Ingress.PersistTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Ingress.Persist
  alias MailglassInbound.TestRepo

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

  # CR-01: a Postgres-backed TestRepo decorator that forces the FIRST `one/2`
  # (the in-transaction `load_duplicate` check) to miss — reproducing the race
  # window where a redelivery's dedup snapshot was taken before the winning
  # transaction committed. Every other call (insert, transact, and the
  # post-violation reload `one/2`) delegates to the real TestRepo, so the
  # fingerprint unique index is genuinely enforced by Postgres.
  defmodule RaceRepo do
    def transact(fun, opts \\ []), do: TestRepo.transact(fun, opts)
    def insert(changeset, opts \\ []), do: TestRepo.insert(changeset, opts)

    def one(query, opts \\ []) do
      case Process.get(:mailglass_inbound_race_one_seen, false) do
        false ->
          Process.put(:mailglass_inbound_race_one_seen, true)
          nil

        true ->
          TestRepo.one(query, opts)
      end
    end
  end

  setup do
    Process.delete(:mailglass_inbound_duplicate_record)
    Process.delete(:mailglass_inbound_inserts)
    Process.delete(:mailglass_inbound_race_one_seen)
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

  describe "Mailgun dedupe (Postgres-backed)" do
    setup do
      owner = Sandbox.start_owner!(TestRepo, shared: true)
      truncate_all()
      on_exit(fn -> Sandbox.stop_owner(owner) end)
      :ok
    end

    test "two Mailgun payloads with the SAME Message-Id collapse to one InboundRecord (generic index)" do
      handoff = mailgun_handoff(provider_message_id: "<mg-same@example.com>", raw_mime: nil)

      {:ok, first} = Persist.persist(handoff, repo: TestRepo, routes: [])
      {:ok, second} = Persist.persist(handoff, repo: TestRepo, routes: [])

      assert first.status == :inserted
      assert second.status == :duplicate
      assert TestRepo.aggregate(InboundRecord, :count) == 1
    end

    test "two Mailgun payloads with NO Message-Id but identical raw collapse to one InboundRecord (fingerprint index)" do
      raw = "Subject: no message id\r\n\r\nidentical raw body"
      handoff = mailgun_handoff(provider_message_id: nil, raw_mime: raw)

      {:ok, first} = Persist.persist(handoff, repo: TestRepo, routes: [])
      {:ok, second} = Persist.persist(handoff, repo: TestRepo, routes: [])

      assert first.status == :inserted
      assert second.status == :duplicate
      assert TestRepo.aggregate(InboundRecord, :count) == 1
    end

    test "documents the Mailgun-scoped partial unique fingerprint index migration" do
      migration =
        File.read!(
          Path.expand(
            "../../../priv/repo/migrations/20260523120000_add_mailgun_fingerprint_index.exs",
            __DIR__
          )
        )

      assert migration =~ "create unique_index"
      assert migration =~ "provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL"
      assert migration =~ "mailglass_inbound_records_mailgun_fingerprint_idx"
      refute migration =~ "generated:"
    end

    # CR-01: the check-then-act dedup window. A concurrent redelivery of the same
    # no-Message-Id Mailgun body can pass `load_duplicate` (both readers see nil)
    # before either evidence row is committed, so both proceed to insert. The
    # canonical record carries no unique key for the no-Message-Id case, so two
    # records insert; the SECOND evidence insert violates the fingerprint partial
    # unique index. Without the matching `unique_constraint/3` this raised a raw
    # `Postgrex.Error` (a 500); the fix translates it to `{:error, changeset}`,
    # the persist layer recognizes the fingerprint constraint and reloads the
    # surviving duplicate, collapsing the race to a clean `:duplicate`.
    #
    # The sandbox serializes connections, so the race window is reproduced
    # deterministically with a repo decorator that returns `nil` for the
    # in-transaction dedup check (simulating the snapshot taken before the winner
    # committed) and delegates everything else — including the post-violation
    # reload — to the real Postgres-backed TestRepo. This drives the exact
    # production code path: insert -> fingerprint violation -> reload -> duplicate.
    test "concurrent no-Message-Id redelivery collapses to :duplicate, never a raised Postgrex.Error" do
      raw = "Subject: race condition\r\n\r\nidentical concurrent body"
      handoff = mailgun_handoff(provider_message_id: nil, raw_mime: raw)

      # Winner: insert the first record + evidence normally (this is the row the
      # concurrent transaction committed first).
      {:ok, winner} = Persist.persist(handoff, repo: TestRepo, routes: [])
      assert winner.status == :inserted
      assert TestRepo.aggregate(InboundRecord, :count) == 1

      # Loser: the same body arrives again, but its in-transaction dedup check
      # missed (RaceRepo forces the first `one/2` to nil). It inserts a second
      # record, then the evidence insert violates the fingerprint unique index.
      result = Persist.persist(handoff, repo: RaceRepo, routes: [])

      assert {:ok, %{status: :duplicate, inbound_record: %InboundRecord{}}} = result
      # The fingerprint constraint rolled back the loser's record insert: still
      # exactly one canonical InboundRecord, never two.
      assert TestRepo.aggregate(InboundRecord, :count) == 1
    end
  end

  defp truncate_all do
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_records CASCADE", [])
  end

  defp mailgun_handoff(opts) do
    provider_message_id = Keyword.get(opts, :provider_message_id)
    raw_mime = Keyword.get(opts, :raw_mime)

    %{
      tenant_id: "mg-tenant",
      provider: :mailgun,
      message: %InboundMessage{
        tenant_id: "mg-tenant",
        provider: :mailgun,
        provider_message_id: provider_message_id,
        message_id: provider_message_id,
        envelope_recipient: "support@example.com",
        from: [%{address: "sender@example.com"}],
        to: [%{address: "support@example.com"}],
        subject: "Mailgun dedupe",
        headers: %{},
        received_at: DateTime.utc_now()
      },
      evidence: %{
        raw_payload: %{"recipient" => "support@example.com"},
        raw_headers: %{},
        raw_mime: raw_mime,
        verification_facts: %{auth: :hmac},
        parse_warnings: %{},
        attachment_blobs: %{}
      }
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
