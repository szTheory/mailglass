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
  alias MailglassAdmin.TestSupport.InboundFixtures
  alias MailglassInbound.InboundRecords.ExecutionRun

  @tenant_id "test-tenant"
  @other_tenant "other-tenant"
  @base_path "/ops/mail/inbound"
  @banned ["Oops", "Whoops", "Uh oh", "Something went wrong"]

  describe "inbound surface" do
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
      # Orientation strip: present when no detail is selected (GAP-09)
      assert html =~ ~s(data-testid="inbound-orientation")
    end

    test "blank tenant renders the empty state and leaks no other-tenant id or recipient (V1)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      # Seed a record under a DIFFERENT tenant; a blank tenant must not surface it.
      %{record: other} =
        InboundFixtures.seed_matched!(@other_tenant, recipient: "secret@elsewhere.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => ""}))

      assert html =~ "No tenant selected"

      assert html =~
               "Enter a tenant ID to inspect inbound routing for one workspace."

      assert clear_filters_count(html) == 1

      # No cross-tenant leak — neither the foreign id nor the foreign recipient.
      refute html =~ other.id
      refute html =~ "secret@elsewhere.com"
      refute html =~ "s*****@e*******.com"
    end

    test "tenant with no inbound history renders truly-empty copy without empty reset", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "No InboundMessages yet"

      assert html =~
               "InboundMessages appear here once this tenant receives its first message."

      assert clear_filters_count(html) == 1
      refute html =~ "No InboundMessages match these filters"
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

    test "gateway-unavailable runtime path renders exact zero summary for tenant query", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      Application.put_env(:mailglass_admin, :inbound_gateway_available?, false)
      on_exit(fn -> Application.delete_env(:mailglass_admin, :inbound_gateway_available?) end)

      InboundFixtures.seed_matched!(@tenant_id, recipient: "hidden@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-overview")
      assert html =~ "InboundMessages"
      assert html =~ "No match"
      assert html =~ "Accepted"
      assert html =~ "No-match rate"
      assert html =~ "0.0%"
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

      assert html =~ "No InboundMessages match these filters"
      assert html =~ "Adjust the filters or wait for the next inbound message."
      assert clear_filters_count(html) == 2
      refute html =~ "No InboundMessages yet"
    end

    test "renders inbound responsive IA hooks and percentage grid contract", %{conn: conn} do
      conn = operator_conn(conn)

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="inbound-filters")
      assert html =~ ~s(data-testid="inbound-filters-toggle")
      assert html =~ "toggle"
      assert html =~ ~s(to&quot;:&quot;#inbound-filter-panel&quot;)
      assert html =~ ~s(id="inbound-filter-panel")
      assert html =~ "hidden md:block"
      assert html =~ "md:grid-cols-[40%_60%]"
      assert html =~ "min-[1440px]:!grid-cols-[33%_67%]"
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

    test "an unselectable foreign-tenant record id surfaces the detail-error band, not a leak", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      %{record: foreign} = InboundFixtures.seed_matched!(@other_tenant)

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
               "Replay recorded. A new replay run was appended to this message's timeline."

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
        {:inbound_record_inserted, fresh.id,
         %{provider: "mailgun", record_type: "inbound_record"}}
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

  describe "brand-voice + PII sweep (IADM-06, V10/V5)" do
    test "empty + no-selection states carry verbatim copy and no banned words (V10)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~
               "No InboundMessages yet"

      assert html =~
               "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence."

      refute_banned(html)
    end

    test "detail-load-error band carries verbatim copy and no banned words (V10)", %{conn: conn} do
      conn = operator_conn(conn)
      %{record: foreign} = InboundFixtures.seed_matched!(@other_tenant)

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
               "Replay recorded. A new replay run was appended to this message's timeline."

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

  defp refute_banned(html) do
    for word <- @banned do
      refute html =~ word, "banned brand-voice word #{inspect(word)} found in rendered HTML"
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
