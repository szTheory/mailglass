defmodule MailglassAdmin.Inbound.ComponentsTest do
  @moduledoc """
  Task 1 component contracts for the cloned inbound sibling components.

  Covers the load-bearing per-component invariants the UI-SPEC and the phase
  pitfalls pin: the empty-state copy, the defensive `suppression_flagged` read
  (Pitfall 2 — must never raise `KeyError`), the `:no_match` Replay-disable
  (Pitfall 1), ExecutionRun source/outcome rendering (Pitfall 7), the outcome
  allow-list select, and the single-target replay modal (IADM-03).
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component, only: [to_form: 2]

  alias MailglassAdmin.Inbound.DetailHeader
  alias MailglassAdmin.Inbound.FiltersForm
  alias MailglassAdmin.Inbound.RecordsList
  alias MailglassAdmin.Inbound.ReplayModal
  alias MailglassAdmin.Inbound.Timeline
  alias MailglassInbound.InboundRecords.ExecutionRun

  describe "RecordsList.records_list/1" do
    test "renders the empty-state copy for []" do
      html = render_component(&RecordsList.records_list/1, records: [], selected_record: nil)

      assert html =~ "No inbound records"

      assert html =~
               "No inbound records match these filters. Clear the filters or wait for the next inbound message."
    end

    test "masks the recipient and renders the record id + meta line" do
      record = %{
        id: "rec-1",
        tenant_id: "tenant-a",
        provider: "mailgun",
        envelope_recipient: "alice@example.com",
        subject: "Hello",
        received_at: ~U[2026-05-24 10:00:00Z],
        mailbox: nil
      }

      html = render_component(&RecordsList.records_list/1, records: [record], selected_record: nil)

      refute html =~ "alice@example.com"
      assert html =~ "a****@e******.com"
      assert html =~ "rec-1"
      assert html =~ "MAILGUN"
      assert html =~ "no match"
    end
  end

  describe "DetailHeader.detail_header/1" do
    test "renders without raising for a record that has NO :suppression_flagged field" do
      detail = %{
        record: %{
          id: "rec-1",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: "MyApp.SupportMailbox",
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      # The flag does not exist -> Map.get default false -> indicator omitted.
      refute html =~ "Sender suppressed:"
      assert html =~ ~s(data-testid="inbound-detail-header")
      assert html =~ "MyApp.SupportMailbox"
    end

    test "Replay button is disabled when the displayed outcome is :no_match" do
      detail = %{
        record: %{
          id: "rec-1",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: nil,
        outcome: :no_match,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      assert html =~ ~r/data-testid="inbound-replay-open"[^>]*disabled/
    end

    test "Replay button is enabled for a matched outcome" do
      detail = %{
        record: %{
          id: "rec-1",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: "MyApp.SupportMailbox",
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      refute html =~ ~r/data-testid="inbound-replay-open"[^>]*disabled/
    end
  end

  describe "Timeline.timeline/1" do
    test "renders ExecutionRun rows with Fresh/Replay source badges and outcome dots" do
      runs = [
        %{
          id: "run-fresh",
          source: :fresh,
          mailbox: "MyApp.SupportMailbox",
          outcome: :accept,
          outcome_reason: nil,
          executed_at: ~U[2026-05-24 10:00:00Z],
          inserted_at: ~U[2026-05-24 10:00:00Z]
        },
        %{
          id: "run-replay",
          source: :replay,
          mailbox: nil,
          outcome: :no_match,
          outcome_reason: nil,
          executed_at: ~U[2026-05-24 11:00:00Z],
          inserted_at: ~U[2026-05-24 11:00:00Z]
        }
      ]

      html = render_component(&Timeline.timeline/1, runs: runs)

      assert html =~ "Fresh"
      assert html =~ "Replay"
      assert html =~ "run-fresh"
      assert html =~ "run-replay"
      # outcome -> dot color per UI-SPEC Color table
      assert html =~ "bg-success"
      assert html =~ "bg-warning"
    end

    test "renders the no-runs copy for []" do
      html = render_component(&Timeline.timeline/1, runs: [])

      assert html =~ "No execution runs have been recorded for this message yet."
    end
  end

  describe "FiltersForm.fields/1" do
    test "the outcome select offers exactly ExecutionRun.__outcomes__/0 options" do
      form =
        to_form(%{"tenant_id" => "", "provider" => "", "outcome" => "", "window_hours" => "168", "search" => ""},
          as: :filters
        )

      html =
        render_component(&FiltersForm.fields/1,
          form: form,
          outcome_values: ExecutionRun.__outcomes__(),
          window_options: [{"Last 24 hours", "24"}, {"Last 7 days", "168"}, {"Last 30 days", "720"}]
        )

      for outcome <- ExecutionRun.__outcomes__() do
        assert html =~ ~s(value="#{Atom.to_string(outcome)}")
      end
    end
  end

  describe "ReplayModal.replay_modal/1" do
    test "renders the single confirmation body with Confirm replay always enabled when open" do
      record = %{
        id: "rec-1",
        tenant_id: "tenant-a",
        envelope_recipient: "alice@example.com"
      }

      html = render_component(&ReplayModal.replay_modal/1, open?: true, record: record)

      assert html =~ ~s(data-testid="inbound-replay-modal")

      assert html =~
               "Replay inbound: This re-runs mailbox routing against the stored message and records a new replay run in the append-only ledger. Confirm to replay."

      assert html =~ ~s(data-testid="inbound-replay-confirm")
    end

    test "renders nothing when closed" do
      record = %{id: "rec-1", tenant_id: "tenant-a", envelope_recipient: "alice@example.com"}

      html = render_component(&ReplayModal.replay_modal/1, open?: false, record: record)

      refute html =~ ~s(data-testid="inbound-replay-modal")
    end
  end
end
