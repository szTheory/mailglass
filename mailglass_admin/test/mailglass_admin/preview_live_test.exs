defmodule MailglassAdmin.Fixtures.HeaderCaseMailer do
  use Mailglass.Mailable, stream: :transactional

  def preview_props, do: [lowercase_headers: %{}, generated_date: %{}]

  def lowercase_headers(_assigns) do
    new()
    |> Mailglass.Message.from("no-reply@example.test")
    |> Mailglass.Message.to("ada@example.test")
    |> Mailglass.Message.subject("Lowercase headers")
    |> Mailglass.Message.header("message-id", "<provided@example.test>")
    |> Mailglass.Message.header("date", "Fri, 09 Oct 2026 12:00:00 +0000")
    |> Mailglass.Message.html_body("<p>hello</p>")
    |> Mailglass.Message.text_body("hello")
    |> Mailglass.Message.put_function(:lowercase_headers)
  end

  def generated_date(_assigns) do
    new()
    |> Mailglass.Message.from("no-reply@example.test")
    |> Mailglass.Message.to("ada@example.test")
    |> Mailglass.Message.subject("Generated date")
    |> Mailglass.Message.html_body("<p>hello</p>")
    |> Mailglass.Message.text_body("hello")
    |> Mailglass.Message.put_function(:generated_date)
  end
end

defmodule MailglassAdmin.PreviewLiveTest do
  @moduledoc """
  RED-by-default coverage for PREV-03 (sidebar + tabs + device/dark toggle
  + assigns form) and PREV-04 (LiveReload subscription + refresh). One
  test per ExUnit tag in 05-VALIDATION.md's per-task verification map.

  Plan 06 lands `MailglassAdmin.PreviewLive` with the mount/render/event
  shape from 05-PATTERNS.md §"preview_live.ex" and turns these RED tests
  green. Tests use literal string assertions from 05-UI-SPEC Component
  Inventory + Copywriting Contract.
  """

  use MailglassAdmin.LiveViewCase, async: false
  # LiveViewCase imports Phoenix.LiveViewTest and sets @endpoint to the
  # synthetic MailglassAdmin.TestAdopter.Endpoint.

  alias MailglassAdmin.Fixtures.{
    EmptyScenarioMailer,
    HappyMailer,
    StubMailer,
    BrokenMailer,
    HeaderCaseMailer
  }

  alias MailglassAdmin.Preview.{AssignsForm, Discovery, Sidebar}

  @readonly_note "Read-only values come from this scenario's defaults. Edit them in its Mailable."

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]
  @theme_cookie MailglassAdmin.Theme.cookie_name()

  setup %{conn: conn} do
    # Stash the explicit fixture list in the session so __session__/2's
    # default :auto_scan does not swallow fixture mailables. Plan 06 wires
    # session["mailables"] into the Discovery call on mount.
    conn = Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
    {:ok, conn: conn}
  end

  describe "orientation strip" do
    test "renders preview-orientation and preserves preview-empty-mailables when mailables is empty",
         %{conn: _conn} do
      # Use a conn with empty mailables (no session key) to trigger the zero-mailables branch
      empty_conn =
        Plug.Test.init_test_session(Phoenix.ConnTest.build_conn(), %{"mailables" => []})

      {:ok, _view, html} = live(empty_conn, "/dev/mail")

      # Both testids must be present simultaneously (GAP-11)
      assert html =~ ~s(data-testid="preview-orientation")
      assert html =~ ~s(data-testid="preview-empty-mailables")
    end
  end

  defp discovered_fixture_mailables do
    Discovery.discover(@fixture_mailables)
  end

  defp preview_pane_attrs(html) do
    [pane] =
      html
      |> Floki.parse_document!()
      |> Floki.find(~s([data-testid="preview-pane"]))
      |> Enum.filter(&(Floki.attribute(&1, "hidden") == []))

    %{
      frame_theme: Floki.attribute(pane, "data-preview-frame-theme"),
      data_theme: Floki.attribute(pane, "data-theme")
    }
  end

  describe "mailables picker" do
    @tag :sidebar
    test "directory variant renders discovered mailables with scenarios, no-previews, and error states" do
      html =
        render_component(&Sidebar.picker/1,
          mailables: discovered_fixture_mailables(),
          current_mailable: nil,
          current_scenario: nil,
          device_width: 768,
          admin_chrome_theme: nil,
          mount_path: "/dev/mail"
        )

      assert html =~ ~s(data-testid="preview-mailables-picker")
      assert html =~ ~s(data-picker-variant="directory")
      refute html =~ ~s(data-testid="preview-mobile-mailables")
      refute html =~ ~s(data-testid="preview-sidebar-desktop")
      assert html =~ "<h2"
      assert html =~ "Email previews"
      assert html =~ "Choose an email"
      assert html =~ "6 emails"
      refute html =~ "3 mailers"

      # HappyMailer module + scenarios rendered
      assert html =~ "HappyMailer"
      assert html =~ "welcome_default"
      assert html =~ "welcome_enterprise"
      refute html =~ "<details"
      refute html =~ "<summary"

      # StubMailer with no preview_props/0 shows the stub indicator
      assert html =~ "StubMailer"
      assert html =~ "No previews defined"

      # BrokenMailer rendered with a warning badge
      assert html =~ "BrokenMailer"

      assert html =~ "badge-warning" or html =~ "Error",
             "expected BrokenMailer to render with warning badge (badge-warning or 'Error' label)"
    end

    @tag :sidebar
    test "dead-render <head> stylesheet href is absolute under the mount path",
         %{conn: conn} do
      # Full scenario page (root layout) dead render — the LiveView client never
      # rewrites the <head>, so a relative `css-<hash>` href would 404.
      html =
        conn
        |> get("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")
        |> html_response(200)

      assert html =~ ~r|<link[^>]*rel="stylesheet"[^>]*href="/dev/mail/css-[0-9a-f]+"|
      refute html =~ ~s(href="css-)
    end

    @tag :sidebar
    test "a picker scenario link is an absolute mount-path URL that resolves to :show", %{
      conn: conn
    } do
      html =
        render_component(&Sidebar.picker/1,
          mailables: discovered_fixture_mailables(),
          current_mailable: nil,
          current_scenario: nil,
          device_width: 768,
          admin_chrome_theme: nil,
          mount_path: "/dev/mail"
        )

      # Grab the first scenario link the picker actually rendered.
      href =
        Regex.run(~r/href="(\/dev\/mail\/[^"]+welcome_default[^"]*)"/, html)
        |> case do
          [_, href] -> href
          _ -> flunk("no absolute /dev/mail picker scenario link found in:\n#{html}")
        end

      # Absolute (mount-aware), never a relative `./` ref.
      assert String.starts_with?(href, "/dev/mail/")
      refute String.contains?(href, "./")

      # Following that link must land on the :show route — no NoRouteError.
      target = href |> String.split("?") |> hd()
      {:ok, _show_view, show_html} = live(conn, target)

      assert show_html =~ "welcome_default"
      assert show_html =~ ~s(data-testid="preview-global-controls")
      assert show_html =~ ~s(data-testid="preview-header-controls")
      assert show_html =~ ~s(data-picker-variant="menu")
      assert show_html =~ ~s(data-testid="preview-email-menu-trigger")
      refute show_html =~ "3 emails"
      refute show_html =~ "3 mailers"

      document = Floki.parse_document!(show_html)

      trigger =
        document
        |> Floki.find(~s([data-testid="preview-email-menu-trigger"]))
        |> List.first()

      assert trigger != nil
      trigger_text = Floki.text(trigger)
      refute trigger_text =~ "3 emails"

      # Phase 178 D-04: humanized primary, Mailable secondary (both namespace-free),
      # and the exact technical identity as visible text.
      assert_trigger_identity(
        trigger,
        "Welcome default",
        "HappyMailer",
        "MailglassAdmin.Fixtures.HappyMailer.welcome_default"
      )

      [affordance] = Floki.find(trigger, ~s([data-testid="preview-email-menu-affordance"]))
      [affordance_class] = Floki.attribute(affordance, "class")
      assert Floki.find(affordance, "span") != []
      refute affordance_class =~ "border-base-300"
      refute affordance_class =~ "bg-base-200"
      refute affordance_class =~ "rounded-field"
      assert Floki.find(trigger, ".hero-chevron-down") == []
      assert Floki.find(trigger, ".hero-envelope") == []

      [menu_panel] =
        Floki.find(document, ~s([data-testid="preview-email-menu-panel"]))

      assert Floki.find(menu_panel, ~s([data-testid="preview-email-menu-count-row"])) == []
      assert Floki.find(menu_panel, ~s([data-testid="preview-email-menu-count"])) == []
      refute Floki.text(menu_panel) =~ "2 emails"
      refute Floki.text(menu_panel) =~ "MailglassAdmin.Fixtures"

      [group_label | _rest] =
        Floki.find(menu_panel, ~s([data-testid="preview-email-menu-group-label"]))

      [group_label_class] = Floki.attribute(group_label, "class")

      assert Floki.text(group_label) =~ "HappyMailer"
      assert group_label_class =~ "text-label"
      assert group_label_class =~ "uppercase"
      assert group_label_class =~ "text-secondary"
      refute group_label_class =~ "text-body"
      refute group_label_class =~ "text-base-content"

      scenario_lists =
        Floki.find(menu_panel, ~s([data-testid="preview-email-menu-scenario-list"]))

      assert scenario_lists != []

      for list <- scenario_lists do
        [class] = Floki.attribute(list, "class")
        assert class =~ "pl-sm"
      end

      [active_option] =
        Floki.find(menu_panel, ~s([data-testid="preview-email-menu-active-option"]))

      [active_class] = Floki.attribute(active_option, "class")

      assert Floki.text(active_option) =~ "welcome_default"
      assert Floki.attribute(active_option, "aria-current") == ["page"]
      assert active_class =~ "bg-primary/5"
      assert active_class =~ "text-base-content"
      refute active_class =~ "font-bold"
      refute active_class =~ "border-l-2"
      assert Floki.find(active_option, ".hero-check") != []

      for link <- Floki.find(menu_panel, "a") do
        [class] = Floki.attribute(link, "class")
        refute class =~ "border-l-2"
      end
    end
  end

  describe "preview page groups" do
    @tag :page_groups
    test "index redirects to the first previewable scenario", %{conn: conn} do
      assert {:error,
              {:redirect,
               %{
                 to: "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=768"
               }}} = live(conn, "/dev/mail")
    end

    @tag :page_groups
    test "index redirects legacy theme query before canonical scenario redirect", %{conn: conn} do
      assert {:error,
              {:redirect,
               %{
                 to: "/dev/mail/theme/dark?return_to=%2Fdev%2Fmail%3Fwidth%3D1024"
               }}} = live(conn, "/dev/mail?theme=dark&width=1024")
    end

    @tag :page_groups
    test "scenario branch does not render the old start page", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      refute html =~ ~s(data-testid="preview-start")
      refute html =~ "Render a real Message before you send it"
      refute html =~ "Preview the first email"
      refute html =~ ~s(data-picker-variant="directory")
    end

    @tag :page_groups
    test "empty branch renders locked copy and setup action without first Mailable CTA",
         %{conn: _conn} do
      empty_conn =
        Plug.Test.init_test_session(Phoenix.ConnTest.build_conn(), %{"mailables" => []})

      {:ok, _view, html} = live(empty_conn, "/dev/mail")

      assert html =~ ~s(data-testid="preview-empty-mailables")
      assert html =~ ~s(data-testid="admin-shell-page-header")
      assert html =~ "Preview"
      # D-09: onboarding leads with the brandbook Empty string verbatim and
      # surfaces the generator as the PRIMARY next step.
      assert html =~ "No mailables discovered yet."
      assert html =~ "mix mailglass.gen.mailable"

      document = Floki.parse_document!(html)
      [generator_command] = Floki.find(document, ~s([data-testid="preview-mailable-generator"]))
      assert String.trim(Floki.text(generator_command)) == "mix mailglass.gen.mailable"
      refute Floki.text(generator_command) =~ "`"

      assert html =~ "Read preview setup"
      refute html =~ "Preview the first email"
    end

    @tag :page_groups
    test "discovered Mailables without scenarios point to preview_props setup", %{conn: _conn} do
      no_scenario_conn =
        Plug.Test.init_test_session(Phoenix.ConnTest.build_conn(), %{"mailables" => [StubMailer]})

      {:ok, _view, html} = live(no_scenario_conn, "/dev/mail")

      assert html =~ ~s(data-testid="preview-no-previewable-mailables")
      assert html =~ "MailglassAdmin.Fixtures.StubMailer"
      assert html =~ "Add named scenarios to"
      assert html =~ "preview_props/0"
      refute html =~ ~s(data-testid="preview-empty-mailables")
      refute html =~ "mix mailglass.gen.mailable"
    end

    @tag :page_groups
    test "a valid empty scenario list uses the missing-scenario setup state", %{conn: _conn} do
      empty_scenario_conn =
        Plug.Test.init_test_session(Phoenix.ConnTest.build_conn(), %{
          "mailables" => [EmptyScenarioMailer]
        })

      {:ok, _view, html} = live(empty_scenario_conn, "/dev/mail")

      assert html =~ ~s(data-testid="preview-no-previewable-mailables")
      assert html =~ "MailglassAdmin.Fixtures.EmptyScenarioMailer"
      assert html =~ "preview_props/0"
      refute html =~ ~s(data-testid="preview-scenario-discovery-error")
    end

    @tag :page_groups
    test "scenario branch exposes header controls, assigns form, tab strip, and pane hooks",
         %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html =~ ~s(data-testid="admin-shell-topbar")
      assert html =~ ~s(data-testid="admin-shell-page-header")

      assert preview_subtitle(html) ==
               "Renders the scenarios in each Mailable's preview_props/0. It doesn't read Deliveries or Inbound messages from any Account."

      {:ok, doc} = Floki.parse_fragment(html)

      assert [_] =
               Floki.find(
                 doc,
                 ~s([data-testid="admin-shell-page-header"] p code.mono)
               )

      # D-12: no provenance claim. Whole-word, case-insensitive; "Deliveries"
      # contains the substring "live" and must not trip the check.
      refute preview_subtitle(html) =~ ~r/\b(sample|demo|fake)\b/i
      refute preview_subtitle(html) =~ ~r/\blive\b/i

      assert html =~ ~s(data-testid="admin-shell-sidebar")
      assert html =~ ~s(data-testid="surface-nav-sidebar")
      assert html =~ ~s(aria-current="page")
      assert html =~ "Preview"
      assert html =~ ~s(href="/ops/mail?tenant_id=browser-tenant")
      assert html =~ ~s(href="/ops/mail?tenant_id=browser-tenant&amp;view=deliveries")
      assert html =~ ~s(href="/ops/mail/inbound?tenant_id=browser-tenant")
      assert html =~ ~s(data-testid="preview-global-controls")
      assert html =~ ~s(data-testid="preview-header-controls")
      # Admin chrome theme lives in the global preview header. Scenario controls
      # keep only scenario-local tools: device width and preview backdrop.
      refute html =~ ~s(data-testid="preview-admin-theme-toggle")
      refute html =~ ~s(phx-click="toggle_theme")
      assert html =~ ~s(phx-click="set_theme")
      assert html =~ ~s(phx-value-theme="system")
      assert html =~ ~s(data-testid="preview-frame-theme-toggle")
      assert html =~ ~s(phx-click="toggle_preview_frame_theme")
      assert html =~ ~s(aria-label="Preview frame width in CSS pixels")
      assert html =~ "375 px"
      assert html =~ "768 px"
      assert html =~ "1024 px"
      assert html =~ "Frame width"
      assert html =~ "Preview background"
      assert html =~ ~s(aria-label="Help for preview background")

      assert html =~
               "Browser preview framing only. It does not establish email-client compatibility or dark-mode behavior."

      assert html =~ ~s(data-testid="preview-mailables-picker")
      assert html =~ ~s(data-picker-variant="menu")
      assert html =~ ~s(data-testid="preview-email-menu-trigger")
      refute html =~ ~s|xl:grid-cols-[18rem_minmax(0,1fr)]|

      {global_controls_index, _} = :binary.match(html, ~s(data-testid="preview-global-controls"))
      {theme_picker_index, _} = :binary.match(html, ~s(name="preview_admin_theme"))

      {scenario_controls_index, _} =
        :binary.match(html, ~s(data-testid="preview-header-controls"))

      assert global_controls_index < theme_picker_index
      assert theme_picker_index < scenario_controls_index

      # Hardened backdrop toggle: aria-pressed + aria-live announce region.
      assert html =~ ~s(aria-pressed=)
      assert html =~ ~s(data-testid="preview-backdrop-status")
      assert html =~ "Preview backdrop"
      assert html =~ ~s(data-testid="preview-assigns-form")
      assert html =~ ~s(data-testid="preview-tab-strip")
      assert html =~ ~s(data-testid="preview-pane")

      {picker_index, _} = :binary.match(html, ~s(data-testid="preview-mailables-picker"))
      {pane_index, _} = :binary.match(html, ~s(data-testid="preview-pane"))
      {form_index, _} = :binary.match(html, ~s(data-testid="preview-assigns-form"))

      assert picker_index < scenario_controls_index
      assert scenario_controls_index < pane_index
      assert pane_index < form_index
    end

    @tag :page_groups
    test "render error branch names the Mailable + scenario and the recovery target",
         %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__")

      assert html =~ ~s(data-testid="preview-render-error")
      assert html =~ ~s(data-testid="preview-mailables-picker")
      assert html =~ ~s(data-picker-variant="menu")
      assert html =~ ~s(data-testid="preview-email-menu-trigger")
      # D-10: generalized recovery-oriented headline; lead names BOTH the Mailable
      # and the scenario; the error card announces the transition (role=status).
      assert html =~ "This Mailable raised while rendering"
      assert html =~ "MailglassAdmin.Fixtures.BrokenMailer"
      assert html =~ "save to reload"
      assert html =~ ~s(role="status")
      # Inline scrollable <pre> kept (no redirect to logs — dev DX, D-10).
      assert html =~ "max-h-80"
      refute html =~ "Something went wrong"
    end
  end

  describe "scenario selection" do
    test "patching to another discovered scenario updates identity and renderer HTML", %{
      conn: conn
    } do
      path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
      {:ok, view, html} = live(conn, path)
      assert html =~ "Hi Ada"

      view
      |> element(~s(a[href*="welcome_enterprise"]))
      |> render_click()

      assert_patch(
        view,
        "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_enterprise?width=768"
      )

      html = render(view)
      assert html =~ "Hi Babbage — enterprise plan"

      [trigger] =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s([data-testid="preview-email-menu-trigger"]))

      assert_trigger_identity(
        trigger,
        "Welcome enterprise",
        "HappyMailer",
        "MailglassAdmin.Fixtures.HappyMailer.welcome_enterprise"
      )
    end

    test "compact picker exposes long non-ASCII scenario identity without truncation" do
      html =
        render_component(&Sidebar.menu/1,
          mailables: discovered_fixture_mailables(),
          current_mailable: HappyMailer,
          current_scenario: :welcome_überraschung_東京__with_a_deliberately_long_name,
          device_width: 375,
          admin_chrome_theme: nil,
          mount_path: "/dev/mail"
        )

      document = Floki.parse_document!(html)

      [label] = Floki.find(document, ~s([data-testid="preview-email-menu-label"]))
      assert String.trim(Floki.text(label)) == "Email preview"

      [trigger] = Floki.find(document, ~s([data-testid="preview-email-menu-trigger"]))
      assert Floki.find(trigger, ~s([data-testid="preview-email-menu-label"])) == []

      [label_id] = Floki.attribute(label, "id")
      [identity] = Floki.find(trigger, ~s([data-testid="preview-email-menu-active-identity"]))
      [identity_id] = Floki.attribute(identity, "id")
      assert Floki.attribute(trigger, "aria-labelledby") == ["#{label_id} #{identity_id}"]

      assert_trigger_identity(
        trigger,
        "welcome_überraschung_東京__with_a_deliberately_long_name",
        "HappyMailer",
        "MailglassAdmin.Fixtures.HappyMailer.welcome_überraschung_東京__with_a_deliberately_long_name"
      )

      [identity] = Floki.find(trigger, ~s([data-testid="preview-email-menu-active-identity"]))
      [identity_class] = Floki.attribute(identity, "class")
      # Phase 171: the long identity wraps inside the trigger (readable at 200% zoom
      # and 320 CSS px) rather than being clipped behind an ellipsis.
      refute identity_class =~ "truncate"
      assert identity_class =~ "whitespace-normal"
      assert identity_class =~ "[overflow-wrap:anywhere]"
      refute Floki.attribute(identity, "title") != []
    end
  end

  describe "Phase 178 selector options" do
    @long_double :welcome_überraschung_東京__with_a_deliberately_long_name
    @long_single :welcome_überraschung_東京_with_a_deliberately_long_name

    defp render_menu(overrides \\ []) do
      attrs =
        Keyword.merge(
          [
            mailables: discovered_fixture_mailables(),
            current_mailable: HappyMailer,
            current_scenario: :welcome_default,
            device_width: 375,
            admin_chrome_theme: nil,
            mount_path: "/dev/mail"
          ],
          overrides
        )

      render_component(&Sidebar.menu/1, attrs)
    end

    defp collapsed_text(node), do: node |> Floki.text() |> String.split() |> Enum.join(" ")

    defp happy_options(html) do
      html
      |> Floki.parse_document!()
      |> Floki.find(
        ~s(a[data-testid="preview-email-menu-option"], a[data-testid="preview-email-menu-active-option"])
      )
      |> Enum.filter(fn link ->
        link |> Floki.attribute("href") |> hd() |> String.contains?("HappyMailer/")
      end)
    end

    test "each HappyMailer option reads humanized first with the raw atom as monospace text" do
      options = html_options = happy_options(render_menu())
      assert length(html_options) == 6

      rows =
        for option <- options do
          [label] = Floki.find(option, ~s([data-testid="preview-email-menu-option-label"]))

          [technical] =
            Floki.find(option, ~s([data-testid="preview-email-menu-option-technical"]))

          [technical_class] = Floki.attribute(technical, "class")
          assert technical_class =~ "font-mono"
          {collapsed_text(label), collapsed_text(technical)}
        end

      assert {"Welcome default", "welcome_default"} in rows
      assert {"Welcome enterprise", "welcome_enterprise"} in rows
      assert {"Typed values", "typed_values"} in rows
      assert {"Recoverable", "recoverable"} in rows
    end

    test "the two long Unicode scenarios are distinguishable by visible primary text" do
      options = happy_options(render_menu())

      primaries =
        for option <- options,
            [label] = Floki.find(option, ~s([data-testid="preview-email-menu-option-label"])),
            collapsed_text(label) =~ "überraschung",
            do: collapsed_text(label)

      assert Enum.sort(primaries) == [Atom.to_string(@long_double), Atom.to_string(@long_single)]
      assert length(Enum.uniq(primaries)) == 2
    end

    test "no option span truncates and each wraps" do
      for option <- happy_options(render_menu()) do
        classes =
          option
          |> Floki.find("[class]")
          |> Enum.flat_map(&Floki.attribute(&1, "class"))
          |> Enum.join(" ")

        refute classes =~ "truncate"
        assert classes =~ "whitespace-normal"
        assert classes =~ "[overflow-wrap:anywhere]"
      end
    end

    test "option hrefs are the unchanged scenario_path/6 output, with and without return context" do
      scenarios = Keyword.keys(HappyMailer.preview_props())

      plain =
        for option <- happy_options(render_menu()), into: %{} do
          {option |> Floki.attribute("href") |> hd(), true}
        end

      assert plain ==
               Map.new(scenarios, fn scenario ->
                 {Sidebar.scenario_base_path("/dev/mail", HappyMailer, scenario) <> "?width=375",
                  true}
               end)

      return_query = [{"return_surface", "deliveries"}, {"return_tenant_id", "tenant-1"}]

      threaded =
        for option <- happy_options(render_menu(return_query: return_query)) do
          [href] = Floki.attribute(option, "href")
          uri = URI.parse(href)
          {uri.path, URI.decode_query(uri.query)}
        end

      for scenario <- scenarios do
        path = Sidebar.scenario_base_path("/dev/mail", HappyMailer, scenario)

        assert {path,
                %{
                  "width" => "375",
                  "return_surface" => "deliveries",
                  "return_tenant_id" => "tenant-1"
                }} in threaded
      end
    end

    test "open renders the details element open and the default does not" do
      default_details =
        render_menu() |> Floki.parse_document!() |> Floki.find("details") |> List.first()

      open_details =
        render_menu(open: true)
        |> Floki.parse_document!()
        |> Floki.find("details")
        |> List.first()

      assert Floki.attribute(default_details, "open") == []
      assert Floki.attribute(open_details, "open") == ["open"]
    end

    test "Mailables sharing a leaf show a distinguishing group label; the title keeps the module" do
      html =
        render_menu(
          mailables: [{Foo.Account.Mailer, [w: %{}]}, {Bar.Account.Mailer, [w: %{}]}],
          current_mailable: Foo.Account.Mailer,
          current_scenario: :w
        )

      document = Floki.parse_document!(html)

      labels =
        document
        |> Floki.find(~s([data-testid="preview-email-menu-group-label"]))
        |> Enum.map(&collapsed_text/1)

      assert labels == ["Foo.Account.Mailer", "Bar.Account.Mailer"]

      [mailable] = Floki.find(document, ~s([data-testid="preview-email-menu-active-mailable"]))
      assert collapsed_text(mailable) == "Foo.Account.Mailer"
    end

    test "empty, single, and unselected states keep their existing rows" do
      stub =
        render_menu(
          mailables: [{StubMailer, :no_previews}],
          current_mailable: nil,
          current_scenario: nil
        )

      assert stub =~ "No previews defined"
      assert stub =~ "Choose an email"
      refute stub =~ "preview-email-menu-active-technical"
      refute stub =~ "preview-email-menu-active-scenario"

      single =
        render_menu(
          mailables: [{HappyMailer, [only_one: %{}]}],
          current_scenario: :only_one
        )

      assert length(happy_options(single)) == 1
      assert single =~ "Only one"
    end

    test "render error shows the module-only technical identity" do
      html =
        render_menu(
          mailables: Discovery.discover([BrokenMailer]),
          current_mailable: BrokenMailer,
          current_scenario: :__error__
        )

      trigger =
        html
        |> Floki.parse_document!()
        |> Floki.find(~s([data-testid="preview-email-menu-trigger"]))

      assert_trigger_identity(
        trigger,
        "render error",
        "BrokenMailer",
        "MailglassAdmin.Fixtures.BrokenMailer"
      )
    end
  end

  describe "tabs" do
    @tag :tabs
    test "HTML, Text, Raw, Headers tabs each render the correct artifact",
         %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      {:ok, renderer_result} =
        Mailglass.Renderer.render(HappyMailer.welcome_default(%{user_name: "Ada"}))

      # HTML tab (default) renders an iframe with srcdoc
      html = render(view)

      assert html =~ ~r/<iframe[^>]*srcdoc=/i,
             "HTML tab must render <iframe ... srcdoc=\"...\"/>"

      [iframe] = Floki.find(Floki.parse_document!(html), "#tab-panel-html iframe")
      assert Floki.attribute(iframe, "srcdoc") == [renderer_result.swoosh_email.html_body]

      assert html =~ "Email HTML preview"
      assert html =~ "browser rendering only"
      assert html =~ ~s(sandbox="allow-same-origin")
      refute html =~ ~s(sandbox="allow-same-origin allow-scripts")

      # Every control reference must resolve, including inactive tabs. The
      # only exposed panel is the selected one and its accessible name comes
      # from that tab.
      document = Floki.parse_document!(html)
      tabs = Floki.find(document, ~s([role="tab"]))
      panels = Floki.find(document, ~s([role="tabpanel"]))

      assert length(tabs) == 4
      assert length(panels) == 4

      Enum.each(tabs, fn tab ->
        [panel_id] = Floki.attribute(tab, "aria-controls")
        [tab_id] = Floki.attribute(tab, "id")
        [panel] = Floki.find(document, "##{panel_id}")
        assert Floki.attribute(panel, "role") == ["tabpanel"]
        assert Floki.attribute(panel, "aria-labelledby") == [tab_id]
      end)

      assert Enum.count(panels, &(Floki.attribute(&1, "hidden") == [])) == 1
      assert Enum.count(tabs, &(Floki.attribute(&1, "aria-selected") == ["true"])) == 1

      # Text tab shows the literal rendered text_body
      text_html = render_click(view, "set_tab", %{"tab" => "text"})

      assert text_html =~ "Hi Ada",
             "Text tab must contain the rendered text_body literal"

      assert text_html =~ "<pre"
      [text_output] = Floki.find(Floki.parse_document!(text_html), "#tab-panel-text pre")
      assert Floki.text(text_output) == renderer_result.swoosh_email.text_body

      # Raw tab shows MIME boundary-looking content
      raw_html = render_click(view, "set_tab", %{"tab" => "raw"})

      assert raw_html =~ ~r/(boundary=|Content-Type:|MIME-Version:)/i,
             "Raw tab must contain RFC 5322 envelope markers"

      assert raw_html =~ "Example MIME source"
      assert raw_html =~ "provider may send a different format"

      # Headers tab shows auto-injected Message-ID + Date rows
      headers_html = render_click(view, "set_tab", %{"tab" => "headers"})

      assert headers_html =~ "Message-ID",
             "Headers tab must show the Message-ID row"

      assert headers_html =~ "Date",
             "Headers tab must show the Date row"

      assert headers_html =~
               "Message-ID and Date are generated when the scenario leaves them unset"

      assert headers_html =~ "Preview value"
      assert headers_html =~ ~r/preview-[0-9]+@mailglass\.dev/
    end

    test "lowercase supplied headers prevent generated duplicate headers", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"mailables" => [HeaderCaseMailer]})

      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HeaderCaseMailer/lowercase_headers")

      raw_html = render_click(view, "set_tab", %{"tab" => "raw"})
      assert raw_html =~ "message-id: &lt;provided@example.test&gt;"
      assert raw_html =~ "date: Fri, 09 Oct 2026 12:00:00 +0000"
      refute raw_html =~ ~r/Message-ID: &lt;preview-/i

      headers_html = render_click(view, "set_tab", %{"tab" => "headers"})
      assert headers_html =~ "message-id"
      assert headers_html =~ "date"
      refute headers_html =~ ~r/preview-[0-9]+@mailglass\.dev/
    end

    test "generated Date header uses RFC 5322 weekday and numeric zone format", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"mailables" => [HeaderCaseMailer]})

      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HeaderCaseMailer/generated_date")

      headers_html = render_click(view, "set_tab", %{"tab" => "headers"})
      document = Floki.parse_document!(headers_html)

      [date_row] =
        document
        |> Floki.find("tbody tr")
        |> Enum.filter(fn row ->
          [name | _] = Floki.find(row, "td") |> Enum.map(&Floki.text/1)
          String.trim(name) == "Date"
        end)

      [_, date_value] = Floki.find(date_row, "td") |> Enum.map(&Floki.text/1)

      assert date_value =~
               ~r/^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), \d{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{4} \d{2}:\d{2}:\d{2} \+0000$/
    end

    test "illustrative raw output includes both renderer-produced body representations" do
      conn =
        Plug.Test.init_test_session(Phoenix.ConnTest.build_conn(), %{
          "mailables" => [HeaderCaseMailer]
        })

      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HeaderCaseMailer/lowercase_headers")

      raw_html = render_click(view, "set_tab", %{"tab" => "raw"})
      [raw_output] = Floki.find(Floki.parse_document!(raw_html), "#tab-panel-raw pre")
      raw_text = Floki.text(raw_output)

      assert raw_text =~
               "Content-Type: multipart/alternative; boundary=\"mailglass_preview_boundary\""

      assert raw_text =~ "Content-Type: text/plain; charset=utf-8"
      assert raw_text =~ "Content-Type: text/html; charset=utf-8"
      assert raw_text =~ "hello"
      assert raw_text =~ "<p>hello</p>"
    end

    test "tabs expose empty HTML guidance and keep long non-ASCII plaintext complete" do
      text = String.duplicate("Prüfung 東京 — ", 1_000)

      html =
        render_component(&MailglassAdmin.Preview.Tabs.tabs/1,
          active_tab: :html,
          html_body: "",
          text_body: text,
          raw_envelope: "illustrative",
          headers: [],
          device_width: 768,
          render_nonce: 1,
          preview_frame_dark_chrome: false
        )

      assert html =~ "This email has no HTML content."
      assert html =~ "This email has no HTML content."

      text_html =
        render_component(&MailglassAdmin.Preview.Tabs.tabs/1,
          active_tab: :text,
          html_body: "",
          text_body: text,
          raw_envelope: "illustrative",
          headers: [],
          device_width: 768,
          render_nonce: 1,
          preview_frame_dark_chrome: false
        )

      assert text_html =~ text
      assert text_html =~ "whitespace-pre-wrap"
    end
  end

  describe "device toggle" do
    @tag :device_toggle
    test "device width toggle updates iframe width CSS inline",
         %{conn: conn} do
      {:ok, view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      # Initial default per 05-UI-SPEC line 184 is 768px (tablet).
      assert html =~ "width: 768px",
             "initial device width must be 768px per 05-UI-SPEC"

      html_375 = render_click(view, "set_device", %{"width" => "375"})
      assert html_375 =~ "width: 375px"

      button_375 =
        html_375
        |> Floki.parse_document!()
        |> Floki.find(~s(button[phx-value-width="375"]))

      assert Floki.text(button_375) =~ "375 px"
      assert Floki.attribute(button_375, "aria-pressed") == ["true"]

      html_1024 = render_click(view, "set_device", %{"width" => "1024"})
      assert html_1024 =~ "width: 1024px"
    end
  end

  describe "URL capture state" do
    @tag :url_state
    test "index route normalizes legacy theme query through persistence",
         %{conn: conn} do
      assert {:error,
              {:redirect,
               %{
                 to: "/dev/mail/theme/dark?return_to=%2Fdev%2Fmail"
               }}} = live(conn, "/dev/mail?theme=dark")

      assert {:error,
              {:redirect,
               %{
                 to: "/dev/mail/theme/light?return_to=%2Fdev%2Fmail"
               }}} = live(conn, "/dev/mail?theme=light")

      assert {:error,
              {:redirect,
               %{
                 to: "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=768"
               }}} = live(conn, "/dev/mail")
    end

    @tag :url_state
    test "width URL param and theme cookie are applied on mount for scenario routes",
         %{conn: conn} do
      path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=375"

      {:ok, _view, html} =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
        |> live(path)

      assert html =~ "width: 375px"
      assert html =~ ~s|data-theme="mailglass-dark"|
    end

    @tag :url_state
    test "invalid width falls back and leaves admin chrome unset",
         %{conn: conn} do
      invalid_path =
        "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=999"

      {:ok, _view, html} = live(conn, invalid_path)

      assert html =~ "width: 768px"

      refute html =~ ~r/data-testid="preview-shell"[^>]+data-theme="mailglass-light"/
      refute html =~ ~r/data-testid="preview-shell"[^>]+data-theme="mailglass-dark"/

      assert html =~
               ~r/data-preview-frame-theme="light"[^>]+data-theme="mailglass-light"[^>]+data-testid="preview-pane"/
    end

    @tag :url_state
    test "invalid legacy theme query is stripped without changing theme preference",
         %{conn: conn} do
      assert {:error,
              {:redirect,
               %{
                 to: "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=999"
               }}} =
               live(
                 conn,
                 "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=999&theme=unknown"
               )
    end

    @tag :url_state
    test "set_device keeps width URL state and set_theme persists outside the URL",
         %{conn: conn} do
      base_path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
      {:ok, view, _html} = live(conn, base_path <> "?width=768")

      render_click(view, "set_device", %{"width" => "375"})
      assert_patch(view, base_path <> "?width=375")

      render_click(view, "set_theme", %{"theme" => "dark"})

      assert_redirect(
        view,
        "/dev/mail/theme/dark?return_to=" <> URI.encode_www_form(base_path <> "?width=375")
      )
    end
  end

  describe "dark toggle" do
    @tag :dark_toggle
    test "preview frame theme toggle does not mutate admin shell data-theme",
         %{conn: conn} do
      {:ok, view, html} =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
        |> live("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html =~ ~s|data-theme="mailglass-dark"|
      assert html =~ ~s|data-preview-frame-theme="light"|
      assert html =~ ~r/data-preview-frame-theme="light"[^>]+data-theme="mailglass-light"/

      after_toggle = render_click(view, "toggle_preview_frame_theme", %{})

      assert after_toggle =~ ~s|data-theme="mailglass-dark"|
      assert after_toggle =~ ~s|data-preview-frame-theme="dark"|
      assert after_toggle =~ ~r/data-preview-frame-theme="dark"[^>]+data-theme="mailglass-dark"/
    end

    @tag :dark_toggle
    test "preview backdrop only changes HTML and text preview panes",
         %{conn: conn} do
      {:ok, view, html} =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
        |> live("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert preview_pane_attrs(html) == %{
               frame_theme: ["light"],
               data_theme: ["mailglass-light"]
             }

      render_click(view, "toggle_preview_frame_theme", %{})

      text_html = render_click(view, "set_tab", %{"tab" => "text"})

      assert preview_pane_attrs(text_html) == %{
               frame_theme: ["dark"],
               data_theme: ["mailglass-dark"]
             }

      raw_html = render_click(view, "set_tab", %{"tab" => "raw"})
      assert preview_pane_attrs(raw_html) == %{frame_theme: [], data_theme: []}

      headers_html = render_click(view, "set_tab", %{"tab" => "headers"})
      assert preview_pane_attrs(headers_html) == %{frame_theme: [], data_theme: []}
    end

    @tag :dark_toggle
    test "admin chrome toggle patches theme without changing preview frame theme",
         %{conn: conn} do
      base_path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
      {:ok, view, _html} = live(conn, base_path)

      render_click(view, "toggle_preview_frame_theme", %{})
      render_click(view, "set_theme", %{"theme" => "dark"})

      assert_redirect(
        view,
        "/dev/mail/theme/dark?return_to=" <> URI.encode_www_form(base_path <> "?frame=dark")
      )
    end

    @tag :dark_toggle
    test "picker scenario links preserve width but not app chrome theme",
         %{conn: conn} do
      {:ok, _view, explicit_html} =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
        |> live("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert explicit_html =~
               ~s|/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=768"|

      refute explicit_html =~ ~s|theme=dark|

      {:ok, _view, default_html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert default_html =~
               ~s|/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=768"|

      refute default_html =~ ~s|width=768&amp;theme=light|
      # Picker links are absolute, not relative `./` refs.
      refute default_html =~ ~s|href="./MailglassAdmin|
    end
  end

  describe "assigns form" do
    @tag :assigns_form
    test "assigns form re-renders preview on change",
         %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      after_change =
        render_change(view, "assigns_changed", %{"assigns" => %{"user_name" => "Grace"}})

      assert after_change =~ "Hi Grace",
             "iframe srcdoc must reflect updated user_name assign"
    end

    test "supported scalar edits preserve their types and update renderer output", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values")

      html =
        render_change(view, "assigns_changed", %{
          "assigns" => %{
            "label" => "東京 résumé",
            "quantity" => "8",
            "ratio" => "2.75",
            "enabled?" => "false",
            "due_on" => "2026-10-10"
          }
        })

      assert html =~ "東京 résumé 9 5.500000"
      assert html =~ "false 2026-10-11"
      assert html =~ ~s(value="東京 résumé")
    end

    test "render failure retains the editor and selected tab until a corrected edit succeeds", %{
      conn: conn
    } do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/recoverable")

      render_click(view, "set_tab", %{"tab" => "text"})

      failed =
        render_change(view, "assigns_changed", %{"assigns" => %{"response" => "fail"}})

      assert failed =~ ~s(data-testid="preview-assigns-form")
      assert failed =~ ~s(value="fail")
      assert failed =~ "deliberate recoverable preview failure"
      assert failed =~ "Last successful preview — not current"
      assert failed =~ "Recoverable first"
      assert failed =~ ~s(data-output-current="false")
      assert failed =~ ~s(data-testid="preview-render-retry")
      assert failed =~ ~s(phx-click="render_preview")
      assert failed =~ ~s(id="preview-state-status")

      [selected_tab] =
        failed
        |> Floki.parse_document!()
        |> Floki.find("#tab-btn-text")

      assert Floki.attribute(selected_tab, "aria-selected") == ["true"]

      corrected =
        render_change(view, "assigns_changed", %{"assigns" => %{"response" => "corrected"}})

      assert corrected =~ "Recoverable corrected"
      assert corrected =~ ~s(data-output-current="true")
      refute corrected =~ "deliberate recoverable preview failure"
      refute corrected =~ ~s(data-testid="preview-render-retry")
    end

    test "retry runs the render event and reset restores the default scenario", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/recoverable")

      render_change(view, "assigns_changed", %{"assigns" => %{"response" => "fail"}})

      retried =
        view
        |> element(~s([data-testid="preview-render-retry"]))
        |> render_click()

      assert retried =~ "deliberate recoverable preview failure"
      assert retried =~ ~s(data-testid="preview-assigns-form")
      assert retried =~ ~s(value="fail")

      reset = render_click(view, "reset_assigns", %{})

      assert reset =~ "Recoverable first"
      assert reset =~ ~s(data-output-current="true")
      refute reset =~ "deliberate recoverable preview failure"
      refute reset =~ ~s(data-testid="preview-render-retry")
    end

    test "invalid numeric and date drafts stay visible with field-associated errors", %{
      conn: conn
    } do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values")

      mixed_draft =
        render_change(view, "assigns_changed", %{
          "assigns" => %{"quantity" => "8items", "label" => "Long draft 東京"}
        })

      assert mixed_draft =~ ~s(value="Long draft 東京")
      assert mixed_draft =~ ~s(value="8items")

      for {key, invalid, message} <- [
            {"quantity", "8items", "Enter a whole number."},
            {"ratio", "2.75tail", "Enter a decimal number."},
            {"due_on", "2026-02-30", "Enter a valid calendar date."}
          ] do
        html =
          render_change(view, "assigns_changed", %{"assigns" => %{key => invalid}})

        assert html =~ "value=\"#{invalid}\""
        assert html =~ ~s(id="assigns-#{key}-error")
        assert html =~ ~s(aria-describedby="assigns-#{key}-error")
        assert html =~ ~s(aria-invalid="true")
        assert html =~ message
        assert_ids_closed!(html)
        refute_generic_helpers!(html)
      end
    end

    test "structured and timezone-sensitive defaults cannot be forged through form events", %{
      conn: conn
    } do
      {:ok, view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values")

      assert html =~ ~s(data-readonly-display="true")
      [note] = html |> Floki.parse_document!() |> Floki.find("#preview-assigns-readonly-note")
      assert String.trim(Floki.text(note)) == @readonly_note
      assert_ids_closed!(html)
      refute_generic_helpers!(html)
      refute html =~ ~s(name="assigns[metadata]")
      refute html =~ ~s(type="datetime-local")

      forged =
        render_change(view, "assigns_changed", %{
          "assigns" => %{
            "metadata" => %{"attacker" => "forged"},
            "scheduled_at" => "2026-10-10T00:00:00Z",
            "unknown_key" => "injected"
          }
        })

      [metadata_display] =
        forged
        |> Floki.parse_document!()
        |> Floki.find("#assigns-metadata")

      assert Floki.text(metadata_display) =~ "%{source: \"fixture\"}"
      refute Floki.text(metadata_display) =~ "forged"
    end

    test "free text fields have a stable form id and built-in debounce" do
      html = render_component(&AssignsForm.assigns_form/1, scenario_assigns: %{label: "Ada"})

      assert html =~ ~s(id="preview-assigns-form")
      assert html =~ ~s(phx-debounce="150")
      refute html =~ "Render preview"
      assert html =~ "Restore defaults"
      refute html =~ "Reset assigns"
    end

    test "restore defaults with no draft and no error re-renders the defaults (idempotent)", %{
      conn: conn
    } do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values")

      form = fn html ->
        html |> Floki.parse_document!() |> Floki.find("#preview-assigns-form") |> Floki.raw_html()
      end

      first = view |> render_click("reset_assigns", %{}) |> form.()
      second = view |> render_click("reset_assigns", %{}) |> form.()

      assert first == second
      assert first =~ ~s(value="Original")
      refute first =~ "-error"
    end

    test "the assigns form ends with one Restore defaults action using the secondary classes" do
      html =
        render_component(&AssignsForm.assigns_form/1, scenario_assigns: %{label: "Ada"})

      [button] =
        html |> Floki.parse_fragment!() |> Floki.find(~s(button[phx-click="reset_assigns"]))

      assert String.trim(Floki.text(button)) == "Restore defaults"

      assert Floki.attribute(button, "class") == [
               "mg-focus-ring btn btn-ghost min-h-11 px-md border border-base-300 w-full sm:ml-auto sm:w-auto"
             ]
    end

    test "editable fields carry no per-field helper and no -help ids" do
      for {key, value} <- [
            user_name: "Ada",
            quantity: 3,
            ratio: 1.5,
            subscribed: true,
            due_on: ~D[2026-10-09]
          ] do
        html = render_component(&AssignsForm.field/1, key: key, value: value)

        refute html =~ "aria-describedby"
        refute html =~ "-help"
        refute_generic_helpers!(html)
        assert_ids_closed!(html)
      end
    end

    test "one form-level note describes read-only values and each display references it" do
      html =
        render_component(&AssignsForm.assigns_form/1,
          scenario_assigns: %{user_name: "Ada", plan: :free}
        )

      document = Floki.parse_fragment!(html)

      assert [note] = Floki.find(document, "#preview-assigns-readonly-note")
      assert Floki.attribute(note, "data-testid") == ["preview-assigns-readonly-note"]
      assert String.trim(Floki.text(note)) == @readonly_note

      [plan] = Floki.find(document, "#assigns-plan")
      assert Floki.attribute(plan, "aria-describedby") == ["preview-assigns-readonly-note"]
      assert Floki.attribute(plan, "data-readonly-display") == ["true"]
      assert Floki.attribute(plan, "aria-readonly") == ["true"]

      [user_name] = Floki.find(document, "#assigns-user_name")
      assert Floki.attribute(user_name, "aria-describedby") == []

      assert_ids_closed!(html)
      refute_generic_helpers!(html)
    end

    test "the read-only note is absent with only editable fields or no editable values" do
      only_editable =
        render_component(&AssignsForm.assigns_form/1, scenario_assigns: %{user_name: "Ada"})

      refute only_editable =~ "preview-assigns-readonly-note"
      assert_ids_closed!(only_editable)

      no_editable =
        render_component(&AssignsForm.assigns_form/1, scenario_assigns: %{plan: :free})

      refute no_editable =~ "preview-assigns-readonly-note"
      assert no_editable =~ "There are no editable values here."
      assert_ids_closed!(no_editable)
    end

    test "every typed_values page state resolves its aria references", %{conn: conn} do
      {:ok, view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values")

      assert_ids_closed!(html)

      invalid = render_change(view, "assigns_changed", %{"assigns" => %{"quantity" => "8items"}})
      assert_ids_closed!(invalid)

      assert_ids_closed!(render_click(view, "reset_assigns", %{}))
    end

    test "assert_ids_closed!/1 fails on a dangling aria-describedby" do
      assert_raise ExUnit.AssertionError, fn ->
        assert_ids_closed!(~s(<div aria-describedby="missing"></div>))
      end

      assert_ids_closed!(~s(<p id="a"></p><div aria-describedby="a" aria-labelledby="a"></div>))
    end

    test "string assigns render stable labels, IDs and names without a helper" do
      html = render_component(&AssignsForm.field/1, key: :user_name, value: "Ada")

      assert html =~ ~s(<label for="assigns-user_name")
      assert html =~ ~s(id="assigns-user_name")
      assert html =~ ~s(name="assigns[user_name]")
      refute html =~ "aria-describedby"
      refute html =~ "assigns-user_name-help"
      assert html =~ "User name"
      refute html =~ "disabled"
    end

    test "boolean assigns render a checkbox with an explicit associated label" do
      html = render_component(&AssignsForm.field/1, key: :subscribed, value: true)

      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(id="assigns-subscribed")
      assert html =~ ~s(name="assigns[subscribed]")
      assert html =~ ~s(<label for="assigns-subscribed")
      refute html =~ "aria-describedby"
      refute html =~ "assigns-subscribed-help"
      assert html =~ "Subscribed"
    end

    test "atom assigns render as read-only display rows instead of fake disabled controls" do
      html = render_component(&AssignsForm.field/1, key: :mode, value: :preview)

      assert html =~ ~s(data-readonly-display)
      assert html =~ ~s(id="assigns-mode")
      assert html =~ ~s(aria-readonly="true")
      refute html =~ "aria-describedby"
      refute html =~ "assigns-mode-help"
      assert html =~ "(atom)"
      assert html =~ ":preview"
      refute html =~ ~s(type="text" disabled)
      refute html =~ ~s(disabled)
    end

    test "unsupported assigns render as read-only displays without disabled text inputs" do
      html = render_component(&AssignsForm.field/1, key: :options, value: {:ok, "raw"})

      assert html =~ ~s(data-readonly-display)
      assert html =~ ~s(id="assigns-options")
      assert html =~ ~s(aria-readonly="true")
      assert html =~ "unsupported type"
      refute html =~ ~s(type="text" disabled)
      refute html =~ ~s(disabled)
    end

    test "maps and timezone-sensitive DateTimes render as truthful read-only values" do
      for {key, value} <- [
            {:metadata, %{source: "fixture"}},
            {:scheduled_at, ~U[2026-10-09 12:00:00Z]}
          ] do
        html = render_component(&AssignsForm.field/1, key: key, value: value)

        assert html =~ ~s(data-readonly-display="true")
        refute html =~ "edit it in the Mailable scenario"
        refute html =~ "aria-describedby"
        refute html =~ "JSON"
        refute html =~ "<textarea"
      end
    end
  end

  describe "live reload" do
    @tag :g_168_8
    test "Preview success feedback dismisses its backing info flash", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      send(view.pid, {:mailglass_live_reload, "lib/my_app/user_mailer.ex"})

      before_dismiss = render(view)
      assert before_dismiss =~ ~s(id="flash-success")
      assert before_dismiss =~ ~s(role="status")
      assert before_dismiss =~ ~s(phx-value-key="info")
      assert before_dismiss =~ "alert-success"
      assert before_dismiss =~ "Reloaded: user_mailer.ex"

      dismissed =
        view
        |> element("#flash-success button[phx-click='lv:clear-flash']")
        |> render_click()

      refute dismissed =~ "Reloaded: user_mailer.ex"
      refute dismissed =~ ~s(id="flash-success")
      refute render(view) =~ "Reloaded: user_mailer.ex"
    end

    @tag :live_reload
    test "PreviewLive subscribes to mailglass:admin:reload and refreshes on broadcast",
         %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      # Broadcast the literal LINT-06-compliant topic. PreviewLive subscribes
      # on mount and `handle_info/2` puts a flash + re-discovers mailables.
      #
      # Message-shape note: the broadcast payload is `{:mailglass_live_reload,
      # path}` — NOT `{:phoenix_live_reload, topic, path}`. Phoenix.LiveView
      # 1.1's `Phoenix.LiveView.Channel` has a hardcoded handle_info clause
      # that intercepts every `{:phoenix_live_reload, _, _}` tuple BEFORE the
      # view's own handle_info runs (deps/phoenix_live_view/lib/phoenix_live_view/channel.ex:346).
      # Using a mailglass-scoped tag keeps the message in PreviewLive's
      # mailbox where our handler can act on it. Adopters who wire
      # phoenix_live_reload's `:notify` config to this topic must match this
      # payload shape — documented in MailglassAdmin.PubSub.Topics and the
      # README.
      Phoenix.PubSub.broadcast(
        Mailglass.PubSub,
        "mailglass:admin:reload",
        {:mailglass_live_reload, "lib/my_app/user_mailer.ex"}
      )

      :timer.sleep(50)

      assert render(view) =~ "Reloaded: user_mailer.ex",
             "LiveReload broadcast must surface a 'Reloaded: <file>' flash"
    end
  end

  # Every token in every aria-describedby / aria-labelledby must name an id in the
  # same fragment (PRVUX-06): a dangling token makes a screen reader announce nothing.
  # Phase 178 D-04: the trigger reads primary scenario, secondary Mailable, then
  # the exact technical identity as visible text. The primary and secondary
  # lines carry no fixture namespace; only the technical line does.
  defp assert_trigger_identity(trigger, primary, mailable, technical) do
    text_of = fn testid ->
      [node] = Floki.find(trigger, ~s([data-testid="#{testid}"]))
      node |> Floki.text() |> String.split() |> Enum.join(" ")
    end

    assert text_of.("preview-email-menu-active-scenario") == primary
    assert text_of.("preview-email-menu-active-mailable") == mailable
    assert text_of.("preview-email-menu-active-technical") == technical
    refute text_of.("preview-email-menu-active-scenario") =~ "MailglassAdmin.Fixtures"
    refute text_of.("preview-email-menu-active-mailable") =~ "MailglassAdmin.Fixtures"
    refute Floki.raw_html(trigger) =~ " · "
  end

  defp assert_ids_closed!(html) do
    document = Floki.parse_fragment!(html)

    ids =
      document
      |> Floki.find("[id]")
      |> Enum.flat_map(&Floki.attribute(&1, "id"))
      |> MapSet.new()

    for attribute <- ["aria-describedby", "aria-labelledby"],
        element <- Floki.find(document, "[#{attribute}]"),
        value <- Floki.attribute(element, attribute),
        token <- String.split(value),
        do:
          assert(
            MapSet.member?(ids, token),
            "#{attribute} token #{inspect(token)} has no matching id"
          )

    :ok
  end

  defp refute_generic_helpers!(html) do
    for generic <- [
          "Text value.",
          "Whole number.",
          "Decimal number.",
          "Toggle on or off.",
          ">Date.<"
        ] do
      refute html =~ generic, "generic per-field helper #{inspect(generic)} must not render"
    end

    refute html =~ ~r/id="assigns-[^"]*-help"/
  end

  defp preview_subtitle(html) do
    {:ok, doc} = Floki.parse_fragment(html)

    doc
    |> Floki.find(~s([data-testid="admin-shell-page-header"] p))
    |> hd()
    |> Floki.text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
