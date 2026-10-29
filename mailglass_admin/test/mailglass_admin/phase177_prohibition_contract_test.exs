defmodule MailglassAdmin.Phase177ProhibitionContractTest do
  @moduledoc """
  Machine-checked form of the Phase 177 must-NOT prohibitions (UXF-09, UXF-10,
  OUTUX-06; D-19, D-52).

  Each prohibition reduces to a forbidden control, a forbidden value, a
  forbidden claim or a forbidden structure on a closed set of rendered states,
  so this file enumerates those states and refutes the violation. Every rule is
  a detector that returns a violation list: `[]` means clean. The "detectors
  have teeth" block feeds each detector a known violation and a known clean
  fixture, so a pass here is not vacuous, and each rule was additionally proven
  red by a temporary source mutation (recorded in the plan SUMMARY) and
  reverted.

  Positive behavior (Back round trip, scope group order, Health population)
  stays in the LiveView and browser suites; this file only owns the
  prohibitions.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @moduletag :phase177

  import Phoenix.Component, only: [sigil_H: 2]

  alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}
  alias MailglassAdmin.Operator.{HealthOverview, Shell}
  alias MailglassAdmin.TestSupport.OperatorFixtures

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]
  @tenant_id "test-tenant"
  @preview_base "/dev/mail"
  @scenario_base "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
  @health_tenant "browser-tenant"
  @canary "zz-canary-7f3"
  @package_root Path.expand("../..", __DIR__)

  # D-12 / UI-SPEC: the exact Preview subtitle.
  @d12_subtitle "Renders the scenarios in each Mailable's preview_props/0. It doesn't read Deliveries or Inbound messages from any Account."

  # P3 (revision W-1): the only static strings in the Preview chrome allowed to
  # say "Account". Adding one is a deliberate edit of this list.
  @provenance_allow_list [
    "It doesn't read Deliveries or Inbound messages from any Account.",
    "Scoped to an Account",
    "Not tied to an Account"
  ]
  @provenance_claims [~r/\b(sample|demo|fake)\b/i, ~r/\blive\b/i, ~r/\blive data\b/i]
  @account_words [~r/\bAccounts?('s)?\b/i, ~r/\btenant[_ ]id\b/i]

  # Account labels and ids configured by the synthetic test router, its
  # fixtures and the return-context tests.
  @configured_accounts ["Acme", "Fjordline", "browser-tenant", "test-tenant", "tenant-b", @canary]

  @health_taxonomy ~w(
    operator-health-deliveries-failed
    operator-health-deliveries-bounced
    operator-health-deliveries-rejected
    operator-health-deliveries-deferred
    operator-health-inbound-failed
    operator-health-inbound-no_match
    operator-overview-health-failures
    operator-overview-health-orphans
  )

  @severity_words ~r/\b(critical|severe|urgent|high|spike|warning level)\b/i
  @severity_classes ~r/^(text|bg|border)-(error|warning)\b/

  @two_options [%{id: "acme", label: "Acme"}, %{id: "fjordline-aps", label: "Fjordline"}]

  @base_attrs %{
    active: :overview,
    preview_path: "/dev/mail",
    overview_path: "/ops/mail?tenant_id=acme",
    deliveries_path: "/ops/mail?tenant_id=acme&view=deliveries",
    inbound_path: "/ops/mail/inbound?tenant_id=acme",
    inbound_available?: true,
    selected_tenant_id: "acme",
    tenant_options: @two_options,
    account_labels: %{"acme" => "Acme", "fjordline-aps" => "Fjordline"},
    page_uri: "/ops/mail?tenant_id=acme",
    title: "Email health"
  }

  @checked_at ~U[2026-10-28 12:00:00Z]

  describe "detectors have teeth (fail-first proof)" do
    test "the P1 detector rejects an Account switcher, an Account details and a disabled control" do
      switcher = ~s(<nav><div data-testid="operator-account-switcher">Acme</div></nav>)

      details =
        ~s(<div data-testid="admin-shell-sidebar"><details><summary>Account</summary></details></div>)

      select = ~s(<div data-testid="admin-shell-topbar"><select name="tenant"></select></div>)

      disabled =
        ~s(<div data-testid="admin-shell-topbar"><button disabled aria-label="Account">A</button></div>)

      for fragment <- [switcher, details, select, disabled] do
        assert preview_account_control_violations(fragment) != [],
               "P1 detector missed #{inspect(fragment)}"
      end
    end

    test "the P1 detector accepts the static scope label" do
      clean = """
      <div data-testid="admin-shell-sidebar">
        <nav data-testid="surface-nav-sidebar">
          <p data-testid="preview-scope-label">Scoped to an Account</p>
        </nav>
      </div>
      """

      assert preview_account_control_violations(clean) == []
    end

    test "the P2 detector rejects the canary in text, title, aria, data and flash" do
      for fragment <- [
            ~s(<p>Back to #{@canary}</p>),
            ~s(<a href="/x" title="#{@canary}">Back</a>),
            ~s(<a href="/x" aria-label="#{@canary}">Back</a>),
            ~s(<a href="/x" data-tenant="#{@canary}">Back</a>),
            ~s(<div id="flash-info">#{@canary}</div>)
          ] do
        assert canary_violations(fragment, @canary) != [],
               "P2 detector missed #{inspect(fragment)}"
      end
    end

    test "the P2 detector accepts the canary inside href attribute values only" do
      clean = ~s(<a href="/ops/mail?tenant_id=#{@canary}">Back to Health</a>)
      assert canary_violations(clean, @canary) == []
    end

    test "the P3 detector rejects provenance claims, Account words and configured Accounts" do
      for text <- [
            "Previews use sample data",
            "Renders live data",
            "Demo scenarios",
            "Fake messages",
            "Shows Deliveries for this Account",
            "Account: Acme",
            "Rendering for tenant_id",
            "Rendering for tenant id",
            "Preview for Fjordline"
          ] do
        assert preview_provenance_violations(text, @configured_accounts) != [],
               "P3 detector missed #{inspect(text)}"
      end
    end

    test "the P3 detector accepts the exact D-12 sentence and the two static Account strings" do
      clean =
        "Preview #{@d12_subtitle} Scoped to an Account Health Deliveries Not tied to an Account"

      assert preview_provenance_violations(clean, @configured_accounts) == []

      assert preview_provenance_violations("Deliveries Inbound Preview", @configured_accounts) ==
               []
    end

    test "the P3 allow-list is exact, not a blanket Account pass" do
      assert preview_provenance_violations(
               "#{@d12_subtitle} for this Account",
               @configured_accounts
             ) != []

      assert preview_provenance_violations(
               "Scoped to an Account Scoped to an Account's data",
               @configured_accounts
             ) != []
    end

    test "the P4 detector rejects a top-level tenant_id key on the Preview href" do
      violating = """
      <nav data-testid="surface-nav-sidebar">
        <a href="/dev/mail?tenant_id=acme&amp;return_surface=overview">Preview</a>
      </nav>
      """

      assert preview_href_tenant_violations(violating) != []
    end

    test "the P4 detector accepts a Preview href carrying only return_* keys" do
      clean = """
      <nav data-testid="surface-nav-sidebar">
        <a href="/dev/mail?return_surface=overview&amp;return_tenant_id=acme">Preview</a>
      </nav>
      <nav data-testid="surface-nav-mobile"><a href="/dev/mail">Preview</a></nav>
      """

      assert preview_href_tenant_violations(clean) == []
    end

    test "the P5 detector rejects Preview inside the group and a group link that is not scoped" do
      inside = """
      <nav data-testid="surface-nav-sidebar">
        <div data-account-scope role="group">
          <a href="/h">Health</a><a href="/d">Deliveries</a><a href="/p">Preview</a>
        </div>
      </nav>
      """

      extra = """
      <nav data-testid="surface-nav-sidebar">
        <div data-account-scope role="group"><a href="/h">Health</a><a href="/x">Settings</a></div>
      </nav>
      """

      assert Enum.any?(
               scope_group_violations(inside, ["Health", "Deliveries"]),
               &(&1 =~ "Preview")
             )

      assert scope_group_violations(extra, ["Health", "Deliveries"]) != []
    end

    test "the P5 detector accepts a group of exactly the rendered scoped items" do
      clean = """
      <nav data-testid="surface-nav-sidebar">
        <div data-account-scope role="group"><a href="/h">Health</a><a href="/d">Deliveries</a></div>
        <div data-testid="surface-nav-preview-block"><a href="/p">Preview</a></div>
      </nav>
      """

      assert scope_group_violations(clean, ["Health", "Deliveries"]) == []
    end

    test "the P6 detector rejects a reworded, missing or extended subtitle" do
      reworded =
        subtitle_fragment("Renders the sample scenarios in each Mailable's preview_props/0.")

      missing = ~s(<div data-testid="admin-shell-page-header"><h1>Preview</h1></div>)

      extended =
        subtitle_fragment(String.replace(@d12_subtitle, "any Account.", "any Account. Demo."))

      for fragment <- [reworded, missing, extended] do
        assert subtitle_violations(fragment) != [], "P6 detector missed #{inspect(fragment)}"
      end
    end

    test "the P6 detector accepts the exact D-12 subtitle" do
      assert subtitle_violations(subtitle_fragment(@d12_subtitle)) == []
    end

    test "the P7 detector rejects a details, a chevron, an option and a switcher" do
      for fragment <- [
            "<div><details><summary>Acme</summary></details></div>",
            ~s(<div><span class="hero-chevron-down"></span></div>),
            ~s(<div><a data-testid="operator-account-option">Acme</a></div>),
            ~s(<div><summary data-testid="operator-account-switcher">Acme</summary></div>)
          ] do
        assert account_picker_violations(Floki.parse_fragment!(fragment)) != [],
               "P7 detector missed #{inspect(fragment)}"
      end
    end

    test "the P7 detector accepts static text" do
      clean =
        Floki.parse_fragment!(~s(<div><p data-testid="operator-account-label">Acme</p></div>))

      assert account_picker_violations(clean) == []
    end

    test "the P8 detector rejects a return_* key, a widened map and Account assigns" do
      expected = ~w(live_session_name mailables)

      assert session_key_violations(
               %{"live_session_name" => 1, "mailables" => [], "return_surface" => "x"},
               expected
             ) != []

      assert session_key_violations(
               %{"live_session_name" => 1, "mailables" => [], "extra" => 1},
               expected
             ) !=
               []

      assert session_key_violations(%{"live_session_name" => 1}, expected) != []

      assert assign_violations(%{current_mailable: nil, tenant_id: "acme"}) != []
      assert assign_violations(%{selected_tenant_id: "acme"}) != []
      assert assign_violations(%{account_labels: %{}}) != []
    end

    test "the P8 detector accepts the unchanged key set and Account-free assigns" do
      expected = ~w(live_session_name mailables)

      assert session_key_violations(%{"live_session_name" => 1, "mailables" => []}, expected) ==
               []

      assert assign_violations(%{current_mailable: nil, return_context: %{tenant_id: "acme"}}) ==
               []
    end

    test "the P9 detector rejects an Inbound mention when Inbound is not rendered" do
      violating = """
      <nav data-testid="surface-nav-sidebar">
        <div data-account-scope role="group"><a href="/h">Health</a><a href="/d">Deliveries</a></div>
        <span data-testid="surface-nav-scope-description">Applies to Health, Deliveries and Inbound.</span>
      </nav>
      """

      assert description_inbound_violations(violating) != []
    end

    test "the P9 detector accepts a description derived from the rendered items" do
      clean = """
      <nav data-testid="surface-nav-sidebar">
        <div data-account-scope role="group"><a href="/h">Health</a><a href="/d">Deliveries</a></div>
        <span data-testid="surface-nav-scope-description">Applies to Health and Deliveries.</span>
      </nav>
      <nav data-testid="surface-nav-mobile">
        <div data-account-scope role="group"><a href="/h">Health</a><a href="/i">Inbound</a></div>
        <span data-testid="surface-nav-scope-description">Applies to Health and Inbound.</span>
      </nav>
      """

      assert description_inbound_violations(clean) == []
    end

    test "the Health order detector rejects a count-sorted or reordered list" do
      asc = health_rows_fragment(Enum.zip(@health_taxonomy, 1..8))
      sorted = health_rows_fragment(Enum.reverse(Enum.zip(@health_taxonomy, 1..8)))
      reversed_counts = health_rows_fragment(Enum.zip(@health_taxonomy, 8..1//-1))
      classed = health_rows_fragment(Enum.zip(@health_taxonomy, 8..1//-1), "text-error")

      # Count order leaking into row order: the list follows the counts.
      assert health_order_violations(asc, sorted) != []
      # Count leaking into the row classes.
      assert health_order_violations(reversed_counts, classed) != []
    end

    test "the Health order detector accepts the taxonomy order for both count orders" do
      asc = health_rows_fragment(Enum.zip(@health_taxonomy, 1..8))
      reversed = health_rows_fragment(Enum.zip(@health_taxonomy, 8..1//-1))
      assert health_order_violations(asc, reversed) == []
    end

    test "the Health severity detector rejects severity words and severity colour on a row" do
      word = health_rows_fragment([{"operator-health-deliveries-failed", 9}], nil, "Critical")
      colour = health_rows_fragment([{"operator-health-deliveries-failed", 9}], "text-error")

      for fragment <- [word, colour] do
        assert health_severity_violations(fragment) != [],
               "severity detector missed #{inspect(fragment)}"
      end

      for text <- ["urgent", "High volume", "a spike", "warning level"] do
        fragment = health_rows_fragment([{"operator-health-deliveries-failed", 9}], nil, text)
        assert health_severity_violations(fragment) != []
      end
    end

    test "the Health severity detector accepts a neutral row and the word Deliveries" do
      neutral =
        health_rows_fragment([{"operator-health-deliveries-failed", 9}], nil, "Deliveries")

      assert health_severity_violations(neutral) == []
    end

    test "the Health deep-link detector rejects a row with no link or an empty href" do
      no_link =
        ~s(<ul><li data-testid="operator-health-deliveries-failed"><p>3</p></li></ul>)

      empty =
        ~s(<ul><li data-testid="operator-health-deliveries-failed"><a data-testid="operator-health-deliveries-failed-link" href="">x</a></li></ul>)

      assert health_deep_link_violations(Floki.parse_fragment!(no_link)) != []
      assert health_deep_link_violations(Floki.parse_fragment!(empty)) != []
    end

    test "the Health deep-link detector accepts rows that each keep a link" do
      clean = Floki.parse_fragment!(health_rows_fragment(Enum.zip(@health_taxonomy, 1..8)))
      assert health_deep_link_violations(clean) == []
    end

    test "the Health reordering detector rejects order-* and reverse flex" do
      for class <- ["order-2", "md:order-last", "@[30rem]:order-first", "flex-row-reverse"] do
        fragment = Floki.parse_fragment!(~s(<div class="flex #{class}"><p>x</p></div>))
        assert health_reorder_violations(fragment) != [], "reorder detector missed #{class}"
      end
    end

    test "the Health reordering detector accepts a border-* or reorder-free class set" do
      fragment =
        Floki.parse_fragment!(
          ~s(<div class="flex border-y border-base-300 gap-x-sm"><p>x</p></div>)
        )

      assert health_reorder_violations(fragment) == []
    end

    test "the live-region detector rejects status, alert and aria-live on a Health notice" do
      for attrs <- [~s(role="status"), ~s(role="alert"), ~s(aria-live="polite")] do
        fragment =
          Floki.parse_fragment!(
            ~s(<p data-testid="operator-health-stale-failed_ingest" #{attrs}>Stale</p>)
          )

        assert health_live_region_violations(fragment) != [],
               "live-region detector missed #{attrs}"
      end
    end

    test "the live-region detector accepts a plain notice and an unrelated status region" do
      fragment =
        Floki.parse_fragment!("""
        <p data-testid="operator-health-stale-failed_ingest">Stale</p>
        <div data-testid="operator-results-status" role="status">3 results</div>
        """)

      assert health_live_region_violations(fragment) == []
    end

    test "the Back-link detector rejects an Account name, an id and an off-set label" do
      for fragment <- [
            ~s(<a data-testid="preview-return-link" href="/x">Back to Acme</a>),
            ~s|<a data-testid="preview-return-link" href="/x">Back to Health (tenant-b)</a>|,
            ~s(<a data-testid="preview-return-link" href="/x" title="tenant-b">Back to Health</a>),
            ~s(<a data-testid="preview-return-link" href="/x" aria-label="Back to Fjordline">Back to Health</a>),
            ~s(<a data-testid="preview-return-link" href="/x">Return</a>)
          ] do
        assert back_link_violations(fragment, @configured_accounts) != [],
               "Back-link detector missed #{inspect(fragment)}"
      end
    end

    test "the Back-link detector accepts the closed set of labels" do
      for label <- ["Back to Health", "Back to Deliveries", "Back to Inbound"] do
        fragment = ~s(<a data-testid="preview-return-link" href="/x?id=tenant-b">#{label}</a>)
        assert back_link_violations(fragment, @configured_accounts) == []
      end
    end

    test "the docs detector rejects a claim that the Account switch re-runs host authorization" do
      for text <- [
            "Switching the Account re-runs host authorization on every patch.",
            "An Account switch re-authorizes the operator through on_mount.",
            "The push_patch switch re-checks authorization for the new Account.",
            "Switching Accounts\nre-runs host\nauthorization."
          ] do
        assert reauthorization_claim_violations("doc.md", text) != [],
               "docs detector missed #{inspect(text)}"
      end
    end

    test "the docs detector accepts honest or unrelated sentences" do
      for text <- [
            "Switching the Account patches the URL. Host authorization runs when the Operator mounts.",
            "An Account switch does not re-run host authorization.",
            "Replay reruns one exact stored mailbox execution.",
            "The on_mount hook runs once per mount."
          ] do
        assert reauthorization_claim_violations("doc.md", text) == [], inspect(text)
      end
    end
  end

  describe "P1 Preview renders no Account control" do
    test "direct entry renders no Account control", %{conn: conn} do
      {:ok, _view, html} = live(preview_conn(conn), @scenario_base <> "?width=768")

      assert preview_account_control_violations(html) == []

      assert Floki.find(Floki.parse_document!(html), ~s([data-testid="preview-scope-label"])) !=
               []
    end

    test "a valid return context renders no Account control", %{conn: conn} do
      conn = preview_conn(conn)

      assert {:error, {:redirect, %{to: to}}} =
               live(conn, @preview_base <> "?return_surface=overview&return_tenant_id=tenant-b")

      assert to =~ "return_tenant_id=tenant-b"

      {:ok, _view, html} = live(conn, to)

      assert preview_account_control_violations(html) == []

      assert Floki.find(Floki.parse_document!(html), ~s([data-testid="preview-return-link"])) !=
               []
    end

    test "a tampered return context renders no Account control", %{conn: conn} do
      conn = preview_conn(conn)

      {:error, {:redirect, %{to: to}}} =
        live(conn, @preview_base <> "?return_surface=https://evil.example&return_tenant_id=x")

      {:ok, _view, html} = live(conn, to)

      assert preview_account_control_violations(html) == []
    end
  end

  describe "P2 return_tenant_id appears only inside href attribute values" do
    test "the canary never reaches Preview text, title, aria, data or flash", %{conn: conn} do
      conn = preview_conn(conn)

      for {surface, label} <- [
            {"overview", "Back to Health"},
            {"deliveries", "Back to Deliveries"},
            {"inbound", "Back to Inbound"}
          ] do
        {:error, {:redirect, %{to: to}}} =
          live(conn, "#{@preview_base}?return_surface=#{surface}&return_tenant_id=#{@canary}")

        {:ok, view, html} = live(conn, to)

        # Non-vacuous: the canary is on the page, and only as a href value.
        assert html =~ @canary
        assert has_element?(view, ~s([data-testid="preview-return-link"]), label)
        assert canary_violations(html, @canary) == []
        assert canary_violations(render(view), @canary) == []
      end
    end

    test "the canary stays inside hrefs across a width patch", %{conn: conn} do
      conn = preview_conn(conn)

      {:ok, view, _html} =
        live(
          conn,
          "#{@scenario_base}?width=768&return_surface=overview&return_tenant_id=#{@canary}"
        )

      html = render_hook(view, "set_device", %{"width" => "375"})
      assert html =~ @canary
      assert canary_violations(html, @canary) == []
    end
  end

  describe "P3 Preview chrome makes no provenance or Account claim" do
    test "direct entry and a valid return use only the allow-listed static strings", %{conn: conn} do
      conn = preview_conn(conn)
      {:ok, _view, direct} = live(conn, @scenario_base <> "?width=768")

      {:ok, _view, with_return} =
        live(
          conn,
          "#{@scenario_base}?width=768&return_surface=overview&return_tenant_id=tenant-b"
        )

      for html <- [direct, with_return] do
        text = preview_chrome_text(html)

        assert text =~ "Scoped to an Account"
        assert text =~ "Not tied to an Account"
        assert preview_provenance_violations(text, @configured_accounts) == []
      end
    end

    test "a tampered return context stays clean", %{conn: conn} do
      conn = preview_conn(conn)

      {:error, {:redirect, %{to: to}}} =
        live(
          conn,
          @preview_base <> "?return_surface=overview&return_tenant_id=" <> @canary <> "%00"
        )

      {:ok, _view, html} = live(conn, to)
      assert preview_provenance_violations(preview_chrome_text(html), @configured_accounts) == []
    end
  end

  describe "P4 operator Preview href never carries a top-level tenant_id" do
    test "every operator surface and mount mints only return_* keys", %{conn: conn} do
      for path <- [
            "/ops/mail?tenant_id=tenant-b",
            "/ops/mail?tenant_id=tenant-b&view=deliveries",
            "/ops/mail/inbound?tenant_id=tenant-b",
            "/ops/mail",
            "/secure/console?tenant_id=tenant-b"
          ] do
        {:ok, _view, html} = live(operator_conn(conn), path)

        assert preview_href_tenant_violations(html) == [], path
        assert length(preview_hrefs(html)) == 2, "#{path}: expected a Preview link per nav copy"
      end
    end
  end

  describe "P5 Preview sits outside the Account scope group" do
    test "operator pages and Preview group exactly the scoped items", %{conn: conn} do
      {:ok, _view, operator} = live(operator_conn(conn), "/ops/mail?tenant_id=tenant-b")
      {:ok, _view, preview} = live(preview_conn(conn), @scenario_base <> "?width=768")

      for html <- [operator, preview] do
        assert scope_group_violations(html, ["Health", "Deliveries", "Inbound"]) == []
      end
    end

    test "the shared nav without Inbound groups only Health and Deliveries" do
      for scope <- [:account, :preview], layout <- [:sidebar, :mobile] do
        html = render_nav(scope, layout, inbound_available?: false)

        doc = Floki.parse_fragment!(html)
        [_] = Floki.find(doc, ~s([data-account-scope]))

        assert scope_group_violations(html, ["Health", "Deliveries"]) == []
      end
    end
  end

  describe "P6 Preview subtitle is exactly the D-12 sentence" do
    test "direct entry, valid return and a not-found scenario", %{conn: conn} do
      conn = preview_conn(conn)

      for path <- [
            @scenario_base <> "?width=768",
            @scenario_base <> "?width=768&return_surface=overview&return_tenant_id=tenant-b",
            "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/no_such_scenario?width=768",
            "/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__?width=768"
          ] do
        {:ok, _view, html} = live(conn, path)
        assert subtitle_violations(html) == [], path
      end
    end
  end

  describe "P7 no choice means no picker" do
    test "fewer than two Account options render no details, chevron or option" do
      none = %{tenant_options: [], selected_tenant_id: nil, tenant_state: :none}
      one = %{tenant_options: [%{id: "acme", label: "Acme"}]}
      one_unselected = %{tenant_options: [%{id: "acme", label: "Acme"}], selected_tenant_id: nil}

      for overrides <- [none, one, one_unselected], layout <- ["sidebar", "mobile"] do
        header =
          render_shell(overrides) |> Floki.find(~s([id="surface-nav-scope-header-#{layout}"]))

        assert header != [], "#{layout} header missing"
        assert account_picker_violations(header) == []
      end
    end

    test "two options do render the picker, so the detector is not vacuous" do
      header = render_shell(%{}) |> Floki.find(~s([id="surface-nav-scope-header-sidebar"]))
      assert account_picker_violations(header) != []
    end

    test "Preview never renders a picker", %{conn: conn} do
      {:ok, _view, html} = live(preview_conn(conn), @scenario_base <> "?width=768")
      assert account_picker_violations(Floki.parse_fragment!(html) |> chrome_nodes()) == []
    end
  end

  describe "P8 session whitelists and Preview assigns are unchanged" do
    @preview_keys ~w(admin_chrome_theme_cookie live_session_name mailables navigation)
    @operator_keys ~w(account_labels admin_chrome_theme_cookie auth_method inbound_router live_session_name navigation recent_auth_at subject_id tenant_id)

    test "the Preview and Operator session maps keep their exact keys and no return_* key" do
      with_context =
        Phoenix.ConnTest.build_conn(
          :get,
          "/dev/mail?return_surface=overview&return_tenant_id=tenant-b"
        )
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.fetch_query_params()

      preview =
        MailglassAdmin.Router.__preview_session__(with_context,
          mailables: :auto_scan,
          live_session_name: :test_session
        )

      operator =
        MailglassAdmin.Router.__operator_session__(with_context,
          auth: MailglassAdmin.TestOperatorAuth,
          session: [
            subject_id: "current_user_id",
            tenant_id: "tenant_id",
            auth_method: "auth_method",
            recent_auth_at: "recent_auth_at"
          ],
          live_session_name: :mailglass_admin_operator,
          unauthorized_path: "/login",
          on_mount: []
        )

      assert session_key_violations(preview, @preview_keys) == []
      assert session_key_violations(operator, @operator_keys) == []
    end

    test "PreviewLive holds no Account assigns on direct entry or with a return context", %{
      conn: conn
    } do
      conn = preview_conn(conn)

      for query <- ["?width=768", "?width=768&return_surface=overview&return_tenant_id=tenant-b"] do
        {:ok, view, _html} = live(conn, @scenario_base <> query)
        %{socket: %{assigns: assigns}} = :sys.get_state(view.pid)

        assert Map.has_key?(assigns, :return_context)
        assert assign_violations(assigns) == []
      end
    end
  end

  describe "P9 the scope description never mentions an absent Inbound" do
    test "Inbound unavailable drops Inbound from every description" do
      doc = render_shell(%{inbound_available?: false})

      html =
        ~s(<div>) <> Floki.raw_html(doc) <> ~s(</div>)

      assert description_inbound_violations(html) == []

      for layout <- ["sidebar", "mobile"] do
        assert [_] =
                 doc
                 |> Floki.find(~s([data-testid="surface-nav-#{layout}"]))
                 |> Floki.find(~s([data-testid="surface-nav-scope-description"]))
      end
    end

    test "Inbound available mentions it, so the detector is not vacuous" do
      html = render_shell(%{}) |> Floki.raw_html()
      assert html =~ "Applies to Health, Deliveries and Inbound."
      assert description_inbound_violations(html) == []
    end
  end

  describe "Health issue order is count-independent" do
    test "ascending and reversed counts render the same rows in taxonomy order", %{conn: conn} do
      asc = health_html(conn, :ascending)
      rev = health_html(conn, :reversed)

      assert health_order_violations(asc, rev) == []
      assert health_issue_testids(asc) == @health_taxonomy
      assert Enum.map(health_issue_rows(asc), &elem(&1, 1)) == ~w(1 2 3 4 5 6 7 8)
      assert Enum.map(health_issue_rows(rev), &elem(&1, 1)) == ~w(8 7 6 5 4 3 2 1)
    end
  end

  describe "Health severity is never derived from count" do
    test "no severity word or severity colour on a row for any count", %{conn: conn} do
      for order <- [:ascending, :reversed] do
        assert health_severity_violations(health_html(conn, order)) == [], inspect(order)
      end

      huge = health_overview_html(issues: [component_issue("health-a", 9_999_999)])
      assert health_severity_violations(huge) == []
    end
  end

  describe "every Health issue keeps a deep link" do
    test "all eight categories and the default seed keep a link with an href", %{conn: conn} do
      html = health_html(conn, :ascending)
      assert length(health_issue_rows(html)) == 8
      assert health_deep_link_violations(html) == []

      OperatorFixtures.seed_phase169_scenario!()
      {:ok, _view, default} = live(health_conn(conn), health_path())
      assert health_issue_rows(default) != []
      assert health_deep_link_violations(default) == []
    end

    test "component rows for both surfaces keep their link" do
      html =
        health_overview_html(
          issues: [
            component_issue("health-a", 1),
            component_issue("health-b", 8, surface: :inbound)
          ]
        )

      assert health_deep_link_violations(html) == []
    end
  end

  describe "Health has no visual reordering" do
    test "the real Health region and every component state carry no order-* class", %{conn: conn} do
      assert health_reorder_violations(health_html(conn, :ascending)) == []
      assert health_reorder_violations(health_html(conn, :reversed)) == []

      for states <- [
            ready_states(),
            with_state(:failed_ingest, :stale),
            with_state(:orphan_backlog, :unavailable)
          ] do
        assert health_reorder_violations(health_overview_html(states: states)) == []
      end

      assert health_reorder_violations(health_overview_html(issues: [])) == []
    end
  end

  describe "persistent Health notices do not announce" do
    test "stale and unavailable notices for every panel carry no live region" do
      for panel <- [:failed_ingest, :orphan_backlog, :delivery_activity, :inbound_activity],
          status <- [:stale, :unavailable] do
        html = health_overview_html(states: with_state(panel, status))

        assert Floki.find(
                 Floki.parse_fragment!(html),
                 ~s([data-testid="operator-health-#{status}-#{panel}"])
               ) != [],
               "#{status} #{panel} notice not rendered"

        assert health_live_region_violations(html) == [], "#{status} #{panel}"
      end
    end

    test "a stale real Health route carries no live region on its notices", %{conn: conn} do
      OperatorFixtures.seed_phase169_health_partial!()
      {:ok, view, _html} = live(health_conn(conn), health_path())

      OperatorFixtures.arm_reader_fault!("operator-1", "failed_ingest", :known)
      html = render_patch(view, health_path(%{"event" => "opened", "window_hours" => "168"}))

      assert Floki.find(Floki.parse_fragment!(html), ~s([data-testid^="operator-health-stale-"])) !=
               []

      assert health_live_region_violations(html) == []
    end
  end

  describe "the Back link never names an Account" do
    test "every surface, including a canary id and a tampered one", %{conn: conn} do
      conn = preview_conn(conn)

      for {surface, tenant} <- [
            {"overview", "tenant-b"},
            {"deliveries", "fjordline-aps"},
            {"inbound", @canary}
          ] do
        {:error, {:redirect, %{to: to}}} =
          live(conn, "#{@preview_base}?return_surface=#{surface}&return_tenant_id=#{tenant}")

        {:ok, _view, html} = live(conn, to)

        assert back_link_violations(html, @configured_accounts ++ [tenant]) == []
        assert html =~ "preview-return-link"
      end
    end
  end

  describe "docs do not claim patch-time re-authorization" do
    test "no mailglass doc or moduledoc claims the Account switch re-runs host authorization" do
      files = doc_files()

      assert length(files) > 10, "expected the package docs and moduledocs, got #{length(files)}"

      violations =
        Enum.flat_map(files, fn path ->
          path |> doc_text() |> then(&reauthorization_claim_violations(path, &1))
        end)

      assert violations == []
    end
  end

  # -- detectors ---------------------------------------------------------------

  # P1: Preview reads no Account data, so its chrome (topbar, both nav copies,
  # page header) holds no Account control of any kind: no `operator-account*`
  # testid anywhere on the page, no `<details>` or `<select>` in the chrome, and
  # no disabled control that names an Account.
  defp preview_account_control_violations(html) do
    doc = Floki.parse_document!(html)

    testid_hits =
      for node <- Floki.find(doc, ~s([data-testid^="operator-account"])) do
        "Account control #{inspect(testid(node))} rendered on Preview"
      end

    chrome = chrome_nodes(doc)

    picker_hits =
      for tag <- ["details", "select"], _node <- Floki.find(chrome, tag) do
        "<#{tag}> rendered in Preview chrome"
      end

    disabled_hits =
      for node <- Floki.find(chrome, "[disabled], [aria-disabled='true']"),
          node |> Floki.raw_html() |> String.downcase() |> String.contains?("account") do
        "disabled Account control rendered in Preview chrome"
      end

    testid_hits ++ picker_hits ++ disabled_hits
  end

  # -- rendering and parsing helpers -------------------------------------------

  # The Preview chrome: topbar, sidebar, mobile nav and page header. The Preview
  # frame and the mailable menu in the page body are authored by adopters and
  # are never part of the chrome.
  defp chrome_nodes(doc) do
    Floki.find(
      doc,
      ~s([data-testid="admin-shell-topbar"], [data-testid="admin-shell-sidebar"], ) <>
        ~s([data-testid="admin-shell-mobile-nav"], [data-testid="admin-shell-page-header"])
    )
  end

  defp testid(node), do: node |> Floki.attribute("data-testid") |> List.first()

  defp preview_conn(conn),
    do: Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})

  # P2: the opaque Account id may ride a href (the Back link and the Preview
  # internal links) and nowhere else. Removing every href attribute value must
  # leave no occurrence in text, title, aria-*, data-*, flash or any other value.
  defp canary_violations(html, canary) do
    stripped = Regex.replace(~r/href="[^"]*"/, html, ~s(href=""))

    case length(String.split(stripped, canary)) - 1 do
      0 -> []
      count -> ["#{canary} appears #{count} time(s) outside href attribute values"]
    end
  end

  # P3 (revision W-1): `text` is the Preview chrome visible text. Step 1 flags
  # whole-word provenance claims ("Deliveries" never trips `live`). Step 2
  # deletes exactly the allow-listed static strings (each only as a complete
  # phrase, never as the prefix of a longer one) and flags any remaining
  # Account word, `tenant_id` or configured Account label or id.
  defp preview_provenance_violations(text, accounts) do
    text = String.replace(text, ~r/\s+/, " ")

    claims =
      for regex <- @provenance_claims, Regex.match?(regex, text) do
        "provenance claim #{inspect(Regex.source(regex))} in #{inspect(text)}"
      end

    remainder =
      Enum.reduce(@provenance_allow_list, text, fn allowed, acc ->
        Regex.replace(~r/(?<![\w'])#{Regex.escape(allowed)}(?![\w'’])/u, acc, "")
      end)

    words =
      for regex <- @account_words, Regex.match?(regex, remainder) do
        "Account wording #{inspect(Regex.source(regex))} outside the allow-list in #{inspect(remainder)}"
      end

    names =
      for account <- accounts,
          String.contains?(String.downcase(remainder), String.downcase(account)) do
        "configured Account #{inspect(account)} named in Preview chrome"
      end

    claims ++ words ++ names
  end

  # P4: the operator -> Preview href carries only return_* keys.
  defp preview_href_tenant_violations(html) do
    for href <- preview_hrefs(html),
        {"tenant_id", _value} <- href |> URI.parse() |> Map.get(:query) |> decode_query() do
      "Preview href carries a top-level tenant_id: #{href}"
    end
  end

  # P5: Preview is never inside [data-account-scope] and the group's links are
  # exactly the rendered scoped items.
  defp scope_group_violations(html, expected_labels) do
    doc = tree(html)

    for layout <- ["sidebar", "mobile"],
        nav <- [Floki.find(doc, ~s([data-testid="surface-nav-#{layout}"]))],
        nav != [],
        violation <- nav_group_violations(layout, nav, expected_labels) do
      violation
    end
  end

  defp nav_group_violations(layout, nav, expected_labels) do
    case Floki.find(nav, "[data-account-scope]") do
      [group] ->
        labels = group |> Floki.find("a") |> link_labels()

        preview =
          for label <- labels,
              label == "Preview",
              do: "#{layout}: Preview link inside the Account group"

        mismatch =
          if labels == expected_labels,
            do: [],
            else: [
              "#{layout}: group links #{inspect(labels)} are not the scoped items #{inspect(expected_labels)}"
            ]

        preview ++ mismatch

      groups ->
        ["#{layout}: expected one Account group, found #{length(groups)}"]
    end
  end

  # P6: the Preview subtitle is exactly the D-12 sentence.
  defp subtitle_violations(html) do
    case html |> tree() |> Floki.find(~s([data-testid="admin-shell-page-header"] p)) do
      [] ->
        ["Preview renders no subtitle"]

      paragraphs ->
        text = paragraphs |> Floki.text() |> String.replace(~r/\s+/, " ") |> String.trim()

        if text == @d12_subtitle,
          do: [],
          else: ["Preview subtitle #{inspect(text)} is not the D-12 sentence"]
    end
  end

  # P7: no choice means no picker, chevron, option or switcher.
  defp account_picker_violations(nodes) do
    nodes = tree(nodes)

    for {selector, what} <- [
          {"details", "<details>"},
          {".hero-chevron-down", "chevron"},
          {~s([data-testid="operator-account-option"]), "Account option"},
          {~s([data-testid="operator-account-switcher"]), "Account switcher"}
        ],
        _node <- Floki.find(nodes, selector) do
      "#{what} rendered without a real choice"
    end
  end

  # P8: the session maps keep exactly their whitelisted keys and never a return_* key.
  defp session_key_violations(session, expected_keys) do
    keys = session |> Map.keys() |> Enum.map(&to_string/1) |> Enum.sort()

    return_keys =
      for key <- keys, String.starts_with?(key, "return_"), do: "session carries #{key}"

    drift =
      if keys == Enum.sort(expected_keys),
        do: [],
        else: ["session keys #{inspect(keys)} differ from #{inspect(Enum.sort(expected_keys))}"]

    return_keys ++ drift
  end

  defp assign_violations(assigns) do
    for key <- [:selected_tenant_id, :tenant_id, :account_labels, :tenant_options],
        Map.has_key?(assigns, key) do
      "PreviewLive assigns #{inspect(key)}"
    end
  end

  # P9: a nav whose group renders no Inbound link must not mention Inbound in
  # its scope description.
  defp description_inbound_violations(html) do
    doc = tree(html)

    for layout <- ["sidebar", "mobile"],
        nav <- [Floki.find(doc, ~s([data-testid="surface-nav-#{layout}"]))],
        nav != [],
        "Inbound" not in (nav |> Floki.find("[data-account-scope] a") |> link_labels()),
        description <- Floki.find(nav, ~s([data-testid="surface-nav-scope-description"])),
        Floki.text(description) =~ ~r/inbound/i do
      "#{layout}: description mentions Inbound but no Inbound link is rendered"
    end
  end

  # Health: ascending and reversed counts must render the same rows in the same
  # (taxonomy) order with the same class lists on every row and descendant.
  defp health_order_violations(asc_html, rev_html) do
    asc = row_signatures(asc_html)
    rev = row_signatures(rev_html)
    asc_ids = Enum.map(asc, &elem(&1, 0))
    rev_ids = Enum.map(rev, &elem(&1, 0))

    order =
      if asc_ids == rev_ids and asc_ids == Enum.filter(@health_taxonomy, &(&1 in asc_ids)),
        do: [],
        else: ["issue order depends on count: #{inspect(asc_ids)} vs #{inspect(rev_ids)}"]

    classes =
      for {{id, row, kids}, {id, row_b, kids_b}} <- Enum.zip(asc, rev),
          {row, kids} != {row_b, kids_b} do
        "classes on #{id} depend on count"
      end

    order ++ classes
  end

  defp row_signatures(html) do
    html
    |> tree()
    |> health_region()
    |> Floki.find("li[data-testid]")
    |> Enum.map(fn row ->
      {testid(row), class_of(row), row |> Floki.find("[class]") |> Enum.map(&class_of/1)}
    end)
  end

  # Health severity is never expressed by count: no severity word in the region
  # text and no severity colour utility on an issue row or its descendants.
  defp health_severity_violations(html) do
    region = html |> tree() |> health_region()

    text = region |> Floki.text(sep: " ") |> String.replace(~r/\s+/, " ")

    words =
      for [word | _] <- Regex.scan(@severity_words, text) do
        "severity word #{inspect(word)} in the Health region"
      end

    colours =
      for row <- Floki.find(region, "li[data-testid]"),
          node <- [row | Floki.find(row, "[class]")],
          token <- node |> class_of() |> String.split(),
          token |> String.split(":") |> List.last() |> then(&Regex.match?(@severity_classes, &1)) do
        "severity colour #{inspect(token)} on #{inspect(testid(row))}"
      end

    words ++ colours
  end

  # Every issue row keeps a non-empty deep link.
  defp health_deep_link_violations(html) do
    for row <- html |> tree() |> health_region() |> Floki.find("li[data-testid]"),
        id = testid(row),
        not (row
             |> Floki.find(~s([data-testid="#{id}-link"]))
             |> Enum.any?(
               &(&1
                 |> Floki.attribute("href")
                 |> Enum.any?(fn href -> href != "" end))
             )) do
      "issue row #{id} has no deep link"
    end
  end

  # No visual reordering inside the Health region: no `order-*` utility (with
  # any variant prefix) and no reversed flex direction.
  defp health_reorder_violations(html) do
    region = html |> tree() |> health_region()

    for node <- Floki.find(region, "[class]"),
        token <- node |> class_of() |> String.split(),
        base = token |> String.split(":") |> List.last(),
        String.starts_with?(base, "order-") or base in ["flex-row-reverse", "flex-col-reverse"] do
      "visual reordering utility #{inspect(token)} in the Health region"
    end
  end

  # Persistent Health notices (stale, unavailable, ...) never announce.
  defp health_live_region_violations(html) do
    for node <- html |> tree() |> Floki.find(~s([data-testid^="operator-health-"])),
        role <- Floki.attribute(node, "role") ++ Floki.attribute(node, "aria-live"),
        role in ["status", "alert", "log", "polite", "assertive"] do
      "#{testid(node)} announces with #{inspect(role)}"
    end
  end

  # The Back link carries one of three closed-set labels and no Account
  # name or id, in its text or any attribute.
  defp back_link_violations(html, accounts) do
    case html |> tree() |> Floki.find(~s([data-testid="preview-return-link"])) do
      [] ->
        ["no Back link rendered"]

      links ->
        for link <- links, violation <- one_back_link_violations(link, accounts), do: violation
    end
  end

  defp one_back_link_violations(link, accounts) do
    text = link |> Floki.text() |> String.replace(~r/\s+/, " ") |> String.trim()

    label =
      if text in ["Back to Health", "Back to Deliveries", "Back to Inbound"],
        do: [],
        else: ["Back link label #{inspect(text)} is outside the closed set"]

    # `href` is the one place the opaque id may legitimately appear.
    visible =
      [
        text
        | for(
            attr <- ["title", "aria-label", "aria-describedby", "data-tenant"],
            value <- Floki.attribute(link, attr),
            do: value
          )
      ]
      |> Enum.join(" ")
      |> String.downcase()

    names =
      for account <- accounts, String.contains?(visible, String.downcase(account)) do
        "Back link names #{inspect(account)}"
      end

    label ++ names
  end

  # Docs: no sentence claims that an Account switch (a push_patch) re-runs host
  # authorization. Negated statements ("does not re-run") are honest and pass.
  defp reauthorization_claim_violations(path, text) do
    negated =
      ~r/\b(does not|doesn't|do not|don't|never|not|without|cannot|can't)\s+(?:\w+\s+){0,3}?(?:re-?runs?|re-?authori|re-?check|re-?evaluat)/i

    text
    |> String.split(~r/(?<=[.!?])\s+|\n{2,}/)
    |> Enum.map(&String.replace(&1, ~r/\s+/, " "))
    |> Enum.filter(fn sentence ->
      sentence = Regex.replace(negated, sentence, "")

      Regex.match?(~r/\b(switch(es|ing)?|push_patch|patch(es|ed)?)\b/i, sentence) and
        Regex.match?(~r/\b(authori[sz]\w*|on_mount)\b/i, sentence) and
        Regex.match?(
          ~r/\b(re-?runs?|re-?ran|re-?authori[sz]\w*|re-?checks?|re-?evaluat\w*|re-?execut\w*|re-?invok\w*)\b/i,
          sentence
        )
    end)
    |> Enum.map(&"#{Path.relative_to(path, @package_root)}: #{&1}")
  end

  # Package markdown (README, CHANGELOG, docs/) and the @moduledoc/@doc
  # heredocs of every lib module, plus the repository guides when present.
  defp doc_files do
    ["README.md", "CHANGELOG.md", "docs/*.md", "lib/**/*.ex", "../guides/**/*.md"]
    |> Enum.flat_map(&Path.wildcard(Path.join(@package_root, &1)))
  end

  defp doc_text(path) do
    contents = File.read!(path)

    if String.ends_with?(path, ".ex") do
      ~r/@(?:module)?doc\s+(?:~[sS])?"""\n(.*?)"""/s
      |> Regex.scan(contents, capture: :all_but_first)
      |> Enum.map_join("\n\n", &hd/1)
    else
      contents
    end
  end

  # -- rendering and parsing helpers -------------------------------------------

  defp tree(html) when is_binary(html), do: Floki.parse_fragment!(html)
  defp tree(nodes), do: nodes

  defp health_region(doc) do
    case Floki.find(doc, ~s([data-testid="operator-overview-health"])) do
      [] -> doc
      region -> region
    end
  end

  defp class_of(node), do: node |> Floki.attribute("class") |> List.first() |> Kernel.||("")

  defp link_labels(links), do: Enum.map(links, &(&1 |> Floki.text() |> String.trim()))

  defp decode_query(nil), do: []
  defp decode_query(query), do: query |> URI.query_decoder() |> Enum.to_list()

  defp visible_text(nodes),
    do: nodes |> Floki.text(sep: " ") |> String.replace(~r/\s+/, " ") |> String.trim()

  # Preview page header plus both nav copies; the Preview frame and the mailable
  # menu are adopter-authored and are never part of the chrome.
  defp preview_chrome_text(html) do
    html
    |> tree()
    |> Floki.find(
      ~s([data-testid="admin-shell-page-header"], [data-testid="surface-nav-sidebar"], ) <>
        ~s([data-testid="surface-nav-mobile"])
    )
    |> visible_text()
  end

  defp preview_hrefs(html) do
    doc = tree(html)

    for layout <- ["sidebar", "mobile"],
        link <- Floki.find(doc, ~s([data-testid="surface-nav-#{layout}"] a)),
        link |> Floki.text() |> String.trim() == "Preview",
        href <- Floki.attribute(link, "href"),
        do: href
  end

  defp subtitle_fragment(text) do
    ~s(<div data-testid="admin-shell-page-header"><h1>Preview</h1><p>#{text}</p></div>)
  end

  defp health_rows_fragment(pairs, extra_class \\ nil, extra_text \\ nil) do
    rows =
      for {id, count} <- pairs do
        """
        <li data-testid="#{id}" class="flex min-w-0 #{extra_class}">
          <p data-testid="#{id}-count">#{count}</p>
          <a data-testid="#{id}-link" href="/ops/mail?x=#{id}">Label #{extra_text}</a>
        </li>
        """
      end

    ~s(<div data-testid="operator-overview-health"><ul>#{Enum.join(rows)}</ul></div>)
  end

  defp render_shell(overrides) do
    assigns = %{attrs: Map.merge(@base_attrs, overrides)}

    html =
      rendered_to_string(~H"""
      <Shell.shell {@attrs}>
        body
      </Shell.shell>
      """)

    Floki.parse_fragment!(html)
  end

  defp render_nav(scope, layout, overrides) do
    attrs =
      Map.merge(
        %{
          active: :overview,
          layout: layout,
          scope: scope,
          preview_path: "/dev/mail",
          overview_path: "/ops/mail?tenant_id=acme",
          deliveries_path: "/ops/mail?tenant_id=acme&view=deliveries",
          inbound_path: "/ops/mail/inbound?tenant_id=acme",
          inbound_available?: true
        },
        Map.new(overrides)
      )

    assigns = %{attrs: attrs}

    rendered_to_string(~H"""
    <MailglassAdmin.SurfaceNav.nav {@attrs}>
      <:scope_header>Account header</:scope_header>
    </MailglassAdmin.SurfaceNav.nav>
    """)
  end

  # -- Health rendering ------------------------------------------------------------

  defp health_html(conn, order) do
    OperatorFixtures.seed_phase177_health_all!(counts: order)
    {:ok, _view, html} = live(health_conn(conn), health_path())
    html
  end

  defp health_issue_testids(html), do: html |> health_issue_rows() |> Enum.map(&elem(&1, 0))

  defp health_issue_rows(html) do
    for row <- html |> tree() |> health_region() |> Floki.find("li[data-testid]") do
      id = testid(row)

      count =
        row |> Floki.find(~s([data-testid="#{id}-count"])) |> Floki.text() |> String.trim()

      {id, count}
    end
  end

  defp health_path(params \\ %{}) do
    "/ops/mail?" <> URI.encode_query(Map.merge(%{"tenant_id" => @health_tenant}, params))
  end

  defp health_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @health_tenant,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
  end

  defp component_issue(testid, count, opts \\ []) do
    %{
      count: count,
      label: "Label #{testid}",
      help: "Help text for #{testid}.",
      testid: testid,
      surface: Keyword.get(opts, :surface, :deliveries),
      path: "/ops/mail?view=deliveries&#{testid}=1",
      stale?: false
    }
  end

  defp ready_states do
    for key <- [:failed_ingest, :orphan_backlog, :delivery_activity, :inbound_activity],
        into: %{},
        do: {key, %{status: :ready, checked_at: @checked_at}}
  end

  defp with_state(panel, status),
    do: Map.put(ready_states(), panel, %{status: status, checked_at: @checked_at})

  defp health_overview_html(overrides) do
    assigns =
      Keyword.merge(
        [
          issues: [
            component_issue("health-a", 1),
            component_issue("health-b", 8, surface: :inbound)
          ],
          activity: %{deliveries: %{total: 21}, inbound: %{total: 3}},
          states: ready_states(),
          deliveries_path: "/ops/mail?view=deliveries",
          inbound_path: "/ops/mail/inbound",
          window_copy: "Last 7 days",
          window_description: "Health looks at the last 7 days.",
          observed_at: @checked_at
        ],
        overrides
      )

    render_component(&HealthOverview.overview/1, assigns)
  end

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
