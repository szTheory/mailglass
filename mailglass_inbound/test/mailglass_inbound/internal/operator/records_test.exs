defmodule MailglassInbound.Internal.Operator.RecordsTest do
  @moduledoc """
  V1 (unit half) — the tenant-safety proof for the inbound admin read-model
  (IADM-01 seam). Covers the three guarantees the admin gateway depends on:

  1. A blank/missing tenant returns `[]`/`nil` — never raises, never leaks
     (D-48-04, tenant-required-or-empty).
  2. A tenant-A query returns ONLY tenant-A rows; tenant-B rows are invisible
     (T-48-01 cross-tenant isolation, enforced by the explicit `tenant_id`
     where-clause regardless of the configured `Tenancy.scope/2` resolver).
  3. The outcome filter casts against `ExecutionRun.__outcomes__/0`; an unknown
     outcome is ignored (the filter is dropped), never passed to SQL.

  The timeline + detail read-models are covered here too for tenant isolation and
  the ExecutionRun-not-ReplayRun source rule (Pitfall 7).
  """

  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.Internal.Operator.Detail
  alias MailglassInbound.Internal.Operator.Records
  alias MailglassInbound.Internal.Operator.Timeline
  alias MailglassInbound.TestRepo

  setup do
    :ok = Sandbox.checkout(TestRepo)
    :ok
  end

  describe "Records.list_records/2 tenant safety" do
    test "blank tenant returns []" do
      assert Records.list_records(%{tenant_id: ""}, []) == []
    end

    test "missing tenant returns []" do
      assert Records.list_records(%{}, []) == []
    end

    test "nil tenant returns []" do
      assert Records.list_records(%{tenant_id: nil}, []) == []
    end

    test "returns ONLY the queried tenant's rows" do
      {:ok, record_a} = insert_record("tenant-a", recipient: "a@example.com")
      {:ok, _record_b} = insert_record("tenant-b", recipient: "b@example.com")

      ids = %{tenant_id: "tenant-a"} |> Records.list_records([]) |> Enum.map(& &1.id)

      assert record_a.id in ids
      assert length(ids) == 1
    end

    test "does not leak another tenant's row even with a matching provider filter" do
      {:ok, _record_b} = insert_record("tenant-b", provider: "postmark")

      assert Records.list_records(%{tenant_id: "tenant-a", provider: "postmark"}, []) == []
    end
  end

  describe "Records.list_records/2 outcome filter" do
    test "filters records to those with a matching execution-run outcome" do
      {:ok, accepted} = insert_record("tenant-a")
      {:ok, accepted_ev} = insert_evidence("tenant-a", accepted.id)
      {:ok, _run} = insert_run("tenant-a", accepted.id, accepted_ev.id, outcome: :accept)

      {:ok, bounced} = insert_record("tenant-a")
      {:ok, bounced_ev} = insert_evidence("tenant-a", bounced.id)

      {:ok, _run} =
        insert_run("tenant-a", bounced.id, bounced_ev.id,
          outcome: :bounce,
          outcome_reason: "mailbox full"
        )

      ids =
        %{tenant_id: "tenant-a", outcome: :accept}
        |> Records.list_records([])
        |> Enum.map(& &1.id)

      assert accepted.id in ids
      refute bounced.id in ids
    end

    test "an unknown outcome value is ignored (filter dropped), not passed to SQL" do
      {:ok, record} = insert_record("tenant-a")

      # :totally_not_an_outcome is not in ExecutionRun.__outcomes__/0 — the filter
      # must be dropped, so the full tenant list comes back (no SQL cast crash).
      ids =
        Records.list_records(%{tenant_id: "tenant-a", outcome: :totally_not_an_outcome}, [])
        |> Enum.map(& &1.id)

      assert record.id in ids
    end

    test "an unknown outcome STRING is ignored without raising on to_existing_atom" do
      {:ok, record} = insert_record("tenant-a")

      ids =
        Records.list_records(%{tenant_id: "tenant-a", outcome: "definitely-unknown-#{System.unique_integer()}"}, [])
        |> Enum.map(& &1.id)

      assert record.id in ids
    end
  end

  describe "Timeline.list_runs/2" do
    test "blank tenant returns []" do
      assert Timeline.list_runs(%{tenant_id: "", inbound_record_id: Ecto.UUID.generate()}, []) ==
               []
    end

    test "returns ALL runs (fresh + replay) for a record, chronologically, scoped to tenant" do
      {:ok, record} = insert_record("tenant-a")
      {:ok, evidence} = insert_evidence("tenant-a", record.id)

      {:ok, _fresh} =
        insert_run("tenant-a", record.id, evidence.id, source: :fresh, outcome: :accept)

      {:ok, _replay} =
        insert_run("tenant-a", record.id, evidence.id, source: :replay, outcome: :accept)

      runs = Timeline.list_runs(%{tenant_id: "tenant-a", inbound_record_id: record.id}, [])

      assert length(runs) == 2
      assert Enum.map(runs, & &1.source) |> Enum.sort() == [:fresh, :replay]
    end

    test "does not return another tenant's runs" do
      {:ok, record} = insert_record("tenant-b")
      {:ok, evidence} = insert_evidence("tenant-b", record.id)
      {:ok, _run} = insert_run("tenant-b", record.id, evidence.id, outcome: :accept)

      assert Timeline.list_runs(%{tenant_id: "tenant-a", inbound_record_id: record.id}, []) == []
    end
  end

  describe "Detail.fetch/2" do
    test "blank tenant returns nil" do
      assert Detail.fetch(%{tenant_id: "", inbound_record_id: Ecto.UUID.generate()}, []) == nil
    end

    test "returns the record + evidence + matched outcome from the latest fresh run" do
      {:ok, record} = insert_record("tenant-a", recipient: "support@example.com")
      {:ok, evidence} = insert_evidence("tenant-a", record.id)

      {:ok, _run} =
        insert_run("tenant-a", record.id, evidence.id,
          source: :fresh,
          mailbox: "MyApp.SupportMailbox",
          outcome: :accept
        )

      assert %{
               record: %{id: record_id},
               evidence: %{id: _},
               mailbox: "MyApp.SupportMailbox",
               outcome: :accept
             } = Detail.fetch(%{tenant_id: "tenant-a", inbound_record_id: record.id}, [])

      assert record_id == record.id
    end

    test "returns nil for a record that belongs to a different tenant (gate before replay)" do
      {:ok, record} = insert_record("tenant-b")

      assert Detail.fetch(%{tenant_id: "tenant-a", inbound_record_id: record.id}, []) == nil
    end
  end

  # ---------------------------------------------------------------------------
  # Fixtures — DB rows via the package-local InboundRecords boundary.
  # ---------------------------------------------------------------------------

  defp insert_record(tenant_id, opts \\ []) do
    InboundRecords.insert_inbound_record(%{
      tenant_id: tenant_id,
      provider: Keyword.get(opts, :provider, "postmark"),
      provider_message_id: Keyword.get(opts, :provider_message_id, unique("pmid")),
      envelope_recipient: Keyword.get(opts, :recipient, "support@example.com"),
      subject: Keyword.get(opts, :subject, "Inbound fixture"),
      received_at: Keyword.get(opts, :received_at, DateTime.utc_now())
    })
  end

  defp insert_evidence(tenant_id, record_id) do
    InboundRecords.insert_inbound_evidence(%{
      tenant_id: tenant_id,
      inbound_record_id: record_id,
      provider: "postmark",
      raw_payload: %{"ok" => true}
    })
  end

  defp insert_run(tenant_id, record_id, evidence_id, opts) do
    base = %{
      tenant_id: tenant_id,
      inbound_record_id: record_id,
      inbound_evidence_id: evidence_id,
      source: Keyword.get(opts, :source, :fresh),
      outcome: Keyword.fetch!(opts, :outcome),
      executed_at: Keyword.get(opts, :executed_at, DateTime.utc_now())
    }

    attrs =
      base
      |> maybe_put(:mailbox, Keyword.get(opts, :mailbox, default_mailbox(base.outcome)))
      |> maybe_put(:outcome_reason, Keyword.get(opts, :outcome_reason, default_reason(base.outcome)))

    InboundRecords.insert_execution_run(attrs)
  end

  # ExecutionRun.validate_outcome_shape/1 requires a mailbox for accept/ignore/
  # reject/bounce and an outcome_reason for reject/bounce; :no_match takes nil.
  defp default_mailbox(:no_match), do: nil
  defp default_mailbox(_outcome), do: "MyApp.Mailboxes.SupportMailbox"

  defp default_reason(outcome) when outcome in [:reject, :bounce], do: "fixture reason"
  defp default_reason(_outcome), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp unique(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"
end
