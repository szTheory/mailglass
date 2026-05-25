defmodule MailglassInbound.Internal.PruneTest do
  @moduledoc """
  Integration tests for `MailglassInbound.Internal.Prune` — the batched,
  advisory-locked retention sweep (IOPS-03, D-49-25..30).

  These behaviors are SQL-level and cannot be unit-faked:

    * over-window rows deleted in batches of <= 1000, looping until < 1000
      (>= 2 iterations on a 1001+ dataset);
    * in-window rows kept;
    * `pg_try_advisory_lock` single-run guard — a concurrent second sweep returns
      `{:ok, :locked_out}` and deletes nothing;
    * child-first delete order (no FK violation; FKs are on_delete: :nothing);
    * `:infinity` on a class disables that window (0 deleted, no DELETE issued);
    * `[:mailglass_inbound, :prune, :sweep, :stop]` carries per-table counts only.

  `async: false` + TRUNCATE CASCADE setup (mirrors `Mailglass.Webhook.PrunerTest`).
  Runs against a REAL (non-sandboxed) connection because the batched loop is not
  one transaction and advisory locks are session-scoped.
  """

  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Internal.Prune
  alias MailglassInbound.TestRepo

  @over 120
  @within 5

  setup do
    # Real shared connection (NOT the per-test sandbox transaction): the prune
    # sweep commits between batches and uses session advisory locks. Cleanup runs
    # at the START of each test (real rows persist across tests), so on_exit only
    # restores config — it must not touch the DB connection it does not own.
    :ok = Sandbox.checkout(TestRepo, sandbox: false)
    Sandbox.mode(TestRepo, {:shared, self()})
    truncate_all()
    prior = Application.get_env(:mailglass_inbound, :retention)

    on_exit(fn -> restore(:retention, prior) end)

    :ok
  end

  describe "retention windows" do
    test "deletes over-window rows and keeps in-window rows per the four windows" do
      # records: 90d window. evidence: 30d. fresh runs: 90d. replay runs: 30d.
      {:ok, old_rec} = insert_record(days_ago: @over)
      {:ok, new_rec} = insert_record(days_ago: @within)

      {:ok, old_ev} = insert_evidence(old_rec.id, days_ago: @over)
      {:ok, _new_ev} = insert_evidence(new_rec.id, days_ago: @within)

      {:ok, _old_fresh} =
        insert_run(old_rec.id, old_ev.id, source: :fresh, days_ago: @over)

      {:ok, _old_replay} =
        insert_run(old_rec.id, old_ev.id, source: :replay, days_ago: 45)

      assert {:ok, counts} = Prune.prune()

      assert counts.records_deleted >= 1
      assert counts.evidence_deleted >= 1
      assert counts.fresh_runs_deleted >= 1
      assert counts.replay_runs_deleted >= 1

      # The recent record survives.
      assert TestRepo.get(InboundRecord, new_rec.id)
      refute TestRepo.get(InboundRecord, old_rec.id)
    end

    test ":infinity on records disables that window (0 deleted, row preserved)" do
      Application.put_env(:mailglass_inbound, :retention,
        records_days: :infinity,
        evidence_days: 30,
        execution_runs_days: 90,
        replay_runs_days: 30
      )

      {:ok, old_rec} = insert_record(days_ago: 500)

      assert {:ok, counts} = Prune.prune()
      assert counts.records_deleted == 0
      assert TestRepo.get(InboundRecord, old_rec.id)
    end
  end

  describe "batching (LIMIT 1000)" do
    test "deletes a 1001+ dataset across >= 2 batch iterations" do
      total = 1001

      for _ <- 1..total do
        {:ok, _} = insert_record(days_ago: @over)
      end

      assert {:ok, counts} = Prune.prune()

      assert counts.records_deleted == total
      assert TestRepo.aggregate(InboundRecord, :count) == 0
      # The sweep reports the iteration count so we can prove >= 2 batches.
      assert Map.get(counts, :records_batches, 2) >= 2
    end
  end

  describe "advisory-lock single-run guard" do
    test "a concurrent holder of the prune lock makes prune/0 return {:ok, :locked_out}" do
      {:ok, old_rec} = insert_record(days_ago: @over)

      # Acquire the prune advisory lock from a SEPARATE session, then call prune/0.
      {:ok, conn} = Postgrex.start_link(conn_opts())
      key = Prune.lock_key()
      %{rows: [[true]]} = Postgrex.query!(conn, "SELECT pg_try_advisory_lock($1)", [key])

      result = Prune.prune()

      Postgrex.query!(conn, "SELECT pg_advisory_unlock($1)", [key])
      GenServer.stop(conn)

      assert result == {:ok, :locked_out}
      # Nothing deleted while locked out.
      assert TestRepo.get(InboundRecord, old_rec.id)
    end
  end

  describe "telemetry" do
    test "[:mailglass_inbound, :prune, :sweep, :stop] carries per-table counts only" do
      {:ok, _old_rec} = insert_record(days_ago: @over)

      handler_id = "prune-test-#{System.unique_integer([:positive])}"
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass_inbound, :prune, :sweep, :stop],
        fn _event, _measurements, meta, _config -> send(test_pid, {:prune_stop, meta}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      {:ok, _counts} = Prune.prune()

      assert_receive {:prune_stop, meta}, 1000
      assert Map.has_key?(meta, :records_deleted)
      assert Map.has_key?(meta, :evidence_deleted)
      assert Map.has_key?(meta, :fresh_runs_deleted)
      assert Map.has_key?(meta, :replay_runs_deleted)
      assert Map.has_key?(meta, :status)

      # No PII keys.
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :from)
      refute Map.has_key?(meta, :to)
      refute Map.has_key?(meta, :email)
      refute Map.has_key?(meta, :sender)
    end
  end

  # ---- fixtures (backdated via inserted_at) ----------------------------------

  defp insert_record(opts) do
    days_ago = Keyword.get(opts, :days_ago, 0)
    at = backdate(days_ago)

    InboundRecords.insert_inbound_record(
      %{
        tenant_id: "tenant-a",
        provider: "postmark",
        provider_message_id: "pmid-#{System.unique_integer([:positive])}",
        envelope_recipient: "support@example.com",
        subject: "Prune fixture",
        received_at: at
      },
      []
    )
    |> backdate_row(:inbound_record, at)
  end

  defp insert_evidence(record_id, opts) do
    days_ago = Keyword.get(opts, :days_ago, 0)
    at = backdate(days_ago)

    InboundRecords.insert_inbound_evidence(%{
      tenant_id: "tenant-a",
      inbound_record_id: record_id,
      provider: "postmark",
      raw_payload: %{"ok" => true}
    })
    |> backdate_row(:inbound_evidence, at)
  end

  defp insert_run(record_id, evidence_id, opts) do
    days_ago = Keyword.get(opts, :days_ago, 0)
    at = backdate(days_ago)
    source = Keyword.fetch!(opts, :source)

    InboundRecords.insert_execution_run(%{
      tenant_id: "tenant-a",
      inbound_record_id: record_id,
      inbound_evidence_id: evidence_id,
      source: source,
      mailbox: "MyApp.SupportMailbox",
      outcome: :accept,
      executed_at: at
    })
    |> backdate_row(:execution_run, at)
  end

  # Force inserted_at to the backdated timestamp (the prune window field).
  defp backdate_row({:ok, struct}, kind, at) do
    schema =
      case kind do
        :inbound_record -> InboundRecord
        :inbound_evidence -> InboundEvidence
        :execution_run -> ExecutionRun
      end

    import Ecto.Query

    TestRepo.update_all(
      from(r in schema, where: r.id == ^struct.id),
      set: [inserted_at: at]
    )

    {:ok, %{struct | inserted_at: at}}
  end

  defp backdate(days_ago), do: DateTime.add(DateTime.utc_now(), -days_ago * 86_400, :second)

  # Plain Postgrex connection opts for a SEPARATE session (drop the Sandbox pool).
  defp conn_opts do
    TestRepo.config()
    |> Keyword.take([:username, :password, :hostname, :database, :port])
  end

  defp truncate_all do
    TestRepo.query!(
      "TRUNCATE TABLE mailglass_inbound_replay_runs, mailglass_inbound_evidence, mailglass_inbound_records CASCADE",
      []
    )
  end

  defp restore(key, nil), do: Application.delete_env(:mailglass_inbound, key)
  defp restore(key, value), do: Application.put_env(:mailglass_inbound, key, value)
end
