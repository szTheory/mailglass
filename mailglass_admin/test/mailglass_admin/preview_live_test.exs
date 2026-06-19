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
  alias MailglassAdmin.Preview.AssignsForm

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]

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

  describe "sidebar" do
    @tag :sidebar
    test "renders discovered mailables with scenarios, no-previews, and error states",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/mail")

      assert html =~ ~s(data-testid="preview-mobile-mailables")
      assert html =~ ~s(data-testid="preview-sidebar-desktop")
      assert html =~ "<h2"
      assert html =~ "Mailables"

      # HappyMailer module + scenarios rendered
      assert html =~ "HappyMailer"
      assert html =~ "welcome_default"
      assert html =~ "welcome_enterprise"

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
      # Full page (root layout) dead render — the LiveView client never
      # rewrites the <head>, so a relative `css-<hash>` href would 404.
      html = conn |> get("/dev/mail") |> html_response(200)

      assert html =~ ~r|<link[^>]*rel="stylesheet"[^>]*href="/dev/mail/css-[0-9a-f]+"|
      refute html =~ ~s(href="css-)
    end

    @tag :sidebar
    test "a sidebar scenario link is an absolute mount-path URL that resolves to :show",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/mail")

      # Grab the first scenario link the sidebar actually rendered.
      href =
        Regex.run(~r/href="(\/dev\/mail\/[^"]+welcome_default[^"]*)"/, html)
        |> case do
          [_, href] -> href
          _ -> flunk("no absolute /dev/mail sidebar scenario link found in:\n#{html}")
        end

      # Absolute (mount-aware), never a relative `./` ref.
      assert String.starts_with?(href, "/dev/mail/")
      refute String.contains?(href, "./")

      # Following that link must land on the :show route — no NoRouteError.
      target = href |> String.split("?") |> hd()
      {:ok, _show_view, show_html} = live(conn, target)

      assert show_html =~ "welcome_default"
      assert show_html =~ ~s(data-testid="preview-header-controls")
    end
  end

  describe "preview page groups" do
    @tag :page_groups
    test "start branch renders locked copy and focusable first Mailable CTA",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/mail?theme=dark")

      assert html =~ ~s(data-testid="preview-start")
      assert html =~ "Render a real Message before you send it"

      assert html =~
               "Pick a Mailable from the sidebar to render it through the same pipeline your production sends use."

      assert html =~ "Preview the first Mailable"
      # Absolute, mount-aware URL — NOT a relative `./` ref (which the browser
      # resolves against `/dev` and 404s, since `/dev/mail` has no trailing slash).
      assert html =~
               ~s|href="/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?theme=dark"|

      refute html =~ ~s|href="./MailglassAdmin|
    end

    @tag :page_groups
    test "empty branch renders locked copy and setup action without first Mailable CTA",
         %{conn: _conn} do
      empty_conn =
        Plug.Test.init_test_session(Phoenix.ConnTest.build_conn(), %{"mailables" => []})

      {:ok, _view, html} = live(empty_conn, "/dev/mail")

      assert html =~ ~s(data-testid="preview-empty-mailables")
      assert html =~ "No Mailables discovered"

      assert html =~
               "Preview scans loaded modules that use Mailglass.Mailable. Nothing was found yet."

      assert html =~ "Read preview setup"
      refute html =~ "Preview the first Mailable"
    end

    @tag :page_groups
    test "scenario branch exposes header controls, assigns form, tab strip, and pane hooks",
         %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html =~ ~s(data-testid="preview-header-controls")
      assert html =~ ~s(data-testid="preview-admin-theme-toggle")
      assert html =~ ~s(phx-click="toggle_theme")
      assert html =~ ~s(data-testid="preview-frame-theme-toggle")
      assert html =~ ~s(phx-click="toggle_preview_frame_theme")
      assert html =~ ~s(data-testid="preview-assigns-form")
      assert html =~ ~s(data-testid="preview-tab-strip")
      assert html =~ ~s(data-testid="preview-pane")
    end

    @tag :page_groups
    test "render error branch names preview_props failure and recovery target",
         %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__")

      assert html =~ ~s(data-testid="preview-render-error")
      assert html =~ "preview_props/0 raised an error"
      assert html =~ "Fix the error in"
      assert html =~ "MailglassAdmin.Fixtures.BrokenMailer"
      assert html =~ "and save the file to reload."
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
    test "index route applies explicit admin chrome theme without forcing absent theme",
         %{conn: conn} do
      {:ok, _view, dark_html} = live(conn, "/dev/mail?theme=dark")
      assert dark_html =~ ~s(data-testid="preview-shell")
      assert dark_html =~ ~s|data-theme="mailglass-dark"|

      {:ok, _view, light_html} = live(conn, "/dev/mail?theme=light")
      assert light_html =~ ~s|data-theme="mailglass-light"|

      {:ok, _view, default_html} = live(conn, "/dev/mail")
      assert default_html =~ ~s(data-testid="preview-shell")
      refute default_html =~ ~s|data-theme="mailglass-light"|
    end

    @tag :url_state
    test "width= and theme= URL params are applied on mount for scenario routes",
         %{conn: conn} do
      path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=375&theme=dark"
      {:ok, _view, html} = live(conn, path)

      assert html =~ "width: 375px"
      assert html =~ ~s|data-theme="mailglass-dark"|
    end

    @tag :url_state
    test "invalid width falls back and invalid theme leaves admin chrome unset",
         %{conn: conn} do
      invalid_path =
        "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=999&theme=unknown"

      {:ok, _view, html} = live(conn, invalid_path)

      assert html =~ "width: 768px"
      refute html =~ ~s|data-theme="mailglass-light"|
      refute html =~ ~s|data-theme="mailglass-dark"|
    end

    @tag :url_state
    test "set_device and toggle_theme keep canonical width/theme URL params",
         %{conn: conn} do
      base_path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
      {:ok, view, _html} = live(conn, base_path <> "?width=768&theme=light")

      render_click(view, "set_device", %{"width" => "375"})
      assert_patch(view, base_path <> "?width=375&theme=light")

      render_click(view, "toggle_theme", %{})

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
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?theme=dark")

      assert html =~ ~s|data-theme="mailglass-dark"|
      assert html =~ ~s|data-preview-frame-theme="light"|

      after_toggle = render_click(view, "toggle_preview_frame_theme", %{})

      assert after_toggle =~ ~s|data-theme="mailglass-dark"|
      assert after_toggle =~ ~s|data-preview-frame-theme="dark"|
    end

    @tag :dark_toggle
    test "admin chrome toggle patches theme without changing preview frame theme",
         %{conn: conn} do
      base_path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
      {:ok, view, _html} = live(conn, base_path)

      render_click(view, "toggle_preview_frame_theme", %{})
      render_click(view, "toggle_theme", %{})

      assert_redirect(
        view,
        "/dev/mail/theme/dark?return_to=" <> URI.encode_www_form(base_path)
      )
    end

    @tag :dark_toggle
    test "sidebar scenario links preserve only explicit admin chrome theme",
         %{conn: conn} do
      {:ok, _view, explicit_html} = live(conn, "/dev/mail?theme=dark")

      assert explicit_html =~
               ~s|/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=768&amp;theme=dark|

      {:ok, _view, default_html} = live(conn, "/dev/mail")

      assert default_html =~
               ~s|/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=768"|

      refute default_html =~ ~s|width=768&amp;theme=light|
      # Sidebar links are absolute, not relative `./` refs.
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
