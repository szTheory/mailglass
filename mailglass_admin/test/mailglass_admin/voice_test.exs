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

  Plan 101-02 extends coverage to all three admin surfaces: Preview, Operator,
  and Inbound. Banned-word assertions run script-stripped to avoid the
  phoenix.mjs "noops" false positive. Flash-only strings are covered by
  source-level grep guards (D-11).
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.Fixtures.{HappyMailer, StubMailer, BrokenMailer}

  # Data-driven banned-word list (D-09, COPY-LD-09). Each entry is checked
  # case-insensitively against script-stripped HTML on every surface.
  @banned_words ~w[oops whoops "uh oh" "something went wrong"]

  describe "banned exclamations (05-UI-SPEC §Copywriting Contract)" do
    test "are absent from rendered UI", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"mailables" => [HappyMailer]})
      {:ok, _view, html} = live(conn, "/dev/mail")
      # Strip inlined <script>…</script> blocks before checking brand voice.
      # Phoenix inlines phoenix.mjs which contains "noops" (a logger no-op utility).
      # Checking the full HTML produces a false positive on that dep-JS token.
      # The brand-voice rule applies to the rendered UI markup, not embedded scripts.
      # See project memory: voice_test "Oops" is dep-JS noise.
      lower = html |> strip_scripts() |> String.downcase()

      Enum.each(@banned_words, fn word ->
        refute lower =~ word,
               "brand voice: #{inspect(word)} must never appear in admin UI (Preview surface)"
      end)
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
      assert html =~ "Mailables"

      # Start page shown when nothing is selected (mailables present)
      assert html =~ "Render a real Message before you send it"

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

  describe "Operator surface (/ops/mail)" do
    test "banned words absent from Operator surface", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, "/ops/mail")
      lower = html |> strip_scripts() |> String.downcase()

      Enum.each(@banned_words, fn word ->
        refute lower =~ word,
               "brand voice: #{inspect(word)} must never appear in admin UI (Operator surface)"
      end)
    end

    test "canonical COPY-LD strings present in Operator surface initial render", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, "/ops/mail?view=deliveries&tenant_id=test-tenant")

      # LD-11: orientation tip — "Delivery never arrived? Start here."
      # Rendered via Shell.orientation_strip surface={:deliveries} in the deliveries branch.
      assert html =~ "Delivery never arrived? Start here.",
             "LD-11: orientation tip must use domain noun Delivery (not Email)"

      # Spot-check: deliveries heading confirming operator surface renders correctly.
      assert html =~ "Deliveries",
             "Operator surface must render the deliveries heading on initial mount"
    end
  end

  describe "Inbound surface (/ops/mail/inbound)" do
    test "banned words absent from Inbound surface", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, "/ops/mail/inbound")
      lower = html |> strip_scripts() |> String.downcase()

      Enum.each(@banned_words, fn word ->
        refute lower =~ word,
               "brand voice: #{inspect(word)} must never appear in admin UI (Inbound surface)"
      end)
    end

    test "canonical COPY-LD strings present in Inbound surface initial render", %{conn: conn} do
      conn = operator_conn(conn)

      # Mount with a provider filter that can never match — forces the :filtered empty state
      # so the filtered-empty data_state is present in the first render.
      # Shell.orientation_strip surface={:inbound} renders in the is_nil(@detail) branch
      # (no record selected), so LD-12 and LD-16 are also present.
      {:ok, _view, html} =
        live(conn, "/ops/mail/inbound?tenant_id=voice-test-tenant&provider=no-such-provider")

      # LD-12: orientation tip — inbound surface.
      # HEEx HTML-escapes the apostrophe in "didn't" as &#39;.
      # Assert the HTML-entity form to match what the rendered output actually contains.
      assert html =~ "InboundMessage didn&#39;t route as expected? Inspect the routing trace.",
             "LD-12: orientation tip must use InboundMessage domain noun"

      # LD-16: rendered-pane select prompt (inbound-empty-detail div, always rendered
      # when no record is selected).
      assert html =~
               "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence.",
             "LD-16: no-selection prompt must use InboundMessage and Mailbox domain nouns"

      # LD-03: filtered empty-state body — Phase 113 UI-SPEC updated to "No records match
      # the current filters." (data_state/1 routes through title "No records" + this body).
      assert html =~ "No records match the current filters.",
             "LD-03: filtered empty state must be present (UI-SPEC copy from Phase 113)"
    end
  end

  describe "Flash string source guards (action-only strings)" do
    # Flash strings only render after a user action (put_flash/3 in event handlers),
    # so they cannot be asserted against a first-render. Assert at source level (D-11).

    test "inbound replay-success flash uses InboundMessage domain noun" do
      source = File.read!("lib/mailglass_admin/inbound_live.ex")

      assert source =~ "InboundMessage's timeline",
             "LD-13: replay flash must use InboundMessage not generic 'message'"
    end

    test "inbound no-selection flash matches LD-16 locked string" do
      source = File.read!("lib/mailglass_admin/inbound_live.ex")

      assert source =~
               ~s|"Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence."|,
             "LD-16: no-selection put_flash must use the locked LD-16 string"
    end
  end

  # Strips inlined <script>…</script> blocks from HTML before brand-voice checks.
  # Phoenix inlines phoenix.mjs which contains "noops" (a logger no-op utility).
  # Without stripping, the banned-word check produces a false positive on that token.
  # See project memory: voice_test "Oops" is dep-JS noise.
  defp strip_scripts(html) do
    Regex.replace(~r/<script\b[^>]*>.*?<\/script>/si, html, "")
  end

  # Builds an authenticated operator connection using the same session shape as
  # OperatorLive and InboundLive tests (operator Auth gate).
  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => "test-tenant",
      "auth_method" => "password",
      "recent_auth_at" => now
    })
  end
end
