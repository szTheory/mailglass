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

  describe "Records.list_providers/2" do
    test "blank tenant returns []" do
      assert Records.list_providers(%{tenant_id: ""}, []) == []
      assert Records.list_providers(%{}, []) == []
    end

    test "returns distinct providers for one tenant within the window" do
      now = DateTime.utc_now()

      {:ok, _} = insert_record("tenant-prov", provider: "mailgun", received_at: DateTime.add(now, -1, :hour))
      {:ok, _} = insert_record("tenant-prov", provider: "mailgun", received_at: DateTime.add(now, -2, :hour))
      {:ok, _} = insert_record("tenant-prov", provider: "ses", received_at: DateTime.add(now, -3, :hour))
      # Outside a 24h window — excluded.
      {:ok, _} = insert_record("tenant-prov", provider: "postmark", received_at: DateTime.add(now, -48, :hour))
      # Another tenant — never leaks.
      {:ok, _} = insert_record("tenant-other", provider: "sparkpost", received_at: DateTime.add(now, -1, :hour))

      assert Records.list_providers(%{tenant_id: "tenant-prov", window_hours: 24}, []) ==
               ["mailgun", "ses"]
    end
  end

  describe "Records.list_records_page/2" do
    test "returns honest total and first-page boundaries from tenant and filter scoped count" do
      now = DateTime.utc_now()

      matching =
        for offset <- 1..3 do
          {:ok, record} =
            insert_record("tenant-page",
              provider: "postmark",
              recipient: "page-#{offset}@example.com",
              received_at: DateTime.add(now, -offset, :second)
            )

          record
        end

      {:ok, _foreign} =
        insert_record("tenant-other",
          provider: "postmark",
          recipient: "foreign@example.com",
          received_at: now
        )

      {:ok, _filtered_out} =
        insert_record("tenant-page",
          provider: "sendgrid",
          recipient: "filtered@example.com",
          received_at: now
        )

      page =
        Records.list_records_page(
          %{tenant_id: "tenant-page", provider: "postmark", page: 1, per_page: 2},
          []
        )

      assert %{
               entries: entries,
               total_count: 3,
               page: 1,
               per_page: 2,
               total_pages: 2,
               has_previous?: false,
               has_next?: true
             } = page

      assert Enum.map(entries, & &1.id) == matching |> Enum.take(2) |> Enum.map(& &1.id)
      assert Enum.count(entries) == 2
    end

    test "returns last-page entries with boundary metadata" do
      now = DateTime.utc_now()

      records =
        for offset <- 1..3 do
          {:ok, record} =
            insert_record("tenant-last",
              provider: "postmark",
              recipient: "last-#{offset}@example.com",
              received_at: DateTime.add(now, -offset, :second)
            )

          record
        end

      page =
        Records.list_records_page(%{tenant_id: "tenant-last", page: 2, per_page: 2}, [])

      assert %{
               entries: [%{id: id}],
               total_count: 3,
               page: 2,
               per_page: 2,
               total_pages: 2,
               has_previous?: true,
               has_next?: false
             } = page

      assert id == records |> List.last() |> Map.fetch!(:id)
    end
  end

  describe "Records.list_records/2 disposition projection (WR-01)" do
    test "a matched record projects its latest-fresh-run outcome + mailbox" do
      {:ok, record} = insert_record("tenant-a")
      {:ok, evidence} = insert_evidence("tenant-a", record.id)

      {:ok, _run} =
        insert_run("tenant-a", record.id, evidence.id,
          source: :fresh,
          mailbox: "MyApp.SupportMailbox",
          outcome: :accept
        )

      assert [row] = Records.list_records(%{tenant_id: "tenant-a"}, [])
      assert row.id == record.id
      assert row.outcome == :accept
      assert row.mailbox == "MyApp.SupportMailbox"
    end

    test "a :no_match record projects a nil mailbox (reads as 'no match')" do
      {:ok, record} = insert_record("tenant-a")
      {:ok, evidence} = insert_evidence("tenant-a", record.id)

      {:ok, _run} =
        insert_run("tenant-a", record.id, evidence.id, source: :fresh, outcome: :no_match)

      assert [row] = Records.list_records(%{tenant_id: "tenant-a"}, [])
      assert row.outcome == :no_match
      assert row.mailbox == nil
    end

    test "a record with no fresh run projects nil outcome + nil mailbox" do
      {:ok, record} = insert_record("tenant-a")

      assert [row] = Records.list_records(%{tenant_id: "tenant-a"}, [])
      assert row.id == record.id
      assert row.outcome == nil
      assert row.mailbox == nil
    end

    test "projects the LATEST fresh run when a record has several" do
      {:ok, record} = insert_record("tenant-a")
      {:ok, evidence} = insert_evidence("tenant-a", record.id)

      {:ok, _older} =
        insert_run("tenant-a", record.id, evidence.id,
          source: :fresh,
          mailbox: "MyApp.OldMailbox",
          outcome: :accept,
          executed_at: DateTime.add(DateTime.utc_now(), -3600, :second)
        )

      {:ok, _newer} =
        insert_run("tenant-a", record.id, evidence.id,
          source: :fresh,
          mailbox: "MyApp.NewMailbox",
          outcome: :ignore
        )

      assert [row] = Records.list_records(%{tenant_id: "tenant-a"}, [])
      assert row.outcome == :ignore
      assert row.mailbox == "MyApp.NewMailbox"
    end

    test "ignores a replay run, projecting only the latest FRESH disposition" do
      {:ok, record} = insert_record("tenant-a")
      {:ok, evidence} = insert_evidence("tenant-a", record.id)

      {:ok, _fresh} =
        insert_run("tenant-a", record.id, evidence.id,
          source: :fresh,
          mailbox: "MyApp.FreshMailbox",
          outcome: :accept
        )

      {:ok, _replay} =
        insert_run("tenant-a", record.id, evidence.id,
          source: :replay,
          mailbox: "MyApp.ReplayMailbox",
          outcome: :ignore
        )

      assert [row] = Records.list_records(%{tenant_id: "tenant-a"}, [])
      assert row.outcome == :accept
      assert row.mailbox == "MyApp.FreshMailbox"
    end

    test "the disposition subquery is tenant-scoped — a foreign run never leaks in" do
      # tenant-a record with NO run of its own; tenant-b has an :accept run.
      # The correlated subquery filters by tenant_id, so tenant-a's row must
      # project nil disposition rather than borrowing tenant-b's run.
      {:ok, record_a} = insert_record("tenant-a")

      {:ok, record_b} = insert_record("tenant-b")
      {:ok, ev_b} = insert_evidence("tenant-b", record_b.id)

      {:ok, _b_run} =
        insert_run("tenant-b", record_b.id, ev_b.id,
          source: :fresh,
          mailbox: "MyApp.BMailbox",
          outcome: :accept
        )

      assert [row] = Records.list_records(%{tenant_id: "tenant-a"}, [])
      assert row.id == record_a.id
      assert row.outcome == nil
      assert row.mailbox == nil
    end
  end

  describe "Records.list_records/2 suppression flag projection (IOPS-05)" do
    test "the list select surfaces each record's suppression_flagged column" do
      {:ok, flagged} = insert_record("tenant-a", suppression_flagged: true)
      {:ok, clean} = insert_record("tenant-a", suppression_flagged: false)

      rows = Records.list_records(%{tenant_id: "tenant-a"}, [])
      by_id = Map.new(rows, &{&1.id, &1})

      assert Map.has_key?(by_id[flagged.id], :suppression_flagged)
      assert by_id[flagged.id].suppression_flagged == true
      assert by_id[clean.id].suppression_flagged == false
    end

    test "a record left at the column default reads suppression_flagged: false" do
      {:ok, record} = insert_record("tenant-a")

      assert [row] = Records.list_records(%{tenant_id: "tenant-a"}, [])
      assert row.id == record.id
      assert row.suppression_flagged == false
    end
  end

  describe "Records.list_records/2 search filter (WR-03)" do
    test "blank search is a no-op (returns all)" do
      {:ok, r1} = insert_record("tenant-a", subject: "Invoice #42")
      {:ok, r2} = insert_record("tenant-a", subject: "Welcome aboard")

      ids =
        %{tenant_id: "tenant-a", search: ""}
        |> Records.list_records([])
        |> Enum.map(& &1.id)

      assert r1.id in ids
      assert r2.id in ids
    end

    test "missing search is a no-op (returns all)" do
      {:ok, r1} = insert_record("tenant-a")
      {:ok, r2} = insert_record("tenant-a")

      ids = %{tenant_id: "tenant-a"} |> Records.list_records([]) |> Enum.map(& &1.id)
      assert r1.id in ids
      assert r2.id in ids
    end

    test "narrows results by a case-insensitive subject substring" do
      {:ok, invoice} = insert_record("tenant-a", subject: "Invoice #42 due")
      {:ok, _welcome} = insert_record("tenant-a", subject: "Welcome aboard")

      ids =
        %{tenant_id: "tenant-a", search: "invoice"}
        |> Records.list_records([])
        |> Enum.map(& &1.id)

      assert ids == [invoice.id]
    end

    test "matches against the envelope recipient" do
      {:ok, support} = insert_record("tenant-a", recipient: "support@acme.test")
      {:ok, _billing} = insert_record("tenant-a", recipient: "billing@other.test")

      ids =
        %{tenant_id: "tenant-a", search: "ACME"}
        |> Records.list_records([])
        |> Enum.map(& &1.id)

      assert ids == [support.id]
    end

    test "matches against the provider message id" do
      {:ok, target} = insert_record("tenant-a", provider_message_id: "needle-abc-123")
      {:ok, _other} = insert_record("tenant-a", provider_message_id: "haystack-zzz")

      ids =
        %{tenant_id: "tenant-a", search: "needle-abc"}
        |> Records.list_records([])
        |> Enum.map(& &1.id)

      assert ids == [target.id]
    end

    test "treats LIKE wildcards as literals (no widening)" do
      {:ok, _literal} = insert_record("tenant-a", subject: "100% complete")
      {:ok, _other} = insert_record("tenant-a", subject: "plain subject")

      # "%%" must NOT match every row — the % is escaped to a literal.
      ids =
        %{tenant_id: "tenant-a", search: "100%%"}
        |> Records.list_records([])
        |> Enum.map(& &1.id)

      assert ids == []
    end

    test "stays tenant-scoped — a matching foreign row is invisible" do
      {:ok, _foreign} = insert_record("tenant-b", subject: "shared keyword")

      assert Records.list_records(%{tenant_id: "tenant-a", search: "shared keyword"}, []) == []
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
      received_at: Keyword.get(opts, :received_at, DateTime.utc_now()),
      suppression_flagged: Keyword.get(opts, :suppression_flagged, false)
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
