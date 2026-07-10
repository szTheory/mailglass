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

  alias MailglassAdmin.Fixtures.{HappyMailer, StubMailer, BrokenMailer}
  alias MailglassAdmin.Preview.{AssignsForm, Discovery, Sidebar}

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
      assert html =~ "2 emails"
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
      refute show_html =~ "2 emails"
      refute show_html =~ "3 mailers"

      document = Floki.parse_document!(show_html)

      trigger =
        document
        |> Floki.find(~s([data-testid="preview-email-menu-trigger"]))
        |> List.first()

      assert trigger != nil
      trigger_text = Floki.text(trigger)
      assert trigger_text =~ "HappyMailer"
      assert trigger_text =~ "welcome_default"
      refute trigger_text =~ "MailglassAdmin.Fixtures"
      refute trigger_text =~ "2 emails"
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
      assert html =~ "No mailables discovered yet. Define one with `mix mailglass.gen.mailable`"
      assert html =~ "mix mailglass.gen.mailable"

      assert html =~ "Read preview setup"
      refute html =~ "Preview the first email"
    end

    @tag :page_groups
    test "scenario branch exposes header controls, assigns form, tab strip, and pane hooks",
         %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html =~ ~s(data-testid="admin-shell-topbar")
      assert html =~ ~s(data-testid="admin-shell-page-header")

      assert html =~
               "Render an email exactly as your app would send it, then inspect HTML, text, raw source, headers, and assigns."

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

  describe "tabs" do
    @tag :tabs
    test "HTML, Text, Raw, Headers tabs each render the correct artifact",
         %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      # HTML tab (default) renders an iframe with srcdoc
      html = render(view)

      assert html =~ ~r/<iframe[^>]*srcdoc=/i,
             "HTML tab must render <iframe ... srcdoc=\"...\"/>"

      # Text tab shows the literal rendered text_body
      text_html = render_click(view, "set_tab", %{"tab" => "text"})

      assert text_html =~ "Hi Ada",
             "Text tab must contain the rendered text_body literal"

      # Raw tab shows MIME boundary-looking content
      raw_html = render_click(view, "set_tab", %{"tab" => "raw"})

      assert raw_html =~ ~r/(boundary=|Content-Type:|MIME-Version:)/i,
             "Raw tab must contain RFC 5322 envelope markers"

      # Headers tab shows auto-injected Message-ID + Date rows
      headers_html = render_click(view, "set_tab", %{"tab" => "headers"})

      assert headers_html =~ "Message-ID",
             "Headers tab must show the Message-ID row"

      assert headers_html =~ "Date",
             "Headers tab must show the Date row"
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

    test "string assigns render stable labels, IDs, names, and help associations" do
      html = render_component(&AssignsForm.field/1, key: :user_name, value: "Ada")

      assert html =~ ~s(<label for="assigns-user_name")
      assert html =~ ~s(id="assigns-user_name")
      assert html =~ ~s(name="assigns[user_name]")
      assert html =~ ~s(aria-describedby="assigns-user_name-help")
      assert html =~ ~s(id="assigns-user_name-help")
      assert html =~ "User name"
      refute html =~ "disabled"
    end

    test "boolean assigns render a checkbox with an explicit associated label" do
      html = render_component(&AssignsForm.field/1, key: :subscribed, value: true)

      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(id="assigns-subscribed")
      assert html =~ ~s(name="assigns[subscribed]")
      assert html =~ ~s(<label for="assigns-subscribed")
      assert html =~ ~s(aria-describedby="assigns-subscribed-help")
      assert html =~ ~s(id="assigns-subscribed-help")
      assert html =~ "Subscribed"
    end

    test "atom assigns render as read-only display rows instead of fake disabled controls" do
      html = render_component(&AssignsForm.field/1, key: :mode, value: :preview)

      assert html =~ ~s(data-readonly-display)
      assert html =~ ~s(id="assigns-mode")
      assert html =~ ~s(aria-readonly="true")
      assert html =~ ~s(aria-describedby="assigns-mode-help")
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
  end

  describe "live reload" do
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
end
