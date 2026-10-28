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
  alias MailglassAdmin.Inbound.QuickView
  alias MailglassInbound.InboundRecords.ExecutionRun

  describe "RecordsList.records_list/1" do
    test "renders the empty-state copy for []" do
      # Phase 113: empty state now routes through Components.data_state/1 with UI-SPEC copy.
      # Default empty_state is :filtered; renders "No messages match the current filters."
      html = render_component(&RecordsList.records_list/1, records: [], selected_record: nil)

      assert html =~ "No messages match the current filters."
      assert html =~ "Clear filters"
    end

    test "shows the recipient and renders the record id + meta line" do
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

      assert html =~ "alice@example.com"
      refute html =~ "a****@e******.com"
      assert html =~ "rec-1"
      assert html =~ "MAILGUN"
      assert html =~ "No execution recorded"
    end

    test "keeps long and non-ASCII row values readable on mobile cards" do
      recipient = String.duplicate("a", 64) <> "@exämple.com"
      record_id = "rec-" <> String.duplicate("界", 40)

      record = %{
        id: record_id,
        tenant_id: "tenant-東京",
        provider: "postmark",
        envelope_recipient: recipient,
        subject: "A subject not shown in this compact row",
        received_at: ~U[2026-05-24 10:00:00Z],
        outcome: :accept,
        mailbox: "MyApp.箱"
      }

      html =
        render_component(&RecordsList.records_list/1, records: [record], selected_record: nil)

      assert html =~ recipient
      assert html =~ ~s(title="#{recipient}")
      assert html =~ record_id
      assert html =~ "tenant-東京"
      assert html =~ "MyApp.箱"
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

    test "renders 'Unrouted' + warning badge for a :no_match record (WR-01)" do
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

      assert html =~ "Unrouted"
      assert html =~ "badge-warning"
      assert html =~ "Unrouted"
    end

    test "renders no history when the record has no execution run yet" do
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

      assert html =~ "No history"
      assert html =~ "badge-outline"
      assert html =~ "No execution recorded"
      refute html =~ "no match"
    end

    test "renders an explicit no-change outcome separately from other outcomes" do
      record = %{
        id: "rec-no-change",
        tenant_id: "tenant-a",
        provider: "postmark",
        envelope_recipient: "alice@example.com",
        subject: "Hello",
        received_at: ~U[2026-05-24 10:00:00Z],
        outcome: :no_change,
        mailbox: "MyApp.SupportMailbox"
      }

      html =
        render_component(&RecordsList.records_list/1, records: [record], selected_record: nil)

      assert html =~ "No change"
      assert html =~ "badge-outline"
      assert html =~ "MyApp.SupportMailbox"
    end

    test "does not label a failed execution as no match" do
      record = %{
        id: "rec-failed",
        tenant_id: "tenant-a",
        provider: "postmark",
        envelope_recipient: "alice@example.com",
        subject: "Hello",
        received_at: ~U[2026-05-24 10:00:00Z],
        outcome: :failed,
        mailbox: nil
      }

      html =
        render_component(&RecordsList.records_list/1, records: [record], selected_record: nil)

      assert html =~ "Failed"
      assert html =~ "Not recorded"
      refute html =~ "no match"
    end
  end

  describe "DetailHeader.detail_header/1" do
    @tag :phase175
    test "eligible full-detail replay uses the primary accent and approved label" do
      detail = %{
        record: %{
          id: "rec-primary-replay",
          tenant_id: "tenant-a",
          provider: "postmark",
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
      button = Floki.find(Floki.parse_document!(html), "#inbound-replay-open-btn")
      classes = button |> Floki.attribute("class") |> List.first() |> String.split()

      assert "btn-primary" in classes
      refute "btn-error" in classes
      assert button |> Floki.text() |> String.trim() == "Review inbound replay"
    end

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

    test "shows missing history separately from no match" do
      detail = %{
        record: %{
          id: "rec-no-history",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: nil,
        outcome: nil,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      assert html =~ "No history"
      assert html =~ "No execution recorded"
      refute html =~ "No match"
    end

    test "shows an unavailable mailbox for a failed execution without one" do
      detail = %{
        record: %{
          id: "rec-failed",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "alice@example.com",
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: nil,
        outcome: :failed,
        outcome_reason: "private execution detail",
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)

      assert html =~ "Failed"
      # The mailbox cell is what degrades here (its label reads "Not recorded"); this
      # assertion previously matched the From cell's "Unavailable" placeholder by accident.
      assert html =~ "Not recorded"
      assert html =~ "Processing failed, but no mailbox name was saved for this attempt."
      refute html =~ "No match"
      refute html =~ "private execution detail"
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

    test "the From cell shows the unmasked SENDER from `from`, not the recipient (WR-02, D-19)" do
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

      # Ordinary authorized detail shows the sender as received; the masked form is gone.
      assert html =~ "bob@sender.test"
      refute html =~ "b**@s*****.test"
      # The recipient is shown in the title, but the From cell is the sender.
      assert html =~ "alice@example.com"
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

      assert html =~ "Carol"
      assert html =~ "carol@vendor.test"
      refute html =~ "c****@v*****.test"
    end

    test "the From cell degrades to 'No From header' on an empty `from`" do
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

      cell = html |> Floki.parse_document!() |> Floki.find("[data-testid='inbound-contact-from']")
      assert Floki.text(cell) =~ "No From header"
      refute Floki.text(cell) =~ "Unavailable"
    end

    test "the From cell degrades to 'Unparseable address' on a malformed `from` entry" do
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

      cell = html |> Floki.parse_document!() |> Floki.find("[data-testid='inbound-contact-from']")
      assert Floki.text(cell) =~ "Unparseable address"
    end

    @tag :phase176
    test "Phase 176 a plain-map record with only id and tenant_id renders missing copy" do
      detail = %{
        record: %{id: "rec-min", tenant_id: "tenant-a"},
        mailbox: nil,
        outcome: nil,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)
      doc = Floki.parse_document!(html)

      assert html =~ "No From header"
      assert html =~ "No To header"

      assert Floki.text(Floki.find(doc, "[data-testid='inbound-contact-delivered-to']")) =~
               "Not recorded by provider"

      assert html =~ "UNKNOWN"
      refute html =~ "Provider message ID"
    end
  end

  describe "Phase 176 contact display" do
    @describetag :phase176

    defp contact_doc(overrides) do
      record =
        Map.merge(
          %{
            id: "rec-1",
            tenant_id: "tenant-a",
            provider: "mailgun",
            envelope_recipient: "support@example.com",
            from: [%{address: "ada@example.com", name: "Ada Lovelace"}],
            to: [%{address: "team@example.com"}],
            subject: "Hello",
            received_at: ~U[2026-05-24 10:00:00Z]
          },
          Map.new(overrides)
        )

      detail = %{
        record: record,
        mailbox: nil,
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)
      {html, Floki.parse_document!(html)}
    end

    defp cell(doc, testid), do: Floki.find(doc, "[data-testid='#{testid}']")

    test "From missing renders 'No From header', To missing 'No To header', envelope nil 'Not recorded by provider'" do
      {_html, doc} = contact_doc(from: [], to: [], envelope_recipient: nil)

      assert doc |> cell("inbound-contact-from") |> Floki.text() =~ "No From header"
      assert doc |> cell("inbound-contact-to") |> Floki.text() =~ "No To header"

      assert doc |> cell("inbound-contact-delivered-to") |> Floki.text() =~
               "Not recorded by provider"
    end

    test "empty Cc and Reply-To rows are hidden; populated ones render in order" do
      {_html, doc} = contact_doc(cc: [], reply_to: [])
      assert cell(doc, "inbound-contact-cc") == []
      assert cell(doc, "inbound-contact-reply-to") == []

      {_html, doc} =
        contact_doc(
          cc: [%{address: "cc@example.com"}],
          reply_to: [%{address: "reply@example.com"}]
        )

      labels =
        doc
        |> Floki.find("dt")
        |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
        |> Enum.filter(&(&1 in ["From", "Reply-To", "To", "Cc", "Delivered to", "Provider"]))

      assert labels == ["From", "Reply-To", "To", "Cc", "Delivered to", "Provider"]
      assert doc |> cell("inbound-contact-cc") |> Floki.text() =~ "cc@example.com"
      assert doc |> cell("inbound-contact-reply-to") |> Floki.text() =~ "reply@example.com"
    end

    test "Delivered to is bound to envelope_recipient and To to the header list, never swapped" do
      {_html, doc} =
        contact_doc(
          envelope_recipient: "envelope@example.com",
          to: [%{address: "header-to@example.com"}]
        )

      delivered = doc |> cell("inbound-contact-delivered-to") |> Floki.text()
      to = doc |> cell("inbound-contact-to") |> Floki.text()

      assert delivered =~ "envelope@example.com"
      refute delivered =~ "header-to@example.com"
      assert delivered =~ "SMTP envelope recipient (RCPT TO), used for routing."
      assert to =~ "header-to@example.com"
      refute to =~ "envelope@example.com"
    end

    test "5 addresses render without overflow; 6 render a 'Show 1 more' details; 7 'Show 2 more'" do
      many = fn n -> for i <- 1..n, do: %{address: "to#{i}@example.com"} end

      {_html, doc} = contact_doc(to: many.(5))
      assert doc |> cell("inbound-contact-to") |> Floki.find("li") |> length() == 5
      assert doc |> cell("inbound-contact-to") |> Floki.find("details") == []

      {_html, doc} = contact_doc(to: many.(6))
      to = cell(doc, "inbound-contact-to")
      assert [details] = Floki.find(to, "details")
      assert details |> Floki.find("summary") |> Floki.text() =~ "Show 1 more"

      {_html, doc} = contact_doc(to: many.(7))
      to = cell(doc, "inbound-contact-to")
      assert [details] = Floki.find(to, "details")
      assert details |> Floki.find("summary") |> Floki.text() =~ "Show 2 more"
      assert Floki.find(to, "ul[role='list']") |> length() == 2
      assert Floki.find(details, "li") |> length() == 2
      assert Floki.text(to) =~ "to7@example.com"
    end

    test "a single address renders one <li> and no <details>" do
      {_html, doc} = contact_doc([])
      to = cell(doc, "inbound-contact-to")
      assert length(Floki.find(to, "li")) == 1
      assert Floki.find(to, "details") == []
    end

    test "exact duplicates collapse within one field" do
      {_html, doc} =
        contact_doc(
          to: [
            %{address: "dup@example.com"},
            %{address: "dup@EXAMPLE.com"},
            %{address: "other@example.com"}
          ]
        )

      assert doc |> cell("inbound-contact-to") |> Floki.find("li") |> length() == 2
    end

    test "unparseable entries render 'Unparseable address' plus the escaped original" do
      {html, doc} = contact_doc(to: ["not an address", "<b>bold</b>"])
      to = cell(doc, "inbound-contact-to")

      assert Floki.text(to) =~ "Unparseable address"
      assert Floki.text(to) =~ "not an address"
      assert Floki.text(to) =~ "<b>bold</b>"
      refute html =~ "<b>bold</b>"
    end

    test "a spoofed display name shows the name, the real address and the cue" do
      {_html, doc} =
        contact_doc(from: [%{address: "sender@mailer.example", name: "billing@paypal.example"}])

      from = cell(doc, "inbound-contact-from")
      assert Floki.text(from) =~ "billing@paypal.example"
      assert Floki.text(from) =~ "sender@mailer.example"

      assert doc |> cell("inbound-address-spoof-cue") |> Floki.text() =~
               "Display name contains a different address."
    end

    test "an ordinary display name shows no spoof cue" do
      {_html, doc} = contact_doc([])
      assert cell(doc, "inbound-address-spoof-cue") == []
    end

    test "Unicode addresses and names render verbatim, long values are never truncated" do
      long_local = String.duplicate("l", 70)
      long_domain = String.duplicate("d", 210) <> ".example"
      long = "#{long_local}@#{long_domain}"

      {html, doc} =
        contact_doc(
          from: [%{address: "zoe@example.com", name: "Zoë Ångström-Łukasiewicz"}],
          to: [%{address: "用户@例子.广告"}, %{address: long}]
        )

      assert Floki.text(cell(doc, "inbound-contact-from")) =~ "Zoë Ångström-Łukasiewicz"
      to = Floki.text(cell(doc, "inbound-contact-to"))
      assert to =~ "用户@例子.广告"
      assert to =~ long
      assert html =~ "[overflow-wrap:anywhere]"
      refute html =~ "line-clamp"
      refute html =~ "truncate"
    end

    test "a script display name renders escaped and never as an element" do
      {html, doc} =
        contact_doc(from: [%{address: "x@example.com", name: "<script>alert(1)</script>"}])

      assert Floki.find(doc, "script") == []
      assert Floki.text(cell(doc, "inbound-contact-from")) =~ "<script>alert(1)</script>"
      assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
      refute html =~ "<script>alert(1)</script>"
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

      assert html =~ "Initial processing"
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

    test "labels no-change separately from ignore and preserves chronological run identity" do
      runs = [
        %{
          id: "run-ignore",
          source: :fresh,
          mailbox: "MyApp.SupportMailbox",
          outcome: :ignore,
          outcome_reason: nil,
          executed_at: ~U[2026-05-24 10:00:00Z],
          inserted_at: ~U[2026-05-24 10:00:00Z]
        },
        %{
          id: "run-no-change",
          source: :replay,
          mailbox: "MyApp.SupportMailbox",
          outcome: :no_change,
          outcome_reason: nil,
          executed_at: ~U[2026-05-24 11:00:00Z],
          inserted_at: ~U[2026-05-24 11:00:00Z]
        }
      ]

      html = render_component(&Timeline.timeline/1, runs: runs)

      assert html =~ "Ignored"
      assert html =~ "No change"
      refute html =~ ">Ignore</p>"
      assert html =~ "Initial processing"
      assert html =~ "Replay"
      assert html =~ "2026-05-24T10:00:00Z"
      assert html =~ "2026-05-24T11:00:00Z"

      row_ids =
        html
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-timeline-run']")
        |> Enum.map(fn row -> row |> Floki.attribute("data-run-id") |> List.first() end)

      assert row_ids == ["run-ignore", "run-no-change"]
    end

    test "never renders raw execution failure reasons" do
      private_reason = "exception-secret-170-05-task2"

      run = %{
        id: "run-failed",
        source: :fresh,
        mailbox: nil,
        outcome: :failed,
        outcome_reason: private_reason,
        failure: %{"kind" => private_reason},
        executed_at: ~U[2026-05-24 10:00:00Z],
        inserted_at: ~U[2026-05-24 10:00:00Z]
      }

      html = render_component(&Timeline.timeline/1, runs: [run])

      assert html =~ "Failed"
      refute html =~ private_reason
      refute html =~ "Reason:"
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
      assert html =~ "mg-trace-clause-failing"
      assert html =~ "Dimension"
      assert html =~ "Expected"
      assert html =~ "Actual"
      assert html =~ "Current router simulation"
      assert html =~ "may differ from the rules used when this message arrived"
      assert html =~ "<details"
      refute html =~ "<details open"
      assert html =~ "<summary"
      assert html =~ ~s(aria-controls="inbound-routing-trace-content")
      assert html =~ "min-h-11"
      assert html =~ "mg-focus-ring"
      refute html =~ "support@example.com"
      refute html =~ "nomatch@example.com"
      refute html =~ "Need help"
      refute html =~ "~r/help/i"
      refute html =~ "x-mailglass-topic"
      refute html =~ "billing"
      assert html =~ "n******@e******.com"
    end

    test "masks long non-ASCII values and safely labels unsupported route clauses" do
      long_subject_expected =
        "subject-expected-170-03-秘密-🔐" <> String.duplicate("expected-long-value-東京-", 12)

      long_subject_actual =
        "subject-actual-170-03-非公開-📨" <> String.duplicate("actual-long-value-秘密-", 12)

      private_values = [
        "recipient-expected-170-03@example.invalid",
        "recipient-actual-170-03@example.invalid",
        long_subject_expected,
        long_subject_actual,
        "regex-source-secret-170-03",
        "regex-actual-secret-170-03",
        "x-private-header-170-03",
        "header-expected-secret-170-03",
        "header-actual-secret-170-03",
        "binding-secret-170-03",
        "exception-secret-170-03"
      ]

      trace = [
        %{
          mailbox: "MyApp.SupportMailbox",
          verdicts: [
            {:recipient, "recipient-expected-170-03@example.invalid",
             "recipient-actual-170-03@example.invalid", false}
          ]
        },
        %{
          mailbox: "MyApp.SupportMailbox",
          verdicts: [{:subject, long_subject_expected, long_subject_actual, false}]
        },
        %{
          mailbox: "MyApp.SupportMailbox",
          verdicts: [
            {:subject, ~r/regex-source-secret-170-03/, "regex-actual-secret-170-03", false}
          ]
        },
        %{
          mailbox: "MyApp.SupportMailbox",
          verdicts: [
            {:header, "x-private-header-170-03", "header-expected-secret-170-03",
             ["header-actual-secret-170-03"], false}
          ]
        },
        %{
          mailbox: "MyApp.SupportMailbox",
          verdicts: [
            {:binding, "binding-secret-170-03", "exception-secret-170-03", false}
          ]
        }
      ]

      rendered =
        try do
          {:ok, render_component(&RoutingTrace.routing_trace/1, trace: trace)}
        rescue
          FunctionClauseError -> {:error, :unsupported_route_clause}
        end

      assert {:ok, html} = rendered

      for value <- private_values do
        refute html =~ value
      end

      assert html =~ "Other condition"
      assert html =~ "Regular expression matcher"
      assert html =~ "Exact value matcher"
      assert html =~ "Value withheld"
      assert html =~ "Recipient did not match the current route."
      assert html =~ "Subject did not match the current route."
      assert html =~ "Header did not match the current route."
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

      refute redacted_html =~ ~s(data-testid="inbound-evidence-redacted")
      assert redacted_html =~ ~s(data-testid="inbound-evidence-reveal")
      refute redacted_html =~ "Raw source locked"
      assert redacted_html =~ ~s(data-testid="inbound-evidence-caption")
      assert redacted_html =~ "Provider"
      assert redacted_html =~ "Payload size"
      assert redacted_html =~ "Header count"
      refute redacted_html =~ "Verification facts"
      assert redacted_html =~ ~s(data-testid="inbound-evidence-facts")
      assert redacted_html =~ "May contain personal information."
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

    test "uses outcome vocabulary and describes the latest fresh result" do
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
      assert html =~ "Accepted"
      assert html =~ "Unrouted"
      assert html =~ "Ignored"
      assert html =~ "No change"
      assert html =~ "Rejected"
      assert html =~ "Bounced"
      assert html =~ "Failed"

      assert html =~
               "Filter by the latest fresh mailbox outcome, including unrouted messages and no change. The summary is hidden while this filter is applied."

      document = Floki.parse_document!(html)
      assert Floki.find(document, "legend") |> Floki.text() |> String.trim() == "Filters"
      assert Floki.find(document, "legend") |> Floki.attribute("class") == ["sr-only"]

      refute html =~ "tracking-["
    end
  end

  describe "ReplayModal.replay_modal/1" do
    test "renders the single confirmation body for an eligible recorded Mailbox" do
      record = %{
        id: "rec-1",
        tenant_id: "tenant-a",
        envelope_recipient: "alice@example.com"
      }

      review = %{
        review_id: "review-1",
        record_id: "rec-1",
        tenant_id: "tenant-a",
        eligibility: %{status: :eligible, mailbox: "MyApp.Mailboxes.Support"}
      }

      html =
        render_component(&ReplayModal.replay_modal/1, open?: true, record: record, review: review)

      assert html =~ ~s(data-testid="inbound-replay-modal")

      assert html =~
               "Replay uses the recorded Mailbox identity with currently deployed code against the stored inbound message. It does not evaluate current router rules or redeliver through the provider."

      assert html =~ "text-heading"
      assert html =~ "min-h-11"
      refute html =~ "text-lg"
      assert html =~ ~s(data-testid="inbound-replay-confirm")
      assert html =~ "Eligible: this exact record can replay through its recorded Mailbox."
    end

    test "renders nothing when closed" do
      record = %{id: "rec-1", tenant_id: "tenant-a", envelope_recipient: "alice@example.com"}

      html = render_component(&ReplayModal.replay_modal/1, open?: false, record: record)

      refute html =~ ~s(data-testid="inbound-replay-modal")
    end
  end

  describe "Phase 175 quick replay and technical evidence" do
    @describetag :phase175

    test "quick view offers an exact replay review only when recorded Mailbox eligibility is clear" do
      record = %{
        id: "rec-quick-175",
        tenant_id: "tenant-a",
        provider: "postmark",
        envelope_recipient: "reader@example.com",
        subject: "Follow-up",
        received_at: ~U[2026-10-24 10:00:00Z],
        outcome: :accept,
        mailbox: "Elixir.Mailboxes.Recorded"
      }

      attrs = %{
        record: record,
        replay_eligibility: %{status: :eligible, mailbox: "Elixir.Mailboxes.Recorded"},
        detail_error: nil,
        outside_results?: false,
        account_labels: %{},
        full_path: "/inbound?tenant_id=tenant-a&inbound_id=rec-quick-175&full=1",
        close_path: "/inbound?tenant_id=tenant-a",
        keyboard?: true
      }

      html = render_component(&QuickView.quick_view/1, attrs)
      button = Floki.find(Floki.parse_document!(html), "#inbound-quick-replay-open-btn")

      assert button != []
      assert Floki.attribute(button, "phx-click") == ["open_replay"]
      assert Floki.attribute(button, "phx-value-origin") == ["quick"]
      assert Floki.attribute(button, "data-testid") == ["inbound-quick-replay-open"]
      classes = button |> Floki.attribute("class") |> List.first() |> String.split()
      assert "btn-primary" in classes
      refute "btn-error" in classes
      assert html =~ "Review inbound replay"
      assert html =~ "rec-quick-175"

      unavailable_html =
        render_component(
          &QuickView.quick_view/1,
          Map.put(attrs, :replay_eligibility, %{
            status: :ineligible,
            reason: :execution_history_missing
          })
        )

      assert unavailable_html =~ "No execution history is recorded for this message."
      refute unavailable_html =~ ~s(id="inbound-quick-replay-open-btn")
    end

    test "full Inbound technical facts stay open with long Unicode identifiers" do
      provider_message_id = "thread-東京<&-" <> String.duplicate("🔐-長い-", 12)

      detail = %{
        record: %{
          id: "record-東京<&-" <> String.duplicate("界", 24),
          tenant_id: "tenant-a",
          provider: "postmark",
          provider_message_id: provider_message_id,
          envelope_recipient: "reader@example.com",
          subject: "Technical evidence",
          received_at: ~U[2026-10-24 10:00:00Z]
        },
        mailbox: "Elixir.Mailboxes.Recorded",
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      }

      html = render_component(&DetailHeader.detail_header/1, detail: detail)
      technical = Floki.find(Floki.parse_document!(html), "#inbound-detail-technical")

      assert length(technical) == 1
      assert Floki.attribute(technical, "tag") == []
      assert Floki.raw_html(technical) =~ "thread-東京"
      refute Floki.raw_html(technical) =~ "<details"
      refute Floki.raw_html(technical) =~ "<summary"
      assert Floki.text(technical) =~ provider_message_id
      assert Floki.text(technical) =~ "record-東京<&-"
      assert Floki.raw_html(technical) =~ "break-all"
    end
  end
end
