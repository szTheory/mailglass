defmodule MailglassAdmin.InboundLiveTest do
  @moduledoc """
  InboundLive shell behaviour (Wave 1, plan 48-02).

  Covers V1 (tenant-required-or-empty + no cross-tenant leak), V5 masking-half
  (recipient masked by default), record selection (push_patch with inbound_id,
  in-place detail render), URL-as-state filters, and the no-selection copy. The
  route mounts in the operator `live_session` (same Operator.Mount + Auth gate as
  OperatorLive), so unauthenticated access is rejected by the existing seam.
  """

  use MailglassAdmin.LiveViewCase, async: false

  import Ecto.Query

  alias MailglassAdmin.PubSub.Topics
  alias MailglassAdmin.Inbound.RecordsList
  alias MailglassAdmin.TestSupport.InboundFixtures
  alias MailglassInbound.InboundRecords.ExecutionRun

  @tenant_id "test-tenant"
  @other_tenant "other-tenant"
  @base_path "/ops/mail/inbound"
  @banned ["Oops", "Whoops", "Uh oh", "Something went wrong"]

  describe "inbound surface" do
    test "bare inbound URL with exactly one accessible tenant canonicalizes to tenant_id", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!("solo-inbound", recipient: "solo@example.com")

      {:ok, view, _html} = live(conn, @base_path)

      assert_patch(view, inbound_path(%{"tenant_id" => "solo-inbound"}))
    end

    test "bare inbound URL with multiple accessible tenants renders selector copy", %{conn: conn} do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!("alpha-inbound", recipient: "alpha@example.com")
      InboundFixtures.seed_matched!("beta-inbound", recipient: "beta@example.com")

      {:ok, _view, html} = live(conn, @base_path)

      assert html =~ "Select a tenant"
      assert html =~ "Choose a tenant to inspect its Deliveries and inbound routing"
      assert html =~ "Select tenant"
      assert html =~ "alpha-inbound"
      assert html =~ "beta-inbound"
      refute html =~ "add a tenant_id to the URL"
    end

    test "renders the no-selection prompt and masks recipients by default (V5)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "alice@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "Recent InboundMessages"
      assert html =~ ~s(data-testid="inbound-master-detail")
      # V5 masking half: masked by default, raw recipient never rendered.
      assert html =~ "a****@e******.com"
      refute html =~ "alice@example.com"
      # No-selection copy verbatim.
      assert html =~
               "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence."

      refute html =~ "Execution timeline"
      # Record id IS rendered (it is not PII) so selection works.
      assert html =~ record.id
      # Orientation strip is empty-pane-only now (D-04): on a POPULATED but
      # unselected view it MUST be absent — the strip no longer tripled labels
      # below a populated table. The inbound-empty-detail column-fill helper
      # (asserted positively above via its Select-an-InboundMessage copy) stays.
      refute html =~ ~s(data-testid="inbound-orientation")
      assert html =~ ~s(data-testid="inbound-empty-detail")
    end

    test "blank tenant renders the empty state and leaks no other-tenant id or recipient (V1)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      # Seed a record under a DIFFERENT tenant; a blank tenant must not surface it.
      %{record: other} =
        InboundFixtures.seed_matched!(@other_tenant, recipient: "secret@elsewhere.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => ""}))

      assert html =~ "Select a tenant"
      assert html =~ "Choose a tenant to inspect its Deliveries and inbound routing"
      assert html =~ "other-tenant"
      assert clear_filters_count(html) == 0

      # No cross-tenant leak — neither the foreign id nor the foreign recipient.
      refute html =~ other.id
      refute html =~ "secret@elsewhere.com"
      refute html =~ "s*****@e*******.com"
    end

    test "genuine no-data renders a single calm pane: truly-empty copy + orientation, toolbar withheld",
         %{
           conn: conn
         } do
      conn = operator_conn(conn)

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "No records"

      # D-07 noun discipline: the InboundMessage noun, not the old "No records…" drift.
      assert html =~
               "No InboundMessages have been recorded yet."

      # Genuine no-data is a single calm pane: orientation strip present,
      # filters toolbar and the master-detail grid WITHHELD (D-02/D-05 —
      # the toolbar is the only scope-widening vector).
      assert html =~ ~s(data-testid="inbound-orientation")
      refute html =~ ~s(data-testid="inbound-filters")
      refute html =~ ~s(data-testid="inbound-master-detail")

      # The toolbar Clear-filters button is gone, and the truly-empty pane has
      # no in-pane reset (that is :filtered-only) — so the count is 0.
      assert clear_filters_count(html) == 0
      refute html =~ "No records match the current filters."
    end

    test "a tenant query returns only that tenant's rows (V1 isolation)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: mine} = InboundFixtures.seed_matched!(@tenant_id, recipient: "mine@example.com")

      %{record: theirs} =
        InboundFixtures.seed_matched!(@other_tenant, recipient: "theirs@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ mine.id
      refute html =~ theirs.id
    end

    test "renders a tenant-scoped summary-backed overview", %{conn: conn} do
      conn = operator_conn(conn)

      InboundFixtures.seed_matched!(@tenant_id, recipient: "accepted@example.com")
      InboundFixtures.seed_no_match!(@tenant_id, recipient: "nomatch@example.com")
      InboundFixtures.seed_matched!(@other_tenant, recipient: "foreign@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-overview")
      assert html =~ "InboundMessages"
      assert html =~ "No match"
      assert html =~ "Accepted"
      assert html =~ "No-match rate"
      assert html =~ "2"
      assert html =~ "1"
      assert html =~ "50.0%"
      refute html =~ "foreign@example.com"
    end

    test "overview summary is not derived from the capped records list", %{conn: conn} do
      conn = operator_conn(conn)

      for index <- 1..101 do
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "accepted-#{index}@example.com",
          provider_message_id: "overview-cap-#{index}"
        )
      end

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-overview")
      assert html =~ "InboundMessages"
      assert html =~ "101"
      refute html =~ "accepted-101@example.com"
    end

    test "gateway-unavailable runtime path renders the calm no-data pane without leaking", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      Application.put_env(:mailglass_admin, :inbound_gateway_available?, false)
      on_exit(fn -> Application.delete_env(:mailglass_admin, :inbound_gateway_available?) end)

      InboundFixtures.seed_matched!(@tenant_id, recipient: "hidden@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      # Gateway-down degrades to an empty record set; with no records, no active
      # filters, and no filter errors this is genuine no-data — the calm pane
      # renders and the health strip is withheld (Phase 121 D-02). The degraded
      # path must still not crash and must not leak the seeded recipient.
      assert html =~ "No records"
      assert html =~ "No InboundMessages have been recorded yet."
      assert html =~ ~s(data-testid="inbound-orientation")
      refute html =~ ~s(data-testid="inbound-overview")
      refute html =~ "hidden@example.com"
    end

    test "active filters with no matching records render filtered empty and reset action", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      InboundFixtures.seed_matched!(@tenant_id, provider: "mailgun", subject: "Welcome")

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "ses",
            "search" => "impossible",
            "window_hours" => "24"
          })
        )

      assert html =~ "No records"
      assert html =~ "No records match the current filters."
      assert clear_filters_count(html) == 2
      refute html =~ "No records have been recorded yet."
    end

    test "inbound page links preserve tenant scope and expose honest boundaries", %{conn: conn} do
      conn = operator_conn(conn)

      for index <- 1..9 do
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "page-#{index}@example.com",
          provider_message_id: "inbound-page-#{index}"
        )
      end

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-result-count")
      assert html =~ "9 results"
      assert html =~ ~s(data-testid="inbound-pagination")
      assert html =~ ~s(data-testid="inbound-pagination-prev-disabled")
      assert html =~ "tenant_id=#{@tenant_id}"
      assert html =~ "page=2"
    end

    test "renders inbound responsive IA hooks and percentage grid contract", %{conn: conn} do
      conn = operator_conn(conn)

      # Populate the tenant so the filters toolbar + master-detail grid render —
      # these IA hooks are withheld in genuine no-data (Phase 121 D-02/D-03).
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-filters")
      assert html =~ ~s(data-testid="inbound-filters-toggle")
      assert html =~ "toggle"
      assert html =~ ~s(to&quot;:&quot;#inbound-filter-panel&quot;)
      assert html =~ ~s(id="inbound-filter-panel")
      assert html =~ "hidden md:block"
      # Master-detail split is conditional: a single column until a record is
      # selected. The split-percentage grid is asserted in the selection test.
      assert html =~ "grid-cols-1"
      refute html =~ "md:grid-cols-[40%_60%]"
      assert html =~ "Recent InboundMessages"
      refute html =~ "tracking-[0.08em]"
    end

    test "selecting a record renders the detail header + timeline in place with URL state", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "selected@example.com")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      view
      |> element("button[phx-value-id='#{record.id}']")
      |> render_click()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "inbound_id" => record.id,
          "window_hours" => "168"
        })
      )

      html = render(view)

      assert html =~ ~s(data-testid="inbound-detail-header")
      assert html =~ ~s(data-testid="inbound-detail-back")
      assert html =~ "Back to inbound records"
      assert html =~ "max-md:hidden"
      # With a record selected, the master-detail percentage grid is active.
      assert html =~ "md:grid-cols-[40%_60%]"
      assert html =~ "min-[1440px]:!grid-cols-[33%_67%]"
      assert html =~ ~s(data-testid="inbound-timeline")
      assert html =~ "Execution timeline"
      assert html =~ "MyApp.Mailboxes.SupportMailbox"
      # Fresh + replay source badges both appear (V matched seed).
      assert html =~ "Fresh"
      assert html =~ "Replay"
      assert html =~ ~s(aria-selected="true")
      # Detail still masks the recipient.
      assert html =~ "s*******@e******.com"
      refute html =~ "selected@example.com"

      view
      |> element(~s(a[data-testid="inbound-detail-back"]))
      |> render_click()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "window_hours" => "168"
        })
      )
    end

    test "filters live in the URL and survive a re-mount", %{conn: conn} do
      conn = operator_conn(conn)

      matching =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "match@example.com",
          provider: "mailgun"
        )

      _other =
        InboundFixtures.seed_no_match!(@tenant_id,
          recipient: "skip@example.com",
          provider: "ses"
        )

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      view
      |> form("#inbound-filters",
        filters: %{
          "tenant_id" => @tenant_id,
          "provider" => "mailgun",
          "outcome" => "accept",
          "window_hours" => "168",
          "search" => ""
        }
      )
      |> render_submit()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "provider" => "mailgun",
          "outcome" => "accept",
          "window_hours" => "168"
        })
      )

      html = render(view)

      assert html =~ matching.record.id
      assert html =~ ~s(value="mailgun")
      assert html =~ ~s(<option value="accept" selected)

      # Re-mount from the URL: filters survive.
      {:ok, _view2, html2} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "mailgun",
            "outcome" => "accept",
            "window_hours" => "168"
          })
        )

      assert html2 =~ ~s(value="mailgun")
      assert html2 =~ ~s(<option value="accept" selected)
    end

    test "clear filters preserves the selected tenant on inbound", %{conn: conn} do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!(@tenant_id, provider: "mailgun")

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "mailgun"
          })
        )

      render_hook(view, "clear_filters", %{})

      assert_patch(view, inbound_path(%{"tenant_id" => @tenant_id}))
    end

    test "inbound detail back preserves tenant and drops inbound id", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "back@example.com")

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      view
      |> element(~s(a[data-testid="inbound-detail-back"]))
      |> render_click()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "window_hours" => "168"
        })
      )
    end

    test "invalid URL-backed filters render recovery copy without widening tenant reads", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: matching} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "match@example.com",
          provider: "mailgun"
        )

      %{record: foreign} =
        InboundFixtures.seed_matched!(@other_tenant,
          recipient: "foreign@example.com",
          provider: "mailgun"
        )

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "outcome" => "not-real",
            "window_hours" => "bogus"
          })
        )

      assert html =~ "Mailbox outcome was not applied. Choose a listed outcome."
      assert html =~ "Time window was not applied. Choose a positive listed time window."
      assert html =~ matching.id
      refute html =~ foreign.id
      assert html =~ ~s(value="168" selected)
      refute html =~ "not-real"
      refute html =~ "bogus"
    end

    test "invalid submitted filters render recovery copy and do not push a patch", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      html =
        render_hook(view, "apply_filters", %{
          "filters" => %{
            "tenant_id" => @tenant_id,
            "provider" => "",
            "outcome" => "not-real",
            "window_hours" => "-5",
            "search" => ""
          }
        })

      assert html =~ "Mailbox outcome was not applied. Choose a listed outcome."
      assert html =~ "Time window was not applied. Choose a positive listed time window."

      assert_raise ArgumentError, fn ->
        assert_patch(view, 0)
      end
    end

    test "an unselectable foreign-tenant record id surfaces the detail-error band, not a leak", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      %{record: foreign} = InboundFixtures.seed_matched!(@other_tenant)

      # Seed a same-tenant record so the surface is populated and the master-detail
      # grid (which holds the detail-error band) renders — genuine no-data withholds
      # the grid entirely (Phase 121 D-02). The error band is the no-leak affordance.
      InboundFixtures.seed_matched!(@tenant_id, recipient: "local@example.com")

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => foreign.id}))

      assert html =~ ~s(data-testid="inbound-detail-error")

      assert html =~
               "InboundMessage not loaded: selected record is outside the current tenant or active filters. Refresh the page or adjust the filters, then try again."
    end

    test "a selected record outside active filters surfaces the detail-error band", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: mailgun_record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "mailgun-filtered@example.com",
          provider: "mailgun"
        )

      %{record: ses_record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "ses-visible@example.com",
          provider: "ses"
        )

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "ses",
            "inbound_id" => mailgun_record.id
          })
        )

      assert html =~ ses_record.id
      refute html =~ mailgun_record.id
      assert html =~ ~s(data-testid="inbound-detail-error")

      assert html =~
               "InboundMessage not loaded: selected record is outside the current tenant or active filters. Refresh the page or adjust the filters, then try again."
    end

    test "a valid selected record outside the capped recent list still loads detail", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      %{record: selected} =
        InboundFixtures.seed_matched!(@tenant_id,
          provider: "mailgun",
          recipient: "deep-link@example.com",
          received_at: DateTime.add(now, -10, :hour)
        )

      for index <- 1..55 do
        InboundFixtures.seed_matched!(@tenant_id,
          provider: "mailgun",
          recipient: "newer-#{index}@example.com",
          provider_message_id: "deep-link-cap-#{index}",
          received_at: DateTime.add(now, -index, :minute)
        )
      end

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "mailgun",
            "inbound_id" => selected.id
          })
        )

      assert html =~ ~s(id="inbound-detail-#{selected.id}")
      assert html =~ ~s(data-testid="inbound-detail-header")
      refute html =~ ~s(data-testid="inbound-detail-error")
    end

    test "rejects mounts without an authorized actor (operator Auth gate)", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} =
               live(conn, inbound_path(%{"tenant_id" => @tenant_id}))
    end
  end

  describe "list disposition (WR-01) — real outcome + mailbox per row" do
    test "a matched row shows its real Accept badge + matched mailbox", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: matched} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "matched@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ matched.id
      # The list row carries the real disposition, not a constant fallback.
      assert html =~ "Accept"
      assert html =~ "MyApp.Mailboxes.SupportMailbox"
    end

    test "a :no_match row reads 'no match' with a warning badge", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: unmatched} =
        InboundFixtures.seed_no_match!(@tenant_id, recipient: "nobody@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ unmatched.id
      assert html =~ "No match"
      assert html =~ "no match"
      assert html =~ "badge-warning"
    end

    test "distinct rows show distinct dispositions in the same list", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: matched} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "yes@example.com")

      %{record: unmatched} =
        InboundFixtures.seed_no_match!(@tenant_id, recipient: "no@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ matched.id
      assert html =~ unmatched.id
      # Both real dispositions are present — the list is no longer a constant.
      assert html =~ "Accept"
      assert html =~ "MyApp.Mailboxes.SupportMailbox"
      assert html =~ "No match"
    end
  end

  describe "search filter (WR-03) — end-to-end narrowing" do
    test "typing a subject search narrows the list", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: invoice} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "billing@example.com",
          subject: "Invoice #42 is due"
        )

      %{record: welcome} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "hello@example.com",
          subject: "Welcome aboard"
        )

      {:ok, view, html0} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      # Both records present before searching.
      assert html0 =~ invoice.id
      assert html0 =~ welcome.id

      view
      |> form("#inbound-filters",
        filters: %{
          "tenant_id" => @tenant_id,
          "provider" => "",
          "outcome" => "",
          "window_hours" => "168",
          "search" => "invoice"
        }
      )
      |> render_submit()

      html = render(view)

      assert html =~ invoice.id
      refute html =~ welcome.id
    end

    test "a blank search is a no-op (all rows remain)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: a} = InboundFixtures.seed_matched!(@tenant_id, recipient: "a@example.com")
      %{record: b} = InboundFixtures.seed_matched!(@tenant_id, recipient: "b@example.com")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      view
      |> form("#inbound-filters",
        filters: %{
          "tenant_id" => @tenant_id,
          "provider" => "",
          "outcome" => "",
          "window_hours" => "168",
          "search" => ""
        }
      )
      |> render_submit()

      html = render(view)
      assert html =~ a.id
      assert html =~ b.id
    end

    test "search stays tenant-scoped — a foreign match never appears", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: foreign} =
        InboundFixtures.seed_matched!(@other_tenant, subject: "shared unique keyword")

      # Seed a same-tenant record so the surface is populated (the filters toolbar
      # only renders in no-match/populated, not genuine no-data — Phase 121 D-02/D-03).
      # Its subject does NOT contain the search keyword, so it never matches.
      InboundFixtures.seed_matched!(@tenant_id, subject: "local unrelated subject")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      view
      |> form("#inbound-filters",
        filters: %{
          "tenant_id" => @tenant_id,
          "provider" => "",
          "outcome" => "",
          "window_hours" => "168",
          "search" => "shared unique keyword"
        }
      )
      |> render_submit()

      html = render(view)
      refute html =~ foreign.id
    end
  end

  describe "routing-trace card (IADM-04)" do
    test "is omitted for a matched record (only :no_match)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "matched@example.com")

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      refute html =~ ~s(data-testid="inbound-routing-trace")
      refute html =~ "Routing trace"
    end

    test "renders per-route clause diffs from explain/2 for a :no_match record", %{conn: conn} do
      conn = operator_conn(conn)

      # A no-match record whose recipient/subject/headers fail the synthetic
      # router's three routes (support@ recipient, ~r/^\[billing\]/ subject,
      # x-priority: high header).
      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id,
          recipient: "nobody@example.com",
          subject: "general question",
          headers: %{}
        )

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      assert html =~ ~s(data-testid="inbound-routing-trace")
      assert html =~ "Routing trace"
      assert html =~ "Why this message did not match"

      # One sub-card per declared route (3 routes in the synthetic router).
      trace_cards =
        html
        |> String.split(~s(data-testid="inbound-route-card"))
        |> length()
        |> Kernel.-(1)

      assert trace_cards == 3

      # Mailbox module name appears in the route header (mono).
      assert html =~ "MailglassAdmin.TestSupport.InboundTestMailbox"
      # Clause dimensions.
      assert html =~ "Recipient"
      assert html =~ "Subject"
      assert html =~ "Header: x-priority"
      # Legend (verbatim).
      assert html =~
               "Each route matches by AND across its clauses: any = no constraint, an exact value matches by string equality, and ~r/…/ matches by regular expression."
    end

    test "renders matcher kinds — nil → any, exact verbatim, regex → ~r/, and masks recipient actual",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id,
          recipient: "nomatch@example.com",
          subject: "general question",
          headers: %{}
        )

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      # Exact recipient matcher verbatim (route 1: recipient "support@example.com").
      assert html =~ "support@example.com"
      # Regex subject matcher rendered as ~r/ form (route 2: ~r/^\[billing\]/).
      assert html =~ "~r/"
      # Wildcard clauses (nil matchers, e.g. the subject on route 1) render "any".
      assert html =~ ~r/>\s*any\s*</
      # The recipient ACTUAL is masked, never raw.
      assert html =~ "n******@e******.com"
      refute html =~ "nomatch@example.com"
      # First failing clause has the error left-border emphasis.
      assert html =~ "border-l-4 border-error"
    end
  end

  describe "evidence card (IADM-02 raw half, V5)" do
    test "default-renders the redacted placeholder and never leaks raw bytes", %{conn: conn} do
      conn = operator_conn(conn)

      secret = "TOP-SECRET-RAW-PROVIDER-BYTES-#{System.unique_integer([:positive])}"

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "evidence@example.com",
          evidence: [
            raw_payload: %{"body" => secret},
            verification_facts: %{"spf" => "pass", "dkim" => "pass"}
          ]
        )

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      assert html =~ ~s(data-testid="inbound-evidence-card")
      assert html =~ "Raw provider source"
      # Redacted-by-default copy (verbatim).
      assert html =~
               "Raw source redacted. Revealing the raw provider payload requires the reveal_raw capability."

      # The raw payload bytes MUST be absent from the HTML by default.
      refute html =~ secret
      # Verification facts ARE shown (not redacted).
      assert html =~ "spf"
    end
  end

  describe "replay confirm flow (IADM-03)" do
    test "confirming replay on a matched record appends a :replay ExecutionRun (V2)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "replay@example.com")

      before_count = run_count(record.id)

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      view |> element("button[phx-click='open_replay']") |> render_click()

      html =
        view
        |> element("button[phx-click='confirm_replay']")
        |> render_click()

      assert unescape(html) =~
               "Replay recorded. A new replay run was appended to this InboundMessage's timeline."

      after_count = run_count(record.id)
      assert after_count == before_count + 1

      # The newest run is source: :replay (append-only — prior rows untouched).
      latest = latest_run(record.id)
      assert latest.source == :replay
    end

    test "replaying a :no_match record is blocked with the mailbox-missing copy and appends no run (V11)",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id, recipient: "nomatch@example.com")

      before_count = run_count(record.id)

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      # The confirm path is defensively mapped even though the button is disabled
      # in the header (render→click race) — drive the event directly.
      html = render_click(view, "confirm_replay", %{})

      assert html =~ "Replay blocked: mailbox module not found."
      assert run_count(record.id) == before_count
    end

    test "a tenant-A operator cannot replay a tenant-B record id (D-48-05 cross-tenant)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: foreign} =
        InboundFixtures.seed_matched!(@other_tenant, recipient: "foreign@example.com")

      before_count = run_count(foreign.id)

      # Operator scoped to @tenant_id selects a guessed tenant-B record id.
      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => foreign.id}))

      html = render_click(view, "confirm_replay", %{})

      assert html =~ "Replay blocked: this action is not authorized for the current operator."
      # No run appended to the foreign record — the tenant gate fired BEFORE replay/2.
      assert run_count(foreign.id) == before_count
    end

    test "a denied :replay_inbound capability changes no state (V6)", %{conn: conn} do
      conn = operator_conn(conn, %{"current_user_id" => "deny-replay"})

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "denied@example.com")

      before_count = run_count(record.id)

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      html = render_click(view, "confirm_replay", %{})

      assert html =~ "Replay blocked: this action is not authorized for the current operator."
      assert run_count(record.id) == before_count
    end
  end

  describe "live updates (IADM-05)" do
    test "a tenant broadcast prepends the re-fetched record without stealing selection (V7)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: selected} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "selected@example.com")

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => selected.id}))

      # A NEW record arrives after mount.
      %{record: fresh} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "fresh@example.com")

      Phoenix.PubSub.broadcast(
        Mailglass.PubSub,
        Topics.inbound_record_inserted(@tenant_id),
        {:inbound_record_inserted, fresh.id, %{provider: "mailgun", record_type: "inbound_record"}}
      )

      html = render(view)

      # The new record appears in the list.
      assert html =~ fresh.id
      # The current selection is preserved (detail header still rendered for it).
      assert html =~ ~s(data-testid="inbound-detail-header")
      assert html =~ selected.id
    end

    test "a foreign-tenant broadcast id is dropped (V7 isolation)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: _mine} = InboundFixtures.seed_matched!(@tenant_id, recipient: "mine@example.com")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      %{record: foreign} =
        InboundFixtures.seed_matched!(@other_tenant, recipient: "foreign@example.com")

      # Broadcast a foreign-tenant id on THIS tenant's topic (a malformed/forged
      # broadcast). The re-fetch is tenant-scoped, so it resolves to nil and is
      # dropped — no foreign id ever reaches the list.
      Phoenix.PubSub.broadcast(
        Mailglass.PubSub,
        Topics.inbound_record_inserted(@tenant_id),
        {:inbound_record_inserted, foreign.id,
         %{provider: "mailgun", record_type: "inbound_record"}}
      )

      html = render(view)

      refute html =~ foreign.id
    end
  end

  describe "dual table+card presentation (DATA-01, Task 1)" do
    test "records present: both inbound-records-table and inbound-records-cards testids appear", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!(@tenant_id, recipient: "table@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-records-table")
      assert html =~ ~s(data-testid="inbound-records-cards")
    end

    test "desktop table uses semantic th scope=col elements in order Outcome Mailbox Tenant Provider Received" do
      # Use render_component to get just the records_list HTML, isolating the table markup
      # so we can assert column header order without interference from page nav text
      %{record: record} = InboundFixtures.seed_matched!(@tenant_id, recipient: "th@example.com")

      html =
        render_component(&RecordsList.records_list/1,
          records: [
            %{
              id: record.id,
              tenant_id: @tenant_id,
              provider: "mailgun",
              envelope_recipient: "th@example.com",
              received_at: nil,
              outcome: :accept,
              mailbox: "MyApp.Mailboxes.SupportMailbox"
            }
          ],
          selected_record: nil,
          empty_state: :filtered,
          page_meta: %{
            total_count: 1,
            page: 1,
            per_page: 10,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      assert html =~ ~s(<th scope="col")
      # Column order within the table header: Outcome first, then Mailbox, Tenant, Provider, Received
      thead_html = html |> String.split("<thead>") |> List.last() |> String.split("</thead>") |> List.first()

      outcome_pos = String.length(thead_html) - (thead_html |> String.split("Outcome") |> List.last() |> String.length())
      mailbox_pos = String.length(thead_html) - (thead_html |> String.split("Mailbox") |> List.last() |> String.length())
      tenant_pos = String.length(thead_html) - (thead_html |> String.split("Tenant") |> List.last() |> String.length())
      provider_pos = String.length(thead_html) - (thead_html |> String.split("Provider") |> List.last() |> String.length())
      received_pos = String.length(thead_html) - (thead_html |> String.split("Received") |> List.last() |> String.length())

      assert outcome_pos < mailbox_pos
      assert mailbox_pos < tenant_pos
      assert tenant_pos < provider_pos
      assert provider_pos < received_pos
    end

    test "both table and cards carry phx-click=select_inbound and selected record shows aria-selected=true",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "selectme@example.com")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      view
      |> element("button[phx-value-id='#{record.id}']")
      |> render_click()

      html = render(view)

      assert html =~ ~s(phx-click="select_inbound")
      assert html =~ ~s(phx-value-id="#{record.id}")
      assert (html |> String.split(~s(aria-selected="true")) |> length()) >= 2
    end

    test "inbound-record-row testid remains reachable and outcome badges carry inbound-outcome- testids",
         %{conn: conn} do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!(@tenant_id, recipient: "badge@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-record-row")
      assert html =~ "inbound-outcome-"
    end

    test "envelope recipient renders via mask_recipient in both table and card presentations", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!(@tenant_id, recipient: "maskinboth@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      # Masked recipient appears (at least twice — once for table, once for cards)
      # "maskinboth" has 10 chars: m + 9 stars = "m*********"
      # "example" has 7 chars: e + 6 stars = "e******"
      masked = "m*********@e******.com"
      assert html =~ masked
      assert (html |> String.split(masked) |> length()) >= 3
      # Raw recipient never appears
      refute html =~ "maskinboth@example.com"
    end

    test "record id renders with title attribute and mono truncate; result count reads from page_meta",
         %{conn: conn} do
      conn = operator_conn(conn)
      %{record: record} = InboundFixtures.seed_matched!(@tenant_id, recipient: "id@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(title="#{record.id}")
      assert html =~ "mono"
      assert html =~ "truncate"
      # result count from page_meta, not faked
      assert html =~ ~s(data-testid="inbound-result-count")
      assert html =~ "1 result"
    end
  end

  describe "four distinct data-state branches on inbound surface (DATA-03, Task 2)" do
    test "no-data render emits data-state-empty and existing copy distinctions survive", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      # truly_empty path: data-state-empty with "No records"-family heading
      assert html =~ ~s(data-testid="data-state-empty")
      assert html =~ "No records"
    end

    test "error signal emits data-state-error distinct from empty" do
      html =
        render_component(&RecordsList.records_list/1,
          records: [],
          selected_record: nil,
          empty_state: :truly_empty,
          data_state: :error,
          page_meta: %{
            total_count: 0,
            page: 1,
            per_page: 10,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      assert html =~ ~s(data-testid="data-state-error")
      assert html =~ "Record data unavailable"
      refute html =~ ~s(data-testid="data-state-empty")
    end

    test "permission-denied signal emits data-state-permission-denied distinct from no-data" do
      html =
        render_component(&RecordsList.records_list/1,
          records: [],
          selected_record: nil,
          empty_state: :truly_empty,
          data_state: :permission_denied,
          page_meta: %{
            total_count: 0,
            page: 1,
            per_page: 10,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      assert html =~ ~s(data-testid="data-state-permission-denied")
      assert html =~ "Access restricted"
      refute html =~ ~s(data-testid="data-state-empty")
    end

    test "stale signal emits data-state-stale with out-of-date copy" do
      html =
        render_component(&RecordsList.records_list/1,
          records: [],
          selected_record: nil,
          empty_state: :truly_empty,
          data_state: :stale,
          page_meta: %{
            total_count: 0,
            page: 1,
            per_page: 10,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      assert html =~ ~s(data-testid="data-state-stale")
      assert html =~ "Data may be out of date"
    end

    test "inbound_live source contains no assign_async, inbound-loading, or Loading InboundMessages string" do
      source =
        File.read!("lib/mailglass_admin/inbound_live.ex")

      refute source =~ "assign_async"
      refute source =~ "inbound-loading"
      refute source =~ "Loading InboundMessages"
    end
  end

  describe "inbound KPI stat_card certification (DATA-02, Task 3)" do
    test "all four inbound KPI tiles render with meaningful non-dash values", %{conn: conn} do
      conn = operator_conn(conn)

      InboundFixtures.seed_matched!(@tenant_id, recipient: "kpi@example.com")
      InboundFixtures.seed_no_match!(@tenant_id, recipient: "nomatch@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-overview-total")
      assert html =~ ~s(data-testid="inbound-overview-no-match")
      assert html =~ ~s(data-testid="inbound-overview-accepted")
      assert html =~ ~s(data-testid="inbound-overview-no-match-rate")

      # Meaningful values present (not dashes)
      refute html =~ ~s(<span class="tabular-nums">—</span>)
      refute html =~ ~s(<span class="tabular-nums">-</span>)
    end
  end

  describe "inbound pagination component" do
    test "renders count and disabled page boundaries from metadata" do
      html =
        render_component(&RecordsList.records_list/1,
          records: [],
          selected_record: nil,
          empty_state: :filtered,
          page_meta: %{
            total_count: 9,
            page: 1,
            per_page: 5,
            total_pages: 2,
            has_previous?: false,
            has_next?: true
          },
          previous_page_path: "/ops/mail/inbound?tenant_id=test-tenant&page=1",
          next_page_path: "/ops/mail/inbound?tenant_id=test-tenant&page=2"
        )

      assert html =~ ~s(data-testid="inbound-result-count")
      assert html =~ "9 results"
      assert html =~ ~s(data-testid="inbound-pagination")
      assert html =~ ~s(data-testid="inbound-pagination-prev-disabled")
      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(data-testid="inbound-pagination-next")
      assert html =~ "page=2"
    end

    test "keeps count and hides pagination chrome for one page" do
      html =
        render_component(&RecordsList.records_list/1,
          records: [],
          selected_record: nil,
          empty_state: :truly_empty,
          page_meta: %{
            total_count: 1,
            page: 1,
            per_page: 5,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      assert html =~ "1 result"
      refute html =~ ~s(data-testid="inbound-pagination")
    end
  end

  describe "brand-voice + PII sweep (IADM-06, V10/V5)" do
    test "empty + no-selection states carry verbatim copy and no banned words (V10)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      # Genuine no-data: the calm pane carries the truly-empty copy (D-07 noun).
      # The no-selection prompt lives in the master-detail grid, which no-data
      # withholds (D-02) — assert it on a populated-but-unselected mount instead.
      {:ok, _view, empty_html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert empty_html =~ "No records"
      assert empty_html =~ "No InboundMessages have been recorded yet."
      refute_banned(empty_html)

      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")
      {:ok, _view, populated_html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert populated_html =~
               "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence."

      refute_banned(populated_html)
    end

    test "detail-load-error band carries verbatim copy and no banned words (V10)", %{conn: conn} do
      conn = operator_conn(conn)
      %{record: foreign} = InboundFixtures.seed_matched!(@other_tenant)

      # Populate the same tenant so the master-detail grid (and its detail-error
      # band) renders — genuine no-data withholds the grid (Phase 121 D-02).
      InboundFixtures.seed_matched!(@tenant_id, recipient: "local@example.com")

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => foreign.id}))

      assert html =~
               "InboundMessage not loaded: selected record is outside the current tenant or active filters. Refresh the page or adjust the filters, then try again."

      refute_banned(html)
    end

    test "no-execution-runs copy renders for a record with no runs (V10)", %{conn: conn} do
      conn = operator_conn(conn)

      # A record with evidence but no execution runs at all.
      record = InboundFixtures.insert_record!(@tenant_id, recipient: "norun@example.com")
      _evidence = InboundFixtures.insert_evidence!(@tenant_id, record.id)

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      assert html =~ "No execution runs have been recorded for this message yet."
      refute_banned(html)
    end

    test "replay success, mailbox-missing block, and not-authorized block carry verbatim copy (V10)",
         %{conn: conn} do
      # Success.
      conn1 = operator_conn(conn)
      %{record: matched} = InboundFixtures.seed_matched!(@tenant_id, recipient: "ok@example.com")

      {:ok, view1, _html} =
        live(conn1, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => matched.id}))

      success_html = render_click(view1, "confirm_replay", %{})

      assert unescape(success_html) =~
               "Replay recorded. A new replay run was appended to this InboundMessage's timeline."

      refute_banned(success_html)

      # Mailbox-missing (:no_match).
      conn2 = operator_conn(conn)
      %{record: nomatch} = InboundFixtures.seed_no_match!(@tenant_id, recipient: "nm@example.com")

      {:ok, view2, _html} =
        live(conn2, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => nomatch.id}))

      block_html = render_click(view2, "confirm_replay", %{})
      assert block_html =~ "Replay blocked: mailbox module not found."
      refute_banned(block_html)

      # Not authorized (denied capability).
      conn3 = operator_conn(conn, %{"current_user_id" => "deny-replay"})
      %{record: denied} = InboundFixtures.seed_matched!(@tenant_id, recipient: "no@example.com")

      {:ok, view3, _html} =
        live(conn3, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => denied.id}))

      denied_html = render_click(view3, "confirm_replay", %{})

      assert denied_html =~
               "Replay blocked: this action is not authorized for the current operator."

      refute_banned(denied_html)
    end

    test "evidence redacted-default + reveal-denied carry verbatim copy (V10)", %{conn: conn} do
      conn = operator_conn(conn, %{"current_user_id" => "deny-reveal"})

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "ev@example.com",
          evidence: [raw_payload: %{"body" => "SECRET-BYTES"}]
        )

      {:ok, view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      assert html =~
               "Raw source redacted. Revealing the raw provider payload requires the reveal_raw capability."

      denied_html = render_click(view, "reveal_raw", %{})

      assert denied_html =~
               "Raw source not revealed: the reveal_raw capability is not granted for this operator."

      refute denied_html =~ "SECRET-BYTES"
      refute_banned(denied_html)
    end

    test "routing-trace heading + sub-label + legend carry verbatim copy (V10)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id, recipient: "trace@example.com")

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      assert html =~ "Routing trace"
      assert html =~ "Why this message did not match"

      assert html =~
               "Each route matches by AND across its clauses: any = no constraint, an exact value matches by string equality, and ~r/…/ matches by regular expression."

      refute_banned(html)
    end

    test "recipient is masked across list, detail header, and routing-trace actual (V5 full)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      raw = "fulltrace@example.com"
      masked = "f********@e******.com"

      %{record: record} = InboundFixtures.seed_no_match!(@tenant_id, recipient: raw)

      # List surface.
      {:ok, _view, list_html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))
      assert list_html =~ masked
      refute list_html =~ raw

      # Detail + routing-trace surfaces (selected).
      {:ok, _view2, detail_html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      # Masked in the detail header AND the routing-trace recipient "actual".
      assert detail_html =~ masked
      refute detail_html =~ raw
      assert detail_html =~ ~s(data-testid="inbound-routing-trace")
    end

    test "raw evidence bytes are absent until :reveal_raw is granted (V5)", %{conn: conn} do
      secret = "RAW-SECRET-#{System.unique_integer([:positive])}"

      # Default-redacted: bytes absent.
      conn1 = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "rr@example.com",
          evidence: [raw_payload: %{"body" => secret}]
        )

      {:ok, _view, redacted_html} =
        live(conn1, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      refute redacted_html =~ secret

      # Granted: bytes present in the read-only pre region.
      conn2 = operator_conn(conn)

      {:ok, view2, _html} =
        live(conn2, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      revealed_html = render_click(view2, "reveal_raw", %{})
      assert revealed_html =~ secret
      assert revealed_html =~ ~s(data-testid="inbound-evidence-raw")
    end
  end

  describe "reveal re-redact + PII-free telemetry (D-11 / D-12)" do
    @pii_keys [:to, :from, :body, :html_body, :subject, :headers, :recipient, :email, :payload]

    test "re_redact_raw collapses :revealed back to :redacted with no auth call (D-11)", %{
      conn: conn
    } do
      secret = "RR-SECRET-#{System.unique_integer([:positive])}"
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "rr@example.com",
          evidence: [raw_payload: %{"body" => secret}]
        )

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      # Grant first so we have something to collapse.
      revealed_html = render_click(view, "reveal_raw", %{})
      assert revealed_html =~ ~s(data-testid="inbound-evidence-raw")
      assert revealed_html =~ secret

      # Re-redact collapses back: raw bytes absent, redacted body present.
      redacted_html = render_click(view, "re_redact_raw", %{})
      refute redacted_html =~ ~s(data-testid="inbound-evidence-raw")
      refute redacted_html =~ secret

      assert redacted_html =~
               "Raw source redacted. Revealing the raw provider payload requires the reveal_raw capability."
    end

    test "reveal emits a PII-free [:reveal_raw, :stop] with outcome=:granted (D-12)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "tg@example.com",
          evidence: [raw_payload: %{"body" => "GRANT-BYTES"}]
        )

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      meta = attach_and_reveal(view)

      assert meta.outcome == :granted
      assert Map.has_key?(meta, :tenant_id)
      assert Map.has_key?(meta, :record_id)
      assert_no_pii(meta)
    end

    test "reveal emits outcome=:denied for a denying operator (D-12)", %{conn: conn} do
      conn = operator_conn(conn, %{"current_user_id" => "deny-reveal"})

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "td@example.com",
          evidence: [raw_payload: %{"body" => "DENY-BYTES"}]
        )

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      meta = attach_and_reveal(view)

      assert meta.outcome == :denied
      assert_no_pii(meta)
    end

    defp attach_and_reveal(view) do
      ref = make_ref()
      test_pid = self()
      handler_id = "test-reveal-#{inspect(ref)}"

      :telemetry.attach(
        handler_id,
        [:mailglass_admin, :inbound, :reveal_raw, :stop],
        fn _event, _measurements, metadata, _config ->
          send(test_pid, {ref, metadata})
        end,
        nil
      )

      try do
        render_click(view, "reveal_raw", %{})

        receive do
          {^ref, metadata} -> metadata
        after
          1_000 -> flunk("expected [:mailglass_admin, :inbound, :reveal_raw, :stop] telemetry event")
        end
      after
        :telemetry.detach(handler_id)
      end
    end

    defp assert_no_pii(meta) do
      for key <- @pii_keys do
        refute Map.has_key?(meta, key),
               "telemetry metadata leaked PII key #{inspect(key)}: #{inspect(meta)}"
      end
    end
  end

  defp refute_banned(html) do
    for word <- @banned do
      refute html =~ word, "banned brand-voice word #{inspect(word)} found in rendered HTML"
    end
  end

  describe "root layout theme (MountPathHook)" do
    test "?theme=dark themes the inbound ROOT <html>, not just the shell", %{conn: conn} do
      conn = operator_conn(conn)

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "theme" => "dark"}))

      assert html =~ ~s|<html lang="en" data-theme="mailglass-dark">|
    end

    test "no theme param leaves the inbound root <html> un-themed", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      refute html =~ ~s|<html lang="en" data-theme="mailglass-dark">|
    end
  end

  defp inbound_path(params) do
    case URI.encode_query(params) do
      "" -> @base_path
      query -> @base_path <> "?" <> query
    end
  end

  defp clear_filters_count(html) do
    html
    |> String.split("Clear filters")
    |> length()
    |> Kernel.-(1)
  end

  # HEEx HTML-escapes text nodes, so verbatim UI-SPEC copy with an apostrophe
  # renders as `&#39;`. Decode the handful of entities Phoenix emits so copy
  # assertions can use the exact UI-SPEC string.
  defp unescape(html) do
    html
    |> String.replace("&#39;", "'")
    |> String.replace("&#x27;", "'")
    |> String.replace("&quot;", "\"")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
  end

  defp run_count(record_id) do
    ExecutionRun
    |> where([run], run.inbound_record_id == ^record_id)
    |> TestRepo.aggregate(:count, :id)
  end

  defp latest_run(record_id) do
    ExecutionRun
    |> where([run], run.inbound_record_id == ^record_id)
    |> order_by([run], desc: run.inserted_at, desc: run.id)
    |> limit(1)
    |> TestRepo.one()
  end

  defp operator_conn(conn, session \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.configure_session(renew: false)
    |> then(fn conn ->
      Plug.Test.init_test_session(conn, Map.merge(get_session_map(conn), session))
    end)
  end

  defp get_session_map(conn) do
    %{
      "current_user_id" => Plug.Conn.get_session(conn, "current_user_id"),
      "tenant_id" => Plug.Conn.get_session(conn, "tenant_id"),
      "auth_method" => Plug.Conn.get_session(conn, "auth_method"),
      "recent_auth_at" => Plug.Conn.get_session(conn, "recent_auth_at")
    }
  end

  describe "motion-reveal re-fire fix (GAP-19 / MOTION-01)" do
    test "inbound detail pane motion-reveal div carries a record-keyed id (D-02)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "motion@example.com")

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      assert html =~ ~s(id="inbound-detail-#{record.id}")
    end
  end
end
