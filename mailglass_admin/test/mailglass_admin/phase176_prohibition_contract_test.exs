defmodule MailglassAdmin.Phase176UnavailableRepo do
  @moduledoc false

  # Every Inbound read raises a known connection failure, so a new-query read
  # lands in the failed state without any fixture trickery.
  def all(_queryable, _opts \\ []),
    do: raise(DBConnection.ConnectionError, message: "synthetic phase176 connection failure")

  def one(_queryable, _opts \\ []),
    do: raise(DBConnection.ConnectionError, message: "synthetic phase176 connection failure")
end

defmodule MailglassAdmin.Phase176ProhibitionContractTest do
  @moduledoc """
  Machine-checked form of the thirteen Phase 176 must-NOT prohibitions
  (FILTER-01..04, INUX-05, INUX-06; D-30). P1..P8 are the original set; P9..P13
  close the verification gaps: P9 (INUX-06), P10 (INUX-05), P11 and P12
  (FILTER-01) and P13 (FILTER-04, D-13).

  Each prohibition reduces to a forbidden control, a forbidden value or a
  forbidden claim on a closed set of rendered states, so this file enumerates
  those states and refutes the violation. The "detectors have teeth" block
  feeds every detector a known violation, so a pass here is not vacuous, and
  each prohibition was additionally proven red by a temporary source mutation
  (recorded in the plan SUMMARY).

  Positive behavior (history policy, focus, reveal authorization) stays in the
  LiveView and browser suites; this file only owns the prohibitions.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @moduletag :phase176

  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.Inbound.{DetailHeader, EvidenceCard, RoutingTrace}
  alias MailglassAdmin.TestRepo
  alias MailglassAdmin.TestSupport.{InboundFixtures, OperatorFixtures}

  @tenant_id "test-tenant"
  @sentinel "secret-raw-payload-176"

  @apply_wording [~r/\bapply\b/i, ~r/\bsubmit\b/i, ~r/\bsearch now\b/i]
  @empty_copy [~r/No deliveries/, ~r/No messages/]

  describe "detectors have teeth (fail-first proof)" do
    test "the P1 detector rejects a form with an apply button, a submit type and disable-with" do
      violating = """
      <form id="operator-filters">
        <button type="submit" phx-disable-with="Applying...">Apply filters</button>
        <button>Go</button>
        <input type="submit" value="Apply" />
      </form>
      """

      found = apply_control_violations(violating)

      assert Enum.any?(found, &(&1 =~ "label"))
      assert Enum.any?(found, &(&1 =~ "type=submit"))
      assert Enum.any?(found, &(&1 =~ "disable-with"))
      assert Enum.any?(found, &(&1 =~ "implicit submit"))
    end

    test "the P1 detector accepts a form whose only button is a plain Clear control" do
      clean = """
      <form id="operator-filters">
        <select name="filters[event]"></select>
        <button type="button" phx-click="clear_filters">Clear filters</button>
      </form>
      """

      assert apply_control_violations(clean) == []
    end

    test "the P2 detector reports a raw matcher or actual value in trace text" do
      assert unmasked_values("Actual nomatch@example.com", ["nomatch@example.com"]) ==
               ["nomatch@example.com"]

      assert unmasked_values("Actual n******@e******.com", ["nomatch@example.com"]) == []
    end

    test "the P3 detector reports swapped To and Delivered to bindings" do
      swapped =
        contact_html(to: "envelope@example.com", delivered: "header@example.com")

      found = binding_violations(swapped, "header@example.com", "envelope@example.com")
      assert length(found) == 2

      correct =
        contact_html(to: "header@example.com", delivered: "envelope@example.com")

      assert binding_violations(correct, "header@example.com", "envelope@example.com") == []
    end

    test "the P4 detector reports sentinel bytes anywhere in the HTML" do
      assert sentinel_leaks(~s(<pre id="inbound-evidence-raw">#{@sentinel}</pre>)) == [@sentinel]
      assert sentinel_leaks("<p>Raw source hidden.</p>") == []
    end

    test "the P5 detector reports extra keys and address-shaped values" do
      assert telemetry_violations(%{outcome: :granted, record_id: "r", tenant_id: "t"}) == []

      found =
        telemetry_violations(%{
          outcome: :granted,
          record_id: "r",
          tenant_id: "t",
          recipient: "who@example.com"
        })

      assert Enum.any?(found, &(&1 =~ "keys"))
      assert Enum.any?(found, &(&1 =~ "@"))
    end

    test "the P6 detector reports a zero fact and a missing Unavailable" do
      zero = facts_html("0 bytes", "0")
      assert length(fact_violations(zero)) == 4

      unknown = facts_html("Unavailable", "Unavailable")
      assert fact_violations(unknown) == []
    end

    test "the P7 detector reports a count or empty copy on a failed read" do
      violating =
        ~s(<span data-testid="operator-result-count">0</span><p>No deliveries match.</p>)

      found = failed_read_violations(violating, "operator-result-count")
      assert Enum.any?(found, &(&1 =~ "count"))
      assert Enum.any?(found, &(&1 =~ "empty copy"))

      assert failed_read_violations(
               "<p>Couldn't load deliveries for these filters</p>",
               "operator-result-count"
             ) == []
    end

    test "the P8 detector reports a missing or unnamed excluded-filter label" do
      assert note_violations("<p>No note</p>", "Latest recorded event") != []

      assert note_violations(
               ~s(<p data-testid="filters-url-invalid-note">Showing results.</p>),
               "Latest recorded event"
             ) != []

      assert note_violations(
               ~s(<p data-testid="filters-url-invalid-note">Showing results without the Latest recorded event filter.</p>),
               "Latest recorded event"
             ) == []
    end

    test "the P9 detector reports a Payload size that disagrees with the revealed bytes" do
      pre = fn bytes ->
        ~s(<pre id="inbound-evidence-raw">#{String.duplicate("x", bytes)}</pre>)
      end

      assert payload_size_violations(facts_html("3 bytes", "1") <> pre.(40)) != []
      assert payload_size_violations(facts_html("40 bytes", "1") <> pre.(40)) == []
      assert payload_size_violations(facts_html("1,500 bytes", "1") <> pre.(1_500)) == []
      assert payload_size_violations(facts_html("1 byte", "1") <> pre.(1)) == []
      assert payload_size_violations(facts_html("40 bytes", "1")) != []
    end

    test "the P10 detector reports a copy control whose accessible name omits its value" do
      unnamed =
        ~s(<button type="button" data-copy-value="a@example.com" aria-label="Copy To address">a@example.com</button>)

      named =
        ~s(<button type="button" data-copy-value="a@example.com" aria-label="Copy To address: a@example.com">a@example.com</button>)

      assert copy_name_violations(unnamed) != []
      assert copy_name_violations(named) == []
    end

    test "the P11 detector reports an empty Deliveries pane that withholds the filter toolbar" do
      without_toolbar = ~s(<section><p data-testid="operator-empty-filtered">None.</p></section>)

      assert toolbar_violations(without_toolbar) != []

      assert toolbar_violations(
               ~s(<section><p data-testid="operator-empty-truly">None.</p></section>)
             ) != []

      with_toolbar =
        ~s(<section><form id="operator-filters"></form><p data-testid="operator-empty-filtered">None.</p></section>)

      assert toolbar_violations(with_toolbar) == []
    end

    test "the P12 detector reports a display-toggle op or an inline style on the filter panel" do
      toggle_json = fn name ->
        [
          [name, %{"to" => "#operator-filter-panel"}],
          ["toggle_attr", %{"attr" => ["aria-expanded", "true", "false"]}]
        ]
        |> Jason.encode!()
        |> Plug.HTML.html_escape()
      end

      toggle_html = fn name ->
        ~s(<button data-testid="operator-filters-toggle" phx-click="#{toggle_json.(name)}">Filters</button><div id="operator-filter-panel" class="hidden"></div>)
      end

      assert toggle_op_violations(toggle_html.("toggle")) != []
      assert toggle_op_violations(toggle_html.("toggle_class")) == []

      styled =
        ~s(<button data-testid="operator-filters-toggle" phx-click="#{toggle_json.("toggle_class")}">Filters</button><div id="operator-filter-panel" style="display: none"></div>)

      assert Enum.any?(toggle_op_violations(styled), &(&1 =~ "style"))
    end
  end

  describe "P1 filter forms have no apply or submit control" do
    test "Deliveries #operator-filters carries no apply, submit or disable-with control", %{
      conn: conn
    } do
      insert_delivery!(recipient: "p1@example.com")
      {:ok, _view, html} = live(operator_conn(conn), deliveries_path())

      form = form_html(html, "#operator-filters")
      assert form != "", "expected #operator-filters on the Deliveries route"
      assert apply_control_violations(form) == []
    end

    test "Inbound #inbound-filters carries no apply, submit or disable-with control", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "p1-inbound@example.com")
      {:ok, _view, html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      form = form_html(html, "#inbound-filters")
      assert form != "", "expected #inbound-filters on the Inbound route"
      assert apply_control_violations(form) == []
    end
  end

  describe "P2 routing-trace matcher values and subjects stay masked" do
    test "the component shows only masked forms of raw matcher and actual values" do
      raw = [
        "support-expected@example.com",
        "nomatch-actual@example.com",
        "Subject expected 176 private",
        "Subject actual 176 private"
      ]

      trace = [
        %{
          mailbox: "MyApp.SupportMailbox",
          verdicts: [
            {:recipient, "support-expected@example.com", "nomatch-actual@example.com", false},
            {:subject, "Subject expected 176 private", "Subject actual 176 private", false}
          ]
        }
      ]

      html = render_component(&RoutingTrace.routing_trace/1, trace: trace)

      assert unmasked_values(visible_text(html), raw) == []
      assert unmasked_values(html, raw) == []
    end

    test "the full detail route keeps the trace masked while the header stays readable", %{
      conn: conn
    } do
      raw = "p2-trace@example.com"
      subject = "P2 subject private 176"

      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id, recipient: raw, subject: subject)

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ raw

      trace =
        html
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-routing-trace']")

      assert [_] = trace
      trace_html = Floki.raw_html(trace)
      assert unmasked_values(trace_html, [raw, subject]) == []
    end
  end

  describe "P3 Delivered to is the envelope recipient and To is the header list" do
    test "the component binds each label to its own source" do
      html =
        render_component(&DetailHeader.detail_header/1,
          detail: %{
            record: %{
              id: "rec-p3",
              tenant_id: @tenant_id,
              provider: "postmark",
              envelope_recipient: "envelope@example.org",
              to: [%{address: "header@example.com"}],
              subject: "P3",
              received_at: ~U[2026-05-24 10:00:00Z]
            },
            mailbox: "MyApp.SupportMailbox",
            outcome: :accept,
            outcome_reason: nil,
            evidence: nil
          }
        )

      assert binding_violations(html, "header@example.com", "envelope@example.org") == []
    end

    test "the Quick view labels the envelope recipient Delivered to and omits the To list", %{
      conn: conn
    } do
      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "envelope@example.org",
          to: [%{address: "header@example.com"}]
        )

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id})
        )

      [quick] =
        html |> Floki.parse_document!() |> Floki.find("[data-testid='inbound-quick-view']")

      text = quick |> Floki.text() |> String.replace(~r/\s+/, " ")
      assert text =~ "Delivered to envelope@example.org"
      refute text =~ "header@example.com"
    end
  end

  describe "P4 raw payload bytes never reach redacted, denied or unauthorized HTML" do
    test "redacted and denied component states carry no sentinel bytes" do
      for state <- [:redacted, :denied] do
        html =
          render_component(&EvidenceCard.evidence_card/1,
            evidence: evidence(raw_payload: %{"body" => @sentinel}),
            reveal_state: state,
            received_at: ~U[2026-05-24 10:00:00Z]
          )

        assert sentinel_leaks(html) == [], "#{state} state leaked the sentinel"
        refute html =~ ~s(id="inbound-evidence-raw")
      end
    end

    test "a denied reveal on the live route leaks no sentinel bytes", %{conn: conn} do
      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "p4-denied@example.com",
          evidence: [raw_payload: %{"body" => @sentinel}]
        )

      {:ok, view, default_html} =
        live(
          operator_conn(conn, %{"current_user_id" => "deny-reveal"}),
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert sentinel_leaks(default_html) == []

      denied_html = view |> element("#inbound-evidence-reveal-btn") |> render_click()
      assert denied_html =~ "have permission to reveal raw source."
      assert sentinel_leaks(denied_html) == []
      assert sentinel_leaks(render(view)) == []
    end
  end

  describe "P5 reveal telemetry metadata carries only outcome, record id and tenant id" do
    test "allowed and denied reveals emit exactly the whitelisted keys", %{conn: conn} do
      for {user, outcome} <- [{"operator-1", :granted}, {"deny-reveal", :denied}] do
        %{record: record} =
          InboundFixtures.seed_matched!(@tenant_id,
            recipient: "p5-#{user}@example.com",
            subject: "P5 subject #{user}",
            evidence: [raw_payload: %{"body" => @sentinel}]
          )

        {:ok, view, _html} =
          live(
            operator_conn(conn, %{"current_user_id" => user}),
            inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id})
          )

        meta = capture_reveal_metadata(view)

        assert meta.outcome == outcome
        assert telemetry_violations(meta) == [], inspect(meta)
      end
    end
  end

  describe "P6 unknown payload size and header count never render as zero" do
    test "the component reads Unavailable for unknown evidence" do
      html =
        render_component(&EvidenceCard.evidence_card/1,
          evidence: %{
            provider: :postmark,
            raw_payload: nil,
            raw_mime: nil,
            raw_headers: nil,
            verification_facts: %{}
          },
          reveal_state: :redacted,
          received_at: ~U[2026-05-24 10:00:00Z]
        )

      assert fact_violations(html) == []
    end

    test "a live record with no stored evidence shows no facts and no zero", %{conn: conn} do
      record = InboundFixtures.insert_record!(@tenant_id, recipient: "p6-none@example.com")

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      [card] =
        html
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-evidence-card']")

      text = Floki.text(card)
      assert text =~ "No raw provider source was stored for this message."
      assert Floki.find(card, "[data-testid='inbound-evidence-reveal']") == []
      assert Floki.find(card, "[data-testid='inbound-evidence-facts']") == []
      refute text =~ "0 bytes"
    end
  end

  describe "P7 a failed new-query read shows no count and no empty copy" do
    test "Deliveries", %{conn: conn} do
      insert_delivery!(recipient: "p7-readable@example.com")
      {:ok, view, html} = live(operator_conn(conn), deliveries_path())
      assert html =~ "p7-readable@example.com"

      OperatorFixtures.arm_reader_fault!("operator-1", "deliveries", :known)
      on_exit(&OperatorFixtures.clear_reader_faults!/0)

      render_hook(view, "validate_filters", %{
        "_target" => ["filters", "event"],
        "filters" => %{
          "search" => "",
          "window_hours" => "168",
          "event" => "sent",
          "provider" => ""
        }
      })

      assert_patch_kind(view, :push)
      html = render(view)

      assert html =~ "Couldn&#39;t load deliveries for these filters"
      assert failed_read_violations(html, "operator-result-count") == []
    end

    test "Inbound", %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "p7-readable@example.com")
      {:ok, view, html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))
      assert html =~ "p7-readable@example.com"

      previous_repo = Application.fetch_env!(:mailglass_inbound, :repo)
      Application.put_env(:mailglass_inbound, :repo, MailglassAdmin.Phase176UnavailableRepo)
      on_exit(fn -> Application.put_env(:mailglass_inbound, :repo, previous_repo) end)

      render_hook(view, "validate_filters", %{
        "_target" => ["filters", "outcome"],
        "filters" => %{
          "search" => "",
          "window_hours" => "168",
          "outcome" => "accept",
          "provider" => ""
        }
      })

      assert_patch_kind(view, :push)
      html = render(view)

      assert html =~ "Couldn&#39;t load inbound messages for these filters"
      assert failed_read_violations(html, "inbound-result-count") == []
    end
  end

  describe "P8 an invalid URL filter is labelled as excluded, never an unlabelled fallback" do
    test "Deliveries names the excluded event filter", %{conn: conn} do
      insert_delivery!(recipient: "p8-fallback@example.com")

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          "/ops/mail?" <>
            URI.encode_query(%{
              "tenant_id" => @tenant_id,
              "view" => "deliveries",
              "event" => "bogus"
            })
        )

      assert html =~ "p8-fallback@example.com"
      assert note_violations(html, "Latest recorded event") == []
    end

    test "Inbound names the excluded outcome filter", %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "p8-fallback@example.com")

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "outcome" => "not-real"})
        )

      assert html =~ "p8-fallback@example.com"
      assert note_violations(html, "Mailbox outcome") == []
    end
  end

  describe "P9 Payload size describes the bytes the reveal shows" do
    test "the component with both fields stored sizes the exact revealed text" do
      for payload <- [
            %{"marker" => "P9-COMPONENT-176"},
            %{"marker" => String.duplicate("p9", 900)}
          ] do
        html =
          render_component(&EvidenceCard.evidence_card/1,
            evidence: evidence(raw_payload: payload, raw_mime: "MIME-P9-COMPONENT-176"),
            reveal_state: :revealed,
            received_at: ~U[2026-05-24 10:00:00Z]
          )

        assert html =~ ~s(id="inbound-evidence-raw")
        assert payload_size_violations(html) == []
      end
    end

    test "the component sizes a mime-only source from the same bytes" do
      html =
        render_component(&EvidenceCard.evidence_card/1,
          evidence: evidence(raw_payload: %{}, raw_mime: "MIME-ONLY-P9-176"),
          reveal_state: :revealed,
          received_at: ~U[2026-05-24 10:00:00Z]
        )

      assert html =~ "MIME-ONLY-P9-176"
      assert payload_size_violations(html) == []
    end

    test "the live authorized reveal of a record seeded with both fields agrees", %{conn: conn} do
      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "p9-both@example.com",
          evidence: [raw_payload: %{"body" => "P9-LIVE-176"}, raw_mime: "MIME-P9-LIVE-176"]
        )

      {:ok, view, _html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      html = render_click(view, "reveal_raw", %{})

      assert html =~ "P9-LIVE-176"
      assert payload_size_violations(html) == []
    end
  end

  describe "P10 copy controls name the value they copy" do
    test "the full Inbound detail names every contact and record copy control", %{conn: conn} do
      from = "p10-from@example.com"
      to = "p10-to@example.com"
      cc = "p10-cc@example.com"
      envelope = "p10-envelope@example.com"

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: envelope,
          from: [%{address: from, name: "P10 Sender"}],
          to: [%{address: to}],
          cc: [%{address: cc}]
        )

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      buttons = html |> Floki.parse_document!() |> Floki.find("button[data-copy-value]")
      values = Enum.flat_map(buttons, &Floki.attribute(&1, "data-copy-value"))

      # One From, one To, one Cc and the envelope recipient: a vacuous loop over a
      # missing list must fail before the containment check runs.
      assert length(buttons) >= 4
      for address <- [from, to, cc, envelope], do: assert(address in values)
      assert copy_name_violations(html) == []
    end

    test "the full Deliveries detail names the provider message id control", %{conn: conn} do
      delivery = insert_delivery!(provider_message_id: "pm_p10_copy_176")

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          "/ops/mail?" <>
            URI.encode_query(%{
              "tenant_id" => @tenant_id,
              "delivery_id" => delivery.id,
              "full" => "1"
            })
        )

      buttons = html |> Floki.parse_document!() |> Floki.find("button[data-copy-value]")
      values = Enum.flat_map(buttons, &Floki.attribute(&1, "data-copy-value"))

      assert buttons != []
      assert "pm_p10_copy_176" in values
      assert copy_name_violations(html) == []
    end
  end

  describe "P11 a committed filter never removes the Deliveries toolbar" do
    test "a narrower time window that matches nothing keeps the toolbar (commit)", %{conn: conn} do
      insert_delivery!(recipient: "p11-old@example.com", last_event_at: hours_ago(48))
      {:ok, view, html} = live(operator_conn(conn), deliveries_path())
      assert html =~ "p11-old@example.com"

      render_hook(view, "validate_filters", %{
        "_target" => ["filters", "window_hours"],
        "filters" => %{
          "search" => "",
          "window_hours" => "24",
          "event" => "",
          "provider" => ""
        }
      })

      assert assert_patch_kind(view, :push) =~ "window_hours=24"
      html = render(view)

      assert html =~ "operator-empty-filtered"
      assert toolbar_violations(html) == []
    end

    test "a narrower time window that matches nothing keeps the toolbar (URL)", %{conn: conn} do
      insert_delivery!(recipient: "p11-old-url@example.com", last_event_at: hours_ago(48))

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          "/ops/mail?" <>
            URI.encode_query(%{
              "tenant_id" => @tenant_id,
              "view" => "deliveries",
              "window_hours" => "24"
            })
        )

      assert html =~ "operator-empty-filtered"
      assert toolbar_violations(html) == []
    end
  end

  describe "P12 the Deliveries filter panel is never hidden by an inline display" do
    test "the mobile toggle switches a class and the panel carries no style", %{conn: conn} do
      insert_delivery!(recipient: "p12@example.com")
      {:ok, _view, html} = live(operator_conn(conn), deliveries_path())

      [toggle] =
        html
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='operator-filters-toggle']")

      [json] = Floki.attribute(toggle, "phx-click")
      ops = Jason.decode!(json)

      # The toggle must still do its job through a class, so an empty op list cannot pass.
      assert "toggle_class" in Enum.map(ops, &hd/1)
      assert toggle_op_violations(html) == []
    end
  end

  describe "P13 an invalid URL filter stays labelled after a later edit or a reconnect" do
    test "Deliveries keeps the event note when Search re-posts the invalid value", %{conn: conn} do
      insert_delivery!(recipient: "p13-fallback@example.com")

      {:ok, view, html} =
        live(
          operator_conn(conn),
          "/ops/mail?" <>
            URI.encode_query(%{
              "tenant_id" => @tenant_id,
              "view" => "deliveries",
              "event" => "bogus"
            })
        )

      assert note_violations(html, "Latest recorded event") == []

      render_hook(view, "validate_filters", %{
        "_target" => ["filters", "search"],
        "filters" => %{
          "search" => "ada",
          "window_hours" => "168",
          "event" => "bogus",
          "provider" => ""
        }
      })

      html = render(view)

      assert html =~ "p13-fallback@example.com"
      assert note_violations(html, "Latest recorded event") == []
      # D-12: the draft note sits beside the URL note. P13 never asserts its absence.
      assert draft_note_present?(html)
    end

    test "Inbound keeps the outcome note when a reconnect re-posts the invalid value", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "p13-fallback@example.com")

      {:ok, view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "outcome" => "not-real"})
        )

      assert note_violations(html, "Mailbox outcome") == []

      render_hook(view, "recover_filters", %{
        "filters" => %{
          "search" => "",
          "window_hours" => "168",
          "outcome" => "not-real",
          "provider" => ""
        }
      })

      html = render(view)

      assert html =~ "p13-fallback@example.com"
      assert note_violations(html, "Mailbox outcome") == []
      assert draft_note_present?(html)
    end
  end

  # -- detectors ---------------------------------------------------------------

  # P1: violations found inside the given form HTML.
  defp apply_control_violations(form_html) do
    nodes = Floki.parse_fragment!(form_html)

    label_hits =
      nodes
      |> Floki.find("button, a, [phx-click], input[type=submit], input[type=image]")
      |> Enum.flat_map(fn node ->
        label = [Floki.text(node) | Floki.attribute(node, "value")] |> Enum.join(" ")

        for pattern <- @apply_wording, Regex.match?(pattern, label) do
          "label #{inspect(String.trim(label))} matches #{inspect(Regex.source(pattern))}"
        end
      end)

    submit_type =
      for _ <- Floki.find(nodes, "[type=submit], [type=image]"), do: "control with type=submit"

    disable_with =
      for _ <- Floki.find(nodes, "[phx-disable-with]"), do: "control with disable-with"

    implicit_submit =
      nodes
      |> Floki.find("button")
      |> Enum.filter(fn node -> Floki.attribute(node, "type") in [[], ["submit"]] end)
      |> Enum.map(fn _ -> "implicit submit button (button without type=button)" end)

    label_hits ++ submit_type ++ disable_with ++ implicit_submit
  end

  # P2: raw values that appear verbatim in the text.
  defp unmasked_values(text, raw_values), do: Enum.filter(raw_values, &String.contains?(text, &1))

  # P3: the dd under "To" must hold only the header address and the dd under
  # "Delivered to" only the envelope address.
  defp binding_violations(html, header_address, envelope_address) do
    doc = Floki.parse_fragment!(html)
    to = doc |> dd_for("To") |> Floki.text()
    delivered = doc |> dd_for("Delivered to") |> Floki.text()

    for {label, text, wanted, forbidden} <- [
          {"To", to, header_address, envelope_address},
          {"Delivered to", delivered, envelope_address, header_address}
        ],
        not String.contains?(text, wanted) or String.contains?(text, forbidden) do
      "#{label} is bound to the wrong source: #{inspect(String.trim(text))}"
    end
  end

  defp dd_for(doc, label) do
    doc
    |> Floki.find("div")
    |> Enum.filter(fn div ->
      div |> Floki.children() |> Enum.any?(&label_node?(&1, label))
    end)
    |> Enum.flat_map(&Floki.find(&1, "dd"))
  end

  defp label_node?({"dt", _attrs, _children} = dt, label),
    do: String.trim(Floki.text(dt)) == label

  defp label_node?(_node, _label), do: false

  # P4: the sentinel byte string anywhere in the document.
  defp sentinel_leaks(html), do: Enum.filter([@sentinel], &String.contains?(html, &1))

  # P5: exact key set and no address-shaped value.
  defp telemetry_violations(meta) do
    keys = meta |> Map.keys() |> Enum.sort()

    key_hits =
      if keys == [:outcome, :record_id, :tenant_id],
        do: [],
        else: ["metadata keys are #{inspect(keys)}, expected [:outcome, :record_id, :tenant_id]"]

    value_hits =
      for {key, value} <- meta, String.contains?(to_string(inspect(value)), "@") do
        "value for #{inspect(key)} contains @"
      end

    key_hits ++ value_hits
  end

  defp capture_reveal_metadata(view) do
    ref = make_ref()
    test_pid = self()
    handler_id = "phase176-reveal-#{inspect(ref)}"

    :telemetry.attach(
      handler_id,
      [:mailglass_admin, :inbound, :reveal_raw, :stop],
      fn _event, _measurements, metadata, _config -> send(test_pid, {ref, metadata}) end,
      nil
    )

    try do
      render_click(view, "reveal_raw", %{})

      receive do
        {^ref, metadata} -> metadata
      after
        1_000 -> flunk("expected a [:mailglass_admin, :inbound, :reveal_raw, :stop] event")
      end
    after
      :telemetry.detach(handler_id)
    end
  end

  # P6: the Payload size and Header count facts must read Unavailable (never a
  # zero), checked per fact on the dd under each dt.
  defp fact_violations(html) do
    doc = Floki.parse_fragment!(html)

    for label <- ["Payload size", "Header count"],
        text = doc |> dd_for(label) |> Floki.text() |> String.trim(),
        violation <- fact_hits(label, text) do
      violation
    end
  end

  defp fact_hits(label, text) do
    zero = if text =~ ~r/^0( bytes?)?$/, do: ["#{label} renders #{inspect(text)}"], else: []
    missing = if text == "Unavailable", do: [], else: ["#{label} is not Unavailable: #{text}"]
    zero ++ missing
  end

  # P7: a failed new-query read must not render the count or any empty copy.
  defp failed_read_violations(html, count_testid) do
    doc = Floki.parse_document!(html)

    count =
      if Floki.find(doc, "[data-testid='#{count_testid}']") == [],
        do: [],
        else: ["failed read still renders a count (#{count_testid})"]

    text = visible_text(html)

    empty =
      for pattern <- @empty_copy, Regex.match?(pattern, text) do
        "failed read renders empty copy #{inspect(Regex.source(pattern))}"
      end

    count ++ empty
  end

  # P8: the labelled-fallback note must exist and name the excluded filter.
  defp note_violations(html, filter_name) do
    note =
      html
      |> Floki.parse_document!()
      |> Floki.find("[data-testid='filters-url-invalid-note']")

    cond do
      note == [] -> ["no filters-url-invalid-note rendered"]
      String.contains?(Floki.text(note), filter_name) -> []
      true -> ["note does not name #{inspect(filter_name)}: #{Floki.text(note)}"]
    end
  end

  defp draft_note_present?(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("[data-testid='filters-draft-pending-note']")
    |> Kernel.!=([])
  end

  # P9: the Payload size fact must equal the byte size of the exact text inside the
  # revealed <pre>. A revealed card with no <pre> or an unparseable size is a violation
  # too, so a pass always compares two real numbers.
  defp payload_size_violations(html) do
    doc = Floki.parse_document!(html)
    size = doc |> dd_for("Payload size") |> Floki.text() |> String.trim()

    case {Floki.find(doc, "pre#inbound-evidence-raw"), Regex.run(~r/^([\d,]+) bytes?$/, size)} do
      {[], _size} ->
        ["no revealed <pre> to compare the Payload size against"]

      {_pre, nil} ->
        ["Payload size is not a byte count: #{inspect(size)}"]

      {[pre | _], [_whole, digits]} ->
        shown = digits |> String.replace(",", "") |> String.to_integer()
        revealed = byte_size(Floki.text(pre))

        if shown == revealed,
          do: [],
          else: ["Payload size states #{shown} bytes, the revealed text is #{revealed} bytes"]
    end
  end

  # P10: every copy control's accessible name must contain the value it copies.
  defp copy_name_violations(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("button[data-copy-value]")
    |> Enum.flat_map(fn button ->
      [value] = Floki.attribute(button, "data-copy-value")
      name = button |> Floki.attribute("aria-label") |> List.first("")

      if String.contains?(name, value),
        do: [],
        else: ["copy control name #{inspect(name)} omits its value #{inspect(value)}"]
    end)
  end

  # P11: on a Deliveries state with a committed filter, an empty pane (filtered or
  # genuine) must not appear without the #operator-filters toolbar.
  defp toolbar_violations(html) do
    doc = Floki.parse_document!(html)

    empty? =
      Floki.find(doc, "[data-testid='operator-empty-filtered']") != [] or
        Floki.find(doc, "[data-testid='operator-empty-truly']") != []

    if empty? and Floki.find(doc, "#operator-filters") == [],
      do: ["an empty Deliveries pane renders without the #operator-filters toolbar"],
      else: []
  end

  # P12: the toggle's phx-click must hold no "toggle" (display) op aimed at the filter
  # panel, and the panel must carry no inline style a breakpoint cannot override.
  defp toggle_op_violations(html) do
    doc = Floki.parse_document!(html)

    op_hits =
      doc
      |> Floki.find("[data-testid='operator-filters-toggle']")
      |> Enum.flat_map(&Floki.attribute(&1, "phx-click"))
      |> Enum.flat_map(&Jason.decode!/1)
      |> Enum.filter(fn
        ["toggle", %{"to" => "#operator-filter-panel"}] -> true
        _op -> false
      end)
      |> Enum.map(fn _ -> "toggle op writes an inline display on #operator-filter-panel" end)

    style_hits =
      for panel <- Floki.find(doc, "#operator-filter-panel"),
          style <- Floki.attribute(panel, "style"),
          String.trim(style) != "" do
        "#operator-filter-panel carries inline style #{inspect(style)}"
      end

    op_hits ++ style_hits
  end

  # -- rendering helpers ---------------------------------------------------------

  defp form_html(html, selector) do
    html
    |> Floki.parse_document!()
    |> Floki.find(selector)
    |> Floki.raw_html()
  end

  defp visible_text(html) do
    html
    |> Floki.parse_document!()
    |> Floki.filter_out("script")
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
  end

  defp contact_html(to: to, delivered: delivered) do
    """
    <dl>
      <div><dt>To</dt><dd>#{to}</dd></div>
      <div><dt>Delivered to</dt><dd>#{delivered}</dd></div>
    </dl>
    """
  end

  defp facts_html(size, count) do
    """
    <dl>
      <div><dt>Payload size</dt><dd>#{size}</dd></div>
      <div><dt>Header count</dt><dd>#{count}</dd></div>
    </dl>
    """
  end

  defp evidence(overrides) do
    Map.merge(
      %{
        provider: :postmark,
        raw_payload: %{},
        raw_mime: nil,
        raw_headers: %{"x-test" => "1"},
        verification_facts: %{}
      },
      Map.new(overrides)
    )
  end

  # -- routes, fixtures and session ------------------------------------------------

  defp deliveries_path,
    do: "/ops/mail?" <> URI.encode_query(%{"tenant_id" => @tenant_id, "view" => "deliveries"})

  defp inbound_path(params) do
    case URI.encode_query(params) do
      "" -> "/ops/mail/inbound"
      query -> "/ops/mail/inbound?" <> query
    end
  end

  defp assert_patch_kind(view, kind) do
    %{proxy: {ref, topic, _pid}} = view
    assert_receive {^ref, {:patch, ^topic, %{kind: ^kind, to: to}}}
    to
  end

  defp insert_delivery!(attrs) do
    %{
      tenant_id: @tenant_id,
      mailable: "Mailglass.Example.OperatorMailer",
      stream: :transactional,
      recipient: "operator@example.com",
      provider: "postmark",
      provider_message_id: "pm_p176_#{System.unique_integer([:positive])}",
      status: :sent,
      last_event_type: :sent,
      last_event_at: DateTime.add(DateTime.utc_now(), -3_600, :second),
      metadata: %{}
    }
    |> Map.merge(Map.new(attrs))
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours * 3_600, :second)

  defp operator_conn(conn, session \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    base = %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    }

    Plug.Test.init_test_session(conn, Map.merge(base, session))
  end
end
