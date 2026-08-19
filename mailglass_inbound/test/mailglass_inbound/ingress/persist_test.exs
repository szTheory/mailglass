defmodule MailglassInbound.Ingress.PersistTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Ingress.Persist
  alias MailglassInbound.TestRepo

  # Phase 135 collapsed the 7 loose historical migrations into a single final-state
  # V01 snapshot (D-08). The partial unique fingerprint/idempotency indexes these
  # tests document now live in the snapshot.
  @schema_snapshot_path Path.expand(
                          "../../../lib/mailglass_inbound/migrations/postgres/v01.ex",
                          __DIR__
                        )

  defmodule SupportMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule TestRouter do
    use MailglassInbound.Router

    route(SupportMailbox, recipient: "support@example.com")
  end

  # IOPS-05: a configurable stub of `Mailglass.SuppressionStore` so the
  # suppression-flag compute can be driven deterministically without a running
  # core `Mailglass.Repo` (the inbound suite owns only `MailglassInbound.TestRepo`;
  # the default `Mailglass.SuppressionStore.Ecto` queries the core repo, which is
  # absent here). The stub reads its scripted reply from the process dictionary so
  # each test owns its own behavior.
  defmodule StubSuppressionStore do
    @behaviour Mailglass.SuppressionStore

    @impl true
    def check(%{tenant_id: _tenant_id, address: _address}, _opts \\ []) do
      Process.get(:mailglass_inbound_stub_suppression_reply, :not_suppressed)
    end

    @impl true
    def record(_attrs, _opts \\ []), do: {:error, :not_supported}
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

  defmodule BackfillLockedRepo do
    def transact(fun, _opts \\ []), do: fun.()

    def query("SELECT pg_try_advisory_xact_lock" <> _rest, _params, _opts),
      do: {:ok, %{rows: [[false]]}}

    def query(_sql, _params, _opts), do: raise("backfill advanced without owning its lock")
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

  test "persists a routes-only matched mailbox binding with the evidence row" do
    {:ok, result} =
      Persist.persist(valid_handoff(),
        repo: FakeRepo,
        routes: TestRouter.__mailglass_inbound_routes__()
      )

    evidence =
      Process.get(:mailglass_inbound_inserts)
      |> Enum.find(&match?(%InboundEvidence{}, &1))

    assert result.status == :inserted

    assert evidence.verification_facts["mailglass_execution_route"] == %{
             "status" => "matched",
             "mailbox" => Atom.to_string(SupportMailbox)
           }
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
    migration = File.read!(@schema_snapshot_path)

    assert migration =~ "unique_index("
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
      migration = File.read!(@schema_snapshot_path)

      assert migration =~ "unique_index("
      assert migration =~ "provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL"
      assert migration =~ "mailglass_inbound_records_mailgun_fingerprint_idx"

      # The fingerprint index is a plain partial unique index — it does not itself
      # declare the STORED generated column (that lives on the evidence table's
      # create block in the collapsed snapshot). Scope the check to the index block.
      mailgun_index =
        Regex.run(~r/unique_index\([^()]*mailgun[^()]*\)/s, migration) |> List.first()

      refute mailgun_index =~ "generated:"
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

  describe "SES dedupe (Postgres-backed, WR-02)" do
    setup do
      owner = Sandbox.start_owner!(TestRepo, shared: true)
      truncate_all()
      on_exit(fn -> Sandbox.stop_owner(owner) end)
      :ok
    end

    test "two SES payloads with the SAME mail.messageId collapse to one InboundRecord (generic index)" do
      handoff = ses_handoff(provider_message_id: "ses-msg-same", raw_mime: nil)

      {:ok, first} = Persist.persist(handoff, repo: TestRepo, routes: [])
      {:ok, second} = Persist.persist(handoff, repo: TestRepo, routes: [])

      assert first.status == :inserted
      assert second.status == :duplicate
      assert TestRepo.aggregate(InboundRecord, :count) == 1
    end

    # WR-02: SES with no mail.messageId previously NEVER deduped (matched the
    # generic provider_message_id: nil clause -> always new). The new SES
    # fingerprint fallback + index collapse identical-raw redeliveries.
    test "two SES payloads with NO mail.messageId but identical raw collapse to one InboundRecord (fingerprint index)" do
      raw = "Subject: ses no message id\r\n\r\nidentical ses raw body"
      handoff = ses_handoff(provider_message_id: nil, raw_mime: raw)

      {:ok, first} = Persist.persist(handoff, repo: TestRepo, routes: [])
      {:ok, second} = Persist.persist(handoff, repo: TestRepo, routes: [])

      assert first.status == :inserted
      assert second.status == :duplicate
      assert TestRepo.aggregate(InboundRecord, :count) == 1
    end

    test "documents the SES-scoped partial unique fingerprint index migration" do
      migration = File.read!(@schema_snapshot_path)

      assert migration =~ "unique_index("
      assert migration =~ "provider = 'ses' AND raw_mime_fingerprint IS NOT NULL"
      assert migration =~ "mailglass_inbound_records_ses_fingerprint_idx"

      # The fingerprint index is a plain partial unique index — it does not itself
      # declare the STORED generated column (that lives on the evidence table's
      # create block in the collapsed snapshot). Scope the check to the index block.
      ses_index = Regex.run(~r/unique_index\([^()]*ses[^()]*\)/s, migration) |> List.first()

      refute ses_index =~ "generated:"
    end
  end

  describe "V02 SHA-256 transition and terminal evidence" do
    setup do
      owner = Sandbox.start_owner!(TestRepo, shared: true)
      truncate_all()
      on_exit(fn -> Sandbox.stop_owner(owner) end)
      :ok
    end

    test "mixed legacy and V02 rows dedupe while the legacy SHA-256 is still null" do
      raw = "Subject: legacy transition\r\n\r\nsame bytes"
      handoff = mailgun_handoff(provider_message_id: nil, raw_mime: raw)

      assert {:ok, %{status: :inserted}} = Persist.persist(handoff, repo: TestRepo, routes: [])

      TestRepo.query!(
        "UPDATE mailglass_inbound_evidence SET raw_mime_sha256 = NULL",
        []
      )

      assert {:ok, %{status: :duplicate}} = Persist.persist(handoff, repo: TestRepo, routes: [])
      assert TestRepo.aggregate(InboundRecord, :count) == 1
    end

    test "bounded backfill returns a resume cursor and converges safely on rerun" do
      for index <- 1..3 do
        handoff =
          mailgun_handoff(
            provider_message_id: "backfill-#{index}",
            raw_mime: "Subject: #{index}\r\n\r\nbody #{index}"
          )

        assert {:ok, %{status: :inserted}} = Persist.persist(handoff, repo: TestRepo, routes: [])
      end

      TestRepo.query!("UPDATE mailglass_inbound_evidence SET raw_mime_sha256 = NULL", [])

      ordered_ids =
        TestRepo.query!("SELECT id::text FROM mailglass_inbound_evidence ORDER BY id", []).rows
        |> List.flatten()

      assert {:ok, %{count: 2, next_cursor: cursor, done?: false}} =
               Persist.backfill_sha256(repo: TestRepo, limit: 2)

      assert cursor == Enum.at(ordered_ids, 1)

      assert {:ok, %{count: 1, next_cursor: next_cursor, done?: true}} =
               Persist.backfill_sha256(repo: TestRepo, limit: 2, after_id: cursor)

      assert is_binary(next_cursor)
      assert next_cursor == Enum.at(ordered_ids, 2)

      assert {:ok, %{count: 0, next_cursor: nil, done?: true}} =
               Persist.backfill_sha256(repo: TestRepo, limit: 2)

      assert %{rows: [[3]]} =
               TestRepo.query!(
                 "SELECT count(*) FROM mailglass_inbound_evidence WHERE raw_mime_sha256 IS NOT NULL",
                 []
               )
    end

    test "a concurrent backfill runner cannot advance or issue a misleading cursor" do
      assert {:error, :backfill_locked} =
               Persist.backfill_sha256(repo: BackfillLockedRepo, limit: 2)
    end

    test "Postmark keeps provider-message-id semantics even when MIME bytes match" do
      raw = "Subject: same\r\n\r\npostmark bytes"

      first = valid_handoff()
      first = %{first | message: %{first.message | provider_message_id: "pm-one"}}
      first = %{first | evidence: Map.put(first.evidence, :raw_mime, raw)}

      second = valid_handoff()
      second = %{second | message: %{second.message | provider_message_id: "pm-two"}}
      second = %{second | evidence: Map.put(second.evidence, :raw_mime, raw)}

      assert {:ok, %{status: :inserted}} = Persist.persist(first, repo: TestRepo, routes: [])
      assert {:ok, %{status: :inserted}} = Persist.persist(second, repo: TestRepo, routes: [])
      assert TestRepo.aggregate(InboundRecord, :count) == 2
    end

    test "terminal persistence stores exact signed bytes and JSON-safe headers" do
      raw = <<0, 255, 10, 13, 123, 125>>

      request = %{
        raw_body: raw,
        headers: [
          {"X-Test", "one"},
          {"x-test", "two"},
          {:malformed, :ignored}
        ]
      }

      verified = %{
        envelope: %{"Type" => "Notification", "MessageId" => "sns-1"},
        verification_facts: %{"auth" => "sns_x509"},
        warnings: %{}
      }

      assert {:ok, %{status: :inserted, inbound_evidence: evidence}} =
               Persist.persist_terminal_failure(
                 "tenant-terminal",
                 :ses,
                 request,
                 verified,
                 :s3_fetch_failed,
                 repo: TestRepo,
                 routes: []
               )

      persisted = TestRepo.get!(InboundEvidence, evidence.id)
      assert persisted.raw_signed_request == raw
      assert persisted.raw_headers == %{"x-test" => ["one", "two"]}
      assert persisted.terminal_failure_class == "s3_fetch_failed"
      assert persisted.terminal_context["replayable"] == true
    end
  end

  describe "suppression flag-only contract (IOPS-05)" do
    setup do
      previous = Application.get_env(:mailglass, :suppression_store)
      Application.put_env(:mailglass, :suppression_store, StubSuppressionStore)
      Mailglass.Runtime.reset_for_test!()

      on_exit(fn ->
        if previous do
          Application.put_env(:mailglass, :suppression_store, previous)
        else
          Application.delete_env(:mailglass, :suppression_store)
        end

        Mailglass.Runtime.reset_for_test!()

        Process.delete(:mailglass_inbound_stub_suppression_reply)
      end)

      :ok
    end

    test "a message from a suppressed sender persists with suppression_flagged: true" do
      Process.put(
        :mailglass_inbound_stub_suppression_reply,
        {:suppressed, %Mailglass.Suppression.Entry{}}
      )

      {:ok, _result} = Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)

      record = inserted_record()
      assert record.suppression_flagged == true
    end

    test "a non-suppressed sender persists with suppression_flagged: false" do
      Process.put(:mailglass_inbound_stub_suppression_reply, :not_suppressed)

      {:ok, _result} = Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)

      record = inserted_record()
      assert record.suppression_flagged == false
    end

    test "degrades OPEN on a store {:error, _}: flag is false AND persist succeeds" do
      Process.put(:mailglass_inbound_stub_suppression_reply, {:error, :boom})

      assert {:ok, result} = Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)
      assert result.status == :inserted

      record = inserted_record()
      assert record.suppression_flagged == false
    end

    test "degrades OPEN on an empty from: flag is false AND persist succeeds" do
      # The store would say suppressed, but with no from-address there is nothing
      # to look up, so the flag is false without ever consulting the store.
      Process.put(
        :mailglass_inbound_stub_suppression_reply,
        {:suppressed, %Mailglass.Suppression.Entry{}}
      )

      handoff = put_in(valid_handoff().message.from, [])

      assert {:ok, result} = Persist.persist(handoff, repo: FakeRepo, router: TestRouter)
      assert result.status == :inserted

      record = inserted_record()
      assert record.suppression_flagged == false
    end

    test "no auto-bounce: a suppressed sender still reaches the mailbox (route matched)" do
      Process.put(
        :mailglass_inbound_stub_suppression_reply,
        {:suppressed, %Mailglass.Suppression.Entry{}}
      )

      {:ok, result} = Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)

      # The message is preserved and routed; the adopter decides reject/process.
      assert result.status == :inserted
      assert result.route == %{status: :matched, mailbox: SupportMailbox}
      assert %InboundMessage{} = result.message
    end

    test "emits a PII-free [:mailglass_inbound, :ingress, :suppression_flag, :stop] span" do
      Process.put(
        :mailglass_inbound_stub_suppression_reply,
        {:suppressed, %Mailglass.Suppression.Entry{}}
      )

      ref = make_ref()
      parent = self()
      event = [:mailglass_inbound, :ingress, :suppression_flag, :stop]

      :telemetry.attach(
        "suppression-flag-test-#{inspect(ref)}",
        event,
        fn ^event, measurements, metadata, _config ->
          send(parent, {ref, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("suppression-flag-test-#{inspect(ref)}") end)

      {:ok, _result} = Persist.persist(valid_handoff(), repo: FakeRepo, router: TestRouter)

      assert_receive {^ref, measurements, metadata}, 1_000
      assert is_integer(measurements.duration)

      assert metadata.flagged == true
      assert metadata.tenant_id == "tenant-123"
      assert metadata.provider == "postmark"

      # No PII may ride the suppression-flag span.
      for forbidden <- [:address, :from, :to, :recipient, :sender, :email, :subject] do
        refute Map.has_key?(metadata, forbidden)
      end
    end
  end

  defp inserted_record do
    Process.get(:mailglass_inbound_inserts, [])
    |> Enum.find(&match?(%InboundRecord{}, &1))
  end

  defp ses_handoff(opts) do
    provider_message_id = Keyword.get(opts, :provider_message_id)
    raw_mime = Keyword.get(opts, :raw_mime)

    %{
      tenant_id: "ses-tenant",
      provider: :ses,
      message: %InboundMessage{
        tenant_id: "ses-tenant",
        provider: :ses,
        provider_message_id: provider_message_id,
        message_id: provider_message_id,
        envelope_recipient: "support@example.com",
        from: [%{address: "sender@example.com"}],
        to: [%{address: "support@example.com"}],
        subject: "SES dedupe",
        headers: %{},
        received_at: DateTime.utc_now()
      },
      evidence: %{
        raw_payload: %{"Type" => "Notification"},
        raw_headers: %{},
        raw_mime: raw_mime,
        verification_facts: %{auth: :sns_x509},
        parse_warnings: %{},
        attachment_blobs: %{}
      }
    }
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
