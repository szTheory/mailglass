defmodule MailglassInbound.Internal.Operator.SummaryTest do
  @moduledoc """
  Tenant-safe aggregate coverage for the internal inbound operator summary seam.
  """

  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.Internal.Operator.Summary
  alias MailglassInbound.TestRepo

  @zero_summary %{
    total: 0,
    outcomes: %{no_match: 0, accept: 0, ignore: 0, reject: 0, bounce: 0, failed: 0},
    unclassified: 0,
    no_match_rate: 0.0
  }

  setup do
    :ok = Sandbox.checkout(TestRepo)
    :ok
  end

  describe "Summary.summarize/2 tenant guard" do
    test "blank tenant returns the zero summary" do
      assert Summary.summarize(%{tenant_id: ""}, []) == @zero_summary
    end

    test "missing tenant returns the zero summary" do
      assert Summary.summarize(%{}, []) == @zero_summary
    end

    test "nil tenant returns the zero summary" do
      assert Summary.summarize(%{tenant_id: nil}, []) == @zero_summary
    end
  end

  describe "Summary.summarize/2 tenant safety and filters" do
    test "cross-tenant isolation keeps tenant B records and runs out of tenant A totals" do
      {:ok, record_a} = insert_record("tenant-a")
      {:ok, evidence_a} = insert_evidence("tenant-a", record_a.id)
      {:ok, _run_a} = insert_run("tenant-a", record_a.id, evidence_a.id, outcome: :accept)

      {:ok, record_b} = insert_record("tenant-b")
      {:ok, evidence_b} = insert_evidence("tenant-b", record_b.id)
      {:ok, _run_b} = insert_run("tenant-b", record_b.id, evidence_b.id, outcome: :failed)

      assert %{
               total: 1,
               outcomes: %{accept: 1, failed: 0},
               unclassified: 0
             } = summary = Summary.summarize(%{tenant_id: "tenant-a"}, [])

      assert summary.no_match_rate == 0.0
    end

    test "provider filter narrows totals" do
      {:ok, postmark} = insert_record("tenant-a", provider: "postmark")
      {:ok, postmark_ev} = insert_evidence("tenant-a", postmark.id, provider: "postmark")
      {:ok, _run} = insert_run("tenant-a", postmark.id, postmark_ev.id, outcome: :accept)

      {:ok, sendgrid} = insert_record("tenant-a", provider: "sendgrid")
      {:ok, sendgrid_ev} = insert_evidence("tenant-a", sendgrid.id, provider: "sendgrid")
      {:ok, _run} = insert_run("tenant-a", sendgrid.id, sendgrid_ev.id, outcome: :bounce)

      assert %{
               total: 1,
               outcomes: %{accept: 1, bounce: 0},
               unclassified: 0
             } = Summary.summarize(%{tenant_id: "tenant-a", provider: "postmark"}, [])
    end

    test "search filter narrows totals by subject, recipient, or provider message id" do
      {:ok, target} =
        insert_record("tenant-a",
          subject: "Escalated invoice",
          recipient: "billing@example.com",
          provider_message_id: "pmid-target"
        )

      {:ok, target_ev} = insert_evidence("tenant-a", target.id)
      {:ok, _run} = insert_run("tenant-a", target.id, target_ev.id, outcome: :reject)

      {:ok, other} =
        insert_record("tenant-a",
          subject: "Welcome",
          recipient: "support@example.com",
          provider_message_id: "pmid-other"
        )

      {:ok, other_ev} = insert_evidence("tenant-a", other.id)
      {:ok, _run} = insert_run("tenant-a", other.id, other_ev.id, outcome: :accept)

      assert %{
               total: 1,
               outcomes: %{reject: 1, accept: 0},
               unclassified: 0
             } = Summary.summarize(%{tenant_id: "tenant-a", search: "invoice"}, [])
    end

    test "window filter narrows totals" do
      recent = DateTime.utc_now()
      old = DateTime.add(recent, -72, :hour)

      {:ok, fresh} = insert_record("tenant-a", received_at: recent)
      {:ok, fresh_ev} = insert_evidence("tenant-a", fresh.id)
      {:ok, _run} = insert_run("tenant-a", fresh.id, fresh_ev.id, outcome: :accept)

      {:ok, stale} = insert_record("tenant-a", received_at: old)
      {:ok, stale_ev} = insert_evidence("tenant-a", stale.id)
      {:ok, _run} = insert_run("tenant-a", stale.id, stale_ev.id, outcome: :bounce)

      assert %{
               total: 1,
               outcomes: %{accept: 1, bounce: 0},
               unclassified: 0
             } = Summary.summarize(%{tenant_id: "tenant-a", window_hours: 24}, [])
    end

    test "outcome filter is ignored for denominator and breakdown" do
      {:ok, accepted} = insert_record("tenant-a")
      {:ok, accepted_ev} = insert_evidence("tenant-a", accepted.id)
      {:ok, _run} = insert_run("tenant-a", accepted.id, accepted_ev.id, outcome: :accept)

      {:ok, bounced} = insert_record("tenant-a")
      {:ok, bounced_ev} = insert_evidence("tenant-a", bounced.id)
      {:ok, _run} = insert_run("tenant-a", bounced.id, bounced_ev.id, outcome: :bounce)

      assert %{
               total: 2,
               outcomes: %{accept: 1, bounce: 1}
             } = Summary.summarize(%{tenant_id: "tenant-a", outcome: :accept}, [])
    end

    test "over-100 records are counted exactly, not through the capped list model" do
      for _ <- 1..101 do
        {:ok, _record} = insert_record("tenant-a")
      end

      assert %{
               total: 101,
               outcomes: %{no_match: 0, accept: 0, ignore: 0, reject: 0, bounce: 0, failed: 0},
               unclassified: 101
             } = summary = Summary.summarize(%{tenant_id: "tenant-a"}, [])

      assert summary.no_match_rate == 0.0
    end
  end

  describe "Summary.summarize/2 outcome breakdown" do
    test "latest fresh execution run counts by the closed outcome set and ignores replay runs" do
      {:ok, record} = insert_record("tenant-a")
      {:ok, evidence} = insert_evidence("tenant-a", record.id)
      {:ok, _fresh} = insert_run("tenant-a", record.id, evidence.id, outcome: :no_match)

      {:ok, _replay} =
        insert_run("tenant-a", record.id, evidence.id, source: :replay, outcome: :accept)

      assert %{
               total: 1,
               outcomes: %{no_match: 1, accept: 0},
               unclassified: 0,
               no_match_rate: 100.0
             } = Summary.summarize(%{tenant_id: "tenant-a"}, [])
    end

    test "records with no fresh run increment unclassified and no outcome bucket" do
      {:ok, _record} = insert_record("tenant-a")

      assert %{
               total: 1,
               outcomes: %{no_match: 0, accept: 0, ignore: 0, reject: 0, bounce: 0, failed: 0},
               unclassified: 1
             } = summary = Summary.summarize(%{tenant_id: "tenant-a"}, [])

      assert summary.no_match_rate == 0.0
    end
  end

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

  defp insert_evidence(tenant_id, record_id, opts \\ []) do
    InboundRecords.insert_inbound_evidence(%{
      tenant_id: tenant_id,
      inbound_record_id: record_id,
      provider: Keyword.get(opts, :provider, "postmark"),
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
      |> maybe_put(
        :outcome_reason,
        Keyword.get(opts, :outcome_reason, default_reason(base.outcome))
      )
      |> maybe_put(:failure, Keyword.get(opts, :failure, default_failure(base.outcome)))

    InboundRecords.insert_execution_run(attrs)
  end

  defp default_mailbox(:no_match), do: nil
  defp default_mailbox(:failed), do: nil
  defp default_mailbox(_outcome), do: "MyApp.Mailboxes.SupportMailbox"

  defp default_reason(outcome) when outcome in [:reject, :bounce], do: "fixture reason"
  defp default_reason(_outcome), do: nil

  defp default_failure(:failed), do: %{"reason" => "fixture failure"}
  defp default_failure(_outcome), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp unique(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"
end
