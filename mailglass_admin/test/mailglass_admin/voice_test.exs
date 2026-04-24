defmodule MailglassAdmin.VoiceTest do
  @moduledoc """
  RED-by-default coverage for BRAND-01 voice/tone enforcement against the
  rendered PreviewLive HTML — asserts the brand book "clear / exact /
  confident / warm / technical — a thoughtful maintainer" tone by matching
  canonical strings from 05-UI-SPEC §Copywriting Contract and refuting
  banned exclamations ("Oops!", "Whoops", "Uh oh", "Something went wrong").

  Plan 06 renders the PreviewLive HEEx with the exact strings from 05-UI-SPEC
  Component Inventory and Copywriting Contract and turns these RED tests
  green.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.Fixtures.{HappyMailer, StubMailer, BrokenMailer}

  describe "banned exclamations (05-UI-SPEC §Copywriting Contract)" do
    test "are absent from rendered UI", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"mailables" => [HappyMailer]})
      {:ok, _view, html} = live(conn, "/dev/mail")
      lower = String.downcase(html)

      refute lower =~ "oops",
             "brand voice: 'Oops' must never appear in admin UI"
      refute lower =~ "something went wrong",
             "brand voice: 'Something went wrong' is a banned generic error phrase"
      refute lower =~ "whoops",
             "brand voice: 'Whoops' must never appear in admin UI"
      refute lower =~ "uh oh",
             "brand voice: 'Uh oh' must never appear in admin UI"
    end
  end

  describe "canonical brand copy (05-UI-SPEC Copywriting Contract)" do
    test "sidebar + empty state strings appear verbatim", %{conn: conn} do
      conn =
        Plug.Test.init_test_session(conn, %{
          "mailables" => [HappyMailer, StubMailer, BrokenMailer]
        })

      {:ok, _view, html} = live(conn, "/dev/mail")

      # Sidebar heading
      assert html =~ "Mailers"

      # Main pane placeholder when nothing selected
      assert html =~ "Select a scenario from the sidebar to preview it."

      # Stub-mailable empty-state copy
      assert html =~ "No previews defined"

      # Error-card heading appears ONLY when BrokenMailer is loaded
      assert html =~ "preview_props/0 raised an error"
    end

    test "button labels use verb+noun form", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"mailables" => [HappyMailer]})

      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html =~ "Render preview",
             "primary CTA must be the verb+noun 'Render preview' (not bare 'Render')"

      assert html =~ "Reset assigns",
             "secondary action must be the verb+noun 'Reset assigns' (not bare 'Reset')"
    end
  end

  describe "live reload info log (Plan 06 persistent_term gating)" do
    # LiveReload topic subscription info log fires exactly once per boot.
    # Depends on Plan 06 landing :persistent_term gating from 05-PATTERNS.md
    # §":persistent_term once-per-BEAM gating". Defer assertion until then.
    @tag :skip
    test "LiveReload topic subscription info log fires exactly once per boot" do
      flunk("skipped until Plan 06 lands persistent_term-gated info log")
    end
  end
end
