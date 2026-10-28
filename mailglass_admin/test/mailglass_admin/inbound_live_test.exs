defmodule MailglassAdmin.InboundUnavailableRepo do
  @moduledoc false

  def all(_queryable, _opts \\ []),
    do: raise(DBConnection.ConnectionError, message: "synthetic inbound connection failure")

  def one(_queryable, _opts \\ []),
    do: raise(DBConnection.ConnectionError, message: "synthetic inbound connection failure")
end

defmodule MailglassAdmin.InboundTimelineFailingRepo do
  @moduledoc false

  alias MailglassAdmin.TestRepo
  alias MailglassInbound.InboundRecords.ExecutionRun

  def all(queryable, opts \\ []) do
    case query_source(queryable) do
      {_table, ExecutionRun} ->
        raise DBConnection.ConnectionError, message: "synthetic timeline connection failure"

      _source ->
        TestRepo.all(queryable, opts)
    end
  end

  def one(queryable, opts \\ []), do: TestRepo.one(queryable, opts)

  defp query_source(queryable) do
    queryable
    |> Ecto.Queryable.to_query()
    |> Map.fetch!(:from)
    |> Map.fetch!(:source)
  end
end

defmodule MailglassAdmin.InboundListFailingRepo do
  @moduledoc false

  alias MailglassAdmin.TestRepo

  def all(_queryable, _opts \\ []),
    do: raise(DBConnection.ConnectionError, message: "synthetic inbound list connection failure")

  def one(queryable, opts \\ []), do: TestRepo.one(queryable, opts)
  def get(queryable, id, opts \\ []), do: TestRepo.get(queryable, id, opts)
end

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

  alias Ecto.Changeset
  alias MailglassAdmin.InboundLive
  alias MailglassAdmin.PubSub.Topics
  alias MailglassAdmin.Inbound.ReadResult
  alias MailglassAdmin.Inbound.RecordsList
  alias MailglassAdmin.TestSupport.InboundFixtures
  alias MailglassInbound.InboundRecords.ExecutionRun

  @tenant_id "test-tenant"
  @other_tenant "other-tenant"
  @base_path "/ops/mail/inbound"
  @banned ["Oops", "Whoops", "Uh oh", "Something went wrong"]
  @theme_cookie MailglassAdmin.Theme.cookie_name()

  describe "inbound surface" do
    test "inbound page header describes its review task", %{conn: conn} do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!("header-inbound", recipient: "reader@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => "header-inbound"}))

      assert html =~ "Follow each received message through routing and mailbox processing."
    end

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

      assert html =~ "Choose an Account"
      assert html =~ "Select an Account to see scoped operator data."
      assert html =~ "Choose Account"
      assert html =~ "alpha-inbound"
      assert html =~ "beta-inbound"
      refute html =~ "add a tenant_id to the URL"
    end

    test "renders the no-selection prompt and identifiable recipients", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "alice@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "Received messages"
      assert html =~ ~s(data-testid="inbound-master-detail")
      # Operators can identify the destination address from the list.
      assert html =~ "alice@example.com"
      refute html =~ "a****@e******.com"
      # No selection → the list stands alone; the Quick view overlay and Full detail
      # are both absent until a record is focused.
      refute html =~ ~s(data-testid="inbound-quick-view")
      refute html =~ ~s(data-testid="inbound-detail-column")
      refute html =~ "Execution timeline"
      # Record id IS rendered (it is not PII) so selection works.
      assert html =~ record.id
      # Orientation strip is empty-pane-only now (D-04): on a POPULATED but
      # unselected view it MUST be absent.
      refute html =~ ~s(data-testid="inbound-orientation")
    end

    test "blank tenant renders the empty state and leaks no other-tenant id or recipient (V1)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      # Seed a record under a DIFFERENT tenant; a blank tenant must not surface it.
      %{record: other} =
        InboundFixtures.seed_matched!(@other_tenant, recipient: "secret@elsewhere.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => ""}))

      assert html =~ "Choose an Account"
      assert html =~ "Select an Account to see scoped operator data."

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

      assert html =~ "No messages"

      # D-07 noun discipline: the InboundMessage noun, not the old "No messages…" drift.
      assert html =~
               "No messages have been received yet."

      # Genuine no-data is a single calm pane: orientation strip present,
      # filters toolbar and the master-detail grid WITHHELD (D-02/D-05 —
      # the toolbar is the only scope-widening vector).
      assert html =~ ~s(data-testid="inbound-orientation")
      refute html =~ ~s(data-testid="inbound-filters")
      refute html =~ ~s(data-testid="inbound-master-detail")

      # The toolbar Clear-filters button is gone, and the truly-empty pane has
      # no in-pane reset (that is :filtered-only) — so the count is 0.
      assert clear_filters_count(html) == 0
      refute html =~ "No messages match the current filters."
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
      assert html =~ "Unrouted"
      assert html =~ "Accepted"
      refute html =~ "No-match rate"
      doc = Floki.parse_document!(html)
      assert summary_count(doc, "accepted") == "1"
      assert summary_count(doc, "no-match") == "1"
      assert summary_count(doc, "failed") == "0"
      assert Floki.find(doc, "[data-testid='inbound-overview-no-change']") == []
      refute html =~ "foreign@example.com"

      assert_in_order(html, [
        ~s(data-testid="inbound-filters"),
        ~s(data-testid="inbound-overview"),
        ~s(data-testid="inbound-master-detail")
      ])
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
      assert html =~ "Accepted"

      assert Floki.find(
               Floki.parse_document!(html),
               "[data-testid='inbound-overview-accepted'] p"
             )
             |> Enum.at(1)
             |> Floki.text()
             |> String.trim() == "101"

      assert html =~ "accepted-101@example.com"
    end

    test "hides all-outcome summary when mailbox outcome narrows records", %{conn: conn} do
      conn = operator_conn(conn)
      matched = InboundFixtures.seed_matched!(@tenant_id, provider: "mailgun", subject: "Invoice")

      unmatched =
        InboundFixtures.seed_no_match!(@tenant_id, provider: "mailgun", subject: "Invoice")

      InboundFixtures.seed_matched!(@tenant_id, provider: "ses", subject: "Invoice")
      InboundFixtures.seed_matched!(@tenant_id, provider: "mailgun", subject: "Other")

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "mailgun",
            "search" => "Invoice",
            "window_hours" => "24",
            "outcome" => "accept"
          })
        )

      doc = Floki.parse_document!(html)

      assert Floki.find(doc, "[data-testid='inbound-overview']") == []
      assert Floki.find(doc, "[data-testid='inbound-summary-outcome-scope']") == []
      assert Floki.find(doc, "[data-testid='inbound-result-count']") != []

      assert html =~ matched.record.id
      refute html =~ unmatched.record.id

      assert Floki.attribute(Floki.find(doc, "#filters_provider"), "aria-describedby") == [
               "filters_provider-help"
             ]

      assert Floki.find(doc, "#filters_provider-help") |> Floki.attribute("class") == ["sr-only"]
    end

    test "gateway-unavailable runtime path names missing support without claiming successful empty data",
         %{
           conn: conn
         } do
      conn = operator_conn(conn)

      Application.put_env(:mailglass_admin, :inbound_gateway_available?, false)
      on_exit(fn -> Application.delete_env(:mailglass_admin, :inbound_gateway_available?) end)

      InboundFixtures.seed_matched!(@tenant_id, recipient: "hidden@example.com")

      selected_id = Ecto.UUID.generate()

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => selected_id}))

      assert html =~ ~s(data-testid="inbound-package-unavailable")
      assert html =~ "Inbound support is unavailable"
      assert html =~ "The selected record could not be checked."
      refute html =~ "No messages have been received yet."
      refute html =~ ~s(data-testid="inbound-orientation")
      refute html =~ ~s(data-testid="inbound-overview")
      refute html =~ ~s(data-testid="inbound-result-count")
      refute html =~ "hidden@example.com"
    end

    test "an out-of-range page keeps the real count and offers a route back to page one", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      InboundFixtures.seed_matched!(@tenant_id,
        provider: "mailgun",
        subject: "Existing record"
      )

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "mailgun",
            "page" => "99"
          })
        )

      assert html =~ "No messages on this page"
      assert html =~ "1 message"
      assert html =~ ~s(data-testid="inbound-page-reset")
      assert html =~ "provider=mailgun"
      refute html =~ "page=99"
      refute html =~ "No messages match the current filters."
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

      assert html =~ "No messages"
      assert html =~ "No messages match the current filters."
      assert clear_filters_count(html) == 2
      refute html =~ "No messages have been recorded yet."
    end

    test "connection failures are identified without claiming empty records or zero summary", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      previous_repo = Application.fetch_env!(:mailglass_inbound, :repo)
      Application.put_env(:mailglass_inbound, :repo, MailglassAdmin.InboundUnavailableRepo)

      on_exit(fn -> Application.put_env(:mailglass_inbound, :repo, previous_repo) end)

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-read-unavailable")
      assert html =~ "Couldn&#39;t load inbound messages for these filters"
      assert html =~ "The read failed. Your filters are unchanged. Retry, or change a filter."
      assert html =~ "Inbound summary unavailable"
      refute html =~ "No messages have been received yet."
      refute html =~ "synthetic inbound connection failure"
      refute html =~ ~s(data-testid="inbound-result-count")
      refute html =~ ~s(data-testid="inbound-overview-total")
    end

    test "an unavailable records list does not claim the selected record is outside the results",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "list-unavailable@example.com")

      previous_repo = Application.fetch_env!(:mailglass_inbound, :repo)
      Application.put_env(:mailglass_inbound, :repo, MailglassAdmin.InboundListFailingRepo)

      on_exit(fn -> Application.put_env(:mailglass_inbound, :repo, previous_repo) end)

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id})
        )

      assert html =~ record.id
      assert html =~ ~s(data-testid="inbound-read-unavailable")
      refute html =~ "This inbound message is outside your current results."
    end

    test "a timeline connection failure does not erase the independently loaded record", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "timeline@example.com")

      previous_repo = Application.fetch_env!(:mailglass_inbound, :repo)
      Application.put_env(:mailglass_inbound, :repo, MailglassAdmin.InboundTimelineFailingRepo)

      on_exit(fn -> Application.put_env(:mailglass_inbound, :repo, previous_repo) end)

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ record.id
      assert html =~ ~s(data-testid="inbound-timeline-unavailable")
      assert html =~ "Timeline unavailable"
      refute html =~ "No execution runs have been recorded for this InboundMessage yet."
      refute html =~ "synthetic timeline connection failure"
    end

    test "gateway result classification is narrow and sanitizes explicit failures" do
      assert ReadResult.fetch(fn -> [] end) == {:ok, []}

      assert ReadResult.fetch(fn -> {:error, {:database, "private failure"}} end) ==
               {:error, :read_unavailable}

      assert ReadResult.fetch(fn ->
               raise DBConnection.ConnectionError, message: "synthetic transient failure"
             end) == {:error, :read_unavailable}

      assert_raise ArgumentError, "unexpected programming error", fn ->
        ReadResult.fetch(fn -> raise ArgumentError, "unexpected programming error" end)
      end
    end

    test "inbound page links preserve tenant scope and expose honest boundaries", %{conn: conn} do
      conn = operator_conn(conn)

      for index <- 1..21 do
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "page-#{index}@example.com",
          provider_message_id: "inbound-page-#{index}"
        )
      end

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-result-count")
      assert html =~ "21 messages"
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

      {:ok, view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-filters")
      assert html =~ ~s(data-testid="inbound-filters-toggle")
      refute view |> element("#inbound-filters") |> render() =~ "phx-disable-with"
      assert html =~ ~s(aria-controls="inbound-filter-panel")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ "toggle"
      assert html =~ ~s(to&quot;:&quot;#inbound-filter-panel&quot;)
      assert html =~ ~s(id="inbound-filter-panel")
      assert html =~ "hidden md:block"
      # Master-detail split is conditional: a single column until a record is
      # selected. The split-percentage grid is asserted in the selection test.
      assert html =~ "grid-cols-1"
      refute html =~ "md:grid-cols-[40%_60%]"
      assert html =~ "Received messages"
      refute html =~ "tracking-[0.08em]"
    end

    test "selecting a record renders the detail header + timeline in place with URL state", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "selected@example.com")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      # Row click → Quick view (peek) over the still-mounted list.
      view
      |> element("button[data-testid='inbound-record-open'][phx-value-id='#{record.id}']")
      |> render_click()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "inbound_id" => record.id,
          "window_hours" => "168"
        })
      )

      quick_html = render(view)
      assert quick_html =~ ~s(data-testid="inbound-quick-view")
      assert quick_html =~ ~s(aria-labelledby="inbound-quick-view-title")
      assert quick_html =~ "Previous inbound record"
      assert quick_html =~ "Next inbound record"
      assert quick_html =~ "text-heading font-bold text-base-content"
      quick_document = Floki.parse_document!(quick_html)

      for {direction, label} <- [
            {"prev", "Previous inbound record"},
            {"next", "Next inbound record"}
          ] do
        button = Floki.find(quick_document, "[data-testid='inbound-quick-view-#{direction}']")
        assert button != []
        assert Floki.attribute(button, "disabled") != []
        assert Floki.attribute(button, "aria-label") == [label]
      end

      assert quick_html =~ ~s(aria-current="true")
      assert quick_html =~ "selected@example.com"
      refute quick_html =~ "s*******@e******.com"
      refute quick_html =~ "Execution timeline"

      # Open full detail → the complete record (header + timeline).
      view
      |> element(~s([data-testid="inbound-quick-view-full"]))
      |> render_click()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "inbound_id" => record.id,
          "window_hours" => "168",
          "full" => "1"
        })
      )

      html = render(view)

      assert html =~ ~s(data-testid="inbound-detail-header")
      assert html =~ ~s(data-testid="inbound-detail-back")
      assert html =~ "Back to quick view"
      assert html =~ ~s(data-testid="inbound-timeline")
      assert html =~ "Execution timeline"
      assert html =~ "MyApp.Mailboxes.SupportMailbox"

      timestamp_copy =
        Floki.find(
          Floki.parse_document!(html),
          "[data-testid='inbound-detail-header'] button[data-timestamp-copy]"
        )

      assert Floki.attribute(timestamp_copy, "data-copy-value") == [
               MailglassAdmin.Components.timestamp_value(record.received_at)
             ]

      # Fresh + replay source badges both appear (V matched seed).
      assert html =~ "Initial processing"
      assert html =~ "Replay"
      # Detail shows the recipient.
      assert html =~ "selected@example.com"

      # Back from Full detail returns to the Quick view (id kept, full dropped).
      view
      |> element(~s(a[data-testid="inbound-detail-back"]))
      |> render_click()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "inbound_id" => record.id,
          "window_hours" => "168"
        })
      )

      # Closing the Quick view returns to the full-width list.
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
      assert html =~ ~s(<option value="mailgun" selected)
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

      assert html2 =~ ~s(<option value="mailgun" selected)
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

    test "clicking the dimmed scrim closes the inbound Quick view back to the list",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "scrim@example.com")

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      assert render(view) =~ ~s(data-testid="inbound-quick-view")

      # Regression: the scrim is a patch link; clicking the dimmed area dismisses the
      # overlay and returns to the records list.
      view
      |> element(~s(a[data-testid="inbound-quick-view-scrim"]))
      |> render_click()

      assert_patch(view, inbound_path(%{"tenant_id" => @tenant_id, "window_hours" => "168"}))
      refute render(view) =~ ~s(data-testid="inbound-quick-view")
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

      # The rejected window stays in the draft: the select shows "Custom period (bogus
      # hours)" selected next to its error instead of silently selecting 168 (D-12).
      document = Floki.parse_document!(html)
      assert Floki.find(document, "#filters_outcome option[value='not-real']") == []
      assert selected_filter_value(html, "#filters_window_hours") == "bogus"

      assert document
             |> Floki.find("#filters_window_hours option[value='bogus']")
             |> Floki.text()
             |> String.trim() == "Custom period (bogus hours)"
    end

    test "invalid submitted filters render recovery copy and do not push a patch", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      html =
        render_hook(view, "validate_filters", %{
          "_target" => ["filters", "outcome"],
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

      document = Floki.parse_document!(html)
      assert Floki.find(document, "#filters_outcome option[value='not-real']") == []

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
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => foreign.id, "full" => "1"})
        )

      assert html =~ ~s(data-testid="inbound-detail-error")

      assert html =~
               "This inbound message could not be loaded in the selected Account. Check the record ID and try again."
    end

    test "exact selected record opens outside the current result page and returns to its context",
         %{
           conn: conn
         } do
      conn = operator_conn(conn)

      %{record: selected} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "mailgun-selected@example.com",
          provider: "mailgun"
        )

      for index <- 1..21 do
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "ses-visible-#{index}@example.com",
          provider: "ses"
        )
      end

      result_context = %{
        "tenant_id" => @tenant_id,
        "provider" => "ses",
        "window_hours" => "168",
        "page" => "2"
      }

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(Map.put(result_context, "inbound_id", selected.id))
        )

      # The exact same-Account record is resolved independently of the active
      # provider/page slice, and the native table control remains the opener.
      assert html =~ selected.id
      assert html =~ "outside your current results"
      refute html =~ "InboundMessage not loaded"

      document = Floki.parse_document!(html)

      row =
        Floki.find(
          document,
          "[data-testid='inbound-records-table'] tr[data-testid='inbound-record-row']"
        )
        |> hd()

      assert Floki.find(row, "button[data-testid='inbound-record-open']") != []
      refute Floki.attribute(row, "phx-click") != []

      {:ok, view, _html} =
        live(conn, inbound_path(Map.put(result_context, "inbound_id", selected.id)))

      view
      |> element("a[data-testid='inbound-quick-view-full']")
      |> render_click()

      assert_patch(
        view,
        inbound_path(Map.merge(result_context, %{"inbound_id" => selected.id, "full" => "1"}))
      )

      assert render(view) =~ ~s(id="inbound-detail-#{selected.id}")
      assert render(view) =~ "outside your current results"

      view
      |> element("a[data-testid='inbound-detail-back']")
      |> render_click()

      assert_patch(view, inbound_path(Map.put(result_context, "inbound_id", selected.id)))
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
            "inbound_id" => selected.id,
            "full" => "1"
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
      assert html =~ "Unrouted"
      assert html =~ "Unrouted"
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
      assert html =~ "Unrouted"
    end

    test "filters an explicit no-change run without including an ignored run", %{conn: conn} do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!(@tenant_id, recipient: "initial@example.com")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      no_change = InboundFixtures.insert_record!(@tenant_id, recipient: "no-change@example.com")
      no_change_evidence = InboundFixtures.insert_evidence!(@tenant_id, no_change.id)

      InboundFixtures.insert_run!(@tenant_id, no_change.id, no_change_evidence.id,
        outcome: :no_change
      )

      ignored = InboundFixtures.insert_record!(@tenant_id, recipient: "ignored@example.com")
      ignored_evidence = InboundFixtures.insert_evidence!(@tenant_id, ignored.id)

      InboundFixtures.insert_run!(@tenant_id, ignored.id, ignored_evidence.id, outcome: :ignore)

      view
      |> form("#inbound-filters",
        filters: %{
          "provider" => "",
          "outcome" => "no_change",
          "window_hours" => "168",
          "search" => ""
        }
      )
      |> render_submit()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "outcome" => "no_change",
          "window_hours" => "168"
        })
      )

      html = render(view)
      assert html =~ no_change.id
      refute html =~ ignored.id
      assert html =~ ~s(<option value="no_change" selected)
      assert html =~ "No change"
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
      refute html =~ "Current router simulation"
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
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ ~s(data-testid="inbound-routing-trace")
      assert html =~ "Current router simulation"
      assert html =~ "How current route rules compare"
      assert html =~ "Does not match current clauses"

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
      assert html =~ "Header"
      refute html =~ "x-priority"
      # Legend (verbatim).
      assert html =~
               "A route matches only when every condition passes. “Any” means that field is unrestricted."
    end

    test "labels a route that matches current rules even when the stored outcome was no-match",
         %{conn: conn} do
      conn = operator_conn(conn)

      # The stored execution says no-match, but the current router's billing
      # subject route matches this message. The trace must report current rules.
      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id,
          recipient: "nobody@example.com",
          subject: "[billing] current route match",
          headers: %{}
        )

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ "Current router simulation"
      assert html =~ "Matches current clauses"
      assert html =~ "Does not match current clauses"
      assert html =~ ~s(data-testid="inbound-route-result")
    end

    test "renders safe matcher summaries and masks recipient actual",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id,
          recipient: "nomatch@example.com",
          subject: "general question",
          headers: %{}
        )

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      # Recipient matcher is masked like the recipient actual; both are PII.
      assert html =~ "s******@e******.com"
      refute html =~ "support@example.com"
      # Regex matcher internals are withheld; the UI communicates its kind only.
      assert html =~ "Regular expression matcher"
      refute html =~ "billing"
      # Wildcard clauses (nil matchers, e.g. the subject on route 1) render "any".
      assert html =~ ~r/>\s*any\s*</
      # The recipient ACTUAL is masked, never raw.
      assert html =~ "n******@e******.com"

      refute html
             |> Floki.parse_document!()
             |> Floki.find("[data-testid='inbound-routing-trace']")
             |> Floki.text() =~ "nomatch@example.com"

      # First failing clause carries the opaque error-tint emphasis.
      assert html =~ "mg-trace-clause-failing"
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
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ ~s(data-testid="inbound-evidence-card")
      assert html =~ "Raw provider source"
      # Collapsed: one persistent disclosure plus the always-visible caption.
      assert html =~ ~s(data-testid="inbound-evidence-caption")
      assert html =~ "May contain personal information."
      assert html =~ "Reveal raw source"
      refute html =~ "Raw source is hidden by default"

      # The raw payload bytes MUST be absent from the HTML by default.
      refute html =~ secret
      # Arbitrary provider verification keys and values are withheld.
      verification_text =
        html
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-evidence-verification']")
        |> Floki.text()

      assert verification_text =~ "Unavailable"
      refute verification_text =~ "spf"
      refute verification_text =~ "dkim"
      refute verification_text =~ "pass"
    end
  end

  describe "evidence card without stored evidence (INUX-06)" do
    @tag :phase176
    test "Phase 176 Inbound detail without stored evidence says so and offers no reveal", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      record = InboundFixtures.insert_record!(@tenant_id, recipient: "no-evidence@example.com")

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert [card] =
               html
               |> Floki.parse_document!()
               |> Floki.find("[data-testid='inbound-evidence-card']")

      card_text = Floki.text(card)
      assert card_text =~ "Raw provider source"
      assert card_text =~ "No raw provider source was stored for this message."
      assert Floki.find(card, "[data-testid='inbound-evidence-reveal']") == []
      assert Floki.find(card, "[data-testid='inbound-evidence-facts']") == []
      # Unknown is never shown as zero.
      refute card_text =~ "0 bytes"
    end
  end

  describe "replay confirm flow (IADM-03)" do
    @describetag :phase175
    test "confirming replay on a matched record appends a :replay ExecutionRun (V2)", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      MailglassAdmin.TestOperatorAuth.reset_inbound_replay_calls!()

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "replay@example.com")

      before_count = run_count(record.id)

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      review_html = render_click(view, "open_replay", %{})

      initial_html = render(view)

      initial_timeline_count =
        initial_html
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-timeline-run']")
        |> length()

      initial_snapshot_at =
        initial_html
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-timeline-snapshot'] time")
        |> Floki.attribute("datetime")
        |> List.first()

      assert review_html =~ ~s(id="inbound-replay-modal")
      assert review_html =~ record.id
      assert review_html =~ "Recorded Mailbox: Elixir.MyApp.Mailboxes.SupportMailbox"
      assert review_html =~ "currently deployed code against the stored inbound message"

      assert review_html =~
               "does not evaluate current router rules or redeliver through the provider"

      refute review_html =~ "Re-runs Mailbox routing"

      confirm_button = Floki.find(Floki.parse_document!(review_html), "#inbound-replay-confirm")
      assert Floki.attribute(confirm_button, "disabled") == []

      assert review_html =~ ~s(phx-hook="ModalFocusTrap")
      assert review_html =~ ~s(data-focus-trap="start")
      assert review_html =~ ~s(data-focus-trap="end")
      assert review_html =~ ~s(phx-window-keydown="close_replay")
      assert review_html =~ ~s(id="inbound-replay-close")
      assert review_html =~ ~s(id="inbound-replay-cancel")

      html =
        view
        |> element("#inbound-replay-confirm")
        |> render_click()

      refute html =~ "Replay run recorded. Mailbox outcome"

      assert_push_event(view, "mailglass:toast", %{
        message: "Replay run recorded. Mailbox outcome: Accepted.",
        error: false
      })

      refute html =~ ~s(data-testid="inbound-replay-modal")

      assert length(
               Floki.find(Floki.parse_document!(html), "[data-testid='inbound-timeline-run']")
             ) ==
               initial_timeline_count + 1

      replay_run = latest_run(record.id)
      assert html =~ replay_run.id

      refreshed_snapshot_at =
        html
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-timeline-snapshot'] time")
        |> Floki.attribute("datetime")
        |> List.first()

      assert is_binary(refreshed_snapshot_at)
      refute refreshed_snapshot_at == initial_snapshot_at

      refreshed_html = render_click(view, "refresh_inbound_timeline", %{})
      assert refreshed_html =~ replay_run.id

      assert length(
               Floki.find(
                 Floki.parse_document!(refreshed_html),
                 "[data-testid='inbound-timeline-run']"
               )
             ) ==
               initial_timeline_count + 1

      assert refreshed_html =~ replay_run.id

      after_count = run_count(record.id)
      assert after_count == before_count + 1
      assert MailglassAdmin.TestOperatorAuth.inbound_replay_calls() == [record.id]

      duplicate_html = render_click(view, "confirm_replay", %{})

      assert duplicate_html =~
               "Replay was already submitted for this review."

      assert run_count(record.id) == after_count

      # The newest run is source: :replay (append-only — prior rows untouched).
      latest = latest_run(record.id)
      assert latest.source == :replay
    end

    test "replaying a :no_match record is blocked with the no-prior-match copy and appends no run (V11)",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id, recipient: "nomatch@example.com")

      before_count = run_count(record.id)

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      review_html = render_click(view, "open_replay", %{})
      assert review_html =~ "No mailbox matched this message when it was received"
      confirm_button = Floki.find(Floki.parse_document!(review_html), "#inbound-replay-confirm")
      assert Floki.attribute(confirm_button, "disabled") != []

      # The confirm path is defensively mapped even though the button is disabled
      # in the header (render→click race) — drive the event directly.
      html = render_click(view, "confirm_replay", %{})

      assert html =~
               "Replay unavailable: no mailbox matched this message when it was received, so there is no route to replay it through."

      assert run_count(record.id) == before_count
    end

    test "replaying a pre-v2.6 (pre-binding) record names the real cause and appends no run",
         %{conn: conn} do
      conn = operator_conn(conn)

      # A row ingested before 61e8c8e8 made the durable route binding the sole
      # source of a replay mailbox. It matched at receive time and persisted a
      # mailbox string, but resolving that string is the unsafe operation the
      # ratchet deliberately closed -- so the row can never replay, and the copy
      # must say so rather than implying a fixable misconfiguration.
      %{record: record} =
        InboundFixtures.seed_pre_binding_matched!(@tenant_id, recipient: "legacy@example.com")

      before_count = run_count(record.id)

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      review_html = render_click(view, "open_replay", %{})
      assert review_html =~ "The original Mailbox binding is missing or unsafe"
      confirm_button = Floki.find(Floki.parse_document!(review_html), "#inbound-replay-confirm")
      assert Floki.attribute(confirm_button, "disabled") != []

      html = render_click(view, "confirm_replay", %{})

      assert html =~
               "Replay unavailable: this message was received before mailglass_inbound 2.6 recorded a durable route binding"

      # The operator must not be pointed at a missing module they could "fix".
      refute html =~ "mailbox module not found"
      refute_banned(html)
      assert run_count(record.id) == before_count
    end

    test "missing execution history disables confirmation with its own reason", %{conn: conn} do
      conn = operator_conn(conn)
      record = InboundFixtures.insert_record!(@tenant_id, recipient: "history@example.com")
      InboundFixtures.insert_evidence!(@tenant_id, record.id)

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      review_html = render_click(view, "open_replay", %{})

      assert review_html =~ "No execution history is recorded for this message"
      confirm_button = Floki.find(Floki.parse_document!(review_html), "#inbound-replay-confirm")
      assert Floki.attribute(confirm_button, "disabled") != []
      assert run_count(record.id) == 0
    end

    test "a changed binding after review is rejected before host authorization", %{conn: conn} do
      conn = operator_conn(conn)
      MailglassAdmin.TestOperatorAuth.reset_inbound_replay_calls!()

      %{record: record, evidence: evidence} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "stale@example.com")

      before_count = run_count(record.id)

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      review_html = render_click(view, "open_replay", %{})
      assert review_html =~ "Recorded Mailbox: Elixir.MyApp.Mailboxes.SupportMailbox"

      stale_facts =
        Map.put(evidence.verification_facts, "mailglass_execution_route", %{
          "status" => "no_match"
        })

      {:ok, _updated_evidence} =
        MailglassAdmin.TestRepo.update(
          Changeset.change(evidence, verification_facts: stale_facts)
        )

      html = render_click(view, "confirm_replay", %{})

      assert html =~
               "Replay review is stale. Review again to check the selected record and recorded Mailbox."

      assert html =~ ~s(data-testid="inbound-replay-modal")
      assert html =~ ~s(data-testid="inbound-replay-feedback")

      old_review_id =
        html
        |> Floki.parse_document!()
        |> Floki.find("#inbound-replay-identity")
        |> Floki.attribute("data-review-id")
        |> hd()

      assert Floki.find(Floki.parse_document!(html), "#inbound-replay-review-again") != []
      assert MailglassAdmin.TestOperatorAuth.inbound_replay_calls() == []
      assert run_count(record.id) == before_count

      refreshed_review = render_click(view, "review_replay_again", %{})

      new_review_id =
        refreshed_review
        |> Floki.parse_document!()
        |> Floki.find("#inbound-replay-identity")
        |> Floki.attribute("data-review-id")
        |> hd()

      refute new_review_id == old_review_id
      assert refreshed_review =~ "No mailbox matched this message when it was received"

      assert Floki.find(Floki.parse_document!(refreshed_review), "#inbound-replay-confirm")
             |> Floki.attribute("disabled") != []

      assert MailglassAdmin.TestOperatorAuth.inbound_replay_calls() == []
      assert run_count(record.id) == before_count
    end

    test "switching Accounts closes the reviewed target and cannot replay it", %{conn: conn} do
      conn = operator_conn(conn)
      MailglassAdmin.TestOperatorAuth.reset_inbound_replay_calls!()

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "account-switch@example.com")

      before_count = run_count(record.id)

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      render_click(view, "open_replay", %{})
      render_patch(view, inbound_path(%{"tenant_id" => @other_tenant, "inbound_id" => record.id}))

      html = render_click(view, "confirm_replay", %{})

      refute html =~ ~s(data-testid="inbound-replay-modal")
      assert MailglassAdmin.TestOperatorAuth.inbound_replay_calls() == []
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
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      render_click(view, "open_replay", %{})
      html = render_click(view, "confirm_replay", %{})

      assert html =~ "Replay blocked: this action is not authorized for the current operator."
      assert html =~ ~s(data-testid="inbound-replay-feedback")
      assert html =~ ~s(data-testid="inbound-replay-modal")
      assert Floki.find(Floki.parse_document!(html), "#inbound-replay-review-again") != []
      assert run_count(record.id) == before_count
    end

    test "reported Mailbox outcomes stay distinct from a queued replay request" do
      assert InboundLive.replay_result_copy(%{status: :queued}) ==
               "Replay requested. The runtime reported that this replay is queued."

      assert InboundLive.replay_result_copy(%{status: :requested}) ==
               "Replay requested. The runtime reported that this replay is queued."

      for {outcome, label} <- [
            {:accept, "Accepted"},
            {:ignore, "Ignored"},
            {:reject, "Rejected"},
            {:bounce, "Bounced"},
            {:no_match, "No mailbox matched"},
            {:no_change, "No change"}
          ] do
        assert InboundLive.replay_result_copy(%{outcome: outcome}) ==
                 "Replay run recorded. Mailbox outcome: #{label}."
      end

      assert InboundLive.replay_result_copy(%{outcome: :failed}) ==
               "Replay run recorded. Mailbox execution failed."

      assert InboundLive.replay_result_copy(%{outcome: :future_outcome}) ==
               "Replay run recorded. Mailbox outcome is unavailable."
    end
  end

  describe "selected timeline snapshot (D-12 / D-18)" do
    test "labels the lineage snapshot time and exposes an explicit native refresh", %{conn: conn} do
      conn = operator_conn(conn)
      %{record: record} = InboundFixtures.seed_matched!(@tenant_id)

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ ~s(data-testid="inbound-timeline-snapshot")
      assert html =~ "Updated"

      refresh =
        Floki.find(Floki.parse_document!(html), "[data-testid='inbound-timeline-refresh']")
        |> hd()

      assert Floki.attribute(refresh, "phx-click") == ["refresh_inbound_timeline"]
      assert Floki.attribute(refresh, "phx-disable-with") == ["Refreshing history…"]
      assert Floki.attribute(refresh, "phx-disable-with") == ["Refreshing history…"]

      assert Floki.find(Floki.parse_document!(html), "[data-testid='inbound-timeline-snapshot']") !=
               []

      assert html =~ "Refresh history"
    end

    test "a failed manual refresh keeps the replay toast and identifies history as unavailable",
         %{conn: conn} do
      conn = operator_conn(conn)
      %{record: record} = InboundFixtures.seed_matched!(@tenant_id)

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      render_click(view, "open_replay", %{})
      render_click(view, "confirm_replay", %{})

      assert_push_event(view, "mailglass:toast", %{
        message: "Replay run recorded. Mailbox outcome: Accepted.",
        error: false
      })

      previous_repo = Application.fetch_env!(:mailglass_inbound, :repo)
      Application.put_env(:mailglass_inbound, :repo, MailglassAdmin.InboundTimelineFailingRepo)

      on_exit(fn -> Application.put_env(:mailglass_inbound, :repo, previous_repo) end)

      html = render_click(view, "refresh_inbound_timeline", %{})

      assert html =~ ~s(data-testid="inbound-timeline-unavailable")
      assert html =~ "Last updated"
      refute html =~ "No execution runs have been recorded for this InboundMessage yet."
      assert html =~ record.id
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
        {:inbound_record_inserted, fresh.id,
         %{provider: "mailgun", record_type: "inbound_record"}}
      )

      html = render(view)

      # The new record appears in the list (rendered behind the Quick view overlay).
      assert html =~ fresh.id
      # The current selection is preserved (the Quick view for it stays open).
      assert html =~ ~s(data-testid="inbound-quick-view")
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
    test "records present: both inbound-records-table and inbound-records-cards testids appear",
         %{
           conn: conn
         } do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!(@tenant_id, recipient: "table@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-records-table")
      assert html =~ ~s(data-testid="inbound-records-cards")
    end

    test "desktop table uses semantic th scope=col elements in order Outcome Mailbox Account Provider Received" do
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

      # Column order within the table header: Outcome first, then Mailbox, Account, Provider, Received
      thead_html =
        html |> String.split("<thead>") |> List.last() |> String.split("</thead>") |> List.first()

      outcome_pos =
        String.length(thead_html) -
          (thead_html |> String.split("Outcome") |> List.last() |> String.length())

      mailbox_pos =
        String.length(thead_html) -
          (thead_html |> String.split("Mailbox") |> List.last() |> String.length())

      account_pos =
        String.length(thead_html) -
          (thead_html |> String.split("Account") |> List.last() |> String.length())

      provider_pos =
        String.length(thead_html) -
          (thead_html |> String.split("Provider") |> List.last() |> String.length())

      received_pos =
        String.length(thead_html) -
          (thead_html |> String.split("Received") |> List.last() |> String.length())

      assert outcome_pos < mailbox_pos
      assert mailbox_pos < account_pos
      assert account_pos < provider_pos
      assert provider_pos < received_pos
    end

    test "table and card selections use native controls with an accessible current state", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "selectme@example.com")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      view
      |> element("button[data-testid='inbound-record-open'][phx-value-id='#{record.id}']")
      |> render_click()

      html = render(view)
      document = Floki.parse_document!(html)

      row =
        Floki.find(
          document,
          "[data-testid='inbound-records-table'] tr[data-testid='inbound-record-row']"
        )
        |> hd()

      assert html =~ ~s(phx-click="select_inbound")
      assert html =~ ~s(phx-value-id="#{record.id}")
      assert Floki.find(row, "button[data-testid='inbound-record-open']") != []
      refute Floki.attribute(row, "phx-click") != []
      assert html |> String.split(~s(aria-current="true")) |> length() >= 2
      refute html =~ ~s(aria-selected="true")
    end

    test "inbound-record-row testid remains reachable and outcome badges carry inbound-outcome- testids",
         %{conn: conn} do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!(@tenant_id, recipient: "badge@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-record-row")
      assert html =~ "inbound-outcome-"
    end

    test "envelope recipient is readable in both table and card presentations", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      InboundFixtures.seed_matched!(@tenant_id, recipient: "maskinboth@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      recipient = "maskinboth@example.com"
      assert html =~ recipient
      assert html |> String.split(recipient) |> length() >= 3
      refute html =~ "m*********@e******.com"
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
      assert html =~ "1 message"
    end
  end

  describe "four distinct data-state branches on inbound surface (DATA-03, Task 2)" do
    test "no-data render emits data-state-empty and existing copy distinctions survive", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      # truly_empty path: data-state-empty with "No messages"-family heading
      assert html =~ ~s(data-testid="data-state-empty")
      assert html =~ "No messages"
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
      assert html =~ "Showing earlier results; refresh failed"
      assert html =~ "Mailglass couldn&#39;t re-read these results. Retry to check for updates."
      refute html =~ ~s(data-testid="inbound-stale-loaded-at")
      refute html =~ "14:32"
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
    test "only actionable inbound summary counts render with explanations", %{conn: conn} do
      conn = operator_conn(conn)

      InboundFixtures.seed_matched!(@tenant_id, recipient: "kpi@example.com")
      InboundFixtures.seed_no_match!(@tenant_id, recipient: "nomatch@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-overview-accepted")
      assert html =~ ~s(data-testid="inbound-overview-no-match")
      assert html =~ ~s(data-testid="inbound-overview-failed")
      assert html =~ "Messages whose latest fresh run was accepted by a mailbox."
      assert html =~ "No mailbox routing rule matched these messages."
      assert html =~ "Mailbox processing ended in failure."
      refute html =~ ~s(data-testid="inbound-overview-total")
      refute html =~ "No-match rate"

      assert Floki.find(Floki.parse_document!(html), "[data-testid='inbound-overview-no-change']") ==
               []
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
      assert html =~ "9 messages"
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

      assert html =~ "1 message"
      refute html =~ ~s(data-testid="inbound-pagination")
    end
  end

  describe "brand-voice + PII sweep (IADM-06, V10/V5)" do
    test "empty + no-selection states carry verbatim copy and no banned words (V10)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      # Genuine no-data: the calm pane carries the truly-empty copy (D-07 noun).
      {:ok, _view, empty_html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert empty_html =~ "No messages"
      assert empty_html =~ "No messages have been received yet."
      refute_banned(empty_html)

      # No-selection now shows the full-width list with no overlay; brand voice clean.
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")
      {:ok, _view, populated_html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert populated_html =~ "Received messages"
      refute populated_html =~ ~s(data-testid="inbound-quick-view")
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
               "This inbound message could not be loaded in the selected Account. Check the record ID and try again."

      refute_banned(html)
    end

    test "no-execution-runs copy renders for a record with no runs (V10)", %{conn: conn} do
      conn = operator_conn(conn)

      # A record with evidence but no execution runs at all.
      record = InboundFixtures.insert_record!(@tenant_id, recipient: "norun@example.com")
      _evidence = InboundFixtures.insert_evidence!(@tenant_id, record.id)

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ "No execution runs have been recorded for this message yet."
      refute_banned(html)
    end

    test "replay success, mailbox-missing block, and not-authorized block carry verbatim copy (V10)",
         %{conn: conn} do
      # Success.
      conn1 = operator_conn(conn)
      %{record: matched} = InboundFixtures.seed_matched!(@tenant_id, recipient: "ok@example.com")

      {:ok, view1, _html} =
        live(
          conn1,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => matched.id, "full" => "1"})
        )

      render_click(view1, "open_replay", %{})
      success_html = render_click(view1, "confirm_replay", %{})

      assert_push_event(view1, "mailglass:toast", %{
        message: "Replay run recorded. Mailbox outcome: Accepted.",
        error: false
      })

      refute_banned(success_html)

      # Mailbox-missing (:no_match).
      conn2 = operator_conn(conn)
      %{record: nomatch} = InboundFixtures.seed_no_match!(@tenant_id, recipient: "nm@example.com")

      {:ok, view2, _html} =
        live(
          conn2,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => nomatch.id, "full" => "1"})
        )

      render_click(view2, "open_replay", %{})
      block_html = render_click(view2, "confirm_replay", %{})

      assert block_html =~
               "Replay unavailable: no mailbox matched this message when it was received, so there is no route to replay it through."

      refute_banned(block_html)

      # Not authorized (denied capability).
      conn3 = operator_conn(conn, %{"current_user_id" => "deny-replay"})
      %{record: denied} = InboundFixtures.seed_matched!(@tenant_id, recipient: "no@example.com")

      {:ok, view3, _html} =
        live(
          conn3,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => denied.id, "full" => "1"})
        )

      render_click(view3, "open_replay", %{})
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
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ "May contain personal information."
      refute html =~ "Raw source is hidden by default"

      denied_html = render_click(view, "reveal_raw", %{})

      assert denied_html =~ "t have permission to reveal raw source."

      assert denied_html
             |> Floki.parse_document!()
             |> Floki.find("[data-testid='inbound-evidence-denied'][role='status']")
             |> Enum.count() == 1

      refute denied_html =~ "SECRET-BYTES"
      refute_banned(denied_html)
    end

    test "routing-trace heading + sub-label + legend carry verbatim copy (V10)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_no_match!(@tenant_id, recipient: "trace@example.com")

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ "Current router simulation"
      assert html =~ "How current route rules compare"

      assert html =~
               "A route matches only when every condition passes. “Any” means that field is unrestricted."

      refute_banned(html)
    end

    test "recipient is readable in list and detail while routing evidence stays masked", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      raw = "fulltrace@example.com"
      masked = "f********@e******.com"

      %{record: record} = InboundFixtures.seed_no_match!(@tenant_id, recipient: raw)

      # List surface.
      {:ok, _view, list_html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))
      assert list_html =~ raw
      refute list_html =~ masked

      # Detail + routing-trace surfaces (selected).
      {:ok, _view2, detail_html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      # Masked in the detail header AND the routing-trace recipient "actual".
      assert detail_html =~ raw

      [trace] =
        Floki.find(Floki.parse_document!(detail_html), "[data-testid='inbound-routing-trace']")

      assert Floki.text(trace) =~ masked
      refute Floki.text(trace) =~ raw
      assert detail_html =~ ~s(data-testid="inbound-routing-trace")
    end

    @tag :phase176
    test "Phase 176 Inbound detail shows From, To and Delivered to", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "support@example.com",
          from: [%{address: "ada@example.com", name: "Ada Lovelace"}],
          to: [%{address: "team@example.com"}]
        )

      {:ok, _view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      doc = Floki.parse_document!(html)
      text = fn testid -> doc |> Floki.find("[data-testid='#{testid}']") |> Floki.text() end

      from = text.("inbound-contact-from")
      assert from =~ "Ada Lovelace"
      assert from =~ "ada@example.com"
      refute html =~ "a**@e******.com"

      to = text.("inbound-contact-to")
      assert to =~ "team@example.com"
      refute to =~ "support@example.com"

      delivered = text.("inbound-contact-delivered-to")
      assert delivered =~ "support@example.com"
      assert delivered =~ "SMTP envelope recipient (RCPT TO), used for routing."
      refute delivered =~ "team@example.com"

      labels = doc |> Floki.find("dt") |> Enum.map(&(&1 |> Floki.text() |> String.trim()))

      assert Enum.take(Enum.filter(labels, &(&1 in ["From", "To", "Delivered to"])), 3) ==
               ["From", "To", "Delivered to"]
    end

    @tag :phase176
    test "Phase 176 Inbound Quick view labels the envelope recipient 'Delivered to'", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "support@example.com",
          to: [%{address: "team@example.com"}],
          cc: [%{address: "cc@example.com"}]
        )

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      [quick] =
        html |> Floki.parse_document!() |> Floki.find("[data-testid='inbound-quick-view']")

      text = quick |> Floki.text() |> String.replace(~r/\s+/, " ")
      assert text =~ "Delivered to support@example.com"
      refute text =~ "team@example.com"
      refute text =~ "cc@example.com"
      refute text =~ "Recipient not recorded"
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
        live(
          conn1,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      refute redacted_html =~ secret

      # Granted: bytes present in the read-only pre region.
      conn2 = operator_conn(conn)

      {:ok, view2, _html} =
        live(
          conn2,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

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
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      # Grant first so we have something to collapse.
      revealed_html = render_click(view, "reveal_raw", %{})
      assert revealed_html =~ ~s(data-testid="inbound-evidence-raw")
      assert revealed_html =~ secret

      # Re-redact collapses back: raw bytes absent, caption + toggle present.
      redacted_html = render_click(view, "re_redact_raw", %{})
      refute redacted_html =~ ~s(data-testid="inbound-evidence-raw")
      refute redacted_html =~ secret

      assert redacted_html =~ ~s(data-testid="inbound-evidence-caption")
      refute redacted_html =~ "Raw source is hidden by default"
    end

    @tag :phase176
    test "one persistent toggle keeps its id across collapse -> reveal -> collapse", %{
      conn: conn
    } do
      secret = "PT-SECRET-#{System.unique_integer([:positive])}"
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "pt@example.com",
          evidence: [raw_payload: %{"body" => secret}]
        )

      {:ok, view, html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      toggle = fn html ->
        assert [btn] =
                 html
                 |> Floki.parse_document!()
                 |> Floki.find("#inbound-evidence-reveal-btn")

        {Floki.text(btn) |> String.trim(), Floki.attribute(btn, "aria-expanded"),
         Floki.attribute(btn, "phx-click")}
      end

      assert toggle.(html) == {"Reveal raw source", ["false"], ["reveal_raw"]}
      refute html =~ secret

      revealed_html = view |> element("#inbound-evidence-reveal-btn") |> render_click()
      assert toggle.(revealed_html) == {"Hide raw source", ["true"], ["re_redact_raw"]}

      assert [pre] =
               revealed_html |> Floki.parse_document!() |> Floki.find("pre#inbound-evidence-raw")

      assert Floki.attribute(pre, "tabindex") == ["0"]
      assert revealed_html =~ secret

      collapsed_html = view |> element("#inbound-evidence-reveal-btn") |> render_click()
      assert toggle.(collapsed_html) == {"Reveal raw source", ["false"], ["reveal_raw"]}
      refute collapsed_html =~ secret
      refute collapsed_html =~ ~s(id="inbound-evidence-raw")
    end

    @tag :phase176
    test "denied reveal on the live route renders status copy and no raw sentinel bytes", %{
      conn: conn
    } do
      conn = operator_conn(conn, %{"current_user_id" => "deny-reveal"})

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "pd@example.com",
          evidence: [raw_payload: %{"body" => "SENTINEL-176-03-RAW"}]
        )

      {:ok, view, _html} =
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      html = view |> element("#inbound-evidence-reveal-btn") |> render_click()

      assert html =~ "have permission to reveal raw source."
      refute html =~ "SENTINEL-176-03-RAW"
      refute html =~ ~s(id="inbound-evidence-raw")
    end

    @tag :phase176
    test "reveal telemetry metadata keys are exactly outcome, record_id, tenant_id", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "tk@example.com",
          evidence: [raw_payload: %{"body" => "KEYS-BYTES"}]
        )

      {:ok, view, _html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

      meta = attach_and_reveal(view)

      assert meta |> Map.keys() |> Enum.sort() == [:outcome, :record_id, :tenant_id]
    end

    test "reveal emits a PII-free [:reveal_raw, :stop] with outcome=:granted (D-12)", %{
      conn: conn
    } do
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
          1_000 ->
            flunk("expected [:mailglass_admin, :inbound, :reveal_raw, :stop] telemetry event")
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
    test "theme cookie themes the inbound ROOT <html>, not just the shell", %{conn: conn} do
      conn =
        conn
        |> operator_conn()
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s|<html lang="en" data-theme="mailglass-dark">|
    end

    test "legacy theme query redirects through persistence", %{conn: conn} do
      conn = operator_conn(conn)

      assert {:error,
              {:redirect,
               %{
                 to:
                   "/ops/mail/theme/dark?return_to=%2Fops%2Fmail%2Finbound%3Ftenant_id%3Dtest-tenant"
               }}} = live(conn, inbound_path(%{"tenant_id" => @tenant_id, "theme" => "dark"}))
    end

    test "no theme param leaves the inbound root <html> un-themed", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      refute html =~ ~s|<html lang="en" data-theme="mailglass-dark">|
    end
  end

  describe "Phase 176 Inbound direct filters" do
    @describetag :phase176

    test "Phase 176 Inbound select change commits one sorted canonical push patch", %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(view, "validate_filters", inbound_change("outcome", %{"outcome" => "accept"}))
      path = assert_patch_kind(view, :push)

      assert path ==
               inbound_path(%{
                 "tenant_id" => @tenant_id,
                 "outcome" => "accept",
                 "window_hours" => "168"
               })

      assert path == @base_path <> "?outcome=accept&tenant_id=#{@tenant_id}&window_hours=168"
      assert selected_filter_value(render(view), "#filters_outcome") == "accept"
    end

    test "Phase 176 Inbound the same payload twice yields exactly one patch", %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))
      payload = inbound_change("outcome", %{"outcome" => "accept"})

      render_hook(view, "validate_filters", payload)
      assert_patch_kind(view, :push)

      render_hook(view, "validate_filters", payload)
      refute_patch(view)
    end

    test "Phase 176 Inbound a select equal to the committed value is a no-op", %{conn: conn} do
      {:ok, view, _html} =
        live(
          operator_conn(conn),
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "outcome" => "accept",
            "window_hours" => "168"
          })
        )

      render_hook(view, "validate_filters", inbound_change("outcome", %{"outcome" => "accept"}))
      refute_patch(view)
    end

    test "Phase 176 Inbound an unchanged commit from a bare entry URL is a no-op, a changing one pushes",
         %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(view, "validate_filters", inbound_change("outcome", %{"outcome" => ""}))
      refute_patch(view)

      render_hook(view, "validate_filters", inbound_change("outcome", %{"outcome" => "accept"}))
      path = assert_patch_kind(view, :push)

      assert %{"outcome" => "accept", "window_hours" => "168", "tenant_id" => @tenant_id} =
               path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
    end

    test "Phase 176 Inbound a foreign tenant_id never changes the Account on change, submit or recover",
         %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(
        view,
        "validate_filters",
        inbound_change("outcome", %{"outcome" => "accept", "tenant_id" => "foreign-tenant"})
      )

      change_path = assert_patch_kind(view, :push)
      refute change_path =~ "foreign-tenant"
      assert change_path =~ "tenant_id=#{@tenant_id}"

      render_hook(view, "apply_filters", %{
        "filters" => %{
          "tenant_id" => "foreign-tenant",
          "outcome" => "bounce",
          "search" => "foo ",
          "window_hours" => "168",
          "provider" => ""
        }
      })

      submit_path = assert_patch_kind(view, :push)
      refute submit_path =~ "foreign-tenant"
      submit_query = submit_path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
      assert submit_query["tenant_id"] == @tenant_id
      assert submit_query["search"] == "foo"

      render_hook(view, "recover_filters", %{
        "filters" => %{
          "tenant_id" => "foreign-tenant",
          "outcome" => "reject",
          "search" => "",
          "window_hours" => "168",
          "provider" => ""
        }
      })

      recover_path = assert_patch_kind(view, :replace)
      refute recover_path =~ "foreign-tenant"
      assert recover_path =~ "tenant_id=#{@tenant_id}"
    end

    test "Phase 176 Inbound a commit drops inbound_id, full and page", %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(
        view,
        "validate_filters",
        inbound_change("outcome", %{
          "outcome" => "accept",
          "inbound_id" => "abc",
          "full" => "1",
          "page" => "3"
        })
      )

      path = assert_patch_kind(view, :push)
      query = path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
      refute Map.has_key?(query, "inbound_id")
      refute Map.has_key?(query, "full")
      refute Map.has_key?(query, "page")
    end

    test "Phase 176 Inbound Account canonicalization replaces history", %{conn: conn} do
      InboundFixtures.seed_matched!("solo-inbound", recipient: "solo@example.com")

      {:ok, view, _html} = live(operator_conn(conn), @base_path)
      render(view)

      path = assert_patch_kind(view, :replace)
      assert path == inbound_path(%{"tenant_id" => "solo-inbound"})
    end

    test "Phase 176 Inbound recover restores a valid differing draft with replace, keeps an invalid one",
         %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(view, "recover_filters", %{
        "filters" => %{
          "outcome" => "accept",
          "search" => "",
          "provider" => "",
          "window_hours" => "168"
        }
      })

      path = assert_patch_kind(view, :replace)
      assert path =~ "outcome=accept"

      html =
        render_hook(view, "recover_filters", %{
          "filters" => %{
            "outcome" => "not-real",
            "search" => "",
            "provider" => "",
            "window_hours" => "168"
          }
        })

      refute_patch(view)
      assert html =~ "Mailbox outcome was not applied. Choose a listed outcome."
    end

    test "Phase 176 Inbound Clear with nothing applied produces no patch and stays enabled", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      assert has_element?(view, "#inbound-filters button[phx-click='clear_filters']")
      refute has_element?(view, "#inbound-filters button[phx-click='clear_filters'][disabled]")

      view |> element("#inbound-filters button[phx-click='clear_filters']") |> render_click()
      refute_patch(view)
    end

    test "Phase 176 Inbound the filter form has no Apply, submit, loading or tenant control", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      form_html = view |> element("#inbound-filters") |> render()
      document = Floki.parse_fragment!(form_html)

      assert Floki.find(document, "[type='submit']") == []
      assert Floki.find(document, "[phx-disable-with]") == []
      assert Floki.find(document, "#filters_tenant_id") == []
      refute form_html =~ "Apply filters"
      assert Floki.attribute(document, "form", "phx-auto-recover") == ["recover_filters"]
    end

    test "Phase 176 Inbound Back via render_patch restores the earlier committed filters", %{
      conn: conn
    } do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(view, "validate_filters", inbound_change("outcome", %{"outcome" => "accept"}))
      assert_patch_kind(view, :push)

      render_patch(view, inbound_path(%{"tenant_id" => @tenant_id}))

      html = render(view)
      assert selected_filter_value(html, "#filters_outcome") in [nil, ""]
    end

    test "Phase 176 Inbound trailing whitespace canonicalizes to the same search URL", %{
      conn: conn
    } do
      {:ok, view, _html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "search" => "foo", "window_hours" => "168"})
        )

      render_hook(view, "validate_filters", inbound_change("search", %{"search" => "foo "}))
      refute_patch(view)
    end

    test "Phase 176 Inbound pagination links preserve the committed filters", %{conn: conn} do
      for index <- 1..21 do
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "paged-#{index}@example.com",
          provider_message_id: "p176-page-#{index}"
        )
      end

      InboundFixtures.seed_no_match!(@tenant_id, recipient: "unrouted@example.com")

      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(view, "validate_filters", inbound_change("outcome", %{"outcome" => "accept"}))
      committed = assert_patch_kind(view, :push)
      render_patch(view, committed)

      next_href =
        view
        |> render()
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-pagination-next']")
        |> Floki.attribute("href")
        |> List.first()

      assert next_href
      query = next_href |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
      assert query["outcome"] == "accept"
      assert query["tenant_id"] == @tenant_id
      assert query["page"] == "2"
      refute Map.has_key?(query, "inbound_id")
      refute Map.has_key?(query, "full")

      render_patch(view, next_href)
      html = render(view)
      assert selected_filter_value(html, "#filters_outcome") == "accept"
      assert html =~ "21 messages"
    end

    test "Phase 176 Inbound a select commit from page 2 patches to a path without page and renders page 1",
         %{conn: conn} do
      for index <- 1..21 do
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "reset-#{index}@example.com",
          provider_message_id: "p176-reset-#{index}"
        )
      end

      {:ok, view, _html} =
        live(
          operator_conn(conn),
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "outcome" => "accept",
            "window_hours" => "168",
            "page" => "2"
          })
        )

      render_hook(
        view,
        "validate_filters",
        inbound_change("window_hours", %{
          "outcome" => "accept",
          "window_hours" => "720"
        })
      )

      path = assert_patch_kind(view, :push)
      query = path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
      refute Map.has_key?(query, "page")
      assert query["window_hours"] == "720"

      render_patch(view, path)
      html = render(view)
      refute html =~ ~s(data-testid="inbound-pagination-prev-link")
      assert html =~ "21 messages"
    end

    test "Phase 176 Inbound a no-op does not leak a pending kind into the next non-commit patch",
         %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))
      earlier = inbound_path(%{"tenant_id" => @tenant_id})

      render_hook(view, "validate_filters", inbound_change("search", %{"search" => "abc"}))
      assert_patch_kind(view, :push)

      render_hook(view, "validate_filters", inbound_change("search", %{"search" => "abc"}))
      refute_patch(view)

      render_patch(view, earlier)

      render_hook(view, "validate_filters", inbound_change("search", %{"search" => "xyz"}))
      assert_patch_kind(view, :push)
    end

    test "Phase 176 Inbound the change handler does not reload provider options", %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      # An invalid outcome is a draft only; it must neither patch nor disturb the provider
      # select, which only handle_params may rebuild (D-04).
      html =
        render_hook(
          view,
          "validate_filters",
          inbound_change("outcome", %{"outcome" => "not-real"})
        )

      refute_patch(view)
      assert html =~ "Mailbox outcome was not applied."
      assert html =~ ~s(id="filters_provider")
    end
  end

  describe "Phase 176 Inbound draft retention" do
    @describetag :phase176

    test "Phase 176 Inbound invalid URL values stay in the draft next to their errors", %{
      conn: conn
    } do
      %{record: matching} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "match@example.com")

      %{record: foreign} =
        InboundFixtures.seed_matched!(@other_tenant, recipient: "foreign@example.com")

      {:ok, _view, html} =
        live(
          operator_conn(conn),
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

      assert selected_filter_value(html, "#filters_window_hours") == "bogus"
      assert html =~ "Custom period (bogus hours)"

      assert html
             |> Floki.parse_document!()
             |> Floki.find("#filters_outcome option[value='not-real']") == []
    end

    test "Phase 176 Inbound an invalid form window stays in the draft without a patch", %{
      conn: conn
    } do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      html =
        render_hook(
          view,
          "validate_filters",
          inbound_change("window_hours", %{"window_hours" => "-5", "outcome" => "accept"})
        )

      refute_patch(view)
      assert html =~ "Time window was not applied. Choose a positive listed time window."
      assert selected_filter_value(html, "#filters_window_hours") == "-5"
      assert html =~ "Custom period (-5 hours)"
    end

    test "Phase 176 Inbound a blank window normalizes quietly without a Custom period option", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")

      {:ok, _view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "window_hours" => ""})
        )

      refute html =~ "Custom period"

      assert selected_filter_value(html, "#filters_window_hours") == "168"
    end

    test "Phase 176 Inbound a listed window never adds a Custom period option", %{conn: conn} do
      {:ok, _view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "window_hours" => "720"})
        )

      refute html =~ "Custom period"
      assert selected_filter_value(html, "#filters_window_hours") == "720"
    end
  end

  describe "Phase 176 Inbound search and toggle" do
    @describetag :phase176

    test "Phase 176 Inbound Search is debounced and carries the search-field attributes only on Search",
         %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      form = view |> render() |> Floki.parse_document!() |> Floki.find("#inbound-filters")
      [search] = Floki.find(form, "#filters_search")

      assert Floki.attribute(search, "phx-debounce") == ["300"]
      assert Floki.attribute(search, "phx-hook") == ["FilterSearchSync"]
      assert Floki.attribute(search, "autocomplete") == ["off"]
      assert Floki.attribute(search, "enterkeyhint") == ["search"]
      assert Floki.attribute(search, "data-committed") == [""]
      assert Floki.attribute(search, "disabled") == []
      assert Floki.attribute(search, "readonly") == []

      for select <- Floki.find(form, "select") do
        assert Floki.attribute(select, "phx-debounce") == []
      end
    end

    test "Phase 176 Inbound the filter form has exactly one implicit-submission text field", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      form = view |> render() |> Floki.parse_document!() |> Floki.find("#inbound-filters")

      text_like =
        ~w(text search email url tel password number date datetime-local month time week)

      text_inputs =
        form
        |> Floki.find("input")
        |> Enum.filter(fn input ->
          case Floki.attribute(input, "type") do
            [] -> true
            [type] -> type in text_like
          end
        end)

      assert length(text_inputs) == 1
      assert Floki.find(form, "button[type='submit'], input[type='submit']") == []
    end

    test "Phase 176 Inbound data-committed follows the committed search while a draft differs", %{
      conn: conn
    } do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(view, "apply_filters", %{
        "filters" => %{
          "search" => "foo",
          "outcome" => "",
          "provider" => "",
          "window_hours" => "168"
        }
      })

      assert_patch_kind(view, :push)
      assert inbound_search_attr(view, "data-committed") == ["foo"]

      render_hook(
        view,
        "validate_filters",
        inbound_change("outcome", %{"search" => "foobar draft", "outcome" => "not-real"})
      )

      refute_patch(view)
      assert inbound_search_attr(view, "data-committed") == ["foo"]
    end

    test "Phase 176 Inbound search history: first commit pushes, next replaces, settled Enter is a no-op",
         %{conn: conn} do
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      render_hook(view, "validate_filters", inbound_change("search", %{"search" => "ab"}))
      assert_patch_kind(view, :push)
      render_hook(view, "validate_filters", inbound_change("search", %{"search" => "abc"}))
      second = assert_patch_kind(view, :replace)
      assert second =~ "search=abc"
      # Enter after a settled commit with an unchanged value does nothing.
      render_hook(view, "apply_filters", %{
        "filters" => %{
          "search" => "abc",
          "outcome" => "",
          "provider" => "",
          "window_hours" => "168"
        }
      })

      refute_patch(view)
    end

    test "Phase 176 Inbound mobile Filters toggle is labelled, controls the panel and starts collapsed",
         %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      toggle =
        view
        |> render()
        |> Floki.parse_document!()
        |> Floki.find("[data-testid='inbound-filters-toggle']")

      assert Floki.attribute(toggle, "aria-controls") == ["inbound-filter-panel"]
      assert Floki.attribute(toggle, "aria-expanded") == ["false"]
      assert inbound_toggle_label(view) == "Filters"
      assert has_element?(view, "#inbound-filter-panel")
    end

    test "Phase 176 Inbound mobile Filters toggle counts committed filters only", %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "present@example.com")

      {:ok, view, _html} =
        live(
          operator_conn(conn),
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "outcome" => "accept",
            "search" => "match",
            "window_hours" => "720"
          })
        )

      assert inbound_toggle_label(view) == "Filters (3 applied)"

      {:ok, default_view, _html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "window_hours" => "168"})
        )

      assert inbound_toggle_label(default_view) == "Filters"

      # An invalid draft is not committed, so the label does not move.
      render_hook(
        default_view,
        "validate_filters",
        inbound_change("outcome", %{"outcome" => "not-real"})
      )

      refute_patch(default_view)
      assert inbound_toggle_label(default_view) == "Filters"

      render_hook(
        default_view,
        "validate_filters",
        inbound_change("outcome", %{"outcome" => "accept"})
      )

      assert_patch_kind(default_view, :push)
    end
  end

  describe "Phase 176 Inbound read states" do
    @describetag :phase176

    test "Phase 176 Inbound new-query read failure shows a truthful error, no count and no empty copy",
         %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "readable-new@example.com")
      {:ok, view, html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))
      assert html =~ "readable-new@example.com"

      swap_inbound_repo(MailglassAdmin.InboundUnavailableRepo)

      render_hook(view, "validate_filters", inbound_change("outcome", %{"outcome" => "accept"}))
      path = assert_patch_kind(view, :push)
      assert path =~ "outcome=accept"

      html = render(view)
      assert has_element?(view, "[data-testid='inbound-read-unavailable']")
      assert html =~ "Couldn&#39;t load inbound messages for these filters"
      assert html =~ "The read failed. Your filters are unchanged. Retry, or change a filter."
      assert has_element?(view, "[data-testid='inbound-retry-messages']", "Retry messages")
      refute has_element?(view, "[data-testid='inbound-result-count']")
      refute has_element?(view, "[data-testid='inbound-record-row']")
      refute has_element?(view, "[data-testid='inbound-stale-results']")
      refute html =~ "No messages have been received yet."
      refute html =~ "No messages match the current filters."
      refute html =~ "readable-new@example.com"
      refute html =~ "synthetic inbound connection failure"
      assert selected_filter_value(html, "#filters_outcome") == "accept"
      assert status_text(view) == "Couldn't load inbound messages"
    end

    test "Phase 176 Inbound Retry adds no history and re-reads the committed filters", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "retry-me@example.com")
      {:ok, view, _html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      previous_repo = swap_inbound_repo(MailglassAdmin.InboundUnavailableRepo)

      render_hook(
        view,
        "validate_filters",
        inbound_change("window_hours", %{"window_hours" => "720"})
      )

      assert_patch_kind(view, :push)
      assert has_element?(view, "[data-testid='inbound-read-unavailable']")

      Application.put_env(:mailglass_inbound, :repo, previous_repo)
      view |> element("[data-testid='inbound-retry-messages']") |> render_click()

      refute_patch(view)
      html = render(view)
      refute has_element?(view, "[data-testid='inbound-read-unavailable']")
      assert html =~ "retry-me@example.com"
      assert has_element?(view, "[data-testid='inbound-result-count']")
      assert selected_filter_value(html, "#filters_window_hours") == "720"
    end

    test "Phase 176 a same-query failed read keeps rows under the stale panel with the load time",
         %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "stale-one@example.com")
      InboundFixtures.seed_matched!(@tenant_id, recipient: "stale-two@example.com")
      {:ok, view, html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))
      assert html =~ "stale-one@example.com"
      assert status_text(view) == "2 messages match"

      swap_inbound_repo(MailglassAdmin.InboundUnavailableRepo)
      view |> render_hook("retry_inbound", %{})
      refute_patch(view)

      html = render(view)
      assert has_element?(view, "[data-testid='inbound-stale-results']")
      assert html =~ "Showing results from "
      assert html =~ " UTC; refresh failed"
      assert html =~ "Mailglass couldn&#39;t re-read these results. Retry to check for updates."
      assert has_element?(view, "[data-testid='inbound-stale-loaded-at']", "Results loaded")
      assert has_element?(view, "[data-testid='inbound-retry-messages']", "Retry messages")
      assert html =~ "stale-one@example.com"
      assert html =~ "stale-two@example.com"

      assert length(
               Floki.find(
                 Floki.parse_document!(html),
                 "[data-testid='inbound-records-table'] [data-testid='inbound-record-row']"
               )
             ) ==
               2

      refute has_element?(view, "[data-testid='inbound-result-count']")
      refute has_element?(view, "[data-testid='inbound-read-unavailable']")
      assert status_text(view) =~ ~r/^Showing results from \d\d:\d\d UTC; refresh failed$/

      # The stale panel sits above the retained rows, not instead of them.
      assert_in_order(html, [
        ~s(data-testid="inbound-stale-results"),
        ~s(data-testid="inbound-records-table")
      ])
    end

    test "Phase 176 RecordsList renders retained rows beneath the stale panel" do
      html =
        render_component(&RecordsList.records_list/1,
          records: [
            %{
              id: "00000000-0000-0000-0000-000000000176",
              tenant_id: @tenant_id,
              provider: "mailgun",
              envelope_recipient: "kept@example.com",
              received_at: nil,
              outcome: :accept,
              mailbox: "MyApp.Mailboxes.SupportMailbox"
            }
          ],
          selected_record: nil,
          empty_state: :filtered,
          data_state: :stale,
          loaded_at: ~U[2026-10-28 14:32:00Z],
          page_meta: %{
            total_count: 1,
            page: 1,
            per_page: 10,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      assert html =~ ~s(data-testid="inbound-stale-results")
      assert html =~ "Showing results from 14:32 UTC; refresh failed"
      assert html =~ ~s(data-testid="inbound-stale-loaded-at")
      assert html =~ ~s(phx-click="retry_inbound")
      assert html =~ "kept@example.com"
      assert html =~ ~s(data-testid="inbound-record-row")
      refute html =~ ~s(data-testid="inbound-result-count")
    end

    test "Phase 176 Inbound status region exists at first render and ignores invalid drafts", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "status-one@example.com")
      InboundFixtures.seed_matched!(@tenant_id, recipient: "status-two@example.com")
      {:ok, view, html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      region = html |> Floki.parse_document!() |> Floki.find("#inbound-results-status")
      assert [_] = region
      assert Floki.attribute(region, "role") == ["status"]
      assert Floki.attribute(region, "aria-live") == ["polite"]
      assert Floki.attribute(region, "aria-atomic") == ["true"]
      assert Floki.attribute(region, "class") |> List.first() =~ "sr-only"
      assert status_text(view) == "2 messages match"

      render_hook(
        view,
        "validate_filters",
        inbound_change("window_hours", %{"window_hours" => "-5"})
      )

      refute_patch(view)
      assert status_text(view) == "2 messages match"

      render_hook(view, "validate_filters", inbound_change("outcome", %{"outcome" => "bounce"}))
      assert_patch_kind(view, :push)
      assert status_text(view) == "No messages match the current filters"
    end

    test "Phase 176 Inbound an invalid draft stays a draft with a pending note outside the filter panel",
         %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "draft-rows@example.com")
      {:ok, view, html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))
      assert html =~ "draft-rows@example.com"
      refute has_element?(view, "[data-testid='filters-draft-pending-note']")

      html =
        render_hook(
          view,
          "validate_filters",
          inbound_change("window_hours", %{"window_hours" => "-5"})
        )

      refute_patch(view)

      assert has_element?(
               view,
               "[data-testid='filters-draft-pending-note']",
               "Showing results for your previous filters until the highlighted field is fixed."
             )

      refute has_element?(
               view,
               "#inbound-filter-panel [data-testid='filters-draft-pending-note']"
             )

      refute has_element?(view, "[data-testid='filters-url-invalid-note']")
      assert html =~ "Time window was not applied. Choose a positive listed time window."
      assert html =~ "draft-rows@example.com"

      document = Floki.parse_document!(html)
      select = Floki.find(document, "#filters_window_hours")
      assert Floki.attribute(select, "aria-invalid") == ["true"]
      assert [describedby] = Floki.attribute(select, "aria-describedby")
      assert "filters_window_hours-error" in String.split(describedby)

      assert Floki.find(document, "#filters_window_hours-error") |> Floki.text() =~
               "Time window was not applied."

      # The note sits inside the filters section but after the collapsible panel.
      assert_in_order(html, [
        ~s(id="inbound-filter-panel"),
        ~s(data-testid="filters-draft-pending-note")
      ])

      # A later valid commit clears it.
      render_hook(
        view,
        "validate_filters",
        inbound_change("window_hours", %{"window_hours" => "720"})
      )

      assert_patch_kind(view, :push)
      refute has_element?(view, "[data-testid='filters-draft-pending-note']")
    end

    test "Phase 176 Inbound an invalid URL value is labelled as excluded, never an unlabelled fallback",
         %{conn: conn} do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "url-rows@example.com")

      {:ok, view, html} =
        live(
          operator_conn(conn),
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "outcome" => "not-real",
            "window_hours" => "bogus"
          })
        )

      assert has_element?(
               view,
               "[data-testid='filters-url-invalid-note']",
               "Showing results without the Mailbox outcome filter."
             )

      assert has_element?(
               view,
               "[data-testid='filters-url-invalid-note']",
               "Showing results for the default time window instead."
             )

      refute has_element?(view, "[data-testid='filters-draft-pending-note']")
      refute has_element?(view, "#inbound-filter-panel [data-testid='filters-url-invalid-note']")
      assert html =~ "Mailbox outcome was not applied. Choose a listed outcome."
      assert html =~ "url-rows@example.com"

      document = Floki.parse_document!(html)
      outcome = Floki.find(document, "#filters_outcome")
      assert Floki.attribute(outcome, "aria-invalid") == ["true"]
      assert [described_by] = Floki.attribute(outcome, "aria-describedby")
      assert "filters_outcome-error" in String.split(described_by)

      render_hook(
        view,
        "validate_filters",
        inbound_change("outcome", %{"outcome" => "accept"})
      )

      assert_patch_kind(view, :push)
      refute has_element?(view, "[data-testid='filters-url-invalid-note']")
    end

    test "Phase 176 Inbound reveal: with both fields stored, Payload size is the byte size of the revealed text",
         %{conn: conn} do
      payload = %{"marker" => "PAYLOAD-LIVE-176-11"}

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "both-stored@example.com",
          evidence: [provider: "ses", raw_payload: payload, raw_mime: "MIME-LIVE-176-11"]
        )

      {:ok, view, _html} =
        live(
          operator_conn(conn),
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      revealed_html = render_click(view, "reveal_raw", %{})
      doc = Floki.parse_document!(revealed_html)

      assert [pre] = Floki.find(doc, "pre#inbound-evidence-raw")
      text = Floki.text(pre)
      assert text =~ "PAYLOAD-LIVE-176-11"
      refute text =~ "MIME-LIVE-176-11"

      size_dd =
        doc
        |> Floki.find("[data-testid='inbound-evidence-facts'] div")
        |> Enum.find(&(&1 |> Floki.find("dt") |> Floki.text() |> String.trim() == "Payload size"))
        |> Floki.find("dd")
        |> Floki.text()
        |> String.trim()

      assert size_dd == "#{byte_size(text)} bytes"
    end
  end

  defp swap_inbound_repo(repo) do
    previous_repo = Application.fetch_env!(:mailglass_inbound, :repo)
    Application.put_env(:mailglass_inbound, :repo, repo)
    on_exit(fn -> Application.put_env(:mailglass_inbound, :repo, previous_repo) end)
    previous_repo
  end

  defp status_text(view) do
    view
    |> render()
    |> Floki.parse_document!()
    |> Floki.find("#inbound-results-status")
    |> Floki.text()
    |> String.trim()
  end

  defp inbound_search_attr(view, name) do
    view
    |> render()
    |> Floki.parse_document!()
    |> Floki.find("#inbound-filters #filters_search")
    |> Floki.attribute(name)
  end

  defp inbound_toggle_label(view) do
    view
    |> render()
    |> Floki.parse_document!()
    |> Floki.find("[data-testid='inbound-filters-toggle']")
    |> Floki.text()
    |> String.split()
    |> Enum.join(" ")
  end

  defp inbound_change(field, overrides) do
    %{
      "_target" => ["filters", field],
      "filters" =>
        Map.merge(
          %{"search" => "", "window_hours" => "168", "outcome" => "", "provider" => ""},
          overrides
        )
    }
  end

  defp assert_patch_kind(view, kind) do
    %{proxy: {ref, topic, _pid}} = view
    assert_receive {^ref, {:patch, ^topic, %{kind: ^kind, to: to}}}
    to
  end

  defp refute_patch(view) do
    %{proxy: {ref, topic, _pid}} = view
    refute_receive {^ref, {:patch, ^topic, _opts}}, 50
  end

  defp selected_filter_value(html, selector) do
    html
    |> Floki.parse_document!()
    |> Floki.find("#{selector} option")
    |> Enum.find_value(fn option ->
      if option |> Floki.attribute("selected") |> Enum.any?() do
        option |> Floki.attribute("value") |> List.first()
      end
    end)
  end

  defp inbound_path(params) do
    case URI.encode_query(params) do
      "" -> @base_path
      query -> @base_path <> "?" <> query
    end
  end

  defp summary_count(doc, outcome) do
    doc
    |> Floki.find("[data-testid='inbound-overview-#{outcome}'] p")
    |> Enum.at(1)
    |> Floki.text()
    |> String.trim()
  end

  defp clear_filters_count(html) do
    html
    |> String.split("Clear filters")
    |> length()
    |> Kernel.-(1)
  end

  defp assert_in_order(html, phrases) do
    offsets =
      Enum.map(phrases, fn phrase ->
        case :binary.match(html, phrase) do
          {offset, _length} -> offset
          :nomatch -> flunk("expected #{inspect(phrase)} to appear in rendered HTML")
        end
      end)

    assert offsets == Enum.sort(offsets),
           "expected phrases to appear in order: #{inspect(phrases)}"
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
        live(
          conn,
          inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id, "full" => "1"})
        )

      assert html =~ ~s(id="inbound-detail-#{record.id}")
    end
  end
end
