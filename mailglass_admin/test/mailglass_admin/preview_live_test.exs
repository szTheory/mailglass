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

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]

  setup %{conn: conn} do
    # Stash the explicit fixture list in the session so __session__/2's
    # default :auto_scan does not swallow fixture mailables. Plan 06 wires
    # session["mailables"] into the Discovery call on mount.
    conn = Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
    {:ok, conn: conn}
  end

  describe "sidebar" do
    @tag :sidebar
    test "renders discovered mailables with scenarios, no-previews, and error states",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/mail")

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
  end

  describe "tabs" do
    @tag :tabs
    test "HTML, Text, Raw, Headers tabs each render the correct artifact",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

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
      {:ok, view, html} = live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      # Initial default per 05-UI-SPEC line 184 is 768px (tablet).
      assert html =~ "width: 768px",
             "initial device width must be 768px per 05-UI-SPEC"

      html_375 = render_click(view, "set_device", %{"width" => "375"})
      assert html_375 =~ "width: 375px"

      html_1024 = render_click(view, "set_device", %{"width" => "1024"})
      assert html_1024 =~ "width: 1024px"
    end
  end

  describe "dark toggle" do
    @tag :dark_toggle
    test "dark chrome toggle flips data-theme on wrapper",
         %{conn: conn} do
      {:ok, view, html} = live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html =~ ~s|data-theme="mailglass-light"|,
             "initial data-theme must be mailglass-light"

      after_toggle = render_click(view, "toggle_dark", %{})
      assert after_toggle =~ ~s|data-theme="mailglass-dark"|,
             "data-theme must flip to mailglass-dark after toggle_dark event"
    end
  end

  describe "assigns form" do
    @tag :assigns_form
    test "assigns form re-renders preview on change",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      after_change =
        render_change(view, "assigns_changed", %{"assigns" => %{"user_name" => "Grace"}})

      assert after_change =~ "Hi Grace",
             "iframe srcdoc must reflect updated user_name assign"
    end
  end

  describe "live reload" do
    @tag :live_reload
    test "PreviewLive subscribes to mailglass:admin:reload and refreshes on broadcast",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

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
