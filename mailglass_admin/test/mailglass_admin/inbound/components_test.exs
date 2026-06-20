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
  alias MailglassAdmin.Inbound.EvidenceCard
  alias MailglassAdmin.Inbound.FiltersForm
  alias MailglassAdmin.Inbound.RecordsList
  alias MailglassAdmin.Inbound.ReplayModal
  alias MailglassAdmin.Inbound.RoutingTrace
  alias MailglassAdmin.Inbound.Timeline
  alias MailglassInbound.InboundRecords.ExecutionRun

  describe "RecordsList.records_list/1" do
    test "renders the empty-state copy for []" do
      # Phase 113: empty state now routes through Components.data_state/1 with UI-SPEC copy.
      # Default empty_state is :filtered; renders "No records match the current filters."
      html = render_component(&RecordsList.records_list/1, records: [], selected_record: nil)

      assert html =~ "No records match the current filters."
      assert html =~ "Clear filters"
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

      html =
        render_component(&RecordsList.records_list/1, records: [record], selected_record: nil)

      refute html =~ "alice@example.com"
      assert html =~ "a****@e******.com"
      assert html =~ "rec-1"
      assert html =~ "MAILGUN"
      assert html =~ "no match"
    end

    test "renders the real outcome badge + matched mailbox for a matched record (WR-01)" do
      record = %{
        id: "rec-2",
        tenant_id: "tenant-a",
        provider: "postmark",
        envelope_recipient: "alice@example.com",
        subject: "Hello",
        received_at: ~U[2026-05-24 10:00:00Z],
        outcome: :accept,
        mailbox: "MyApp.SupportMailbox"
      }

      html =
        render_component(&RecordsList.records_list/1, records: [record], selected_record: nil)

      assert html =~ "Accept"
      assert html =~ "badge-success"
      assert html =~ "MyApp.SupportMailbox"
      refute html =~ "Pending"
      refute html =~ "no match"
    end

    test "renders 'no match' + warning badge for a :no_match record (WR-01)" do
      record = %{
        id: "rec-3",
        tenant_id: "tenant-a",
        provider: "postmark",
        envelope_recipient: "alice@example.com",
        subject: "Hello",
        received_at: ~U[2026-05-24 10:00:00Z],
        outcome: :no_match,
        mailbox: nil
      }

      html =
        render_component(&RecordsList.records_list/1, records: [record], selected_record: nil)

      assert html =~ "No match"
      assert html =~ "badge-warning"
      assert html =~ "no match"
    end

    test "renders the neutral Unknown badge for a record with no run yet (nil outcome)" do
      record = %{
        id: "rec-4",
        tenant_id: "tenant-a",
        provider: "postmark",
        envelope_recipient: "alice@example.com",
        subject: "Hello",
        received_at: ~U[2026-05-24 10:00:00Z],
        outcome: nil,
        mailbox: nil
      }

      html =
        render_component(&RecordsList.records_list/1, records: [record], selected_record: nil)

      assert html =~ "Unknown"
      assert html =~ "badge-outline"
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

    test "the From cell shows the masked SENDER from `from`, not the recipient (WR-02)" do
      detail = %{
        record: %{
          id: "rec-1",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          from: [%{address: "bob@sender.test"}],
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: "MyApp.SupportMailbox",
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      # Sender masked + present; raw sender never leaks.
      assert html =~ "b**@s*****.test"
      refute html =~ "bob@sender.test"
      # The recipient is masked in the title, but the From cell is the sender.
      assert html =~ "a****@e******.com"
    end

    test "the From cell reads STRING-keyed `from` maps (DB JSONB round-trip)" do
      detail = %{
        record: %{
          id: "rec-1",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          from: [%{"address" => "carol@vendor.test", "name" => "Carol"}],
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: "MyApp.SupportMailbox",
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      assert html =~ "c****@v*****.test"
      refute html =~ "carol@vendor.test"
    end

    test "the From cell degrades to 'Unavailable' on an empty `from`" do
      detail = %{
        record: %{
          id: "rec-1",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          from: [],
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: "MyApp.SupportMailbox",
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      assert html =~ "Unavailable"
    end

    test "the From cell degrades gracefully on a malformed `from` entry" do
      detail = %{
        record: %{
          id: "rec-1",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          from: [%{"display" => "no address key"}],
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: "MyApp.SupportMailbox",
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      assert html =~ "Unavailable"
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

  describe "RoutingTrace.routing_trace/1" do
    test "renders a responsive clause grid with masked recipient actuals" do
      trace = [
        %{
          mailbox: "MyApp.SupportMailbox",
          verdicts: [
            {:recipient, "support@example.com", "nomatch@example.com", false},
            {:subject, ~r/help/i, "Need help", true},
            {:header, "x-mailglass-topic", nil, ["billing"], true}
          ]
        }
      ]

      html = render_component(&RoutingTrace.routing_trace/1, trace: trace)

      assert html =~ ~s(data-testid="inbound-routing-trace")
      assert html =~ ~s(data-testid="inbound-route-card")
      assert html =~ ~s(data-testid="inbound-trace-clause")
      assert html =~ "sm:grid-cols"
      assert html =~ "bg-base-100"
      assert html =~ "border-l-4 border-error"
      assert html =~ "Dimension"
      assert html =~ "Expected"
      assert html =~ "Actual"
      refute html =~ "nomatch@example.com"
      assert html =~ "n******@e******.com"
    end
  end

  describe "EvidenceCard.evidence_card/1" do
    test "redacted and denied states keep raw payload absent while revealed shows it" do
      evidence = %{
        provider: "mailgun",
        raw_payload: %{"body" => "secret-raw-payload-99-03"},
        raw_headers: %{"x-mailglass-signature" => "ok"},
        verification_facts: %{"signature" => "verified", "dkim" => true}
      }

      redacted_html =
        render_component(&EvidenceCard.evidence_card/1,
          evidence: evidence,
          reveal_state: :redacted
        )

      assert redacted_html =~ ~s(data-testid="inbound-evidence-redacted")
      assert redacted_html =~ ~s(data-testid="inbound-evidence-reveal")
      assert redacted_html =~ "Raw source locked"
      assert redacted_html =~ "Provider"
      assert redacted_html =~ "Payload size"
      assert redacted_html =~ "Header count"
      assert redacted_html =~ "Verification facts"
      assert redacted_html =~ "bg-base-100"
      assert redacted_html =~ "min-h-11"
      refute redacted_html =~ ~s(data-testid="inbound-evidence-raw")
      refute redacted_html =~ "secret-raw-payload-99-03"

      denied_html =
        render_component(&EvidenceCard.evidence_card/1,
          evidence: evidence,
          reveal_state: :denied
        )

      assert denied_html =~ ~s(data-testid="inbound-evidence-denied")
      refute denied_html =~ ~s(data-testid="inbound-evidence-raw")
      refute denied_html =~ "secret-raw-payload-99-03"

      revealed_html =
        render_component(&EvidenceCard.evidence_card/1,
          evidence: evidence,
          reveal_state: :revealed
        )

      assert revealed_html =~ ~s(data-testid="inbound-evidence-raw")
      assert revealed_html =~ "secret-raw-payload-99-03"
    end
  end

  describe "FiltersForm.fields/1" do
    test "the outcome select offers exactly ExecutionRun.__outcomes__/0 options" do
      form =
        to_form(
          %{
            "tenant_id" => "",
            "provider" => "",
            "outcome" => "",
            "window_hours" => "168",
            "search" => ""
          },
          as: :filters
        )

      html =
        render_component(&FiltersForm.fields/1,
          form: form,
          outcome_values: ExecutionRun.__outcomes__(),
          window_options: [
            {"Last 24 hours", "24"},
            {"Last 7 days", "168"},
            {"Last 30 days", "720"}
          ]
        )

      for outcome <- ExecutionRun.__outcomes__() do
        assert html =~ ~s(value="#{Atom.to_string(outcome)}")
      end
    end

    test "uses token-clean labels and Time window copy" do
      form =
        to_form(
          %{
            "tenant_id" => "",
            "provider" => "",
            "outcome" => "",
            "window_hours" => "168",
            "search" => ""
          },
          as: :filters
        )

      html =
        render_component(&FiltersForm.fields/1,
          form: form,
          outcome_values: ExecutionRun.__outcomes__(),
          window_options: [
            {"Last 24 hours", "24"},
            {"Last 7 days", "168"},
            {"Last 30 days", "720"}
          ]
        )

      assert html =~ "Time window"

      assert html =~
               ~r/<legend class="(?=[^"]*\btext-label\b)(?=[^"]*\buppercase\b)(?=[^"]*\bfont-bold\b)(?=[^"]*\btext-secondary\b)[^"]*">Filters<\/legend>/

      refute html =~ "tracking-["
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
               "Re-runs Mailbox routing against the stored InboundMessage and records a new replay run in the append-only ledger. Confirm to replay."

      assert html =~ "text-heading"
      assert html =~ "min-h-11"
      refute html =~ "text-lg"
      assert html =~ ~s(data-testid="inbound-replay-confirm")
    end

    test "renders nothing when closed" do
      record = %{id: "rec-1", tenant_id: "tenant-a", envelope_recipient: "alice@example.com"}

      html = render_component(&ReplayModal.replay_modal/1, open?: false, record: record)

      refute html =~ ~s(data-testid="inbound-replay-modal")
    end
  end
end
